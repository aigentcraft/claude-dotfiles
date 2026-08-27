---
title: "UC: Labels Stayed at Overview Size After Zooming Into a Child Node"
description: "User on the weevee graph: '子ノードをクリックした後の文字が小さくて読みづらい'. Focus mode reused the overview font sizes (fs-3 for keywords) and relied on the camera zoom (~1.4x) alone, which was not enough. Fix: font sizes are a function of state — focus members get larger labels (kw fs+3, cluster fs+4, domain fs+5) and the layout spacing/fit padding follow the larger text."
type: "user-correction"
tags: ["user-correction", "graph", "typography", "zoom", "readability", "weevee"]
---

## 1. Plan / Context
フォーカス（マインドマップ整列）時はカメラが 1.4〜2 倍に寄るので、ラベルは俯瞰と同じサイズのままで読めると想定していた。

## 2. Do / The Error（ユーザー指摘 2026-08-27）
- 「いいかんじだけど、子ノードをクリックした後の文字が小さくて読みづらい」

## 3. Check / Root Cause
1. **文字サイズを状態の関数にしていなかった** — 俯瞰用の小さいサイズ（キーワード fs-3 ≒ 12px）をズーム倍率に頼って拡大していたが、下部バーの分だけカメラの倍率が下がり実効 15px 程度に留まった
2. 「読む」状態と「俯瞰する」状態で求められる文字サイズは別（俯瞰 = 密度優先、フォーカス = 判読優先）

## 4. Act / Prevention Strategy (Fix)
- `labelSize(level, focusMode, inFocus)` でサイズを状態から決める: フォーカス中の対象はキーワード fs+3 / 中分類 fs+4 / 大分類 fs+5、俯瞰は従来値。葉の行間（(fs+3)×1.55）・枝間隔・fitRect のラベル幅見込みも同じ基準に
- **予防ルール: ズームで文字を大きく見せる設計は、状態ごとの実効フォントサイズ（px）を計算して 16px 以上を保証する**。倍率に頼らない
- 関連: [[uc-graph-focus-relayout-and-click-feedback]]
