---
title: "レート制限のページを「求人 0 件」と読んでいた"
description: "429 のページには構造化データが載らない。読み取りは例外にならず空配列を返すため、ブロックされたことが『結果が無かった』に化ける。ステータスを見ないスクレイパは、制限を沈黙で飲み込む。"
type: "technical-error"
tags: ["rate-limit", "silent-failure", "scraping", "playwright", "cloudflare", "observability", "hootl"]
relationships:
  caused_by: []
  related_to:
    - "unmeasured-counted-as-zero-fabricates-rejection-evidence"
    - "stale-selector-reported-success-as-failure"
  fixes_node: []
---

## 1. Plan / Context

インディードの求人一覧は DOM のクラス名ではなく、ページが持つ構造化データから読んでいた。
クラス名より寿命が長く、壊れにくいという判断で、それ自体は正しい。

```ts
const results = window.mosaic?.providerData?.['mosaic-provider-jobcards']
  ?.metaData?.mosaicProviderJobCardsModel?.results ?? [];
```

## 2. Do / The Error

実行すると `求人検索: 0 件` と出る。エラーも警告も出ない。

実際にはインディードの Cloudflare が **HTTP 429**（表題「しばらくお待ちください…」）を
返していた。そのページには `window.mosaic` そのものが存在しない。

## 3. Check / Root Cause

**オプショナルチェーンと `?? []` が、ブロックを空配列に変換していた。**

`?.` は「無ければ undefined」を返すだけで、なぜ無いのかは問わない。
したがって次の 2 つが**同じ観測値 0** になる。

- 条件に合う求人が本当に 0 件だった
- ページを読ませてもらえなかった

区別する情報は **HTTP ステータスにしか無く、それを見ていなかった**。
防御的に書いたつもりの `?? []` が、そのまま沈黙装置になっていた。

同じセッションで、レート制限に掛かった原因も設計側にあった。
検索と本文取得で `withAuthenticatedPage` を**2 回**開いており、
その都度ログイン確認のプローブが走る。要求数が倍になっていた。

## 4. Act / Fix & Prevention

ページを開く箇所を 1 つに集約し、429 / 403 をタグ付きエラーにした。

```ts
async function openOrThrow(page: Page, url: string): Promise<void> {
  const response = await page.goto(url, { waitUntil: 'domcontentloaded' });
  const status = response?.status() ?? 0;
  if (status === 429 || status === 403) {
    throw Object.assign(new Error('レート制限に掛かりました（HTTP ' + status + '）'),
      { code: RATE_LIMITED });
  }
}
```

本文取得の途中で掛かったら残りを叩かず打ち切り、取れた分だけ活かして残りは次回へ繰り越す。

### 予防ルール

1. **`?? []` / `?? 0` を書く時は、「無い」の理由が 1 つかを確かめる。**
   理由が複数あるなら、その既定値は観測を潰している。
   空を返す前に、空になった理由を見られる情報（ステータス・表題）を必ず当たる。
2. **取得層は「成功して空」と「取得できなかった」を別の型で返す。**
   呼び出し側が区別できない形に丸めた時点で、上位のどこでも区別できない。
3. **レート制限の予算は「1 実行あたりの件数」ではなく「時間窓あたりの要求数」。**
   実測: 6 要求の実行が成功した 30 秒後の再実行が 429。
   実行単位で上限を設けても、連続実行は防げない。
4. **1 つの仕事を複数の認証セッションに分けない。** セッションごとに
   ログイン確認のプローブが走り、要求数がその分だけ増える。
   DB 参照など同期的な処理は、セッションの内側でやればよい。
5. **同名のセレクタでも寿命は別。** 同じ `.p-recruit__stop` が、詳細ページでは
   死んでいて一覧ページでは生きていた（実測）。片方の腐敗を見て
   もう片方も直したつもりになると、今度は生きている方を壊す。
   **場所ごとに診断する。**
