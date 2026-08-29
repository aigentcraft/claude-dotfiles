---
title: "SaaS App Screens Rendered Blank or Spinner-Only in Headless Chromium With a Spoofed UA"
description: "weevee lab browse.mjs launched Playwright Chromium headless with a hand-written Chrome/128 user agent. Marketing pages rendered, but the app/auth screens of Notta (signup), Rimo (signup) and tl;dv (login) stayed blank or on a loading spinner — bot detection (navigator.webdriver=true, UA/client-hint mismatch, headless fingerprint). Result: a second $4 research run with zero sign-ups. Fix: headed browser placed off-screen (--window-position=-32000,-32000), ignoreDefaultArgs ['--enable-automation'], --disable-blink-features=AutomationControlled, no UA override, plus a networkidle settle after navigation (the 'text' command was also reading the body before the SPA painted)."
type: "bug"
tags: ["playwright", "headless", "bot-detection", "spa", "research-lab", "weevee"]
---

## 1. Plan / Context
無料サインアップの実測（人間決定⑧）を Playwright の永続コンテキストで行う。

## 2. Do / The Error（2026-08-30 記事 13 再調査 2 回目）
- Notta の新規登録フォーム: `body` テキスト 0 文字（白紙）／Rimo・tl;dv: スピナーのまま
- researcher が単発で `--disable-blink-features=AutomationControlled` を試すと Notta が描画された（原因の切り分けは正しかった）

## 3. Check / Root Cause
1. ヘッドレス + 手書き UA（Chrome/128）→ `navigator.webdriver=true`・UA と Client Hints の不一致・ヘッドレス指紋で bot 判定され、アプリ側 JS が描画を止める
2. 別問題として `text` コマンドが再ナビゲーション直後（domcontentloaded）に本文を読んでおり SPA の描画前だった

## 4. Act / Prevention Strategy (Fix)
- ヘッド付きで画面外に配置（`--window-position=-32000,-32000`）・`ignoreDefaultArgs: ['--enable-automation']`・AutomationControlled 無効・UA 偽装なし → 3 サービスとも描画（webdriver=false）
- ナビゲーション後は `networkidle`（8 秒上限）+ 1.5 秒の settle を共通化
- **予防ルール: ブラウザ自動化の導入時は「公開ページが見える」ではなく「対象サービスの認証/アプリ画面に入力欄が見える」ことを受け入れ基準にする。UA 偽装は検知を増やす側に働く**
- 関連: [[payment-gate-false-positive-stripe-hidden-iframe]] [[uc-comparison-article-without-real-measurement]]
