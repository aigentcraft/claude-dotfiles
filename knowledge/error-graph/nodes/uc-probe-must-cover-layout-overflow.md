---
id: uc-probe-must-cover-layout-overflow
title: 長URLのモバイル横はみ出しが検品を素通り —「視覚チェック機能が不十分」（3度目の検品条件カバレッジ指摘）
type: user-correction
severity: high
date: 2026-08-16
project: pullie (Kintone受注目的メディア運営自動化)
cluster: uc
tags: [pullie, visual-inspection, layout, overflow, mobile, verification]
---

# 検品の盲点は「新しく入れた要素の種類」ごとに再点検が要る

## 症状（ユーザー指摘）
「スマホで見たときに⑤認定パートナーのリンクが右に突き出ていてレイアウトが崩れており、
視覚チェック機能が不十分」— 同日追加した出典URL（改行不能な長い英数字列）が375px幅で
71pxはみ出したまま、機械プローブ+LLM視覚検品の両方をpassして承認依頼に到達した。

## 根本原因
1. **機械プローブの検査項目が過去の事故由来のみ**: probe_reader_viewはopacity残留・
   画像欠落・アイキャッチ有無（=8/15の事故の再発防止）だけを見ており、
   横オーバーフローは計測対象外。scrollWidth比較1行で機械検出できる欠陥だった。
2. **新要素の導入時に検品カバレッジを再点検しなかった**: サイトSS機能で「長い生URL」
   という新種のコンテンツを記事に入れた瞬間、既存レイアウトの前提（本文に改行不能な
   長い英数字列は来ない）が崩れた。機能追加＝検品の前提破壊の可能性。
3. CSS側の一次原因: 記事本文のa/emに折り返し指定がなく、長URLが右へ突き出た
   （overflow-wrap:anywhere で解消）。

## 修正（2026-08-16・実走検証済み）
- probe_reader_viewに横はみ出し検査（scrollWidth-innerWidth>8pxでfail+犯人要素特定）。
  **壊れた実プレビューに対して71px・犯人URLの検出を確認してからCSSを直した**
  （検出器は必ず実欠陥で較正する）
- 記事テンプレのa/emにoverflow-wrap:anywhere → 再デプロイ後 overflow 0px を実測
- 併発修正: 09_notify承認リマインドのプレビューURLが旧ドメイン（draft.pullie-site→404）
  のままだった（8/6のPages移行の消費者側更新漏れ — PCだけ404の正体）

## 予防ルール（一般化）
- **記事に新種のコンテンツ要素を入れる機能（スクショ・URL・表・埋め込み等）を追加したら、
  検品プローブに「その要素が壊しうるレイアウト検査」を同じコミットで足す**。
  検品は過去の事故の集積であり、新機能は必ず検品の空白地帯に着地する。
- [[uc-inspection-must-match-reader-conditions.md]]（条件カバレッジ）
  [[image-dark-canvas-margin-passes-vision-review.md]]（本体と地の分離検査）に続く3例目。
  共通則: **決定論で測れるものはLLMの目視に残さない**（はみ出しはscrollWidth 1行）。
- インフラ移行（ドメイン・プロジェクト名変更）時は旧名の全文grepを移行チェックリストに
  入れる（09のPREVIEW_BASEは8/6から10日間壊れたリンクを案内し続けた）。
