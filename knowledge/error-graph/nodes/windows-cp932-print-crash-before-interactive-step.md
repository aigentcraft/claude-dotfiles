---
title: "windows-cp932-print-crash-before-interactive-step"
type: "error"
tags: ["windows", "encoding", "cp932", "print", "interactive-tool", "weevee"]
date: "2026-09-02"
---

## 症状（Symptom）

`python tools/x_login_setup.py`（人間がブラウザ窓でログインするツール）が、窓を開く**前**の案内 print で
`UnicodeEncodeError: 'cp932' codec can't encode character '—'` を出して落ちた（rc=1・人間は何も見ていない）。
同日、`tools/envclip.py` も完了メッセージの「—」で同じ落ち方をした（こちらは書き込み後だったので実害なし）。

## 根本原因（Root Cause）

- Windows のコンソール既定エンコーディングが cp932。全角ダッシュ「—」(U+2014) など cp932 に無い文字を
  `print` すると例外になる（subprocess 経由で PYTHONUTF8 が無いときに顕在化）
- 参照プロジェクトの教訓（[[windows-subprocess-cp932-decode-crash]]）は「子プロセスの出力の decode」側だったが、
  今回は自分の print の encode 側 — 同じ根で別の面

## 修正（Fix）

- 両ツールの main 冒頭に `sys.stdout.reconfigure(encoding="utf-8")`（try/except で囲む）。envclip は「—」を "-" に置換も
- ヘッドレス実行が前提の scheduler スクリプト（publish-batch.sh 等）は `export PYTHONUTF8=1` 済み — CLI ツールにも同じ保険を入れる

## 予防ルール（Prevention）

1. **人間操作を伴う CLI は「案内 print → 操作開始」の順なので、print が落ちると操作に到達しない**。CLI の main 冒頭で
   stdout を utf-8 に reconfigure する（プロジェクトの新規 CLI テンプレに含める）
2. 全角ダッシュ・絵文字を print に使うなら reconfigure が前提。無いなら ASCII に寄せる
3. 関連: [[windows-subprocess-cp932-decode-crash]] [[xmcp-venv-python-exe-lookup-windows]]
