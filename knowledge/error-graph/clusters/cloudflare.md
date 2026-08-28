# Cluster: Cloudflare（Pages / D1 / wrangler / DNS）

> Layer 1 Community Summary — 関連ノードの蒸留サマリー。
> Cloudflare Pages のデプロイ・環境変数・wrangler.toml・D1・DNS を触るタスク時にロードする。

**対象タグ**: `cloudflare`, `pages`, `wrangler`, `d1`, `deploy`, `env-vars`

---

## 蒸留ルール（Distilled Rules）

### R1: wrangler.toml がある Pages プロジェクトでは wrangler.toml が唯一の正
ダッシュボード/API で設定した環境変数・バインディングは、デプロイのたびに wrangler.toml の内容で上書き（無いものは削除）される。
- **対策**: 公開値（GA4 測定 ID 等）は `[vars]` に書く。プレビュー環境は `[env.preview.vars]` で分ける
- **禁止**: API で `env_vars` を PATCH して「設定できた」と報告すること（次のデプロイで消える）
- **確認**: デプロイログの `Build environment variables:` 行と公開 HTML の grep の両方

### R2: wrangler.toml が参照するファイル・手順は実在を機械検査する
コメントに書いた初期化ファイル（例: `db/leads.sql`）が存在しないまま公開されていた事故がある。
- **対策**: wrangler.toml / README が指すパスは CI かスクリプトで `ls` する

### R3: 「設定 API 成功」≠「反映」
Cloudflare に限らず、設定系 API の成功応答は「保存された」であって「本番で効いている」ではない。実物（ログ・HTML・DNS 応答）で確認する。

---

## ノード一覧
- [[../nodes/cloudflare-pages-wrangler-toml-overrides-dashboard-env-vars.md]] — API で入れた `PUBLIC_GA4_ID` が次デプロイで消えた（2026-08-29・weevee）
- [[../nodes/wrangler-toml-referenced-file-missing.md]] — wrangler.toml が指す D1 初期化 SQL が存在しなかった（2026-08-06・pullie）
