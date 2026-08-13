---
title: "windows-wsl-sqlite-transient-open-failure"
type: "error"
tags: ["sqlite", "wsl", "windows", "wal", "file-lock", "pullie"]
date: "2026-08-13"
---

## 症状（Symptom）

pullie のWSL側手動run終盤（正午前後の約20分間）、5つのワーカーが連鎖して
`sqlite3.OperationalError: unable to open database file` で失敗（08_sns_post / 04_inbox /
02a / 09_notify / gen_org_status）。前後の時間帯は同じDBに正常接続できる。

## 根本原因（Root Cause）

- db/media.db は /mnt/c（NTFS）上にあり、**WindowsネイティブプロセスとWSLプロセスの両方が触る**
- WAL の -wal/-shm ファイルをWindows側プロセス（定時起動のPython・インデクサ/AV等）が
  一時的に排他ロックすると、WSL側の新規接続が「unable to open database file」で落ちる
- 加えて run_pipeline は**ロック確認より先に db.connect() していた**ため、ロック退出するだけの
  定時起動プロセスまでDBに触っていた（クロス環境アクセスの発生源を1つ増やしていた）

## 修正（Fix）

- run_pipeline: `acquire_lock()` を `db.connect()` より先に移動（ロック退出プロセスはsqlite非接触）
  + 取得後〜tryブロック到達前の例外でロックを漏らさない except-release-reraise を追加
- db.connect(): 「unable to open database file」に限定した有界リトライ
  - **追記（同日2回目の実走で15秒リトライが突破された）**: ロック窓は数分規模。
    5/10/20/40/60秒の計135秒へ延長
  - パターン: **大量書き込みフェーズ（執筆・検閲のLLMコスト/リフレクション書込）の直後**に発生
    → Windows常駐スキャナ（Defender/インデクサ）が書込後の -wal を掴む説が最有力
  - 根治はWindows Defenderの除外設定にプロジェクトフォルダを追加（ユーザー操作）

## 予防ルール（Prevention）

- NTFS上のSQLiteをWindows/WSL両方から使う構成では、**一過性のopen失敗を正常系として設計する**
  （接続の有界リトライ + 非クリティカル段の翌run自己修復）
- 「ロックを見て即退出する」プロセスは、退出判断より前に共有リソース（DB等）へ接続しない
- 手動runは定時起動の時間帯（05:00/12:00 JST前後）を避ける
