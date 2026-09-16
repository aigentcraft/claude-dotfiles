---
title: "ボット検知の正体が User-Agent の 1 語だけだった"
description: "Playwright のヘッドレスが Cloudflare に 403 された。IP でもフィンガープリントでもなく、UA に含まれる HeadlessChrome の文字列だけが原因で、表記を直すだけで無人実行のまま通った。"
type: "technical-error"
tags: ["playwright", "bot-detection", "cloudflare", "headless", "scraping", "hootl"]
relationships:
  caused_by: []
  related_to: ["recovery-implemented-but-not-wired"]
  fixes_node: []
---

## 1. Plan / Context
副業サイト自動化基盤に 2 サイト目（Indeed）を追加する。無人運用（HOOTL）が前提なので
`headless: true` で動かす必要がある。1 サイト目（ママワークス）は素の設定で問題なく動いていた。

## 2. Do / The Error
実装前の到達性確認で、トップもログイン画面も **403** を返した。

```
status      : 403
title       : Blocked - Indeed.com
body        : リクエストがブロックされました / Ray ID: a3bcddd4de9d915d
signals     : {"cloudflare":true,"captcha":true}
inputs      : []
```

「Indeed はボット検知が厳しい」で片付けると、**無人運用そのものを諦める**判断になる。

## 3. Check / Root Cause
条件を 1 つずつ変えて切り分けた（同一 IP・同一バイナリ・同一引数）。

| 条件 | 結果 |
|---|---|
| `headless: true` / 既定 UA | **403 Blocked** |
| `headless: false` / 既定 UA | 200 OK |
| `headless: true` / UA だけ実ブラウザ表記 | **200 OK** |

`headless: false` が通る時点で **IP ブロックではない**。
UA を替えるだけで通る時点で **フィンガープリント検知でもない**。

原因は UA に入るこの 1 語だけだった:

```
... AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.0.0 Safari/537.36
                                           ^^^^^^^^^^^^^^
```

## 4. Act / Fix & Prevention

実 UA から表記だけを直す。**版数ごと固定の UA をベタ書きしない**
（ブラウザを更新すると実バイナリと版数がズレ、その不一致自体が新たな検知材料になる）。

```ts
const ua = await page.evaluate(() => navigator.userAgent);
const masked = ua.includes('HeadlessChrome/')
  ? ua.replace('HeadlessChrome/', 'Chrome/')
  : null;   // 画面付きは元から正常なので何もしない
```

### 予防ルール

1. **「ブロックされた」を結論にしない。必ず 1 変数ずつ切り分ける。**
   最低限 headless / UA / IP の 3 つ。どれが効いているか分からないまま
   stealth プラグイン等の重い対策を入れると、原因も分からず依存だけ増える。
2. **制約は「自動化しない理由」ではなく「自動化の設計条件」。**
   403 を理由に有人運用へ落とすのは、切り分けを終えてからでよい。
3. **ブロックページは「未ログイン」と誤判定しやすい。**
   403 ページにはヘッダーも入力欄も無いため、ログイン状態の判定は
   描画ガードを先に見て `unknown` に落とすこと。
   さもないと上位エージェントが無限に再ログインを試みる。
