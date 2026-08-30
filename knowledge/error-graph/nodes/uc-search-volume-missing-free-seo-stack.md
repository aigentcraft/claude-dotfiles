---
title: "UC: Search Volume Was Never Obtainable — Free SEO Stack Declared It Impossible and Faked It From GSC Impressions"
description: "User: '検索ボリュームを取れるようにしないと'. docs/07 asserted '検索Volの絶対値は無料では取れない' and routed search_volume to GSC-only, while weekly_pdca silently wrote weekly impressions×4 into keywords.search_volume (a different quantity). Root cause: rule 10 (no paid ops) was over-applied to 'anything Google Ads', so the free Keyword Planner path (Google Ads API, Basic access) was never planned, and the placeholder estimate had no provenance column so nobody noticed. Fix: Google Ads API Keyword Planner client (LLM-Free), volume provenance columns, GSC impressions kept as a separate signal, human runbook for MCC + developer token + Basic access."
type: "user-correction"
tags: ["user-correction", "seo", "keyword-planner", "google-ads-api", "data-provenance", "weevee"]
---

## 1. Plan / Context
docs/07「無料データドリブンSEO基盤」は「検索Volの絶対値は無料では取れない」と断定し、search_volume は GSC 実測のみ・有料のラッコキーワード導入は人間判断待ち、とした。seo-strategist の優先度式（検索Vol × CV期待値 × 鮮度 × 戦略配分）は Vol を前提にしているのに、供給経路が無かった。

## 2. Do / The Error（ユーザー指摘 2026-08-30）
- 「検索ボリュームを取れるようにしないと」
- 実態: keywords.search_volume は 54 件すべて NULL。weekly_pdca は GSC の週間表示回数 × 4 を search_volume に書き込む（表示回数は「自サイトが表示された回数」で検索ボリュームではない）。出所を示す列が無く、混入しても見分けがつかない

## 3. Check / Root Cause
1. **ルール 10（課金操作禁止）の過剰適用** — 「Google Ads = 課金」と短絡し、Google Ads アカウントは無料で作れ、Keyword Planner の API（`generateKeywordHistoricalMetrics`）が無料で月間検索数（JP・完全一致・12 ヶ月系列・CPC）を返すことを設計時に検討しなかった
2. **「無料では取れない」を検証せずに docs に断定で書いた** — 断定が後続の設計を縛った
3. **代替値（表示回数×4）に出所列を付けなかった** — 推定値と実測値の区別（docs/06 §3「データ根拠の有無を明示分離」）を自分で破った

## 4. Act / Prevention Strategy (Fix)
- `workers/shared/google_ads.py`（stdlib・OAuth リフレッシュトークン → Keyword Planner REST）+ `kwcli volume --print/--write`（`keywords.search_volume` + `volume_source='kwp'` + `competition` + `cpc_jpy` + `keyword_volumes` 月次系列）
- weekly_pdca の表示回数×4 は `gsc_impressions_month` 列へ移し、`volume_source='kwp'` の値を上書きしない
- 人間作業を明文化: Google Ads MCC 作成 → developer token → Basic access 申請（用途「Researching keywords」・Explorer access では planning 系が使えない・2026 年は審査バックログあり）
- **予防ルール: 「無料では取れない」「不可能」を設計書に書く前に、公式ドキュメントで 1 回検索する。代替の推定値を本来の列に書く時は必ず出所列を付け、実測/推定/推計を混ぜない**
- 関連: [[cloudflare-pages-wrangler-toml-overrides-dashboard-env-vars]]（「設定できた」≠「反映された」と同型の「書いた」≠「取れている」）
