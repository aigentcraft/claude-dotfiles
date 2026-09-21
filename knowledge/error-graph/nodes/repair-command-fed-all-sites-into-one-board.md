---
title: "1 サイト分のチャンネルに全サイトのデータを流し込み、整合コマンドが 40 件の誤投稿を作った"
description: "repair が listJobsByState を site で絞らずに回していた。チャンネルは 1 サイト分しか渡らないため、他サイトの案件がこのボードに生えた。ドライランを挟まずに実行して踏んだ。"
type: "technical-error"
tags: ["multi-tenant", "repair", "dry-run", "discord", "data-scoping", "fukugyo-hootl"]
relationships:
  caused_by: []
  related_to: ["approval-keyed-by-container-breaks-on-aggregation.md"]
  fixes_node: []
---

## 1. Plan / Context

副業サイトごとに Discord のカテゴリと案件ボード（フォーラム）を持つ。
`repair` は「案件に投稿があるか・タグが状態と合っているか」を整える整合コマンドで、
`ensureChannels(site)` で **1 サイト分の `ChannelMap`** を作って回す。

## 2. Do / The Error

「カードに応募ボタンが無い」を直す作業の一環で `npm run repair` を実行したところ:

```
対象案件        : 125 件
投稿を作成      : 49 件   ← 想定は数件
```

確認すると、**インディードの案件 40 件がママワークスのボードに作られていた**。
うち 28 件は `screening`（判定中）で 🔴要対応 タグが付くため、
**利用者のボードに要対応が 28 件増えた。**

## 3. Check / Root Cause

```ts
const jobs = states.flatMap((state) => listJobsByState(state));  // ← 全サイトが返る
for (const job of jobs) await syncJobPost(bridge, channels, job); // ← channels は 1 サイト分
```

`listJobsByState` はサイトを問わず返す。`JobRow` はどのサイトでも同じ形なので
**型では防げない**。投稿が無い案件には `createBoardPost(channels.board, ...)` が走り、
渡されたボード＝ママワークスに他サイトの案件が生えた。

**加えて、ドライランを挟まずに実行した。** `--dry-run` があるのに使わなかったため、
49 件という異常な件数を事前に見られなかった。

## 4. Act / Prevention Strategy (Fix)

1. `repair` の入口でサイトを 1 つに決め、`jobs.filter(j => j.site === site)` で絞る。
   `npm run repair -- <site>` でサイトを選べるようにした
2. 誤投稿の削除は条件を 3 つ全部満たすものだけに限定した
   （親が違う ∧ **メッセージ 0 件** ∧ DB に存在）。
   やり取りが入っている投稿は 1 件も触らない
3. 正しいボードに作り直して復旧

### 汎用ルール

> **「1 つ分のコンテキスト」を受け取る関数に、全体のデータを流し込まない。**
> テナント・サイト・アカウント単位の資源（チャンネル・プロファイル・認証）を
> 引数に取る処理は、**入口でデータも同じ単位に絞るのが唯一の防御**。
> レコードの型は同じなので、型検査は助けてくれない。

> **整合コマンドは必ずドライランしてから実行する。**
> 全件を舐める処理は、間違っていた時の被害も全件に及ぶ。
> 件数が想定と桁違いなら、そこで止まれる。
