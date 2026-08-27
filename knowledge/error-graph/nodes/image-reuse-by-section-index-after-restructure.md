---
title: "Section Images Reused by Index After the Article Was Restructured"
description: "weevee 05_generate_images reused existing sec-N-*.png whenever a file with the same section number existed, so after a send-back rewrite changed the H2 structure, H2#1 '迷ったらこれ' got the old H2#1 cost diagram with a freshly written caption claiming it showed '3 reasons'. Root cause: idempotency keyed on position, not identity. Fix: a per-slug manifest.json (sec-N → heading/kind); reuse only when heading and kind match; orphaned sec-N files are deleted; legacy dirs without a manifest never reuse."
type: "bug"
tags: ["images", "idempotency", "pipeline", "caption-mismatch", "weevee"]
---

## 1. Plan / Context
05 は冪等に作ってあり、`sec-N-*.png` が存在して品質検査に通れば再生成しない（`--force` で全再生成）。記事の章構成は変わらない前提だった。

## 2. Do / The Error（2026-08-28 実測: 記事 7 の差し戻し再執筆）
- 初心者ファースト構成で H2 が「迷ったらこれ / 最短手順 / 失敗Top3 / 次の一歩 / もっと詳しく」に変わったのに、05 は旧 `sec-1-diagram.png`（旧 H2#1 のコスト図）を H2#1 に再利用し、designer が新しく書いたキャプション「根拠は3つ…」を付けた
- 見出しごとに「新キャプション + 旧画像」の不一致が 4 箇所。06 検閲直前に目視で発見しバッチを停止

## 3. Check / Root Cause
1. **冪等性のキーが「位置（章番号）」で「同一性（どの見出しの図か）」ではなかった** — 章構成が変わると同じ番号が別の章を指す
2. 差し戻し再執筆は構成が変わる典型ケースなのに、その経路で再利用ロジックが検証されていなかった
3. キャプションは新規生成、画像は旧物、という組み合わせを検出する検査がなかった（06b の画像プローブはファイル品質と重複のみ）

## 4. Act / Prevention Strategy (Fix)
- `site/public/img/blog/{slug}/manifest.json` に `sec-N → {heading, kind, file}` を保存。再利用は **見出し（正規化）と種別が一致する場合のみ**。マニフェストの無い旧世代ディレクトリは再利用しない（安全側）
- 参照が外れた `sec-N-*` は掃除（孤児画像を draft ブランチへ載せない）
- **予防ルール: 冪等スキップの条件は「成果物の同一性」で判定する。位置・連番・存在チェックだけで再利用しない**
- 関連: [[uc-article-image-cropped-caption-overlap]] [[uc-article-images-decorative-not-explanatory]]
