---
title: "UC: 'GPT Image Can't Render Japanese' Was a Self-Inflicted Prompt Rule, Not a Model Limit"
description: "User: 'Gptimage2のモデルで画像生成してる？日本語が崩れることはほぼない。' On 2026-08-27 I concluded GPT Image produced abstract, label-less diagrams and replaced it with an HTML→PNG table renderer. The real cause: imagegen.BRAND_STYLE said 'never Japanese characters; never numbers, prices' and section prompts said 'No numbers anywhere' — we forbade the text ourselves and never tested it. A live test via Codex's built-in image tool (gpt-image-2 class) rendered a 3×3 Japanese table with exact numbers flawlessly. Fix: allow exact Japanese text/numbers from the spec, verify text fidelity after generation, keep the HTML renderer only as fallback."
type: "user-correction"
tags: ["user-correction", "images", "gpt-image", "japanese", "false-premise", "weevee"]
---

## 1. Plan / Context
見出しごとの説明画像を Codex 内蔵の画像ツール（サブスク・API 費ゼロ）で作る方針だった。初回の結果が「抽象的で日本語ラベルも数値も無い」ため、決定論的な HTML→PNG レンダラ（表・カード）に切り替えた。

## 2. Do / The Error（ユーザー指摘 2026-08-28）
- 「Gptimage2のモデルで画像生成してる？日本語が崩れることはほぼない。」
- 直前に私は「GPT Image は日本語ラベル・数値・構図を守れない」と説明していた

## 3. Check / Root Cause
1. **禁止していたのは自分だった** — `imagegen.BRAND_STYLE` に「never Japanese characters; never numbers, prices」、節画像のプロンプトに「No numbers anywhere in the image」「single short English label」。モデルは指示通りに文字を描かなかっただけ
2. **前提を検証せずに設計を変えた** — 「日本語が崩れる」は旧世代モデルの経験則。gpt-image-2 級（Codex 内蔵 image_gen）では日本語表を正確に描けることを、1 枚生成すれば分かった（実測: 3×3 表・数値 6 個・注記まで誤字ゼロ）
3. 結果として「CSV を絵にした」ような HTML 表画像を量産し、ユーザーに「画像、csv か何かで書いてない？」と見抜かれた

## 4. Act / Prevention Strategy (Fix)
- BRAND_STYLE の文字禁止を撤廃し、「spec の日本語・数値を**一字一句そのまま**描く」指示に変更。プロンプトは日本語で書く
- 節画像は GPT Image（日本語テキスト入り）を第一候補にし、生成後に画像内の文字を読み戻して spec と照合（欠落・誤字なら再生成 → それでも駄目なら HTML レンダラにフォールバック）
- **予防ルール: モデルの限界を語る前に、その限界を「自分のプロンプトが作っていないか」を確認し、最小 1 枚の実測で検証する。ユーザーの元指示（GPT Image 2 で生成）から外れる時は、外れる根拠を実測で示す**
- 関連: [[uc-article-images-decorative-not-explanatory]] [[uc-article-image-cropped-caption-overlap]] [[infographic-text-clipped-in-narrow-cards]]
