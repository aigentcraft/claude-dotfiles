---
title: "CRLF のシェルスクリプトが全 Bash 実行を止めた"
description: "Windows 側から同期された *.sh が CRLF になり、行継続の \\ の直後の \\r で bash が構文エラー。PreToolUse フックが壊れて Claude Code から 1 コマンドも実行できなくなった。"
type: "technical-error"
tags: ["shell", "line-endings", "cross-platform", "hooks", "claude-code", "windows-mac"]
relationships:
  caused_by: []
  related_to: ["swallowed-error-logged-as-success"]
  fixes_node: []
---

## 1. Plan / Context
Windows（Antigravity）と Mac の 2 台で同じ dotfiles リポジトリを共有している。
Claude Code の `PreToolUse` フックに、push 前の PDCA 検証スクリプトを噛ませてある。

## 2. Do / The Error
Mac 側で最新を取り込んだ直後から、**あらゆる Bash 実行が即座に失敗**するようになった。

```
PreToolUse:Bash hook error: pre-bash-git-push.sh: line 4: : command not found
  command substitution: line 10: syntax error near unexpected token `||'
  line 76: syntax error: unexpected end of file
```

PreToolUse フックは全 Bash 呼び出しに掛かるため、**1 コマンドも実行できない**。
自分自身を直すためのコマンドすら打てなくなる。

## 3. Check / Root Cause
ファイルを読むと構文は正常に見えた。手がかりは **エラーの行番号が実ファイルと 3 行ずれていた**こと。
「読めば正しいのに bash だけが失敗する」＝ 見えない文字の問題。

正体は改行コード。Windows から同期された `*.sh` が CRLF だった。

```bash
... 2>/dev/null \<CR><LF>
  || echo ...
```

bash は `\` が直後の **CR** をエスケープしたと解釈し、そこで行が終わったことにする。
結果、次行頭の `||` が構文エラーになる。

## 4. Act / Fix & Prevention

6 ファイルを LF に変換し、リポジトリ側で改行を固定した。

```gitattributes
*.sh text eol=lf
```

### 予防ルール

1. **複数 OS で共有するリポジトリは `.gitattributes` で `*.sh text eol=lf` を必ず置く。**
   「今は動いている」は、片方の OS でしか編集していないだけのことがある。
2. **フックを噛ませる時は「そのフックが壊れた時に復旧できるか」を考える。**
   全ツール呼び出しに掛かるフックが壊れると、復旧手段そのものを失う。
   ファイル編集系のツールなど、シェルを経由しない復旧経路を残しておく。
3. **「読むと正しいのに実行だけ失敗する」時は不可視文字を疑う。**
   行番号のズレは有力な手がかり。`file` コマンドで CRLF を確認できる。
