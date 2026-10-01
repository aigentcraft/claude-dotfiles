---
name: uc-resident-leaked-working-notes-to-thread
title: 常駐エージェントの作業メモ（文字数の確認・最終版の宣言）までスレッドに出ていた
cluster: uc
type: "ai-behavior"
tags: ["uc", "agent", "discord", "streaming", "output-hygiene", "fukugyo-hootl"]
date: 2026-10-01
severity: low
relationships:
  related_to:
    - "uc-desk-agent-still-mechanical-one-shot.md"
---

## ユーザーの指摘（原文）

「415字で400〜600の範囲に入った。これで最終版とする。 という、実際に送信する内容ではないものはアウトプットしないで」

## 何が起きていたか

常駐の Claude Code（agent/resident.ts）は、アシスタントの発言を**出たそばから全部**スレッドへ投稿する作り。
応募文を整える作業中、モデルが自分向けに書いた「415字で範囲内。これで最終版とする」まで本人に届いた。

## 根本原因

- 「発言＝本人への返事」という前提で、流れてくる文章を区別せずに全部出していた
- モデル側には「あなたの発言は全部そのまま本人に見える」と伝えていなかった

## 予防ルール

1. 出力をそのまま人に見せる作りなら、**「発言は全部見える」ことをモデルに明示**し、作業メモを書かせない
2. 見せるのは結果・確認事項・実際に送る文面だけ。文面を見せる時は文面だけを出す
3. selftest で指示文にこの規則が入っていることを固定した
