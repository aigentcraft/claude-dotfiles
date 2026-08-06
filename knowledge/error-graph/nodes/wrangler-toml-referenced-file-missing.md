---
title: "wrangler-toml-referenced-file-missing"
type: "error"
tags: ["cloudflare", "pages", "d1", "wrangler", "deploy", "lead-pipeline"]
date: "2026-08-06"
---

## 症状（Symptom）

pullie の本番フォーム（/api/lead）が D1 保存に失敗する状態で公開されていた。`site/wrangler.toml` のコメントに「`wrangler d1 execute pullie-leads --remote --file=db/leads.sql` で初期化」と書かれているのに、**db/leads.sql がリポジトリに存在しなかった**。D1 は Tables: 0 のまま（leads テーブル未作成）。

## 根本原因（Root Cause）

- 実装セッション（Mac）が wrangler.toml に手順を書いた時点で leads.sql の作成を後回しにし、コミット漏れした
- 手順書（コメント）と実体（ファイル・リモートDB状態）の突合を誰も検証しなかった。D1 バインディングが存在する＝初期化済み、という思い込み

## 修正（Fix）

- `db/leads.sql` を lead.ts の INSERT 文からリバースして作成（`sqlite3 :memory:` でスモーク後コミット）
- CloudflareダッシュボードのD1コンソールで CREATE TABLE + INDEX を実行し、本番 /api/lead → D1 保存の E2E で疎通確認（curl 303 + SELECTでレコード確認）

## 予防ルール（Prevention）

1. **設定ファイルが参照するファイルパスは、書いた時点で存在検証する**（`--file=X` と書いたら `test -f X` まで）
2. マネージドDB（D1等）を導入したら「バインディング設定」と「スキーマ適用」を別チェック項目にする。`/tables` 相当の実体確認をデプロイ前チェックリストに入れる
3. リード導線のような**取りこぼし厳禁の経路は、本番相当環境で1件流すE2Eをリリース条件**にする
