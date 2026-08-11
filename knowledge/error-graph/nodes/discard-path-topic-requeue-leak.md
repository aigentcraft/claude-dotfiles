---
id: discard-path-topic-requeue-leak
title: 記事破棄の複数経路のうち一部だけが企画キュー返却を行い、topicが孤立した
type: failure
severity: medium
date: 2026-08-11
project: pullie (Kintone受注目的メディア運営自動化)
cluster: pipeline-idempotency
tags: [pipeline, state-machine, cleanup, sqlite]
---

# 破棄経路ごとに後始末が非対称で、企画（topic）が'selected'のまま孤立

## 症状
記事#5がスコア床（66<70）で破棄された後、対応するtopicが'selected'のまま残り、
以後の企画選定から永久に漏れる状態になった（通知文は「企画は再検討リストに戻ります」と
主張するが、実際には戻していなかった）。

## 根本原因
記事破棄に3経路（①リサーチ3日停滞 ②検閲ラウンド超過 ③検閲スコア床）があり、
topicの'planned'返却が①にしか実装されていなかった。②の先行事例(#6)は手動修復で
発覚が遅れた。破棄という「同じ結果」に至る経路が増えるたび、後始末が個別実装で分散した。

## 修正
run_pipelineの記事処理末尾に「status='rejected'ならtopicを'planned'へ戻す」共通処理を追加
（経路に依存しない事後条件として実装）。孤立していたtopic 3は手動でplannedへ修復。

## 予防ルール
**状態遷移の「後始末」は遷移を起こした経路ごとに書かず、結果状態に対する共通の事後処理として
1箇所に書く**（どの経路で rejected になっても topic は必ず planned に戻る、という不変条件で守る）。
通知文が主張する副作用（「〜に戻します」）は、その通知を送るコードの近くで実際に起きているか確認する。
