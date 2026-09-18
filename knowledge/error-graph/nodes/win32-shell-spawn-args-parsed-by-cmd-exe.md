---
name: win32-shell-spawn-args-parsed-by-cmd-exe
title: "Windows で spawn(shell:true) の引数は cmd.exe が解釈する — `()=>{}` が `{}` ファイルを作り、テスト自体も無効になった"
cluster: platform-syntax
type: "silent-failure"
tags: ["windows", "node", "child_process", "cmd.exe", "shell", "taskkill", "npm-shim", "fukugyo-hootl"]
date: 2026-09-19
severity: high
---

## 症状
Node の `spawn('node', ['-e', 'setTimeout(()=>{},60000)'], { shell: true })` を Windows で実行したら、
- プロジェクト直下に **`{}` という 0 バイトのファイル**が出来た（`git status` に `?? {}` が現れて発覚）
- 子プロセスは即終了し、「孫プロセスが生き残るか」を測るテストが**何も測れないまま「children=[]」**を返した

## 根本原因
`shell: true` は Windows では `cmd.exe /d /s /c "<command line>"` になる。引数は **cmd.exe が再解釈**するので
`()=>{}` の `>` が**出力リダイレクト**、`{}` がその出力先ファイル名になった。`&` `|` `^` `<` も同様に効く。
Node の `spawn` の引数配列は「そのまま渡る」という POSIX の感覚が Windows + shell では成り立たない。

前提として shell が要る理由: npm グローバルの `claude` の実体は `claude.cmd`（npm シム）で、
`spawn('claude')` は `.exe/.com` しか探さず **ENOENT**（実測）。Node 20.12 以降は `.cmd` を shell 無しで
起動すると EINVAL で弾かれる。だから cmd.exe を通すしかなく、引数の再解釈が付いてくる。

## 修正
- 引数は**定数だけ**（`-p` / `--model` / モデル名）にし、本文はすべて **stdin** で渡す。コードのコメントに固定した
- テストは引数にコードを載せず、スクリプトファイルを渡す形に変えた
- タイムアウト時の停止は `taskkill /PID <shell pid> /T /F`。`child.kill('SIGKILL')` は cmd.exe しか殺さず
  孫（node / claude.exe）が生き残る（PID を追跡して実測: child.kill → 生存 yes、taskkill /T → 生存 no）

## 予防ルール
1. **`shell: true` で渡す引数にメタ文字（`> < | & ^`）や利用者由来の文字列を入れない。** 本文は stdin
2. shell 経由の子プロセスを止める時は **`taskkill /T`** でツリーごと落とす（macOS の SIGKILL と分岐する）
3. 「テストが通った／空だった」は「測れた」ではない。**cwd に見覚えの無いファイルが出来ていないか**を見る
4. 関連: [[windows-claude-cli-subprocess-needs-cmd-and-gitbash.md]]（Python 側の同じ穴）。
   claude CLI は環境によって `CLAUDE_CODE_GIT_BASH_PATH` を要求する。対話セッションからの起動では通ったが、
   タスクスケジューラなど別環境で動かす時は再実測する
