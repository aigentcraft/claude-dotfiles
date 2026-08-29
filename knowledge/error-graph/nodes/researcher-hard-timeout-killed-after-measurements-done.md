---
title: "Researcher Was Killed by the 30-Minute Hard Limit After Finishing All Measurements (3 Retries, Same Result)"
description: "weevee claude_client enforces OVERALL_TIMEOUT_SEC=1800 per attempt with 3 retries. The article-13 researcher signed up to Notta/Rimo/tl;dv, uploaded two audio files each and saved six transcripts to the lab dir, but each attempt exceeded 30 minutes before writing the factsheet; every retry restarted the agent with a fresh context and re-explored instead of reusing the saved outputs. ~90 minutes and 3 attempts produced no factsheet. Fix: per-call overall_timeout (researcher 90 min) and an explicit 'resume from existing lab outputs' instruction."
type: "bug"
tags: ["timeout", "retry", "research-lab", "resume", "claude-client", "weevee"]
---

## 1. Plan / Context
`claude -p` の安全弁: 無応答 chunk_timeout + 絶対上限 30 分 + 3 回リトライ。ラボ dir（成果物）は試行をまたいで残る。

## 2. Do / The Error（2026-08-30 記事 13 再調査 3 回目）
- 3 サービスへのサインアップ（OTP はブラウザ Gmail 経由）・音声 2 本ずつのアップロード・文字起こし 6 本の保存まで完了
- 30 分の上限で kill → リトライは新しいコンテキストで最初から探索 → 再び上限 → 3 回目も同じ → factsheet なし・$4 消費

## 3. Check / Root Cause
1. 上限がタスクの性質（外部サービスの処理待ち・OTP 待ち）を考慮しない固定値だった
2. リトライは「同じ入力で再実行」であり、**前回試行の成果物を使えと伝えていない**ため再開にならない
3. 成果物は揃っていたので、書き上げだけを再開できれば数分で終わっていた

## 4. Act / Prevention Strategy (Fix)
- `run_agent(..., overall_timeout=)` を追加し 03 は 90 分を指定
- 03 のタスクに「ラボ dir の `out_*.txt` / `shots/` / `lab.log` を最初に読み、取得済みは再実測しない」を明記
- **予防ルール: リトライする長時間エージェントには、必ず「前回の成果物の在処」と「そこから再開せよ」を入力に含める。上限は作業の種類ごとに呼び側で決める**
- 関連: [[headless-browser-blank-app-screens-bot-detection]] [[chunk-timeout-90-truncated-long-generation]]
