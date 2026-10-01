---
name: discord-gateway-dropped-silently-buttons-failed
title: Discord のゲートウェイが黙って落ち、プロセスは生きたままボタンが「インタラクションに失敗」した
cluster: observability
type: "runtime-error"
tags: ["discord", "gateway", "reconnect", "heartbeat", "watchdog", "fukugyo-hootl"]
date: 2026-09-30
severity: high
relationships:
  related_to:
    - "status-says-ready-but-the-page-was-never-served.md"
---

## ユーザーの指摘（原文）

「インタラクションに失敗しました、と出ています.#93の承認ボタン押したらｄました」／「切断を記録して自動で張り直す仕組みを入れて」

## 1. Plan / Context

常駐（cli/watch.ts）は discord.js の 1 クライアントでゲートウェイに接続し、ボタン（interaction）を受ける。
生存確認は `heartbeat.txt`（自前の setInterval で書く）。

## 2. Do / The Error

承認ボタンを押すと Discord が「インタラクションに失敗しました」を表示。ログには**1 行も**出ない。
プロセスは生きていて（PID 実在）、heartbeat も 1 分前に更新されていた。だが Discord のゲートウェイ接続だけが
落ちていて（最後のゲートウェイイベントは約 2 時間前）、discord.js の自動再接続も復旧しておらず、
interaction がハンドラに届いていなかった。3 秒 ACK が返らず Discord 側で失敗表示になる。

## 3. Check / Root Cause

- **heartbeat は生存の証拠にならない。** 自前タイマーで書くので、ゲートウェイが死んでも更新され続ける。
- 切断・再接続を**何もログに残していなかった**（shard 系イベントを購読していなかった）ので、
  落ちたことに気づけず、原因調査の手がかりも無かった。
- discord.js は通常は自動再接続するが、今回は復旧しなかった（ゾンビ化）。最後の安全弁が無かった。

## 4. Act / Prevention Strategy (Fix)

`discord/bot.ts` の startBridge に:
- shard の切断・エラー・再接続・再開・接続確立を必ずログに残す（ShardDisconnect / ShardError /
  ShardReconnecting / ShardResume / ShardReady）
- 30 秒ごとのウォッチドッグ: `client.ws.status !== Status.Ready` が 3 分続いたら `destroy()`→`login()` で張り直す。
  `close()` で `clearInterval`

### 予防ルール

1. **自前 heartbeat を「生きている」証拠にしない。** 外部接続の生死は、その接続自身のイベントで確かめる
2. 長寿命の外部接続（ゲートウェイ・WS・DB プール）は、**切断を必ずログに残し、再接続の最後の安全弁を持つ**
3. 「ボタンが赤字で失敗」の一次切り分けは「Bot がゲートウェイに繋がっているか」。ログが無音なら接続を疑う
