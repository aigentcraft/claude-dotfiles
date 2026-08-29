---
title: "claude-bash-heredoc-backslash-escape-halved"
type: "error"
tags: ["claude-code", "bash-tool", "heredoc", "python", "escaping", "windows", "weevee"]
date: "2026-08-30"
---

## 症状（Symptom）

Claude Code の Bash ツールから `python - <<'EOF' … EOF` で Python スクリプトを流し、その中で `'notify.discord(verdict + "\n" + "\n".join(lines))'` のように **文字列リテラル `"\n"` を書き込む**コードを生成したところ、書き込まれたファイルでは `"` の直後に**実改行**が入り `SyntaxError: unterminated string literal` になった。同じセッションで 2 回（gsccli.py / 01_collect_signals.py）再発。

## 根本原因（Root Cause）

ツール経由のコマンド文字列は、クォート付きヒアドキュメント（`<<'EOF'`）でもバックスラッシュが 1 段解釈され `\n` → `\n` になる。Python はそれを改行エスケープとして評価し、**書き込むソースコードの中に実改行が入る**。エディタで直接書く時と挙動が違うため、目視では気づけない。

## 修正（Fix）

- ソースコードを生成するスクリプト内で改行を表す時はバックスラッシュを使わず `chr(10)` を使う（`verdict + chr(10) + chr(10).join(lines)`）
- 書き込み直後に必ず `python -c "import ast; ast.parse(open(f).read())"` で構文検査する（今回それで検知できた）

## 予防ルール（Prevention）

1. **Bash ツールのヒアドキュメント経由でコードを書く時、バックスラッシュ・エスケープ（`\n` `\t` `\`）を含む文字列は書かない**。必要なら `chr(10)` / raw 文字列 / 別ファイルから読む
2. ファイル生成後の構文検査（`ast.parse` / `node --check`）を出口条件にする
3. 関連: [[windows-subprocess-cp932-decode-crash]]（同じく Windows + Claude ツール経路でのエンコード事故）
