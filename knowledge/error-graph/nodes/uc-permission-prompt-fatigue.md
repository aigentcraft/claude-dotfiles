---
title: "uc-permission-prompt-fatigue"
type: "user-correction"
tags: ["ai-behavior", "permissions", "claude-code", "workflow-friction"]
correction_category: "workflow-design"
date: "2026-08-06"
---

## 症状（Symptom）

検証フェーズで curl / wrangler / sqlite3 / node 等のコマンドを1つずつ実行するたびに承認プロンプトが発生し、ユーザーが2度指摘した:

> 「いちいち操作の承認が来るのがめんどくさい」
> 「バッシュコマンドの承認もめんどくさいし、いちいち承認していられない」

さらに、承認のたびに settings.local.json へ**一度きりの完全一致エントリ**（トークン平文入りの printf コマンド等）が蓄積し、AIが書いた整理版を承認機構が上書きで潰す事象も発生した。

## 根本原因（Root Cause）

- 検証サイクルが始まる**前に**プロジェクトの許可リストを整備しなかった（デフォルト設定のまま高頻度のコマンド実行フェーズに突入）
- 完全一致承認の蓄積は permission システムの仕様であり、放置すると秘密情報がsettingsに平文で残る

## 修正（Fix）

- `.claude/settings.local.json` を整理: 検証系プレフィックス許可（curl */node */npx */sqlite3 */git commit * 等）+ `defaultMode: "dontAsk"` + 危険操作のask維持（git push* / rm * / git reset * / git clean *）
- 秘密情報入りの一度きりエントリを削除

## 予防ルール（Prevention）

1. **検証・イテレーションフェーズに入る前に、そのセッションで多用するコマンド群をプレフィックスルールで許可しておく**（初回指摘を待たない）
2. settings.local.json に承認由来の完全一致エントリが溜まったら定期的に棚卸しし、**トークン・URL等の秘密が平文で残っていないか確認**する
3. dontAsk を使う場合は必ず ask 配列で破壊的操作（push/rm/reset/clean）をガードする
