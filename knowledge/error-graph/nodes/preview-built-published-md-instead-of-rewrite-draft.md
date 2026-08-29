---
title: "Preview Gate Built the Old Published Markdown Instead of the Rewrite Draft"
description: "weevee 06b_preview placed the draft into site/src/content only when no file existed there ('temp_placed'). For a rewrite of a published article the production file exists, so the local build used the OLD markdown; 05 had already deleted the old section images as orphans, and the gate failed on a stale image reference — sending a passing rewrite (score 83) back for another round. Fix: always build from the draft and restore the production file afterwards."
type: "bug"
tags: ["preview", "rewrite-lane", "build", "stale-artifact", "weevee"]
---

## 1. Plan / Context
06b はローカル Astro ビルドで実物 HTML を検査してから draft ブランチへ push する。下書きは `site/src/content/blog/{lang}/{slug}.md` に一時配置し、ビルド後に消す設計（新規記事前提）。

## 2. Do / The Error（2026-08-29 記事 7 の競合超えリライト・第 2 ラウンド）
- 検閲 score 83 で合格 → 06b が「画像参照が実ファイルに解決しない: sec-5-infographic.png」でゲート不合格 → draft へ戻り第 3 ラウンドの 04 が走った（無駄な 1 ラウンド）
- 下書きには sec-5 への参照は無かった。参照していたのは**本番の旧 md**

## 3. Check / Root Cause
1. `temp_placed = not dest.exists()` — 公開済み記事のリライトでは本番 md が存在するため下書きを配置せず、旧 md でビルドしていた
2. 05 は manifest に無い旧 `sec-N` を孤児として削除する → 旧 md の参照だけが残る
3. 新規記事しか通らなかった間は顕在化しなかった（リライトレーンの初実走で発覚）

## 4. Act / Prevention Strategy (Fix)
- 06b: 本番 md があっても**必ず下書きで上書きしてビルド**し、finally で元の内容を復元（無ければ削除）
- **予防ルール: 「ファイルが無い時だけ配置する」条件分岐は、既存ファイルがある経路（更新・リライト）で古い成果物を検査する事故になる。検査対象は常に「今回の成果物」に固定する**
- 関連: [[image-reuse-by-section-index-after-restructure]] [[reviewer-flagged-machine-rendered-log-image-as-fabricated]]
