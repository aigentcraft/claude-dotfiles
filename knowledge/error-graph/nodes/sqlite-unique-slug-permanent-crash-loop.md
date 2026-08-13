---
title: "sqlite-unique-slug-permanent-crash-loop"
type: "error"
tags: ["sqlite", "unique-constraint", "pipeline", "pullie", "slug", "self-healing"]
date: "2026-08-13"
---

## 症状（Symptom）

pullie の日次パイプラインで記事#8の執筆（04_write_article）が3日連続（8/11夜〜8/13昼）
`sqlite3.IntegrityError: UNIQUE constraint failed: articles.slug` でクラッシュし、
新規記事の生産ラインが完全停止していた。run_pipelineは失敗をログして次runで再試行するが、
同じ入力→writerが同じslugを再生成→同じ衝突、の恒久ループ。

## 根本原因（Root Cause）

- **棄却済み（rejected）記事もslugを保持し続ける**設計のまま、articles.slug に UNIQUE 制約がある
- 同系テーマの企画が再登場すると、writerは自然に同じslug（例: kintone-construction-cost-breakdown）を
  生成する。生成物の一意性をLLMの偶然に依存し、機械側に衝突解決がなかった
- 「3日でstale破棄→企画をplannedへ返却」の自己修復機構が、**同じ企画を再投入するため
  同じ衝突を再生産する**（自己修復が無限ループの部品になった）

## 修正（Fix）

- `unique_slug(con, slug, article_id)`: INSERT前に衝突を検査し `-2`, `-3`… で決定論的に一意化
  （自記事の再執筆＝同slugは衝突扱いしない）
- writerプロンプトに「使用済みslug一覧（棄却分含む・重複禁止）」を注入し、そもそも衝突しにくくする
- 実DBで衝突/自己/新規の3ケースを検証後、実runで記事#8の復旧を確認

## 予防ルール（Prevention）

- **LLM生成物をUNIQUE列に書き込むときは、機械側の衝突解決（サフィックス等）を必ず挟む**。
  「LLMが一意な値を作ってくれる」は成立しない（特に同系テーマの再企画で確実に再発する）
- リトライ型の自己修復（破棄→再投入）を設計するときは「同じ入力なら同じ失敗になる」ケースを
  シミュレートする。入力が変わらないリトライは修復ではなくループ
- UNIQUE違反のIntegrityErrorがrunログに出たら、次runでの自然回復を期待せず即恒久対処
