---
title: "失敗を握りつぶした直後に成功ログを出していた"
description: "catch で握りつぶした後に無条件で成功ログを出していたため、権限不足でチャンネル更新が全て失敗していたのに『更新しました』が4件並んでいた。ログが嘘をつくと調査自体が誤った前提から始まる。"
type: "technical-error"
tags: ["error-handling", "logging", "silent-failure", "discord", "observability"]
relationships:
  caused_by: []
  related_to: ["existence-vs-completion-check", "recovery-implemented-but-not-wired"]
  fixes_node: []
---

## 1. Plan / Context
Discord のチャンネル名・トピックを、設定を変えたら起動時に追随させる処理。
更新できなくても致命的ではない（名前が古いままになるだけ）ので、
例外で常駐プロセスを落としたくなかった。

## 2. Do / The Error
常駐ログに更新成功が 4 件並んでいた。

```
[ OK ] チャンネル名を更新: #やり取り-毎日8時・12時・18時
[ OK ] チャンネル名を更新: #案件探索-月木8時
[ OK ] チャンネル名を更新: #応募管理-随時
[ OK ] チャンネル名を更新: #受注指示-待機中
```

ところが同じ Bot は、別コマンドでカテゴリ作成に失敗していた。

```
DiscordAPIError[50013] Missing Permissions (status 403)
ManageChannels: false
```

**権限が無いのに「更新しました」が出る**という矛盾。実際には 4 件とも失敗していた。

## 3. Check / Root Cause

```ts
// 欠陥のあったコード
await channel.edit({ name: spec.name, topic }).catch(() => undefined);
log.ok('チャンネル名を更新: #' + spec.name);   // ← 常に実行される
```

`.catch(() => undefined)` は「落とさない」ためには正しい。
**間違いは、その直後に成功を無条件で報告したこと。**

握りつぶす判断（プロセスを止めない）と、
報告する内容（成功したか）は**別の判断**なのに、ひとつにまとめてしまっていた。

害は「ログが汚れる」ことではない。**調査の前提が壊れる。**
「更新は成功しているのだから権限はあるはずだ」と読めてしまい、
本当の原因（権限不足）から目を逸らす。

## 4. Act / Fix & Prevention

```ts
try {
  await channel.edit({ name: spec.name, topic });
  log.ok('チャンネル設定を更新: #' + spec.name);
} catch (error) {
  // 止めはしない。しかし成功したとは言わない。
  log.warn('チャンネル設定を更新できませんでした: #' + spec.name +
    (isMissingPermissions(error) ? '（権限がありません）' : ''));
}
```

### 予防ルール

1. **`.catch(() => ...)` の直後に成功ログを書かない。**
   握りつぶすなら、成否は分岐の中で報告する。
2. **「続行するか」と「成功したか」を分けて考える。**
   続行してよい失敗は多いが、成功と報告してよい失敗は無い。
3. **矛盾するログを見たら、まずログを疑う。**
   「権限が無いのに成功している」は、権限の謎ではなく報告の嘘であることが多い。
