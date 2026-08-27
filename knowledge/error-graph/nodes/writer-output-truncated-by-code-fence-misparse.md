---
title: "Writer Output Truncated to 159 Characters by Code-Fence Misparse"
description: "weevee 04_write_article: parse_slug_markdown searched the writer output for any '```\\n' as an optional wrapping fence; in a code-heavy how-to (docker compose) the first code block's closing fence matched, so the parser returned the few lines between two code blocks, raised 'frontmatter not found', retried, then synthesized frontmatter around a 159-char fragment — while the raw output was a complete 13,500-char article. Fix: only unwrap a fence that starts at the beginning of the output and closes at its end; regression tests with code blocks."
type: "bug"
tags: ["parsing", "llm-output", "regex", "writer", "silent-degradation", "weevee"]
---

## 1. Plan / Context
writer の応答は「SLUG 行 + frontmatter 付き Markdown」。LLM が全体を ```markdown で包むことがあるため、パーサはフェンスがあれば中身を取る設計だった。

## 2. Do / The Error（2026-08-28 記事 1 の再執筆）
- 原稿は 13,500 字で SLUG・frontmatter とも正常。しかし保存された draft は 159 字（`つまずきポイント: usermod…` から次のコードブロックまでの断片）+ 合成 frontmatter
- 06 に 159 字の記事が流れ、差し戻しラウンドを 1 回消費

## 3. Check / Root Cause
1. **「包みフェンス」の判定が非アンカー** — `re.search("```…\n(.*?)```")` は本文中の最初のコードブロックの**閉じフェンス**を開きフェンスと誤認し、次のコードブロックまでを本文にした
2. その結果 frontmatter が見つからず ValueError → 矯正リトライ（同じ誤判定）→ `synthesize_frontmatter`（同じ正規表現）で断片を「救済」。**三段構えのフォールバックが同じバグを共有していたため、静かに劣化した**
3. 手順記事はコードブロックが多く、初心者ファースト構成（最短手順にコマンド）で発生確率が上がった

## 4. Act / Prevention Strategy (Fix)
- `_unwrap_fence()`: 出力先頭（SLUG 直後）で始まり末尾で閉じるフェンスのみ剥がす（`re.match(r"\s*```…\n(.*)\n```\s*$")`）。parse/synthesize 双方で共用
- `tests/test_lib_parse.py`: コードブロック複数を含む原稿・全体包みフェンス・frontmatter 欠落の 3 ケース
- **予防ルール: LLM 出力のパースで「任意位置の区切り記号」を根拠にしない（先頭/末尾にアンカー）。フォールバック段は一次パーサと別のロジックにし、字数の急減（原稿 13k → 保存 159）をエラーとして検知する**
- 関連: [[image-reuse-by-section-index-after-restructure]]（同じバッチで発見）
