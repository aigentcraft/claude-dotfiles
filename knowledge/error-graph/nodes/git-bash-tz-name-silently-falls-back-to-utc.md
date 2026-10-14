---
name: git-bash-tz-name-silently-falls-back-to-utc
title: Git Bash で TZ=Asia/Tokyo と書くと、何も言わずに世界標準時（9時間前）になる
cluster: platform-syntax
type: "technical-error"
tags: ["git-bash", "windows", "timezone", "jst", "utc", "silent-failure", "royal-cloak"]
date: 2026-10-12
severity: medium
relationships:
  related_to:
    - "utc-timestamps-render-as-last-night.md"
---

## 症状
状態ボードに書く時刻を取るため、Git Bash で `TZ=Asia/Tokyo date '+%Y-%m-%d %H:%M'` を実行したら `08:09` が返った。
実際の日本時間は 17:09。エラーも警告も出ない。

## 根本原因
Git Bash（MSYS2）には地域名のタイムゾーン情報（zoneinfo）が無い。知らない TZ 名は**黙って UTC 扱い**になる。

## 確かめ方（4通りを並べる）
```bash
date '+%H:%M %Z'                 # 現地時刻（Windows の設定 = 東京）
date -u '+%H:%M'                 # UTC
TZ=JST-9 date '+%H:%M'           # POSIX 形式なら地域情報が無くても効く
powershell.exe -NoProfile -Command "Get-Date -Format 'HH:mm K'"
```

## 修正
日本時間は `TZ=JST-9`（POSIX 形式）か、PC の現地時刻で取る。Node なら
`new Date().toLocaleString('sv-SE', { timeZone: 'Asia/Tokyo' })`（ICU が内蔵のため OS に依存しない）。

## 予防ルール
- Git Bash で地域名の TZ（Asia/Tokyo など）を使わない。時刻を記録に書く前に、現地時刻と並べて1回確かめる
- 書き込み先（スプレッドシート等）のタイムゾーン設定も別に確かめる（今回の状態ボードは Asia/Tokyo で正しかった）
