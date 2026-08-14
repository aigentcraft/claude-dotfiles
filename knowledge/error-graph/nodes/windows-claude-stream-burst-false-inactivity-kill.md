---
title: "windows-claude-stream-burst-false-inactivity-kill"
type: "error"
tags: ["windows", "claude-code", "subprocess", "streaming", "timeout", "buffering"]
date: "2026-08-07"
---

## 症状（Symptom）

Windowsで `claude -p --output-format stream-json` をPythonから呼ぶと、健全に実行中でも
「ストリーム90秒無応答」の監視に引っかかり3回連続killされた（reviewer=sonnetの長い検閲タスク）。
同じ仕組みの短いタスク（lead-handler・40秒）は成功する。

## 根本原因（Root Cause）

- Windowsでは claude.cmd（npmシム→node）経由のパイプで stdout がバースト到着することがあり、
  出力チャンク間の無応答時間が実際の生成状況と一致しない
- Mac/WSLの90-120秒設定をそのまま流用したため、長い生成（フルチェックリスト検閲）で誤killが発生

## 修正（Fix）

`workers/shared/claude_client.py` の run_agent で `os.name == "nt"` の場合に
`chunk_timeout` の下限を適用（呼び出し側は無変更・Mac不変）。当初は300秒。

**追記（2026-08-14・下限を600秒へ）**: 監査ダッシュボードで実データを集計したところ、300秒でも
writer/reviewer/researcher(sonnet)の重タスク（成功時でも平均214-231秒・**最大379秒**）が誤killされ
続けていた（対策後も17件）。実タスクの所要が無応答しきい値を上回るのが原因。下限を**600秒**へ引き上げた。
真のハング検知は `STEP_TIMEOUT`(3600秒)+リトライが担保する。軽タスクは正常時数十秒で600秒に達しないため無影響。
教訓: しきい値は「**最長クラスのタスクの実所要**」を実測してから決める（最大379秒に対し300秒は不足だった）。

## 予防ルール（Prevention）

1. ストリーム無応答監視のしきい値はOS・実行経路（直接/シム経由）で特性が違う前提で設計する
2. 「短いタスクは通るが長いタスクだけ落ちる」パターンはタイムアウト誤爆をまず疑う
3. kill系の安全装置を移植した時は、最長クラスのタスクで実測してから本番に載せる
