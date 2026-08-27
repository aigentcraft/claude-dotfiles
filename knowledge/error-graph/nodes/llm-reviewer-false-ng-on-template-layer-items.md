---
title: "LLM Reviewer Flags Draft for Items the Template Layer Inserts (False NG)"
description: "The reviewer agent failed C01/C02 (PR notice / AI-generated notice) on every draft because those blocks are machine-inserted by the Astro layout at build time, not written by the writer. The checklist must state WHERE each requirement is fulfilled; and keep a raw LLM response dump so such misjudgments can be diagnosed from evidence."
type: "technical-error"
tags: ["ai-behavior", "llm-pipeline", "reviewer", "checklist", "audit-log", "weevee"]
---

## 1. Plan / Context
weevee パイプラインの 06_review で reviewer エージェント（`claude -p`）が checklist.md に基づき F/C/Q 系チェックを行う。
C01（PR表記）・C02（AI生成表示）は **サイトテンプレート層（ArticleLayout）がビルド時に機械挿入**する設計（writerの裁量外・docs/01 §6）。

## 2. Do / The Error
- reviewer がドラフト Markdown 内に PR表記が無いことを理由に C01/C02 を NG → C系1件でも不合格＝自動公開禁止ルールにより**毎回差し戻し**
- writer は「PR表記を書くな」という指示を守っており、両者が正しく振る舞った結果としてループが成立
- 原因特定に時間がかかった: 06 の結果は quality_checks のコメント要約しか残らず、LLM が何を見て判定したかが追えなかった。`claude_client` に生応答の常時ダンプ（`logs/llm_raw/`・text+events）を追加して初めて「テンプレ挿入を知らずに判定している」ことが確定した

## 3. Check / Root Cause
1. **要件の「充足場所」がチェックリストに書かれていなかった** — 要件（PR表記必須）だけを列挙し、それがドラフトで満たされるのかテンプレで満たされるのかを区別していない。LLM は「無い＝NG」と素直に判定する
2. 検閲対象（ドラフト）と最終成果物（レンダリング済みHTML）が別物なのに、両者の責務分界を検閲側に伝えていなかった
3. LLM 判定の一次証拠（生応答）が保存されておらず、誤判定が「たまたま厳しい」のか「構造的な誤解」なのか切り分けられなかった

## 4. Act / Prevention Strategy (Fix)
- checklist.md に **「C01/C02 はテンプレ層挿入のためドラフト非対象。ドラフト内に手書きの PR表記があれば逆に二重挿入で NG」** と明記（充足場所と逆条件の両方を書く）
- 実物への挿入検証は 06b_preview（レンダリング済みHTMLの機械プローブ）が担当 — 「どの層が何を保証するか」を検閲設計に固定
- **予防ルール: LLM 検閲のチェック項目は「何を」だけでなく「どの層・どの成果物で満たされるか」を必ず併記する**。多層パイプライン（ドラフト→テンプレ→ビルド）では特に
- **予防ルール: LLM 呼び出しの生応答は常時ダンプする**（gitignore 下・容量は日次ローテ）。誤判定・切断・形式崩れの一次証拠を後から取れないと、原因が推測になり修正が空振りする
- 関連: [[claude-headless-chunk-timeout-truncation]]（同じダンプが空記事問題の決定打になった）
