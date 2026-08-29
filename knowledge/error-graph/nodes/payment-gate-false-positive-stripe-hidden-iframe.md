---
title: "Payment Gate Fired on Every Sign-up Page Because Stripe.js Loads Hidden Fraud-Detection Iframes"
description: "weevee lab browse.mjs gated on 'iframe[src*=\"stripe.com\"]'. Stripe.js injects invisible controller/fraud iframes (js.stripe.com/v3/controller-*, m.stripe.network) on sign-up and login pages that have no card form, so Notta, Rimo and tl;dv all stopped at the first screen and the transcription comparison (article 13) had zero real measurements — 30 minutes and $4 of research produced '未実施' three times. Fix: gate only on real card inputs and on payment iframes that are visible with input-sized bounding boxes (elements-inner-*, checkout.stripe.com, paypal smart buttons)."
type: "bug"
tags: ["payment-gate", "playwright", "stripe", "false-positive", "research-lab", "weevee"]
---

## 1. Plan / Context
支払いゲート（人間決定⑧）: カード入力ページに到達したら停止して人間に確認。検出は URL パターン + カード入力欄 + 決済 iframe。

## 2. Do / The Error（2026-08-29〜30 記事 13 の再調査）
- Notta のサインアップ画面・Rimo のトップ・tl;dv のログイン画面で `iframe[src*="stripe.com"]` にヒット → 3 サービスとも最初の画面で停止
- researcher は「カード入力欄は無い（誤検知の可能性が高い）」と記録しつつ規則どおり停止 → 実測ゼロのファクトシート（$4.18）

## 3. Check / Root Cause
- Stripe.js は不正検知のため**不可視の** controller iframe を、決済フォームが無いページにも読み込む。src だけで判定すると必ず誤検知する
- 前回（2026-08-29 notta.ai/pricing）の誤検知を「文言では止めない」に直したが、iframe セレクタは見直していなかった

## 4. Act / Prevention Strategy (Fix)
- iframe は `elements-inner-*` / `checkout.stripe.com` / `__privateStripeFrame` / paypal smart / braintree / checkout.com に限定し、さらに **可視かつ 100x20px 以上の boundingBox** がある時だけゲート
- 誤検知した `payment_gate.json` は `payment_gate.false-positive-<date>.json` に退避（`gated()` の恒久ブロックを解除）
- **予防ルール: 「存在」で止める検出器は SDK のトラッカー/コントローラ要素で誤検知する。ユーザーが操作できる（可視・サイズあり）要素だけを根拠にする。停止系ゲートは導入時に対象サービスの最初の画面で誤検知テストをする**
- 関連: [[payment-gate-false-positive-on-pricing-text]] [[uc-comparison-article-without-real-measurement]]
