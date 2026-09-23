---
name: arrival-notice-hardwired-to-first-site-channel
title: インディードの新着が、ママワークスの #やり取り に届いていた（通知の宛先が既定値に固定）
cluster: observability
type: "runtime-error"
tags: ["discord", "routing", "multi-site", "default-destination", "notification", "fukugyo-hootl"]
date: 2026-09-23
severity: medium
relationships:
  related_to:
    - "fallback-notice-used-thread-api-on-channel.md"
---

## ユーザーの指摘（原文）

「なんでindeedの案件の通知がママworksのチャンネルに来てる？」

## 1. Plan / Context

新着メッセージは `handleArrival(bridge, channels, thread)` が受け、案件の投稿が無ければ
`bridge.notifyArrival(thread)` で #やり取り にスレッドを作る。`channels` はそのサイトのチャンネル一式。

## 2. Do / The Error

Discord に問い合わせると、インディードの新着 2 件（ビズリンク・インベスター）のスレッドの親が
**ママワークスの `💬やり取り`（1549262154996260894）**だった。ログは「Discord へ通知しました」で成功。

## 3. Check / Root Cause

- `notifyArrival` は**宛先を受け取らない**。Bot の設定のチャンネル（資格情報の account＝ママワークスの通知先）へ固定で出していた
- `handleArrival` はインディードの `channels` を受け取っていたが、この呼び出しにだけ渡していなかった
- 2026-09-17 にインディードの受信箱を足した時、表示（`siteLabel` 等）はサイト非依存にしたが、**送り先は単一サイト時代のまま**残った
- 同じ形がメール巡回にもあった: 企業名が一致したサイトが分かっていても、案件が無いと**先頭のサイト（ママワークス）**の #やり取り へ出していた
- **「通知しました」は届いたことしか言わない。どこに届いたかは見ていなかった**（C-2 の確認はログの成功行で済ませた）

## 4. Act / Prevention Strategy (Fix)

- `notifyArrival(thread, channelId)` にし、`handleArrival` が `channels.inbox` を渡す。Bot の設定のチャンネルは接続確認とメンション解決だけに使う
- メール巡回は、企業名が一致したサイトの #やり取り へ（案件も企業も分からない時だけ先頭のサイト）
- selftest に 3 件（宛先を受け取る形・常駐が渡す値・メールの宛先）。故障注入で FAIL を確認
- LINE の通知はサイトに属さないので先頭のサイトのまま（意図どおり）
- 既に出た 2 件のスレッドは Discord の仕様上チャンネル間を移動できないので、そのまま

### 予防ルール

1. **送り先を暗黙の既定値にしない。** 多サイト化したら「どこへ出すか」を引数で受け取り、既定値で届く道を消す
2. **通知の確認は「どこに届いたか」まで見る。** 成功ログは届いたことしか言わない。新しい経路は、最初の 1 件の親チャンネルを実物で確かめる
3. 2 つ目のサイトを足す時は、表示だけでなく**送り先・保存先・既定値**を全部洗う
