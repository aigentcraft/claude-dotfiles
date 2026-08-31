---
title: "Infographic Text Clipped at Card Edges After Enlarging Type"
description: "weevee diagram_render: to fix sparse infographics I enlarged the 'big' variant type globally; a 3-column compare card then clipped values ('MSYS_NO_PATHCO…', 'Git Bashの自動変換で—') because the size ignored column count, long ASCII tokens could not wrap, and .col had overflow:hidden with no check. Fix: overflow-wrap:anywhere, per-column-count sizing, and a two-pass render where render.mjs counts overflowing elements and diagram_render re-renders with a compact class when any are found."
type: "bug"
tags: ["images", "rendering", "infographic", "overflow", "self-verification", "weevee"]
---

## 1. Plan / Context
情報図は HTML → Playwright で決定論的に描く。余白が多い（3 行の表が画面の 1/4）という実見に対し、`big` バリアントの文字を一律に拡大した。

## 2. Do / The Error（2026-08-28 記事 7 プレビュー実見）
- 3 列の compare カードで値テキストが右端で切れた（「Git Bashの自動変換で—」「MSYS_NO_PATHCO」）。承認プレビューに「見切れた文字」が載った

## 3. Check / Root Cause
1. **サイズを列数と無関係に決めた** — 2 列で余裕がある文字サイズは 3 列（幅 1/3）では入らない
2. **長い英数トークン（環境変数名）は折り返せない** — `overflow-wrap` 未指定 + `.col{overflow:hidden}` で黙って切れる
3. **描画結果を自己検証していなかった** — 決定論描画でも「入るかどうか」は内容依存。目視するまで分からない状態だった

## 4. Act / Prevention Strategy (Fix)
- CSS: `overflow-wrap:anywhere` をテキスト要素に付与、`.cols[data-n="3"]` で列数別サイズ
- `render.mjs` が #stage 内の要素の `scrollWidth/Height > client` と #stage 外への突出を数えて `OVERFLOW n` を出力
- `diagram_render.render()` は 2 パス: overflow > 0 なら `#stage.compact`（全種別 20〜30% 縮小）で描き直し、それでも残れば warn
- 計測の注意（同日追記）: CJK フォントは line-height < 1.4 で字面が行箱をはみ出し `scrollHeight > clientHeight` になる偽陽性がある。縦方向の検査は `overflow-y` が visible でないクリップ箱（.col / #stage）に限定し、横方向は全要素で検査する
- **予防ルール: 文字サイズを大きくする変更は「最も狭いレイアウト（最大列数・最長トークン）」で確認し、描画器に自己検証（overflow 計測）を持たせる**
- 関連: [[uc-article-image-cropped-caption-overlap]] [[uc-article-images-decorative-not-explanatory]]
