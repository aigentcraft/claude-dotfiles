---
name: git-bash-msys-path-conversion-mangles-slash-args
title: "Git Bash は `/pass` のようなスラッシュ始まりの引数を `C:/Git/pass` に変換する — cmdkey のテストが 2 回無効になった"
cluster: platform-syntax
type: "silent-failure"
tags: ["git-bash", "msys", "path-conversion", "cmdkey", "windows", "fukugyo-hootl"]
date: 2026-09-19
severity: medium
---

## 症状
Git Bash から `cmdkey /generic:x /user:u@example.com /pass` を実行すると、資格情報は「追加成功」と出るのに
読み戻すと **account が `u@example.com C:/Git/pass`、secret が空**。`/pass` の対話プロンプトも出ない。
「cmdkey が対話入力に対応していない」と誤読しかけた。

## 根本原因
MSYS（Git Bash）は非 MSYS プログラムに渡す引数のうち **`/` で始まるものを Windows パスに変換**する。
`/pass` → `C:/Git/pass`。`/generic:x` や `/user:u` のようにコロンを含むものは変換されないため、
一部の引数だけが化けて**エラーにならずに別の意味**になる。

## 修正
- 検証は **PowerShell かコマンドプロンプト**から実行した（`.ps1` を書いて `powershell.exe -File` で呼ぶ）
- 利用者向けの案内文に「PowerShell かコマンドプロンプトで実行する（Git Bash は /pass をパスに変換する）」を入れた
- Git Bash から呼ばざるを得ない時は `MSYS_NO_PATHCONV=1` を付ける

## 予防ルール
1. **Windows ネイティブの道具（cmdkey / schtasks / reg / netsh 等）は Git Bash から検証しない。** PowerShell か cmd で
2. 「動かない」の原因が道具ではなく**殻（シェル）**である可能性を、最初の 1 回で切り分ける
3. `/` 始まりのスイッチを持つコマンドの案内文には、実行するシェルを明記する
