---
title: "Stale .pipeline.lock Blocked Restarts for 3 Hours After a Killed Run"
description: "weevee run_pipeline uses an O_EXCL lock file with a 3-hour age-based stale rule. After the send-back batch was killed (taskkill /T), the lock remained with a dead pid and every relaunch exited with '別のパイプラインが実行中'. Fix: read the owner pid from the lock and seize it when the process is not alive (psutil / tasklist on Windows — never os.kill(pid, 0) on Windows, which terminates the process)."
type: "bug"
tags: ["lock", "pipeline", "resume", "windows", "process-lifecycle", "weevee"]
---

## 1. Plan / Context
`run_pipeline` は多重起動防止に `.pipeline.lock`（O_EXCL 作成・pid と開始時刻を JSON で保存）を使い、3 時間より古いロックだけを残骸として奪取する設計だった。

## 2. Do / The Error（2026-08-28）
- 画像再利用バグの修正のためバッチを `taskkill /T /F` で停止 → ロックが残る
- 修正後にバッチを再起動すると全ループが「別のパイプラインが実行中のため終了します（.pipeline.lock）」で即終了（5 回分が 1 秒で空回り）

## 3. Check / Root Cause
1. **残骸判定が「年齢」だけで「所有プロセスの生存」を見ていなかった** — pid を保存しているのに使っていない
2. 異常終了（kill・クラッシュ・電源断）は年齢ゼロのロックを残す。3 時間ルールは「長時間ハング」の対策であって「即死」の対策ではない
3. バッチ側も rc=0 で「done」と報告したため、何も起きていないことに気づきにくい（ログを見て判明）

## 4. Act / Prevention Strategy (Fix)
- `acquire_lock()`: ロックの pid を読み、`_pid_alive(pid)` が偽なら年齢に関わらず奪取（print で明示）
- `_pid_alive`: psutil があれば `pid_exists`、無ければ Windows は `tasklist /FI "PID eq N"`、POSIX は `os.kill(pid, 0)`。**Windows で `os.kill(pid, 0)` は TerminateProcess になるので使わない**
- **予防ルール: ロック/リースの残骸判定は「所有者の生存」を一次条件にし、年齢は二次条件にする**。バッチスクリプトは「実行できなかった」を rc≠0 で表現する
- 関連: [[image-reuse-by-section-index-after-restructure]]
