---
title: "Claude CLI OAuth Expiry Masked as 'subtype=success' — All Pipeline LLM Calls Die in 650ms"
description: "pullieパイプラインで claude -p のOAuthセッションが失効（Failed to authenticate: OAuth session expired and could not be refreshed）した際、result JSONは is_error=true かつ subtype='success' で返り、claude_clientのエラー文が「subtype=success」という無意味な文字列になった。全LLM呼び出しが650ms・$0で即死し、記事再走バッチ4本中3本がstep-error。実メッセージは result フィールドに入っており、直接プローブ（claude -p --output-format json）で特定。復旧はWindows側での人間の再ログインのみ。"
type: "technical-error"
tags: ["api-network", "claude-cli", "oauth", "auth-expiry", "error-surface", "pullie", "diagnosability"]
---

## 1. Plan / Context
pullieの全LLMステージは Windows側 `claude -p`（OAuth=サブスクリプション認証）を
claude_client.run_agent 経由で呼ぶ。result イベントの成否判定は
`is_error || subtype != "success"`、エラー文は `f"subtype={subtype}"` だった。

## 2. Do / The Error（2026-09-02 10:25 JST）
- 10:25:20の成功呼び出しを最後に、以後の writer 呼び出しが**650ms・$0**で連続失敗
- llm_calls の error 列は全て「subtype=success」— 成功を名乗るエラーで原因が読めない
- 破棄記事の再走バッチが4本中3本 step-error で完走扱いに

## 3. Check / Root Cause
1. **OAuthセッション失効**: `claude -p` 直接プローブで
   `is_error=true, subtype="success", result="Failed to authenticate: OAuth session
   expired and could not be refreshed"` を確認 — 失効時のresult JSONは
   **subtypeが"success"のまま is_error だけ立つ**
2. claude_client のエラー文が subtype しか拾わず、実メッセージ（resultフィールド）を
   捨てていた — 記録上「subtype=success」という自己矛盾文字列だけが残る
3. 同時刻に画像生成（codex CLI）も usage limit で全滅しており、複合障害で誤誘導されやすかった

## 4. Act / Prevention Strategy (Fix)
- claude_client: is_error時のエラー文に `result` 先頭160字を含める（原因が llm_calls から
  直接読めるように）
- 認証失効はコードでは直せない（OAuthは対話ブラウザ必須・パスキー/リフレッシュ不能）—
  **人間がWindowsで `claude` → /login**。復旧後にバッチ再実行
- **予防ルール**:
  1. CLIラッパーのエラー記録は「判定に使った字段」でなく**実応答本文**を残す
     （成功フラグの組（is_error, subtype）は矛盾しうる — 本文だけが真実を語る）
  2. 数百msで$0のLLM「実行失敗」が連続したら、モデルやプロンプトでなく**認証・квота層**を
     最初に疑い、パイプライン外から最小プローブ（`claude -p "reply ok" --output-format json`）
     で切り分ける
  3. リトライはauth系エラーに無力 — 即死（sub-second）失敗はリトライ抑止の条件にしてよい
- 関連: [[x-api-reply-restriction-403.md]]（プラットフォーム側制約の切り分け）/
  [[wrangler-oauth-refresh-rotation-conflict]]（Win/Mac間のOAuthローテーション競合 — 類似の失効様式）
