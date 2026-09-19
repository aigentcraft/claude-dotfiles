---
name: jina-402-mid-run-degrades-to-lexical-clusters
title: 外部 API の残高切れ（Jina 402）が run の途中で起き、語彙だけのクラスタ + 競合ゼロで「調査した」ことになりかけた
cluster: api-network
type: "error"
tags: ["jina", "http-402", "quota", "silent-degradation", "keyword-research", "fail-closed", "weevee"]
date: 2026-09-19
severity: high
---

## 症状
週次キーワード調査（`tools/keyword_research.py --auto 6`）の初回実走（2026-09-19 18:32）で、SERP 指紋の取得が
4 語目から全部 `HTTP 402` になった。処理は止まらず、語彙シグネチャだけで束ねたクラスタ（`語彙のみ（要確認）`）を作り、
競合は 8 群すべて失敗し、`rc=1` で終わった。直前の 3 run（07:40 / 07:51 / 09:32 UTC・SERP 67 語 + 競合 50 ページ ≈ 31 万字）で
残高を使い切っていた。

## 根本原因
- `serp.fetch_fingerprints` は Jina の失敗を**語ごとに**飲んで次の語へ進む設計（1 語の失敗で面を落とさないため）。
  402（残高）/ 401・403（キー）は**全部の語で同じ結果になる**のに、区別せず 1 語ずつ失敗し続けた
- 調査の結果（bundle）は「クラスタがある」ので、企画補充（02a）の材料ゲート（`has_material` = クラスタの語に結ばれているか）を
  **通る**。SERP も競合も無いのに「材料あり」と判定され、9/18 と同じ「材料なしの企画」が起きうる状態だった
- 外部 API の残高は AI が補充できない（人間決定③: 課金操作は人間）のに、人間に届く経路が無かった（rc=1 が Task Scheduler に残るだけ）

## 修正
- `keyword_research.research()`: SERP の失敗理由に「続行不能 / HTTP 402・401・403」があれば `stats["jina_fatal"]` に残し、
  その run の競合取得は最初から諦める（`status='jina_unavailable'`）
- 02a: `jina_fatal` なら **seo-strategist を呼ばず企画しない**（③物理: 材料が揃わない）。`topics.replenish_blocked` を記録
- 着手時の取り直し（`refresh_for_topic`）: `jina_fatal` なら企画時の意図ブロック（SERP つき）を語彙だけのもので上書きしない
- `warn_jina_fatal()`: Discord ops に **1 日 1 回**（`ops.jina_fatal` イベントで重複抑止）。人間の作業（残高補充）を明記
- `daily_invariants.check_jina_usable`: 直近 24 時間の `ops.jina_fatal` を毎朝の赤に。補充が済むまで消えない
- 週次ラッパーの rc=1 は既存の `launchers_did_work` が「失敗して終了」と拾う（`naming.JOB_LABELS` に役名を追加）

## 予防ルール
- **外部 API の「続行不能」（残高・キー）は語ごとの失敗と同列に扱わない。** 1 件目で run 全体の状態にし、残りの呼び出しを止める
- **材料ゲートは「材料の入れ物がある」でなく「材料が入っている」を見る。** クラスタがあっても SERP 由来でなければ材料ではない
- 人間にしかできない復旧（課金・鍵）は、**人間に届く経路（通知 + 毎朝の一覧）と一緒に**実装する。rc だけでは届かない

## 関連
- [[uc-planned-without-the-designed-keyword-research]] — この材料集めを配線した当日に起きた
- [[verification-tool-that-cannot-fail]] — 「調査した」の証拠が rc や件数だけだと嘘になる型
- [[stale-external-approval-never-reverified]] — 外部の状態は再確認する日と場所を決める
