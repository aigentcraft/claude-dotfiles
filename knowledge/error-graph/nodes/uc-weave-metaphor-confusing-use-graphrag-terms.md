---
title: "UC: Warp/Weft Weaving Metaphor Confusing — Use GraphRAG Terms; Footer 'Warp' Listed Cross-Product Cluster Names; Geometric Nodes → Blobs"
description: "User: '縦糸なのに◯◯×◯◯みたいな横糸も混じった表記になっていて意味がわかんない' '縦糸横糸がよくわかんない。GraphRAG の用語にしてもらった方がいい' '図形の形じゃなくて、ふよふよしたブロブで色分け'. Three related fixes on weevee.net: (1) the footer column titled 縦糸（分類軸） listed cluster labels like 'n8n × VPS' (axis×infra cross-products, i.e. weft mixed into a warp list) → now lists the 7 domains with featured high-traffic keywords (Claude Code, n8n, Ollama…) as sub-links; (2) the warp/weft metaphor was replaced across the site with knowledge-graph vocabulary (クラスタ/ノード/エッジ); (3) GraphHero's geometric node shapes (tri/quarter/diamond) were replaced with seeded organic blobs + slow wobble."
type: "user-correction"
tags: ["user-correction", "design", "information-architecture", "terminology", "weevee"]
---

## 1. Plan / Context
ブランド名 weevee は weave（織る）由来。初期デザインは「縦糸=分類軸 / 横糸=実測」の織物メタファーで UI 文言を統一し、フッターの縦糸列にはクラスタ（中分類）を並べていた。クラスタ名は「ローカルLLM × VPS」のような掛け合わせ名。トップの GraphRAG 風グラフは幾何図形（三角・四分円・菱形）でノードを描いていた。

## 2. Do / The Error（ユーザー指摘 2026-08-31）
- 「縦糸なのに何々×何々みたいな、横糸も混じった表記になっていて意味がわかんない」（フッターの縦糸列に掛け合わせ名）
- 「大きな括り + 検索流入が大きいもの（Claude Code など）を縦糸の中の小見出しに」
- 「グラフの見た目と縦糸横糸のイメージが合わない。縦糸横糸がよくわかんない。GraphRAG の用語にした方がいい」
- 「図形の形じゃなくて、ふよふよしたブロブで色分けした方がいい」

## 3. Check / Root Cause
1. **メタファー（織物）と実装（グラフ）が乖離** — 見た目はノード・エッジのグラフなのに、言葉だけ縦糸横糸で説明していた。読者はメタファーの解読を強いられる
2. **「縦糸」を名乗る UI に中分類（軸×インフラの交点名）を使った** — 交点は定義上「横糸との掛け合わせ」なので、縦糸リストに置くと自己矛盾する
3. 幾何図形は「分類記号」に見え、グラフの有機的な知識ネットワーク感と合わない

## 4. Act / Prevention Strategy (Fix)
- フッター: 縦糸列 → 「クラスタ（分類軸）」として**大分類 7 つ + featured キーワード**（taxonomy.json `domain.featured`・Keyword Planner の search_volume が入ったら実測順位で見直す）
- 文言: 縦糸/横糸/warp/weft を全 UI から撤去し、クラスタ・ノード・エッジ・知識グラフに統一（トップ lead・AboutBlock・Principles・運営者情報・記事一覧 description）。ブランド名の weave 由来説明は残す
- GraphHero: ノードを seeded blob（id から決定論の有機閉曲線・リサイズ後も同形）+ ゆっくり回転伸縮の「ふよふよ」に。ドメイン色で色分け（紺ブロブは紺背景で消えるので白リング）
- **予防ルール: UI の説明語彙は「見た目がそう見えるもの」の語彙を使う（実装がグラフならグラフの用語）。上位概念のラベルを名乗るリストに下位の掛け合わせ名を並べない**
- 関連: [[uc-search-volume-missing-free-seo-stack]]（featured の順位は search_volume で実測化）
