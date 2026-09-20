---
name: review-step-crashed-six-days-on-a-wrong-column-name
title: 検閲ステップが存在しない列名で 6 日間毎 run 落ち、traceback はどこにも残らず、通知は「介入が必要」を出すだけだった
cluster: observability
type: "error"
tags: ["sqlite", "column-name", "silent-crash", "stderr", "task-scheduler", "fake-schema-test", "weevee"]
date: 2026-09-20
severity: critical
---

## 症状
2026-09-14 の変更以降、記事の検閲（06_review）が LLM の応答を受け取った直後に毎回落ちた（記事 25 → 27/28・9/17〜9/20 で 10 回）。
reviewer のセッションは毎回 8〜10 分走って正常な JSON を返していたのに、その結果は 1 行も保存されず、完成記事 0 本が 6 日続いた。
人間には Discord の「🚨 介入が必要です: 記事の検閲（06_review.py）」と、毎朝 3 回の「検閲担当の作業が終わっていません」だけが届いた。

## 根本原因
1. `cta_zero_event()` が `workflow_events WHERE event_type=…` を引いていた。列は `event`。1 文字の誤りで `OperationalError`
2. **本番の起動役（Task Scheduler が python を直接叩く）では子プロセスの stderr がどこにも残らない**。`run_step` は
   `subprocess.run` を素で呼び、失敗時に「失敗」とだけ記録していた。traceback は 6 日間で 1 行も残らなかった
3. その関数のテストは無く、同じ日に入れた隣の関数（04 側）のテストは本番 schema で通していたが、06 側は検査していなかった。
   独立診断（9/12）の「手書き CREATE TABLE のテストを本番 schema に」の残りがここに刺さった

## 修正
- 列名を `event` に（同型は grep で 1 箇所のみ）。本番 schema（conftest.real_db）で `cta_zero_event` を検査 — 旧コードでは OperationalError で赤
- `run_step` が子の stderr を取り、失敗時は末尾 4,000 字を `execution_logs.detail` に残す（手動実行では画面にも出す）
- 保存済みの reviewer 出力 + DB のコピーで LLM 後の処理を再現するスクリプトで原因を特定（LLM を回し直さず 1 分で再現）

## 予防ルール
- **失敗の記録には原因の断片（stderr の末尾）を必ず添える。**「失敗」だけの記録は 6 日間の空回りを許す
- **DB を引く関数は本番 schema のテストを 1 つ持つ。**列名は IDE も LLM も補完しない（`event` / `event_type` / `entity_type` が同じ表に並ぶ）
- LLM の後段が落ちたら、**保存済みの生応答で後段だけを再現する**（LLM を回し直すと 10 分 × 回数の待ちになる）

## 関連
- [[verification-tool-that-cannot-fail]] — テストが本番と別の schema で通る型
- [[feedback-with-no-address-never-arrives]] — 記録はあるのに読める形で届かない同型
- [[uc-explained-by-filename-not-by-role]] — この障害の通知を人が読み飛ばした背景（識別子だらけの通知）
