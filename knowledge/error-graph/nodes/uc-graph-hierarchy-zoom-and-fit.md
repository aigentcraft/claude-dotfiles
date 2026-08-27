---
title: "UC: Knowledge Graph Had Fixed Sparse Layout, Tiny Nodes, No Zoom, and Narrow 'Parent' Nodes"
description: "User on the weevee top-page graph: 'ノードの配置が隙間が多すぎるし、小さくて見づらい。画面のサイズとか比率に合わせて配置すべき。ノードを選択するとそのノードにピンチインで寄って、子ノードが大きく表示されないと。親ノードは LLM とか TTS とかノーコード/ローコードとか大きな括りじゃないと'. The graph used build-time fixed coordinates (1200×760) scaled into any viewport, had only one hierarchy level (SEO clusters as hubs), and no camera. Fix: runtime layout fitted to the container, a 3-level taxonomy (domain → cluster → keyword), and click-to-zoom with the camera (viewBox) animating to the node so children render large."
type: "user-correction"
tags: ["user-correction", "graph", "layout", "zoom", "taxonomy", "responsive", "weevee"]
---

## 1. Plan / Context
トップページのナレッジグラフを `tools/export_graph.py` が固定座標（1200×760・ハブ円周 + 扇）で書き出し、SVG の viewBox で任意の画面に縮尺していた。ハブ = SEO 用の 9 クラスタ（n8n×VPS 等）。クリックでパネル表示のみ。

## 2. Do / The Error（ユーザー指摘 2026-08-27）
- 「配置が隙間が多すぎる、小さくて見づらい。画面のサイズとか比率に合わせて配置すべき」
- 「ノードを選択するとそのノードにピンチインで寄って、子ノードが大きく表示されないと」
- 「親ノードは LLM とか TTS とかノーコード・ローコードとか大きな括りじゃないと」

## 3. Check / Root Cause
1. **ビルド時の固定座標**: 縦横比の違う画面で余白か切れが出る。図の「密度」を画面に合わせて決める設計が無かった
2. **カメラ（ズーム）が無い**: 60 超のノードを 1 画面に収めれば必ず小さくなる。階層ナビゲーション（寄る/引く）が前提の情報量なのに、静的な 1 スケールで描いた
3. **階層が 1 段（SEO クラスタ）**: クラスタは検索キーワードの束であり、読者が直感する「AI の大分類」（LLM / 音声 / 画像 / ノーコード…）ではない。親ノードが読者の語彙と一致していなかった
4. 内部のデータ構造（keywords.cluster）をそのまま UI に出した — 「構造化が価値」なら**読者の分類軸**を UI 用に定義して DB の軸をその下にぶら下げるべきだった

## 4. Act / Prevention Strategy (Fix)
- `site/src/data/taxonomy.json` に **大分類（domain）→ 中分類（cluster）** を定義し、Python（export）と TS（UI）の単一ソースにする
- グラフは **実行時レイアウト**（コンテナの幅・高さから楕円半径・ノード径・フォントを算出、リサイズで再計算）。域を埋めるまで反発と引力で緩和
- **カメラ**: 選択ノードの周辺矩形へ viewBox をイージングで寄せる（600ms・easeOutCubic）。寄った状態で子ノードのラベルを表示、背景クリック/×で引く。浮遊とホバー拡大は維持
- **予防ルール: グラフ UI は「全体 → 寄る → 選ぶ」の 3 段を最初から設計する**（ノード数が 30 を超えたら静的 1 スケールは破綻する）。親ノードは「読者の語彙」で定義し、内部のクラスタは子に置く
- 関連: [[uc-layout-without-design-reference]]・[[uc-site-design-direction-before-content]]
