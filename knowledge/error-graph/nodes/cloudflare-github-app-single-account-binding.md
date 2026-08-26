---
title: "Cloudflare Pages GitHub App: 1 Installation Binds to Only 1 Cloudflare Account"
description: "The Cloudflare Workers & Pages GitHub App installs once per GitHub personal account, and that installation links to exactly one Cloudflare account. Connecting a second CF account dead-ends. Fix: create a dedicated GitHub Organization per project."
type: "technical-error"
tags: ["cloudflare-pages", "github-app", "git-integration", "infrastructure", "multi-account"]
---

## 1. Plan / Context
weevee プロジェクト（アフィリエイトエージェント）で、爆発半径分離のため pullie とは別の Cloudflare アカウントを新設し、同じ GitHub 個人アカウント（aigentcraft）のリポジトリを Pages Git 連携しようとした。

## 2. Do / The Error
- 2つ目の CF アカウントから「Connect GitHub」すると、GitHub 側で「既にインストール済み」の設定ページに飛ばされ、state コールバックが発火せず接続できない（何度やっても袋小路）
- アプリを uninstall→reinstall すると、**新規インストールのフローを踏んだ側の CF アカウントに紐付けが移り、もう一方の CF アカウントの既存 Pages プロジェクトに「internal issue with your Git installation」警告が出て自動デプロイが停止**する（綱引き構造）

## 3. Check / Root Cause
- GitHub App は個人アカウントにつき1インストールのみ。Cloudflare はそのインストールを**1つの CF アカウントにしか紐付けない**
- 紐付けは「新規インストール時の setup コールバック」でのみ確立される。既存インストールへの接続試行はコールバックが発火しない

## 4. Act / Prevention Strategy (Fix)
- **恒久解: CF アカウントを分けるプロジェクトは GitHub Organization も分ける**（無料 org で可）。インストールは org 単位で独立するため衝突しない
  - 手順: org 作成 → リポジトリ移管（即時・旧URLリダイレクトあり）→ ローカル `git remote set-url` → CF から org へ新規インストール → プロジェクト再接続
- 壊れた側の復旧: アプリを uninstall → 壊れた CF アカウントのフローから reinstall → プロジェクトの Git を Disconnect→Connect（ビルド設定・バインディング・ドメインは保持される）
- Pages の D1 バインディングは `wrangler.toml` に書いておけばダッシュボード設定不要（自動適用）
