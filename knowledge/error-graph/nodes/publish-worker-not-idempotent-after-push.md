---
id: publish-worker-not-idempotent-after-push
title: 公開ワーカーがpush済み状態からの再実行で「差分ゼロcommit失敗」により永久に完了しない
type: failure
severity: high
date: 2026-08-11
project: pullie (Kintone受注目的メディア運営自動化)
cluster: pipeline-idempotency
tags: [git, idempotency, pipeline, publish, cloudflare-pages]
---

# 公開ワーカーの再実行が「nothing to commit」で確定失敗するnon-idempotency

## 症状
記事承認→07_publishがコミットをpush→**Pagesビルドのキュー詰まりで6分の公開検証がタイムアウト**
→ SystemExitでstatus更新前に終了。後続の自己回復runが07を再実行するも、
今度は差分ゼロで `git commit` が非ゼロ終了→RuntimeError→**何度再実行しても完了しない**恒久スタック。

## 根本原因（二段）
1. 検証が常に失敗していた真因: **pullie.jp / pages.dev はCloudflare配下で、素のPython
   urllib UAが403ブロックされる**（当初「Pagesビルドキュー詰まり」と誤診 — 実測で訂正。
   同一プロジェクト内でDiscord通知が同じ理由で403った既知パターンの横展開漏れ。
   06bのプレビュー検証が全日 verified=false だったのも同根）
2. 非冪等: 07が「必ず新規コミットが生まれる」前提で、push済み状態からの再開経路がなかった

## 修正
- `git diff --cached --quiet` でステージ差分を確認し、差分ゼロなら commit/push をスキップして
  検証以降（URL 200確認→DB更新→通知）を続行
- 検証窓を6分→12分に拡張

## 予防ルール
**push・API送信など「外界に効果が残る」ステップを含むワーカーは、
「効果が既に反映済みの状態から再実行して完了できるか」を実装時に必ず確認する。**
再開性の判定は内部状態でなく外界の実状態（git差分・HTTP 200・レコード存在）で行う。
**Cloudflare配下URLへのHTTPアクセスは必ずブラウザ風User-Agentを付ける** — 1箇所で直した
既知の落とし穴は、リポジトリ全体を `grep urlopen` して横展開するまでが修正。
「検証失敗」を調査する時はまず同じ検証を手元で最小再現する（curl成功≠urllib成功。
今回curlの成功を根拠にビルドキュー説へ誤誘導された）。
