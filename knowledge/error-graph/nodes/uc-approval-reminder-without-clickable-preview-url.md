---
title: "UC: Discord Approval Reminder Pointed at a Local File Path Instead of the Preview URL"
description: "weevee 09_notify's '承認待ちリマインド' listed each stale article with 'プレビュー: `site/dist/ja/blog/<slug>/index.html`' — a local build path in backticks — while 06b's original approval request used the clickable draft URL (https://draft.weevee.pages.dev/{lang}/blog/{slug}/). User (2026-08-30): 'ディスコードの承認未完了通知がurlの遷移できるものになっていない'. Root cause: the reminder was written before the draft-branch preview existed and was never updated when 06b switched to open-able URLs; the two messages had no shared URL builder."
type: "uc"
tags: ["uc", "notification", "discord", "approval", "consistency", "weevee"]
---

## 1. Plan / Context
承認依頼（06b）と放置リマインド（09）は同じ「プレビューを見て承認/差し戻し」を求める通知。06b は 2026-08-27 に draft ブランチの開ける URL に切り替え済み。

## 2. Do / The Error（2026-08-30 ユーザー指摘）
- リマインドの各行が `site/dist/ja/blog/<slug>/index.html`（ローカルのビルド成果物パス・バッククォート内）で、スマホの Discord から何も開けない

## 3. Check / Root Cause
1. リマインド文面は draft プレビュー導入前に書かれ、06b の変更時に同期されなかった
2. プレビュー URL の組み立てが 06b にだけあり（`PREVIEW_BASE`）、共通関数が無かった
3. 通知文面のテストが無い（文面は目視でしか検証されない）

## 4. Act / Prevention Strategy (Fix)
- `_lib.preview_url(lang, slug)` を共通化し、06b と 09 の両方がそれを使う。リマインドは `[プレビューを開く](URL)` のマスクリンク + 生 URL
- **予防ルール: 人間の行動を求める通知は「開けるリンク」を必ず含める。同じ行動を求める通知が複数あるなら URL 生成を一箇所に集約し、片方を変えたら grep で他方も直す**
- 関連: [[uc-ai-authorship-still-visible-in-site-chrome]]
