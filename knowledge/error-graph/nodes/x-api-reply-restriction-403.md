---
title: "X API 自発リプの403（2026-02 プラットフォーム規制）"
description: "台帳TL/検索への自発リプがxmcp経由で403。原因はX APIの2026-02リプ規制。経路をUI操作/引用に分岐して解決。"
type: "technical-error"
tags: ["api", "x-twitter", "policy-change", "403", "mcp"]
---

## 1. Plan / Context
pullieのX課「交流レーン」で、台帳アカウントのTLや検索で見つけた投稿へ自発的にリプライを送っていた（xmcp = X公式MCP経由、実体は POST /2/tweets の reply 指定）。「MCP経由だからAPIエラーは出ないはず」という思い込みがあった。

## 2. Do / The Error
createPosts が `403 Forbidden - {'detail': 'You can only reply if the original author @mentions you or quotes your post...'}` を返す。2026-08-12〜13の自発リプ試行9回がすべて失敗（成功例ゼロ）。一方で、**同一run・同一認証・同一ツール**での通常投稿といいねは成功していた。ブロックされた3投稿の reply_settings はいずれも `everyone`（＝相手の返信制限ではない）。

## 3. Check / Root Cause
2026-02-23にXが実施したAPI規制「Operation Kill the bots」。低品質AIリプのスパム対策として、POST /2/tweets のプログラム的リプライを、**元投稿の作者が先に@mention/引用でこちらに関与した場合のみ**許可に変更した。Free/Basic/Pro/Pay-Per-Use 全対象、免除は Enterprise / Public Utility のみ。
- **MCPは回避策にならない**: xmcp は X API の OpenAPI spec から生成された薄い変換器で、同一 REST API を同じ OAuth 資格情報で叩くだけ。ポリシー判定は X サーバー側で行われる。規制対象外なのは人間のブラウザ/アプリ操作のみ。
- pullieのリプ機能初稼働(8/12)は規制施行(2/23)後 = **最初から一度も通らない構造**だった。

## 4. Act / Prevention Strategy (Fix)
**Fix:** 会話の入口ごとに送信経路を分岐した。
- メンション応対（相手が@mention済み）→ API可のまま（04_inbox）
- 引用ポスト（`quote_tweet_id`・非リプライで規制対象外）→ API（07_amplify を新設）
- 自発リプ → ブラウザUI操作（Playwright + 保存ログインセッション `.secrets/x_state.json`、05_engage）

**Prevention:**
1. 外部プラットフォームのAPIに依存する自動化は、**ポリシー変更で特定機能が予告なく死ぬ**前提で設計する。403等の"恒久エラー"は自己修復リトライでなく**代替経路への切替**で対処する（リトライは無駄なコスト/枠を垂れ流すだけ）。
2. **「ラッパー（MCP/SDK）経由だから制限が違う」という仮定を置かない** — 制限は常にプラットフォーム側で判定される。
3. **新機能が最初から一度も成功しない場合、コードでなく前提（利用可否・権限・ポリシー）を疑う**。実測（同一経路で他機能は成功しているか、公式アナウンスはないか）で切り分ける。
