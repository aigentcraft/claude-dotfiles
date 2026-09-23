---
title: "planner-promised-trial-the-lab-cannot-run"
type: "bug"
tags: ["planning", "measurement", "notification", "observability", "missing-material", "weevee"]
date: "2026-09-23"
---

## 1. Plan / Context
速報レーン（`tools/breaking.py`）は、公式発表のアラートから企画担当（seo-strategist）に企画させ、取材 → 執筆 → 検閲へ流す。
取材担当はラボ（Windows・ブラウザ/ターミナル/Docker）で試せる範囲を自分で判断し、録画するかも自分で決める。
取材後に録画の物理検査をし、使える録画が 0 本なら Discord ops に「録画なし（実測ラボ）」を送っていた（docs/15）。

## 2. Do / The Error
人間が Discord の「録画なし（実測ラボ）」を貼ってきた（記事 34「Claude Code/CoworkのPC自動操作機能、使い方と実際に試した結果」）。
- 通知は正しい事実だったが、**取材 15 回中 13 回鳴っていて、次の一手が一度も書かれていなかった**
- 追うと本当の問題は企画側: 機能（バックグラウンドの Computer use）は **macOS 専用**、ラボは **Windows でブラウザしか動かせない**のに、
  企画は「macOS が揃えば試す」の条件付き実測を書きながら**題で「実際に試した結果」を約束**していた
- さらに企画書は「環境が揃わない場合は『今回は環境の都合で実機検証ができなかった』と明記」— 同日禁止した「調べ方の報告」を執筆担当に指示していた

## 3. Check / Root Cause
1. 企画担当へのブリーフの冒頭が「**本日中に公開する実測つき速報記事**を 1 本企画」のまま（同日「公式に載っていれば実測しない」に変えたのは本文の条件だけ）
2. 企画担当は**ラボが何を動かせるかを知らない**（材料が渡っていない）
3. 公開面の決まり（`PUBLIC_SURFACE_CONTRACT`）は執筆・検閲には渡したが**企画には渡していなかった**
4. 「録画 0 本」は取材担当の判断の結果で、故障ではない。docs/15 は「③物理」に分類して通知していたが、物理の故障は
   「撮ったのに使えない」の方だった

## 4. Act / Prevention Strategy (Fix)
- 企画ブリーフを純関数 `breaking.planner_task()` に切り出し、「実測つき」を外す。`lab.planning_capability_note()`
  （この PC で試せるもの／試せないもの: デスクトップアプリの画面操作・他 OS 専用機能・新たな課金）と `PUBLIC_SURFACE_CONTRACT` を渡す
- 通知は `03_research.broken_recordings_notice()`: **撮った録画がすべて物理検査で落ちたときだけ**、理由と「直すのはコード側・あなたの操作は不要」を付けて送る。
  0 本は `lab.recordings` イベントと実行ログに残すだけ
- 結果: 執筆担当は自分で題を「Claude Computer Use新機能｜使い方と対応プラン」に直していた（材料と決まりがあれば役は正しく判断する）
- **予防ルール: 役に約束させる前に、その約束を果たせるかの材料（道具・環境の限界）を渡す。題の約束は取材の実力の範囲で**
- **予防ルール: 通知は「誰かが次に何かをする」ときだけ送る。数えた事実の報告は記録に残し、鳴る頻度を実データで数えてから通知にする**
- 関連: [[public-surface-check-skipped-rendered-frontmatter]] [[uc-do-not-measure-what-is-officially-published]]
  [[uc-alert-in-internal-words-with-no-next-step]] [[uc-comparison-article-without-real-measurement]]
