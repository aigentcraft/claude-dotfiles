---
id: frontmatter-field-not-wired-into-all-renderers
title: heroImage追加時にトップページのレンダラーだけ未結線でプレースホルダが本番に残った
type: technical-error
severity: medium
date: 2026-08-15
project: pullie (Kintone受注目的メディア運営自動化)
cluster: producer-consumer-sync
tags: [producer-consumer-sync, astro, schema-sync, renderer, visual-inspector, pullie]
---

# heroImage を追加した時、同じカードを描く2つ目のレンダラー（トップページ）を結線し忘れた

## 症状（ユーザー報告 2026-08-15）
「pullieのトップページの記事一覧にアイキャッチ画像が表示されてないみたいだから直して」
— 公開4記事すべてに heroImage frontmatter と実画像
（`site/public/img/blog/<slug>/eyecatch.png`）が揃っているのに、
トップページの記事カードは全てストライプのプレースホルダ表示だった。

## 根本原因
1. **同じデータを描くレンダラーが2箇所あり、片方だけ更新された**。
   05_generate_images（プロデューサー）が heroImage を自動設定するようになった際、
   `/articles/` 一覧（`site/src/pages/articles/index.astro`）には
   「heroImage あれば `<img>`・なければストライプ」の分岐が入ったが、
   トップページの `site/src/components/home/ArticlesSection.astro` は
   `post.data.heroImage` を一度も参照しないプレースホルダ固定実装のまま残った。
2. **検知はあったが修正レーンに接続されなかった**。
   visual-inspector は 2026-08-13 の実走でこの画面を実見し
   「記事カードはすべてストライプのプレースホルダー」と記録していた
   （domain_knowledge id=18・own_top_mobile）。しかし
   「実画像が入ると存在感が大きくなる設計」と**コンテンツ未整備と誤診**し、
   designer向けデザイン助言（status=candidate）として沈んだ。
   実際はデータが既に存在するのに描画されないコード欠陥であり、
   人間の指摘（2日後）まで直らなかった。

## 修正
- `ArticlesSection.astro` に `/articles/` と同一の分岐を追加
  （`heroImage` あれば `<img loading="lazy" object-fit:cover>`・なければ従来ストライプ）。
  ローカルビルドで index.html に3記事分の `<img src="/img/blog/...eyecatch.png">` が
  入りプレースホルダ0件を確認 → main push → 本番反映を実見確認。

## 予防ルール
1. **スキーマ/frontmatterにフィールドを追加したら、そのコレクションの全消費側を
   grepで洗い出して同一コミットで結線する**（Astroなら `getCollection('blog')` と
   カード描画コンポーネントを全部）。
   [[catalog-key-added-without-consumer-sync.md]]（2026-08-11）と同型 —
   カタログ・enum・スキーマの「プロデューサー拡張は消費側の全数同期まで1コミット」。
2. **「プレースホルダ/画像なし」を見つけた検分者は、先に
   「データは既に存在するか」を確認する**。存在するのに表示されない＝コード欠陥
   （high・修正レーン/ops通知行き）。存在しない＝コンテンツ課題（design助言行き）。
   誤診すると検知済みの欠陥が knowledge に沈んで直らない。
