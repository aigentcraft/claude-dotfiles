---
title: "claude -p Headless: Low chunk_timeout Silently Truncates Long Generations"
description: "Setting chunk_timeout=90s on claude -p streaming killed the writer agent mid-output, saving a 262-byte fragment as the article. Long single-turn generations have >90s inter-chunk gaps. Keep 600s (per prior lesson) and add format-repair fallbacks."
type: "technical-error"
tags: ["claude-headless", "llm-pipeline", "timeout", "streaming", "weevee"]
---

## 1. Plan / Context
weevee パイプライン（04_write_article）で writer エージェント（`claude -p` ヘッドレス）が3,000〜7,000字の記事を生成する。参照プロジェクトの教訓で claude_client のデフォルト chunk_timeout は 600s に設定済みだった。

## 2. Do / The Error
- 各ワーカーが `run_agent(..., chunk_timeout=90)` と**呼び出し側で低い値を明示指定**しており、デフォルト600sが無効化されていた
- 長い単一ターン生成ではチャンク間ギャップが90秒を超え、ストリームが途中killされ**部分テキストが正常応答として返った**（ok=1・エラーなし）
- 下流の frontmatter パースが失敗 → 矯正リトライも同様に切断 → 合成フォールバックが断片から262バイトの「記事」を生成 → 検閲で0点連発 + 無駄なリトライでコスト消費 → 日次コスト上限（$5名目）到達で 06 がクラッシュ

## 3. Check / Root Cause
1. **タイムアウトの教訓がデフォルト値にしか反映されず、呼び出し箇所（13ファイル）で上書きされていた** — 移植エージェントが参照プロジェクトの古い値をコピーした
2. 部分応答が ok=1 で返る設計のため、切断がパース段階まで検出されない
3. 検閲エージェントがサイトスキーマを記憶で判定し、実在しない要件（pubDate/category/lang）で誤検出 → 実ファイル（content.config.ts）参照を checklist に明記して解決

## 4. Act / Prevention Strategy (Fix)
- `chunk_timeout=90/120` を全ワーカーで 600 に一括修正（`grep -rn "chunk_timeout=" workers/` で棚卸し）
- **予防ルール: タイムアウト等の教訓値はデフォルト引数だけでなく、呼び出し側の明示指定を grep で検査する**（移植時は特に）
- writer 出力パースは三段構え（厳密→矯正リトライ→frontmatter合成）にして単発の形式崩れを自己修復
- LLM品質検閲の判定基準に「実ファイルパスの参照」を明記し、スキーマ類を記憶で判定させない
- サブスク運用でも日次コスト上限（名目値）はガードとして残し、`.env` の DAILY_COST_LIMIT_USD で運用調整
