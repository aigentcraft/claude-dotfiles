---
title: "回復機能を実装したのに、必要な経路に配線していなかった"
description: "自動ログイン関数は実装済みだったが、有人コマンドにしか繋がっておらず、無人実行の経路では失効時に例外を投げて停止した。ドキュメントには「再ログイン不要」と書いていたが実測していなかった。"
type: "technical-error"
tags: ["automation", "resilience", "design-gap", "verification"]
relationships:
  caused_by: []
  related_to: ["claude-cli-headless-oauth-expiry", "ai-instruction-enforcement"]
  fixes_node: []
---

## 1. Plan / Context
副業HOOTL は「人間の介在を初回の資格情報登録だけに閉じ込める」ことを設計目標にしていた。
Keychain から資格情報を読んで自動ログインする `performAutoLogin()` も実装済みだった。

## 2. Do / The Error
実装から約2時間後、無人実行の入口である `withAuthenticatedPage()` を呼んだところ:
```
Error: ママワークス にログインしていません（状態: anonymous）。
次のコマンドでブラウザを開き、ログインしてください:
  npm run login -- mamaworks
```
セッションが失効しただけで**停止し、人間を呼んだ**。

## 3. Check / Root Cause
`performAutoLogin()` は実装されていたが、**有人コマンド `cli/login.ts` からしか呼ばれていなかった。**
無人実行の入口 `core/runtime.ts` は失効を検知すると例外を投げるだけだった。

```ts
// 欠陥のあったコード
const probe = await probeAuthState(adapter, page);
if (probe.state !== 'authenticated') {
  throw authRequiredError(adapter, probe.state, probe.detail);  // ← 回復を試みない
}
```

**能力を実装しても、必要な経路に配線しなければ存在しないのと同じ。**

さらに悪いことに、`CLAUDE.md` と commit メッセージには
「以降のエージェント実行は再ログイン不要」と書いていた。**実測せずに書いた主張だった。**
セッションが生きている間しかテストしていなかったため、失効という最も起きる事象を一度も通していない。

## 4. Act / Prevention Strategy (Fix)

```ts
let probe = await probeAuthState(adapter, page);

// セッションは必ず失効する。資格情報があるなら自動で再ログインして自己回復する。
if (probe.state === 'anonymous' && adapter.performLogin) {
  const credential = readCredential(siteId);
  if (credential) {
    await performAutoLogin(adapter, context, credential);
    probe = await probeAuthState(adapter, page);
  }
}
if (probe.state !== 'authenticated') throw authRequiredError(...);
```

実測（失効状態から）: 失効検知 → 自動再ログイン → データ取得が 4 秒で完了。

### 予防ルール

1. **回復機能を作ったら、それを必要とする経路を全部列挙して配線する。**
   「実装した」と「その経路で呼ばれる」は別。有人経路だけ繋いで満足しやすい。
2. **「〜は不要になる」「以降は自動で〜」と書いたら、その主張を実測してから書く。**
   書いた時点では検証していない仮説にすぎない。
3. **劣化条件を意図的に作ってテストする。** セッション失効・トークン失効・ネットワーク断は
   「いつか起きる例外」ではなく「必ず起きる通常状態」。正常系だけのテストは未検証と同じ。
   失効を待てない場合は、セッションを削除して人工的に作る。
4. **ドキュメントの主張は「実測済み」と「設計意図」を区別して書く。**
   設計意図を実績のように書くと、自分も後続も検証済みだと誤認する。
