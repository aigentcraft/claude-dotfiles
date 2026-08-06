---
title: "uc-reverted-user-config-without-asking-intent"
type: "uc"
tags: ["uc", "settings", "permissions", "user-intent", "claude-code"]
date: "2026-08-06"
---

## 症状（Symptom）

settings.json 修復時、`defaultMode: bypassPermissions` を「コミット済み内容からの逸脱＝間違い」と断定して削除・復元しようとし、ユーザーに書き込みを拒否された（「バイパスで良くて、承認は余程重要じゃない限りいらない」）。

## 根本原因（Root Cause）

- 「git の diff ＝ 誤り」という推定で進めた。**手動で加えられた設定変更はユーザーの意図である可能性**を確認しなかった
- 修正内容に「ユーザーの運用方針を上書きする要素（承認プロンプト復活）」が含まれるのに、方針確認なしで書き込みに進んだ

## 修正（Fix）

bypassPermissions を維持したまま秘密防御（deny+フック）をマージする形で決着。方針は feedback メモリに保存済み。

## 予防ルール（Prevention）

1. **設定ファイルの diff を「壊れた」と断定する前に、その変更がユーザーの意図か1行確認する**（特に permissions / defaultMode などの運用方針系）
2. 復元とユーザー変更の維持は排他ではない — まずマージ案を提示する
