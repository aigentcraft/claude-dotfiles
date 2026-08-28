---
title: "UC: Article Hero Images Were Cropped on All Sides by an 'Edge to Edge' Rule Plus Trim + Center-Crop"
description: "User: '記事のトップ画像が見切れてる気がする'. The hero (abstract GPT illustration) had shapes cut at top/bottom/right. Three compounding causes: BRAND_STYLE demanded 'spans the canvas edge to edge with almost no empty margin' (so the model drew shapes bleeding off the canvas), imgproc.finalize then trimmed remaining paper margins and center-cropped to 3:2, and the 8% max-border rule made any safe margin a rejection. Fix: prompt for a ~5% safe margin with nothing cut, no trim/crop for GPT heroes, edge-touch detection with a retry hint, and a 32% border allowance for hero/infographics."
type: "user-correction"
tags: ["user-correction", "images", "hero", "cropping", "gpt-image", "weevee"]
---

## 1. Plan / Context
hero は生成 AI の抽象図。8/27 の「余白が多すぎる」指摘を受けて「端まで描け」（edge to edge・余白率 8% 未満）を強制し、後処理でトリム + 3:2 中央クロップしていた。

## 2. Do / The Error（ユーザー指摘 2026-08-28）
- 「記事のトップ画像が見切れてる気がする」— 実見: hero.png は 1200×800 まで削られ、図形が上下右で切れていた

## 3. Check / Root Cause
1. **「端まで描け」という指示は「端で切れる」を生む** — モデルは図形をキャンバス外まで伸ばして要求を満たす
2. **後処理が切れを増やした** — トリムで紙色の余白を全部落とし、さらに 3:2 へ中央クロップ（1536×1024 は最初から 3:2 なのに）
3. **余白率 8% ルール**が hero にも適用され、安全余白を残した良品を棄却する圧力になっていた（情報図で同じ問題を前日に直したのに hero には適用していなかった）

## 4. Act / Prevention Strategy (Fix)
- BRAND_STYLE: 「各辺 5% の安全余白・端で切れる図形は不可・ただし図形は大きく」に変更。FRAMING_FIX（再試行ヒント）も同趣旨に
- 05: hero は `edge_margins` で端接触を検出したら再生成、`finalize(trim=False)`（トリム・クロップなし）、余白率上限は `max_border_for()` で hero/情報図 32%（06b と共用）。`--force-hero` で hero だけ作り直せる
- **予防ルール: 「余白を減らせ」と「切るな」は同時に指示する。生成物の後処理で切り抜きを行うなら、切られて困る内容（文字・主題図形）が無いことを前提条件にする。1 種別で直した余白/切れのルールは全種別に横展開する**
- 関連: [[uc-gpt-image-japanese-text-was-self-forbidden]] [[uc-article-image-cropped-caption-overlap]] [[infographic-text-clipped-in-narrow-cards]]
