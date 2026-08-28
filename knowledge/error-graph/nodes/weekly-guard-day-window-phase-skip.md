---
title: "週1ガードを日数窓で実装すると定時スロットと位相ズレしてスキップする"
type: "technical-error"
tags: ["scheduling", "cadence", "guard", "idempotency", "false-alarm", "pullie"]
description: "「直近6日以内に実行済みならスキップ」の週1ガードは、週の途中で一度走ると翌月曜の定時スロットを弾き、次実行まで9日空く。ops-auditorが3監査連続で「実行痕跡なし」をwatch報告する誤警報も誘発した。週次の冪等はカレンダー週（ISO週）で切る。"
---

## 1. Plan / Context
pullie 製品課の週次リサーチ（product/00_research）は run_pipeline の月曜朝ブロックから
呼ばれ、二重実行防止に「直近6日以内に product.researched があればスキップ」の
日数窓ガードを持っていた。

## 2. Do / The Error
- 2026-08-22（土）にレーン新設の初回実行 → 8/24（月）の定時スロットでガードが発動しスキップ
  → 次の自然実行は8/31（月）＝**9日間の空白**
- ops-auditor が「product.researched の実行痕跡が確認できない」を3監査連続で watch 報告
  （さらに監査自身も「月曜=8/25」と曜日を誤認しており、人間が「またエラー通知」と反応）

## 3. Check / Root Cause
週次ジョブの冪等単位は「実行から7日」ではなく「カレンダー週」。日数窓は初回実行や
手動実行が週の途中に入った瞬間、定時スロット（月曜）と位相がズレる。
producer-consumer-sync R3（観測周期と窓の交差）と同族の時間軸バグ。

## 4. Act / Prevention Strategy (Fix)
- 修正: ガードを「最終実行のISO週 == 現在のISO週」判定に変更
  （SQLite `strftime('%Y-%W', created_at, 'localtime')` vs Python `now().strftime('%Y-%W')`
  — 保存時刻はUTCのため 'localtime' 変換を忘れない）
- スキップされた当週分は手動実行で回収（3企画提案を登録）
- **予防ルール**: 周期ジョブの二重実行ガードは**周期の暦単位**（日=date/週=ISO週/月=年月）で
  切る。「直近N時間/日」窓は定時スロットとの位相ズレを起こす（同種の既存実装も
  見つけたら同じ単位に揃える）
