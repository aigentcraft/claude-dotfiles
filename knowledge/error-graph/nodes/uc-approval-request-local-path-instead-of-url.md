---
title: "UC: Approval Request Pointed to a Local File Path — Human Could Not Open It"
description: "06b_preview sent 'ローカルプレビュー: site/dist/ja/blog/{slug}/index.html' in the Discord approval request. The human (on phone) said 'リンクになっていないから表示できない'. The remote preview-branch deploy had been deferred to Phase 1 in a docstring, even though the prerequisite (Pages Git integration) was already live one session earlier. A human-facing request must carry an openable URL, and 'deferred until X' assumptions must be re-checked when X completes."
type: "user-correction"
tags: ["user-correction", "hitl", "approval-flow", "stale-assumption", "cloudflare-pages", "weevee"]
---

## 1. Plan / Context
weevee の 06b_preview は承認待ち記事をローカル Astro ビルドで機械プローブし、Discord の approvals チャンネルへ承認依頼を送る。
docstring に「リモートの draft ブランチデプロイは GitHub 連携が本稼働してから（Phase 1）— Phase 0 ではローカルビルドの実物HTMLをプローブ」と書かれていた。

## 2. Do / The Error
- 承認依頼の本文が `ローカルプレビュー: site/dist/ja/blog/{slug}/index.html`（`cd site && npm run preview` で確認可）だった
- ユーザーはスマホの Discord で受信 → **「記事の承認依頼が来てるけど、リンクになっていないから表示できない」**
- HITL 全承認の設計なのに、承認者が成果物を見られない = 承認フローが機能していない

## 3. Check / Root Cause
1. **前提条件が完了した後も「後回し」の判断を再評価しなかった** — Pages の Git 連携は 2026-08-26 #2 で完了していたが、同日 #3 で書いた 06b は「連携がまだ」という古い前提のまま。docstring の「Phase 1 で」が凍結された
2. **人間宛て通知の受信環境（スマホ）を想定していなかった** — ローカルパスは開発者の PC でしか意味を持たない。「承認は実物レンダリングで」（参照プロジェクトの教訓）は知っていたが、「実物 = 人間が開ける URL」まで具体化していなかった
3. 参照プロジェクトには `push_draft_branch`（git plumbing で origin/main + 下書きの commit を draft ブランチへ強制 push → `https://draft.<project>.pages.dev`）が既にあり、移植すれば済んだ。「Phase 0 では簡略版」と自分で決めて移植を省いた

## 4. Act / Prevention Strategy (Fix)
- 06b に参照プロジェクトの `push_draft_branch` を移植: origin/main + review 全記事の md + 画像を plumbing で commit → `refs/heads/draft` へ force push → Cloudflare Pages がプレビューデプロイ（`X-Robots-Tag: noindex` 自動付与）→ 反映待ち（内容ハッシュ変化で判定）→ **URL を通知**
- **予防ルール: 人間宛ての依頼・通知には「その人の受信環境で開ける URL」を必ず含める**。ローカルパス・コマンドは補足に留める
- **予防ルール: 「X が終わってから」と後回しにした実装は、X の完了をトリガーに再評価する**。docstring / CLAUDE.md に「前提: X 未完了」と書いた箇所は、X 完了のコミットで grep して棚卸しする
- **予防ルール: 参照プロジェクトに同名の実装があるものを「簡略版で」と省略しない**（CLAUDE.md「車輪の再発明禁止」の逆方向 — 再発明どころか未実装）
- 関連: [[ai-instruction-enforcement]]（後処理は出口条件にする）・[[stale-claude-md-duplicate-implementation]]（古い記述が判断を凍結する）
