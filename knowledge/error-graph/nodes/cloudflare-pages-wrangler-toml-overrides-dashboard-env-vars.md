---
title: "cloudflare-pages-wrangler-toml-overrides-dashboard-env-vars"
type: "error"
tags: ["cloudflare", "pages", "wrangler", "env-vars", "deploy", "analytics", "weevee"]
date: "2026-08-29"
---

## 症状（Symptom）

GA4 の測定 ID を Cloudflare API（`PATCH /pages/projects/{name}` の `deployment_configs.production.env_vars`）で `PUBLIC_GA4_ID` として設定し、`--show` で `<set>` を確認。その後 `POST .../deployments` で本番を再デプロイしたが、公開 HTML に `gtag/js?id=G-…` が出ない。デプロイ直 URL（`{id}.weevee.pages.dev`）でも出ない。デプロイオブジェクトの `env_vars` は `{}`、プロジェクトの production `env_vars` も **空に戻っていた**。ビルドログ: `Found wrangler.toml file. Reading build configuration...` → `Build environment variables: (none found)`。

## 根本原因（Root Cause）

`site/wrangler.toml`（`pages_build_output_dir` あり）が存在する Pages プロジェクトでは、**wrangler.toml が設定の唯一の正**として扱われ、ダッシュボード/API で設定した環境変数・バインディングは **デプロイのたびに wrangler.toml の内容で上書き（無いものは削除）** される（プロジェクトに `wrangler_config_hash` が付く）。API で入れた値は「次のデプロイまで」しか生きない。

## 修正（Fix）

- 公開値（GA4 測定 ID は HTML に出るので秘密ではない）は `wrangler.toml` の `[vars]` に書く。承認プレビュー（draft ブランチ）では `[env.preview.vars]` で空文字にして計測を止める
- `tools/cfcli.py` に `pages-deploy`（本番再デプロイ）/ `pages-deployments`（状態一覧）を追加し、環境変数の反映確認をコマンドで行えるようにした
- 反映確認は「デプロイログの `Build environment variables:` 行」と「公開 HTML の grep」の両方で行う（`cfcli pages-env --show` が `<set>` でも信用しない）

## 予防ルール（Prevention）

1. **wrangler.toml がある Pages プロジェクトの環境変数は wrangler.toml に書く**。ダッシュボード/API は使わない（消える）
2. 秘密情報を Pages のビルド時に渡す必要が出たら、wrangler.toml に書けないので「ダッシュボードの Secrets（encrypted）」か「wrangler.toml を撤去してダッシュボード管理へ統一」のどちらかを人間が決める
3. 「設定 API が成功した」は「反映された」ではない。デプロイ後に実物（ログ・HTML）で確認する（R-HAZUDESU）
4. 関連: [[wrangler-toml-referenced-file-missing]]（同じファイルが「正」であることに起因する別事故）
