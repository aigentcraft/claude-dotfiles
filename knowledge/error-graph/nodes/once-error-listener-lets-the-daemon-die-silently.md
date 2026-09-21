---
title: "起動用の once('error') を残したまま運用すると、2 回目のエラーで常駐が無言で死ぬ"
description: "接続待ちに使った once(Events.Error, reject) を外さずにいると、1 回目の error でリスナが消え、2 回目は listener 不在で EventEmitter が throw する。ログを 1 行も残さず常駐が終了し、利用者にはボタンが効かないとしか見えない。"
type: "technical-error"
tags: ["daemon", "discord", "event-emitter", "silent-failure", "observability", "fukugyo-hootl"]
relationships:
  caused_by: []
  related_to: ["uc-error-message-names-the-symptom-not-the-cause.md"]
  fixes_node: []
---

## 1. Plan / Context

Discord Bot を常駐させ、ボタン操作を受けて不可逆操作（求人への応募・企業への返信送信）を行う。
接続完了は `ClientReady` を待ち、失敗時に備えて `once(Events.Error, reject)` を張っていた。

```ts
await new Promise<void>((resolve, reject) => {
  client.once(Events.ClientReady, () => resolve());
  client.once(Events.Error, reject);          // ← 接続後も残る
  client.login(config.token).catch(reject);
});
```

## 2. Do / The Error

利用者からの報告（2026-09-21）:

> 承認して応募する、のボタンをおしたけど**時間内に反応しなかった**と赤字でエラーが出ている

調べると常駐は**終了コード 1 で停止**しており、ログは最後の成功行
（`[16:28:23] [ OK ] 応募完了 job#62`）で途切れ、**理由が 1 行も書かれていなかった**。
Bot が繋がっていないので Discord は 3 秒の ACK を受け取れず、赤字の
「アプリケーションは応答しませんでした」を出していた。

## 3. Check / Root Cause

2 つが重なっていた。

1. **`once` のリスナが接続後も残っていた。**
   接続後の 1 回目の gateway error で `reject`（解決済み Promise なので無害）が呼ばれ、
   **リスナが外れる**。2 回目の error は listener 不在となり、
   EventEmitter の仕様で `'error'` は throw される → プロセス終了。
2. **`unhandledRejection` / `uncaughtException` を登録していなかった。**
   そのため死因がどこにも記録されない。

症状が「ボタンが効かない」としか見えないのが最悪で、
**利用者は UI のバグを疑い、運用者はログを見ても何も分からない。**

## 4. Act / Prevention Strategy (Fix)

```ts
let failStartup: ((e: unknown) => void) | null = null;
const onStartupError = (e: unknown) => failStartup?.(e);
await new Promise<void>((resolve, reject) => {
  failStartup = reject;
  client.once(Events.ClientReady, () => resolve());
  client.on(Events.Error, onStartupError);
  client.login(config.token).catch(reject);
});
// 接続できたら恒久リスナへ差し替える（**落とさずに記録する**）
client.off(Events.Error, onStartupError);
client.on(Events.Error, (e) => log.error('Discord の接続でエラー: ' + String(e)));
```

さらに `unhandledRejection` / `uncaughtException` を登録し、
**スタックを書いてから**終了するようにした（即 `exit` すると出力が切れるので少し待つ）。

### 汎用ルール

> **起動待ちに使ったリスナは、起動できた時点で必ず外す。**
> `once(..., reject)` を残すと「1 回目は無害・2 回目で突然死」という、
> 再現しにくく原因も残らない壊れ方をする。

> **常駐は死因を必ず書いてから死ぬ。** `unhandledRejection` と `uncaughtException` を
> 登録していない常駐は、落ちた瞬間に調査手段が消える。
> 利用者に見えるのは「操作が効かない」だけで、実装のどこを見ればよいか分からない。
