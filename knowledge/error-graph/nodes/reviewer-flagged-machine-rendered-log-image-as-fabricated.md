---
title: "Reviewer Flagged a Machine-Rendered Terminal Image as Fabricated Evidence (F05)"
description: "weevee article 8 round 2: the reviewer failed F05/F03/C09 on sec-4-terminal.png ('port is already allocated' log) because the factsheet did not quote that log line — but the image is rendered deterministically by 05 from the researcher's lab.log line range, i.e. real evidence the reviewer simply could not see. Each false send-back burns one of the 3 rewrite rounds. Fix: 05 records each image's provenance (lab.log range / shots file / body-transcribed infographic) in manifest.json and 06 shows it to the reviewer with a rule not to treat those kinds as fabrication unless they contradict the text."
type: "bug"
tags: ["reviewer", "false-positive", "images", "provenance", "send-back-loop", "weevee"]
---

## 1. Plan / Context
F05（実測ログにない体験を書かない）は最重要チェック。reviewer はファクトシート + 原稿を見て判定する。画像は 05 が後から機械生成する。

## 2. Do / The Error（2026-08-28 記事 8・第 2 ラウンド）
- `sec-4-terminal.png`（lab.log の「port is already allocated」区間を描画）を「ファクトシートに無いログ文言を実ログと断定 = 証跡の捏造」として F05/F03/C09 で差し戻し。実際はラボの実ログそのもの

## 3. Check / Root Cause
1. **reviewer に画像の出所が渡っていなかった** — 画像の種別（terminal / screenshot-edit / infographic）と元データ（lab.log 行範囲・shots ファイル）は 05 だけが知っていた
2. ファクトシートは実測ログの要約であり、lab.log の全行を含まない。「ファクトシートに無い＝捏造」の推論は画像には成り立たない
3. 差し戻し 1 回で 3 ラウンド上限の 1/3 を消費する（記事 1 が Q06 ループで破棄された前例と同型）

## 4. Act / Prevention Strategy (Fix)
- 05: `manifest.json` の各節に `source`（lab.log L…／shots/NN.png／本文転記）と caption を記録
- 06: 検閲タスクに「画像の出所（05 が機械生成した記録）」節を挿入し、該当種別を F05/C09 の対象にしない（本文/実測ログと矛盾する場合のみ指摘）
- **予防ルール: 検閲者には「成果物がどう作られたか」（出所メタデータ）を渡す。生成経路を知らない検閲者は正しい成果物を捏造と誤判定する**
- 関連: [[reviewer-send-back-loop-on-unfixable-screenshot-item]] [[image-reuse-by-section-index-after-restructure]]
