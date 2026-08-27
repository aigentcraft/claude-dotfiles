---
title: "UC: Zoom Kept the Overview Layout, Ring Center Was Empty, Children Were Monochrome, Click Had No Feedback"
description: "Second round on the weevee top-page graph: '親ノード群の真ん中が空いていてスペースが有効活用できていない / 子ノードの色が単一すぎて見づらい / 親をクリックした後のレイアウトが全体像のまま — 寄った後はマインドマイスターみたいに整列させたい / クリックしたときにホワンという反応をしてから次の配置に動いて欲しい'. Zooming the camera into a static layout is not the same as focusing: a focus needs its own layout (mind-map branches), a filled composition (root at center, children spreading inward too), per-branch colors, and a tactile click reaction before the transition."
type: "user-correction"
tags: ["user-correction", "graph", "layout", "mind-map", "motion", "color", "weevee"]
---

## 1. Plan / Context
3 階層のナレッジグラフを実行時レイアウト（大分類を楕円上に・外向きの扇）+ カメラのズームで実装した。

## 2. Do / The Error（ユーザー指摘 2026-08-27）
- 「親ノード群の真ん中が空いていてスペースが有効活用できていない」
- 「子ノードの色が単一すぎて見づらい」
- 「親ノードをクリックした後のノードのレイアウトが全体像の時のままになっている。寄った後は関連するノードをマインドマイスターみたいに整列させた方がいい」
- 「ノードをクリックしたときにホワンていう動きのリアクションを取ってから次の配置に動くようにして欲しい」

## 3. Check / Root Cause
1. **「寄る」= カメラ移動だけ**と捉えた。フォーカスは**別のレイアウト**（対象を中心に、枝を左右に、葉を縦に整列）を要する。全体像の配置は俯瞰用で、読むための配置ではない
2. 楕円 + 外向き扇の構図は幾何学的に**中心が空く**。根ノードを中央に置く／子を内側にも展開するという「面を埋める」設計が無かった
3. 色を「大分類のトーン」で決めたため、同じ親の子が全部同色になり枝の区別がつかない。色は**枝（中分類）単位**で変えるべき
4. クリック → 即座に遷移、では操作の手応えが無い。ユーザーの語彙「ホワン」= 押した対象が一瞬膨らんで戻る反応（~300ms）→ その後に配置/カメラが動く、という**順序**の要求

## 4. Act / Prevention Strategy (Fix)
- **フォーカス用レイアウト**（マインドマップ）: 選択した親を中心に、中分類を左右交互の枝に、キーワードを枝の外側に縦積み。非対象は外へ押し出して減光。位置は毎フレーム目標へ補間（lerp）して滑らかに遷移し、その後カメラが矩形にフィット
- **面を埋める**: 根ノード（weevee）を中央に置き大分類と結ぶ。子の扇は全周に展開し、反発 + ばねで内側にも広がる
- **枝ごとの色**: taxonomy.json に中分類ごとの `color`（ブランド 5 色の濃淡展開）を持たせ、キーワードは所属中分類の色
- **クリック反応**: `.pulse`（scale 1→1.45→1 + リング拡散、320ms）を先に再生してから目標配置とカメラを動かす
- **予防ルール: インタラクティブな図では「状態ごとのレイアウト」「面の充填」「枝の色」「操作の手応え（反応→遷移の順序）」を仕様に含める**。ズームだけでフォーカスを済ませない
- 関連: [[uc-graph-hierarchy-zoom-and-fit]]・[[uc-layout-without-design-reference]]
