---
title: "Codex Built-in Image Tool: Multi-line Prompts Skip the Tool, and `-i` Placed Before the Prompt Swallows It"
description: "Two silent failures while switching weevee infographics to GPT Image via `codex exec`: (1) a structured multi-line Japanese prompt (headers + bullet lists) made Codex answer with the imagegen skill's documentation / '【画像内の全文字】が含まれていません' instead of calling the image tool — 6 consecutive rc=0 runs with no image; (2) read-back via `codex exec -i <img> <prompt>` failed with 'No prompt provided via stdin' because `-i <FILE>...` is variadic and consumed the positional prompt. Fix: flatten the prompt to one line; put the prompt before `-i`."
type: "bug"
tags: ["codex", "imagegen", "cli-contract", "silent-failure", "weevee"]
---

## 1. Plan / Context
情報図を GPT Image（Codex 内蔵 image_gen・サブスク）で生成し、生成後に画像の文字を Codex（画像入力）で読み戻して spec と照合する設計。

## 2. Do / The Error（2026-08-28）
1. 節画像 3 枚 × 2 回 = 6 回連続で `rc=0` なのに画像なし。codex の応答は imagegen スキルの説明文や「【画像内の全文字】の内容がメッセージに含まれていません」
2. 読み戻し（`codex exec … -i image.png "<prompt>"`）が全件「Reading prompt from stdin... No prompt provided via stdin.」

## 3. Check / Root Cause
1. imagegen の契約は「`@imagegen <向き指示> <プロンプト>` を 1 行目に置く」。改行と箇条書きを含む長い構造化プロンプトは 1 行目で切れ、残りが別段落扱いになり、Codex はツールを呼ばず文面を要求した。**rc=0 のため失敗が静か**
2. clap の `-i, --image <FILE>...` は可変長で、後ろに置いた位置引数（プロンプト）を画像パスとして飲み込む。既存の `edit()` も同じ順序で書かれていた（実走前だったため未発覚）

## 4. Act / Prevention Strategy (Fix)
- `infographic_prompt.spec_to_prompt()` は改行を含まない 1 行を返す（区切りは「 ／ 」）。テストで `"\n" not in prompt` を固定
- `imagegen.run_codex()` はプロンプトを先に `cmd` へ入れ、`-i` は後ろに付ける
- **予防ルール: 外部 CLI の「位置引数と可変長オプションの順序」「1 行契約」は、成功ケース 1 件の実走で固定してからテンプレートを拡張する。rc=0 でも成果物が無ければ失敗として扱う（imagegen は既に実装済み）**
- 関連: [[uc-gpt-image-japanese-text-was-self-forbidden]] [[infographic-text-clipped-in-narrow-cards]]
