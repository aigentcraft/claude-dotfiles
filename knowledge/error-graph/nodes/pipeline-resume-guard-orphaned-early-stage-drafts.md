---
title: "pipeline-resume-guard-orphaned-early-stage-drafts"
type: "error"
tags: ["pullie", "pipeline", "orchestration", "resume", "orphan"]
date: "2026-08-09"
---

## 症状（Symptom）

日次パイプラインの再開ロジックを「未完了draft全般」に拡張した際、`slug IS NOT NULL` 条件を付けたため、リサーチ段階（03）で失敗したslugなしdraft（article #5）が翌日以降拾われず再び孤児化した。1週間前に手動掃除した孤児記事(#3,#4)と同型の再発。

## 根本原因（Root Cause）

- 「再開=執筆済み記事の続行」というイメージでresume対象を絞り、**最も失敗しやすい初期ステージ（リサーチ）こそ再試行が必要**という逆説を見落とした
- 一方で無条件再開は恒常失敗のコスト垂れ流しになる、という対の設計（打ち切り条件）を同時に入れなかった

## 修正（Fix）

`run_pipeline`: resumeを全draft対象に（stage検知が03から積み直す）+ 作成3日超でslugなしのdraftは自動破棄して topics を planned へ返却（ops通知付き）。

## 予防ルール（Prevention）

1. リトライ/再開ロジックは「対象の絞り込み」と「打ち切り条件」を必ずペアで設計する（絞り込みだけだと孤児、無限再開だとコスト事故）
2. 状態機械にstatusを追加・分岐させたら「この状態の行は誰がいつ拾うのか」を全statusについて表にして確認する
