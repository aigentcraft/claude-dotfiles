---
name: serp-tracking-id-splits-same-page
title: SERP の URL 正規化が Google の追跡 ID（srsltid）を残し、同じページが別 URL として比較されていた
cluster: api-network
type: "defect"
tags: ["serp", "url-normalization", "tracking-parameter", "clustering", "jina", "weevee", "pullie"]
date: 2026-09-23
severity: medium
---

## 症状
「上位 3 件のうち 2 件以上が同じ URL なら同じ検索意図」という SERP 指紋のクラスタリングで、
**同じページなのに重なりに数えられない**組があった。
pullie の実データ: 「kintone 開発 外注」と「kintone 外注」は上位に同じ lancers.jp のページがあるのに、
URL 末尾が `?srsltid=AfmBOoqW…` と `?srsltid=AfmBOopf…` で**別の URL**として比較され、重なりが 1 件になって束ならなかった。

## 根本原因
Google は検索結果のリンクに `srsltid`（検索ごとに値が変わる追跡 ID）を付けることがある。
URL 正規化の「落とす追跡パラメータ」一覧（広告クリック ID・utm 等）に `srsltid` が無かった。
実測（2026-09-23）: weevee の keyword_serps 175 行中 11 行、pullie の旧 SERP 531 URL 中 3 件に残っていた。

## 修正
- `serp.TRACKING_EXACT` に `srsltid` を追加（weevee・pullie とも）
- 保存済みの指紋を正規化し直した（weevee: 11 行 → 0 行。束なった群は 27 → 27 で、weevee の現データでは結果に影響なし
  ＝予防。pullie では上記の組が正しく束なるようになった）
- テスト: `normalize_url("https://example.com/a?srsltid=XYZ&page=2") == "example.com/a?page=2"`

## 予防ルール
1. **外部から取った URL を同一性の比較に使うときは、実データでクエリパラメータの一覧を取ってから除去リストを決める**
   （`SELECT` で `?` 以降のキーを集計する。想像で列挙した一覧は、実在するパラメータを取りこぼす）
2. **値が検索ごと・訪問ごとに変わるパラメータは同一性を壊す** — 「中身が変わるか（?page=2 は残す）」で判定する
3. 一方のプロジェクトで見つけた正規化の穴は、同じモジュールを持つ隣のプロジェクトにも当てる（pullie → weevee）

## 関連
- [[uc-reported-stale-wait-while-sibling-had-the-fix]] — 同じ日の移植作業（weevee → pullie）で見つかった。逆方向の横展開
