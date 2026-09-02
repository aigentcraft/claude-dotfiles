---
title: "claude-in-chrome-secret-exposure-find-tool-values"
type: "error"
tags: ["claude-in-chrome", "secrets", "find-tool", "screenshot", "clipboard", "weevee"]
date: "2026-09-02"
---

## 症状（Symptom）

console.x.com の資格情報モーダルを Claude in Chrome で操作中、秘密値が 2 回 AI コンテキスト（= 会話ログ）に入った:
1. 保存後モーダルのスクリーンショットに OAuth 2.0 Client ID / Client Secret が平文で写った
2. `find` に「copy buttons **(with which value it copies)**」と尋ねたら、要素説明に Access Token と Secret の値そのものが返った

## 根本原因（Root Cause）

- 秘密値を扱うモーダルの位置・ボタン配置を知るためにスクリーンショットを撮った（値は同じ画面に必ず表示される）
- `find` の自然言語クエリで「どの値をコピーするか」を要求した → ツールは忠実に値を引用した
- 「値を AI に通さない」設計（コピーボタン → クリップボード → CLI）は用意していたが、**ボタンを特定する工程**で漏れた

## 修正（Fix）

- 露出した値は**その場で再生成して無効化**（OAuth2 Client Secret・Access Token/Secret）。`.env` には再生成後の値のみ保存
- 以後の工程を統一: `find` は「copy-to-clipboard buttons in top-to-bottom order **(do not describe or quote any values)**」で参照だけ取得 →
  `computer left_click ref=...` → `python tools/envclip.py set KEY`（値は長さと sha256 指紋のみ表示・書込後クリップボード消去）
- 確認は `envclip status`（指紋）と `envclip verify-x`（API で username / x-access-level）で行い、画面を見ない

## 予防ルール（Prevention）

1. **秘密値が表示される画面ではスクリーンショットを撮らない**。位置特定は `find` / `read_page`（ref）で行う
2. **`find` のクエリに値の説明を求めない**。「値を引用しない」を明示する
3. **露出したら議論せず再生成**（一度きり表示のトークンは再生成が唯一の無効化手段）
4. 既存パターンの継承: [[google-ads-api-setup-gotchas-oauth-timeout-customer-not-enabled]]（クリップボード → CLI 直渡し）
