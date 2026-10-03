---
name: gas-webapp-intermittent-404-on-rapid-calls
title: Google Apps Script のウェブアプリが、続けて呼ぶと時々 HTTP 404 のページを返す（作る要求は送り直すと二重になる）
cluster: external-api
type: "runtime-error"
tags: ["google-apps-script", "calendar", "retry", "idempotency", "fukugyo-hootl"]
date: 2026-10-03
severity: medium
relationships:
  related_to:
    - "uc-secretary-relays-without-verifying-or-acting.md"
---

## 1. Plan / Context

副業HOOTL の予定の自動登録は、Apps Script のウェブアプリ（合言葉つき POST）でカレンダーを読み書きする。
POST は 302 で script.googleusercontent.com に転送され、GET で結果を受け取る。

## 2. Do / The Error

設定後の確認（`npm run calendar -- --verify`）で、ping は通るのに次の list が HTTP 404 で落ちた。
続けて試すと、同じ list が通ったり、その直後の ping が 404 の HTML ページになったりした（設定は正しい）。
一度は転送先から doGet の返事が返ったこともある。

## 3. Check / Root Cause

- Google 側の一時的な失敗（短い間に続けて呼ぶと起きる）。要求の形や合言葉の誤りではない
- 1 回の失敗をそのまま「つながらない」と扱っていた

## 4. Act / Prevention Strategy (Fix)

- 404・408・429・5xx・接続失敗は、読むだけ・同じ結果になる操作（ping・list・update）に限り 3 秒・8 秒置いて送り直す
- **create は送り直さない。** Google 側では作れていて返事だけが失敗することがあるので、一覧で同じ題名・同じ開始の予定を探し、
  あればそれを使い、無い時だけ 1 回作り直す

### 予防ルール

1. 外の API の失敗は「一時的か」を分けてから扱う。一時的なものは待って送り直す
2. **作る・送るなど、繰り返すと結果が増える操作は、送り直す前に「もう起きていないか」を確かめる**
