---
title: "Task Time Limit Killed the Run — and the Alarm That Would Have Reported It"
description: "pullie の朝パイプラインが Windows Task Scheduler の ExecutionTimeLimit=PT2H で強制終了され、記事以降の工程（X課・note・知識キュレーション・運用監査・集約通知・ダッシュボード再生成）が丸ごとスキップされていた。プロセスが即死するため finally もログも走らず、**通知役の09_notify自身が道連れになるので『エラー通知が来ないこと』が唯一の症状**。2026-08-31 / 09-02 / 09-03 / 09-06 の4日発生し、4日間誰も気づかなかった（人間が『今日は不合格で終わったみたいだけど問題ない？』と聞いたことで発覚）。判定材料はDBに最初からあった — `run開始` の後に `run完了` が無い、それだけ。"
type: "technical-error"
tags: ["observability", "monitoring", "system-design", "pullie", "silent-failure", "task-scheduler", "windows", "watchdog"]
---

## 1. Plan / Context
pullie の日次パイプラインは Windows Task Scheduler（`pullie-daily`・05:00/12:00）が
`run-pipeline.ps1` を起動し、記事レーン→X課→note→L4→集約通知→ダッシュボード再生成まで
1プロセスで直列に走る。異常は `09_notify` がDiscordへ通知する設計。

## 2. Do / The Error（発覚 2026-09-06・人間の問い「今日は不合格で終わったみたいだけど問題ない？」）
記事が破棄されたこと自体を調べていて、別の異常に気づいた。

- `pullie-daily` の `LastTaskResult` が **267014 (0x41306) = SCHED_S_TASK_TERMINATED**
- `ExecutionTimeLimit` が **PT2H**。05:00開始 → **07:00 に強制終了**
- ログには `pipeline start` はあるが **`pipeline exit` 行が無い**（ラッパーのAdd-Contentまで到達していない）
- その日の `x.*` イベントは **0件**。`ops.audited` も未実行。09_notifyもダッシュボード再生成も未実行

過去ログを機械的に調べると、**今日が初めてではなかった**:

| 日 | 朝runの所要 |
|---|---|
| 08-26 / 27 / 28 | 114分 / 111分 / 107分（上限まで残り6〜13分） |
| **08-31 / 09-02 / 09-03 / 09-06** | **強制終了**（exit行なし） |

**4日間、誰も気づいていない。** そして 09-02・09-03 は「review.passed が64時間停止」を
調査していた期間そのもので、その調査でも見落とされていた。

## 3. Check / Root Cause
1. **障害が自分の警報装置を道連れにする。** プロセスが即死する終わり方では `finally` も
   ログ出力も走らない。通知役（09_notify）は同じプロセスの後段にいるので一緒に消える。
   結果、**「エラー通知が来ないこと」が唯一の症状**になり、静観と区別がつかない
2. **エラーが1件も出ない。** warn/error集約にもイベント地図にも何も現れないので、
   ops-auditor の材料からも見えない。「異常の不在」を異常として検出する経路が無かった
3. **上限に対する余裕を誰も測っていなかった。** 107〜114分の日が常態で、上限120分に対して
   残り6〜13分。記事の書き直しが1ラウンド増えれば必ず超える構造だった
4. **判定材料は最初からDBにあった。** `run開始` / `run完了` は既にログされていた。
   **足りなかったのは観測者であって、データではない**

## 4. Act / Prevention Strategy (Fix)
- **`ExecutionTimeLimit` を PT2H → PT4H**（登録タスクと `scheduler/pullie-daily-task.xml` の両方。
  12:00runの前に必ず終わる範囲に収める。`MultipleInstances=IgnoreNew` なので重複は起きない）
  - 副産物: XMLの `<Exec>` が `wsl.exe` 起動のまま陳腐化していた（2026-08-07にpwshへ移行時の
    同期漏れ）。**このXMLは再登録の正本なので、そのまま使うとパイプラインが起動しない罠**だった
- **`check_previous_run()` を run_pipeline 起動時に新設**: 自分の `run開始` を書く前に、
  直近の記録が `run完了` でなければ「前回runは完走していない」と判定し、
  ops へ通知 + `pipeline.aborted` イベントを発行する。**次のrunが前回の墓標を立てる**
- **ops_audit の材料に「パイプラインの完走状況（直近8日・開始 vs 完了）」を追加**。
  開始>完了の日が一目で分かる

**予防ルール（横展開可能な一般形）**
1. **警報装置が本体と同じプロセス／同じ寿命にいると、本体の即死は警報も殺す。**
   監視は必ず**別の寿命**に置く。最小実装は「次回起動時に前回の完走を検査する」— 常駐監視より安く確実
2. **「異常の不在」を異常として検出する経路を用意する。** エラーログが出ない障害は実在し、
   静かな方が危険。開始と完了の対応、ハートビート、前回完走フラグのいずれかを必ず持つ
3. **時間・容量の上限は、実測の分布と一緒に見る。** 上限120分に対し常態が107〜114分なら
   それは「動いている」ではなく「いつ落ちてもおかしくない」。余裕率を定期的に測る
4. **再登録用の設定ファイル（タスクXML・IaC）は、実体を変えたら同じコミットで同期する。**
   陳腐化した正本は、いざ復旧する時に静かに牙をむく

## 5. Related
- [[nodes/aggregate-material-collapses-distribution.md]] — 同じ「材料が足りず観測者がいない」系列
- [[nodes/underpowered-verdicts-become-doctrine.md]] — データはあるのに読む主体がいない構図
- [[nodes/uc-mechanical-notifications-lack-situation.md]] — 同日の人間指摘（通知の質）
