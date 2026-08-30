---
title: "google-ads-api-setup-gotchas-oauth-timeout-customer-not-enabled"
type: "error"
tags: ["google-ads-api", "oauth", "keyword-planner", "claude-in-chrome", "captcha", "weevee"]
date: "2026-08-30"
---

## 症状（Symptom）

Google Ads API（Keyword Planner）の開通を Claude in Chrome で代行した際に起きた 4 件:
1. **OAuth loopback の待ち受けが人間の同意より先に終了** — `kwcli auth` は 127.0.0.1 の一時サーバで code を 10 分待つ設計。人間がアカウント選択に手間取り、同意後のリダイレクトが `ERR_CONNECTION_REFUSED` になった。ブラウザ URL には `?code=...` が残っていた
2. **MCC の UI からクライアントアカウントを作ると「下書き（申込未完了）」のまま** — API は `authorizationError: CUSTOMER_NOT_ENABLED`。有効化はキャンペーン作成＋支払い設定が前提（課金操作 = AI 禁止）
3. **Explorer access では planning 系が `DEVELOPER_TOKEN_NOT_APPROVED`** — developer token は即時発行され Explorer access が自動付与されるが、`KeywordPlanIdeaService` は Basic access 申請（審査 5 営業日〜・設計書 .pdf/.doc/.rtf 添付必須）が通るまで使えない。`googleAds:search`（レポート）は Explorer で通るので認証チェーンの疎通確認に使える
4. **Google 広告のアカウント作成フォームは reCAPTCHA 付き**（MCC 作成・サブアカウント作成の両方）。AI は CAPTCHA を操作しない → その 1 クリックだけ人間に渡し、前後のフォーム入力は AI が埋める

## 根本原因（Root Cause）

- 1: 人間の操作時間を 10 分固定で見積もった。loopback 方式は「待ち受けが生きている間」しか code を受け取れない
- 2: Google 広告の新規アカウントは「申込フロー完了」で ENABLED になる。MCC 配下でも UI 作成は同じフローに入る（API の `CustomerService.createCustomerClient` なら請求なしで ENABLED になる）
- 3: アクセスレベルの制約（Explorer は planning/account/billing 系を除外）
- 4: 仕様

## 修正（Fix）

- `google_ads.authorize_interactive` の既定タイムアウトを 30 分に延長し、`exchange_code(code, redirect_uri)` を切り出した（ブラウザ URL の code と PORT で手動交換できる — 実際にこれで救済した）
- kwcli volume の API エラーをトレースバックではなく JSON（error + hint: Basic access 未承認）で出す
- Basic access 承認後の順序を docs/07 §5.2 に明記: ①MCC 直接指定で `--print` → ②`CUSTOMER_NOT_ENABLED` なら API でクライアントアカウント作成 → ③それも不可なら人間判断

## 予防ルール（Prevention）

1. **人間の操作を待つローカル待ち受けは 30 分以上 + 「期限切れ後の救済手順」を最初から用意する**（code はブラウザ URL に残る）
2. **Google 広告のアカウントは API（`createCustomerClient`）で作る**。UI 作成は申込フロー（支払い設定）に巻き込まれる
3. **Explorer / Basic の違いを先に確認**してから設計する（planning 系は Basic 必須）
4. 関連: [[uc-search-volume-missing-free-seo-stack]] [[claude-bash-heredoc-backslash-escape-halved]]
