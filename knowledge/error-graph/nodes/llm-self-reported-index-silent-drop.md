---
title: "llm-self-reported-index-silent-drop"
type: "error"
tags: ["llm", "contract-validation", "pullie", "images", "silent-failure"]
date: "2026-08-13"
---

## 症状（Symptom）

pullie 記事#8が検閲スコア62で破棄。理由の1つが「図解が3見出しで未実装」。
画像生成ログは `generated=4 failed=0` で一見成功しており、原因がどこにも記録されていなかった。

## 根本原因（Root Cause）

- 原稿の図解コメントは3件なのに、designer（LLM）が `index=4` を自己申告
- 生成側はindexを検証せず fig-4.png を生成（コスト浪費・孤児ファイル）
- 記事への置換ループは範囲外indexを **無言でスキップ**（ログなし・失敗カウントなし）
- 結果: 図解コメントが残ったまま検閲へ → 減点 → 破棄。全工程が「成功」を報告していた

## 修正（Fix）

- `validate_figure_indexes()`: 範囲外/重複indexは空きスロットが一意に特定できる場合のみ再割当、
  特定できなければ失敗として記録（warn + failed カウント）。置換ループにも安全弁のwarnを追加

## 予防ルール（Prevention）

- **LLMが自己申告する対応キー（index・ID・ファイル名等）は、消費する前に必ず実在集合と突合する**。
  LLMは1-originを守らない・要素を飛ばす・増やすことがある
- パイプラインの「対応付けループ」で対応先が見つからないケースを無言スキップにしない。
  スキップには必ずログと失敗カウントを付ける（silent capは成功報告に化ける）
- 「generated=N failed=0 なのに成果物が壊れている」時は、生成と消費の間の対応付け層を疑う
