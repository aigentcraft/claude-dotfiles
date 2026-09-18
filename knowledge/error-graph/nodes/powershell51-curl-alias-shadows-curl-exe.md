---
name: powershell51-curl-alias-shadows-curl-exe
title: "Windows PowerShell 5.1 では `curl` が Invoke-WebRequest の別名 — `& curl --version` がリモート名解決エラーになる"
cluster: platform-syntax
type: "error"
tags: ["powershell", "curl", "alias", "windows", "fukugyo-hootl"]
date: 2026-09-19
severity: low
---

## 症状
環境診断の `.ps1` が `foreach ($t in @('node','npm','git','curl')) { & $t --version }` で
`Invoke-WebRequest : リモート名を解決できませんでした。: '--version'` を出して止まった。
同じスクリプトは **pwsh 7 では通っていた**（pwsh には別名が無い）。
皮肉なことに、そのスクリプトのコメントには「PowerShell の curl は別名なので不可」と書いてあった。

## 根本原因
Windows PowerShell 5.1 は `curl` と `wget` を `Invoke-WebRequest` の別名として定義している。
`& 'curl'` でも別名が解決される。`Get-Command curl` も別名を返す。

## 修正
スクリプト内では **`curl.exe`** と拡張子付きで書く（`Get-Command curl.exe` / `& curl.exe --version`）。

## 予防ルール
1. `.ps1` から外部コマンドを呼ぶ時は **`.exe` を付ける**（curl / wget / where / sc など別名や組み込みと衝突するもの）
2. 「pwsh 7 で通った」は「Windows PowerShell 5.1 で通る」を意味しない。**両方で実行**する（5.1 は BOM の有無にも敏感）
