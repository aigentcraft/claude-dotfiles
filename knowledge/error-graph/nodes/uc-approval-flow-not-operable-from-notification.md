---
title: "uc-approval-flow-not-operable-from-notification"
type: "uc"
tags: ["uc", "hitl", "discord", "approval", "ux", "pullie"]
date: "2026-08-07"
---

## 症状（Symptom）

記事承認フローを「Discordに通知→ユーザーがClaude Codeチャットに戻って『承認』と打つ」設計のまま完成扱いにし、ユーザーに「ディスコードから承認・差し戻しの操作ができないと意味ない」と指摘された。さらに肝心の通知自体が届いていなかった（notify失敗が戻り値boolのまま握りつぶされ、どこにも警告されない）。

## 根本原因（Root Cause）

- HITLの承認UXを「通知が届くこと」で完成と定義し、**承認者がその場で完結できるか**（操作の往復コスト）を要件にしていなかった
- notify.discord の失敗がサイレント（False返却のみ・ログなし）で、未達に誰も気づけない

## 修正（Fix）

1. notify失敗を execution_logs に warn 記録するよう修正
2. Discord Interactions（ボタン+差し戻し理由モーダル）→ Cloudflare Worker → D1 approvals → run_pipeline が回収、の承認基盤を実装

## 予防ルール（Prevention）

1. **HITL設計は「人間が受け取る」でなく「人間がその場で完結する」を完成条件にする**（通知チャネル=操作チャネル）
2. 通知・外部送信系の失敗は必ずログに残す。「失敗しても主処理を殺さない」と「失敗を無音にする」を混同しない
3. 通知機能は実装時に必ず1回実送信して着信目視まで確認する
