---
title: "stale-claude-md-duplicate-implementation"
type: "error"
tags: ["multi-machine", "git", "claude-md", "session-handoff", "duplicate-work"]
date: "2026-08-06"
---

## 症状（Symptom）

Windowsセッションが CLAUDE.md の「未解決・次のタスク」（db/schema.sql・エージェント定義・/api/lead が未実装）を根拠に半日分の実装を行ったが、**origin/main には Mac セッションが同じ機能の完成版を既に push 済み**だった（Phase 0 完走・記事公開まで済み）。3コミット分の実装を破棄してリセットする羽目になった。

## 根本原因（Root Cause）

- 2台開発（Windows/Mac）で CLAUDE.md の「現在の作業状態」は**書いた瞬間から陳腐化する**。作業ブランチ（feature/website）だけ fetch し、main の進行を確認しなかった
- セッション冒頭の `git fetch` は行ったが、**origin/main と作業ブランチの差分（`git log origin/main..HEAD` / `git merge-base`）を見る習慣がなかった**
- 「CLAUDE.md に未実装と書いてある」を実装済みでないことの証拠として扱った（ドキュメント＝真実の思い込み）

## 修正（Fix）

- feature/website を origin/main に `reset --hard`（ユーザー承認済み）し、main 実装を正とした
- 当日の非重複成果（kintoneアプリ実地確認・APIトークン発行・Pages Git連携移行・D1初期化）は維持

## 予防ルール（Prevention）

1. **セッション開始時に必ず `git fetch origin && git log --oneline -5 origin/main` を実行し、CLAUDE.md の記載と突合する**。差異があれば CLAUDE.md ではなく main を正とする
2. 機能実装に着手する前に、**その成果物ファイルが origin/main に存在しないか `git ls-tree origin/main <path>` で確認**する
3. マルチマシン運用では「区切りごとに main へマージ」だけでなく「**セッション終了時に必ず push**」を徹底する（今回のMac側は push していたのに Windows側が見なかった —— 見る側のルール化が必要）
