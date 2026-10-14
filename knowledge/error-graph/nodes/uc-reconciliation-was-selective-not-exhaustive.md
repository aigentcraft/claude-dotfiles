---
title: "uc-reconciliation-was-selective-not-exhaustive"
type: "user-correction"
tags: ["uc", "planning", "manual-reconciliation", "spreadsheet", "royal-cloak"]
date: "2026-10-11"
relationships:
  related_to:
    - "uc-automation-plan-skipped-data-level-verification.md"
    - "uc-mixed-system-gaps-with-procedure-gaps.md"
---

## ユーザーの指摘（原文）

「怖いな。各マニュアルもう一回網羅的に読んでチェックして。」
（2026-10-11・マニュアルと計画の照合表を出し、漏れが6件見つかった直後）

## 症状

- マニュアルとの照合表を、目についた行だけ拾って作った（全行を対象にしていなかった）
- 手順の版を作り直すたびに、前の版にあった項目（「違う金額で契約してしまった → すぐSlack」）を落とした
- 自分の推測（アポ被りに当たった人 → 【5】）を「確定」と表示した
- セルの本文だけを読み、メモ・入力規則・リンク先を読んでいなかった。
  そのため、I列の「△（同じジャンル3日以内）」、M列の「対応済」、P列の投稿日の手入力ルールを見落とした

## 根本原因

- get_values（本文だけ）で読んで「全部読んだ」と判断した
- 照合を行単位・行番号つきで網羅せず、要約から突き合わせた
- 版の差分を取らずに書き直した
- 出典（マニュアル／テンプレ／ユーザーの決定／自分の推測）を区別しなかった

## 予防ルール（一般化）

- マニュアル照合は、全行に行番号を振って1行ずつ「反映済み／漏れ／食い違い／対象外」を付ける
- スプレッドシートは get_spreadsheet の fields に note・dataValidation・chipRuns・hyperlink・comments を含めて読む。リンク先の文書も読む
- 手順を作り直すときは、前の版との差分を確認してから出す
- 推測は「確定」にしない。出典のない項目は「提案」と表示する
