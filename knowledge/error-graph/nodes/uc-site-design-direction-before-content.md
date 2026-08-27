---
title: "UC: Shipped Articles Into a Site With No Top Page and Generic 'AI-Made' Design"
description: "User: 'そもそものトップページができておらず、記事のデザインがいかにもAIが作ったようなレベルの低いもの'. weevee had a skeleton index, default-looking article layout, and a logo sitting unused in logo/. Required order: top page first (logo-matched, professionally animated) to set the design direction, then article layout; because 'structuring' is the site's value, articles must be structurally organized and visually navigable."
type: "user-correction"
tags: ["user-correction", "design", "site-structure", "top-page", "brand", "weevee"]
---

## 1. Plan / Context
Phase 0 は「パイプラインが動くこと」を優先し、Astro の骨格（必須5ページ・PR表記・i18n）で公開準備に入った。ロゴ PNG は `logo/` に置かれていたが「出所不明・未コミット」として扱い、デザインに反映していなかった。

## 2. Do / The Error（ユーザー指摘 2026-08-27）
- 「そもそものトップページができておらず、記事のデザインがいかにもAIが作ったようなレベルの低いもの」
- 「まずはトップページから作ってサイトデザインの方向性を作った方が良さそう」
- 「ロゴだけ決めており、ローカルの logo フォルダに入れてある。それに合うデザインに」
- 「アニメーターが作ったような、プロのアニメーションを作ったようなトップページ」
- 「構造化することがこのサイトの価値提供 → 記事自体も構造的にまとめられ、視覚的に探しやすい仕様に」

## 3. Check / Root Cause
1. **順序の誤り**: コンテンツ生成基盤を先に作り、デザインの方向性（ブランド・トーン・構造）を決めないまま記事を量産しようとした。承認依頼で人間が最初に目にするのは「記事の見た目」なのに、そこが未設計だった
2. **ロゴを「未確認の資産」として放置** — ユーザーは決定済みのブランド資産として置いていた。確認せずに「出所不明」と判断し、デザインの起点を捨てていた
3. **「構造化が価値」を UI に落としていなかった** — docs/01 の価値提供（AI 情報の構造化）はテキストの話として扱い、サイトのナビゲーション・記事内の構造表示（分類軸・比較軸・目次）として設計していない（[[uc-articles-must-carry-own-positioning]] と同型: 上位ドキュメントの価値がプロダクトに現れない）
4. テンプレート初期状態（グレー背景・カード並び）をそのまま出した = ECC design-quality ルールの禁止パターン

## 4. Act / Prevention Strategy (Fix)
- **順序**: ロゴ → デザイントークン（色・書体・余白・モーション）→ トップページ（アニメーション込み）→ 記事レイアウト → 画像仕様 → コンテンツ再生成。以降のフェーズでも「人間が見る面」を先に作る
- **ロゴ等のブランド資産は見つけた時点で開いて確認し、ユーザーに用途を聞く**（未確認のまま放置しない）
- **価値提供を UI 仕様に翻訳する**: 「構造化」= クラスター/軸で辿れるトップのマップ・記事内の構造ブロック（対象/軸/結論を先頭に固定・比較表・目次）・シリーズ導線
- **予防ルール: 承認依頼の前に「この面はプロが作ったと言えるか」を自問する。テンプレ既定値のまま人間に見せない**
- 関連: [[uc-article-images-decorative-not-explanatory]]・[[uc-articles-must-carry-own-positioning]]
