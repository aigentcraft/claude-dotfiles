---
title: "windows-subprocess-cp932-decode-crash"
type: "error"
tags: ["windows", "python", "subprocess", "encoding", "cp932", "utf8"]
date: "2026-08-09"
---

## 症状（Symptom）

パイプラインの書き直しrunが `UnicodeDecodeError: 'cp932' codec can't decode byte ...`（subprocess.py の _readerthread 内）を大量に出した。npm build や codex exec などUTF-8を出力する子プロセスのcapture時に発生。

## 根本原因（Root Cause）

- Windows の Python は `subprocess.run(text=True)` のデコードに**ロケール既定のcp932**を使う。`encoding=` 未指定のcapture箇所すべてが地雷
- `-X utf8` を付けた手動実行では再現せず、スケジューラ/ワーカー経由（フラグなし）でのみ発火するため、テストをすり抜けた

## 修正（Fix）

1. capture系 `subprocess.run` 全箇所に `encoding="utf-8", errors="replace"` を明示（run_pipeline / 06b / 07 / imagegen_client）
2. 起動ラッパー（run-pipeline.ps1 / run-approvals.ps1）で `$env:PYTHONUTF8="1"` を設定（子孫全プロセスに伝播する保険）

## 予防ルール（Prevention）

1. **Windowsで動かすPythonの `text=True` capture には必ず `encoding="utf-8"` を書く**（書かないコードはWindowsに持ち込んだ瞬間に地雷化する）
2. エントリポイントのラッパーで `PYTHONUTF8=1` を立てるのを標準にする
3. 「手動では動くがスケジューラで死ぬ」時は、フラグ・環境変数の差分（-X utf8 / PATH / PYTHONUTF8）をまず疑う
