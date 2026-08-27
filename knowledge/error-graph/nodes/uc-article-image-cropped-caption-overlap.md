---
title: "UC: Article Images Cropped and Captions Overlapping in the Approval Preview"
description: "User on weevee article previews: '画像は見切れてるしキャプションが入っていてしかも画像と被ってる'. The image inserter wrote `![alt](path)` and `*caption*` on adjacent lines (one paragraph), so rehype-figure never wrapped them; the fallback CSS forced aspect-ratio 3/2 + object-fit cover on the bare img and pulled the em up with a negative margin. Fix: emit image + caption as separate blocks, make the figure plugin accept img+em paragraphs, never crop with object-fit, and have 06b probe the rendered DOM (figure/figcaption/overlap) instead of only the source files."
type: "user-correction"
tags: ["user-correction", "images", "captions", "rehype", "css", "preview", "weevee"]
---

## 1. Plan / Context
05_generate_images が各 H2 に画像 + キャプションを挿入し、rehype-figure が `<figure><img><figcaption>` に変換、06b が画像ファイル（サイズ・比率・重複）を検査して承認依頼を出す想定だった。

## 2. Do / The Error（ユーザー指摘 2026-08-27）
- 「記事の承認依頼がきてるけど、画像は見切れてるしキャプションが入っていてしかも画像と被ってるし問題ありすぎ」

## 3. Check / Root Cause
1. **Markdown の挿入形式が図版ではなく「段落」だった** — `image_block()` が `![alt](path)\n*caption*`（空行なし）を出すため、1 つの `<p>` に `<img>` と `<em>` が同居。rehype-figure は「img だけの段落」しか包まないので figure 化されず、キャプションは本文の斜体として描画された
2. **フォールバック CSS が重なりと見切れを作った** — `.prose img + em { margin-top:-0.7em }` が em を画像の上に引き上げ、`.prose > p > img { aspect-ratio:3/2; object-fit:cover }` が 3:2 でない画像（hero 1200×800 は一致するが、生成の揺れで違う比率の図版）を切り抜いた
3. **06b の検査対象が「ファイル」だけで「描画結果」を見ていなかった** — PNG の寸法・比率は合格でも、HTML 上で figure になっているか・キャプションが重なっていないかは誰も確認していない。承認依頼は「見た目」を人が判断するものなのに、見た目の自動検査がゼロだった

## 4. Act / Prevention Strategy (Fix)
- `image_block()` は `![alt](path)` と `*caption*` を **空行で区切った別ブロック**として出力し、rehype-figure も `img + em` 同居段落を figure 化できるよう両対応にする
- 画像の見切れ防止: `object-fit: cover` による切り抜きをやめ、`aspect-ratio` は figure の枠にだけ与えて画像は `contain`（余白は紙色）。負マージンのキャプション CSS は削除
- 06b に **描画 DOM プローブ**（Playwright で本番ビルドを開き、`.prose img` ごとに figure/figcaption の有無・画像とキャプションの矩形重なり・画像の natural 比率と表示比率の差を測る）を追加し、1 件でも NG なら承認依頼を出さず差し戻す
- **予防ルール: 人に「見た目」を承認させる前に、機械が「見た目」を検査する**。ファイル検査（寸法・重複）だけでは HTML/CSS 層の破綻を検出できない
- 関連: [[uc-article-images-decorative-not-explanatory]] [[uc-approval-request-local-path-instead-of-url]]
