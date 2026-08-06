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
`chunk_timeout = max(chunk_timeout, 300)` の下限を適用（呼び出し側は無変更・Mac不変）。

## 予防ルール（Prevention）

1. ストリーム無応答監視のしきい値はOS・実行経路（直接/シム経由）で特性が違う前提で設計する
2. 「短いタスクは通るが長いタスクだけ落ちる」パターンはタイムアウト誤爆をまず疑う
3. kill系の安全装置を移植した時は、最長クラスのタスクで実測してから本番に載せる
