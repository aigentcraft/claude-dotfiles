# Cluster: プラットフォーム固有の構文エラー

> Layer 1 Community Summary — 関連ノードの蒸留サマリー。
> PowerShell / Windows 環境での CLI ツール呼び出し時にロードする。

**対象タグ**: `powershell`, `git`, `syntax-error`, `windows`, `cli`

---

## 蒸留ルール（Distilled Rules）

### R1: PowerShell 特殊文字 — 外部CLI引数は必ずクォート
PowerShell は `@{...}`, `$var`, `(expr)` 等を自動的にPS構文として解釈しようとする。
- **対策**: PowerShell から git / docker / npm 等を呼ぶとき、特殊文字を含む引数は必ずダブルクォートで囲む
- **対象文字**: `@`, `{`, `}`, `$`, `(`, `)`
- **例**:
  - ❌ `git rev-parse @{u}`
  - ✅ `git rev-parse "@{u}"`
- 詳細: [[../nodes/powershell-hash-literal-git.md]]

---

## クイック参照テーブル

| 状況 | 適用するルール |
|---|---|
| PowerShell (.ps1) で git コマンドを書く | R1: 引数をダブルクォートで囲む |
| PowerShell で CLI ツールに `@`, `$`, `{` を渡す | R1: 必ずクォート |
| Windows 環境でスクリプトが ParserError を出す | R1: クォート漏れを確認 |

---

## このクラスターのノード一覧

- [[../nodes/powershell-hash-literal-git.md]] — `powershell`, `git`, `syntax-error`

---

*Last updated: 2026-02-25 | Node count: 1*
- [[../nodes/codex-image-tool-prompt-contract-multiline-and-attach-order.md]] — `codex`, `imagegen`, `cli-contract`, `silent-failure`（1 行契約・-i は後ろ）
- [[../nodes/heredoc-python-escapes-corrupted-regex-and-tmp-path-mismatch.md]] — `git-bash`, `heredoc`, `windows-path`, `commit-gate`（正規表現はリテラルのままファイルへ・/tmp を Python に渡さない・コミットは pytest の終了コードでゲート）
- [[../nodes/windows-cp932-print-crash-before-interactive-step.md]] — `cp932`, `print`, `interactive-tool`（人間操作 CLI の案内 print が「—」で落ちて操作に到達しない → main 冒頭で stdout.reconfigure(utf-8)）
