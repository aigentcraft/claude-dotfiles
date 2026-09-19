---
name: uc-handed-bash-syntax-to-a-powershell-user
title: "利用者のシェルを確かめずに Bash の構文を渡し、1 行目で止めた — 「1こ目のコマンドからエラー出てるけど」"
cluster: uc
type: "user-correction"
tags: ["powershell", "windows", "shell-mismatch", "handoff", "human-in-the-loop", "fukugyo-hootl"]
date: 2026-09-19
severity: medium
---

## ユーザー指摘（原文）
「1こ目のｋまんどからえらーでてるけど」

## 症状
push がフックに拒否された後、対処コマンドを 3 つ提示した。1 つ目が
`FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch ...` で、利用者の PowerShell では
`用語 'FILTER_BRANCH_SQUELCH_WARNING=1' は…認識されません` になり、そこで完全に止まった。
利用者は 3 コマンド分の手間を無駄にし、進捗はゼロ。

## 根本原因
**利用者が使っているシェルを確かめずに渡した。** このプロジェクトのセッションは
PowerShell 7 が既定で、私自身は Bash ツールで作業していた。自分の手元で動く形をそのまま貼った。

`VAR=value command` という前置きは POSIX シェル固有で、PowerShell には無い
（`$env:VAR = 'value'` を別行で書く）。さらに埋め込みの二重引用符も PowerShell の
ネイティブコマンド呼び出しで壊れうるため、**構文を直すだけでは足りない**種類の差だった。

## なぜ悪いか
手渡した手順が動かないと、利用者は「手順が悪いのか自分の環境が悪いのか」を切り分ける作業を
肩代わりさせられる。**AI が実行できない部分を人に頼む時ほど、一発で通る形で渡す必要がある。**

## 修正
- そのタスクは私が実行する形に切り替えた（履歴書き換えではなく、未 push コミットの作り直し）
- 以後、コマンドを渡す時は cmdkey / PowerShell 前提の形にし、
  Git Bash でしか動かないものは「どのシェルで実行するか」を明記した

## 予防ルール
1. **コマンドを人に渡す前に、その人のシェルを確かめる。** Windows のこの環境は PowerShell が既定
2. **POSIX 固有の書き方を渡さない。** 環境変数の前置き・`&&` 連結の癖・`$(...)`・ヒアドキュメント。
   必要なら「Git Bash で実行してください」と実行環境を明記する
3. **複数コマンドを渡す時は、1 つ目が最も壊れやすい前提を含んでいないか見る。**
   止まるなら早いほうがよいが、止まる前提なら渡さないほうがよい
4. そもそも**自分で実行できる作業を人に投げない**。今回は私が実行可能だった
5. 関連: [[git-bash-msys-path-conversion-mangles-slash-args.md]]（逆に Git Bash で
   Windows ネイティブの道具を叩いて壊した例。シェルの取り違えは双方向に起きる）
