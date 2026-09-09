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


### R2: .ps1 は UTF-8 **BOM 付き**で保存する — BOM 無し + LF は「静かに何もしない」
PowerShell 5.1 は BOM の無い `.ps1` を **cp932** として読む。日本語コメント末尾の
`）`（`EF BC 89`）の `89` は cp932 の lead byte で、.NET のデコーダは**次の 1 バイト（LF）を必ず食う**。
その結果コメントが次の行を飲み込み、**そこにあった実行行が消える**。
- **症状**: 定時タスクが `LastTaskResult = 0` で「成功」。ログは開始と終了が同一秒・出力ゼロ
- **対策**: 非 ASCII を含む `.ps1` は BOM 必須（+ `.gitattributes` で `*.ps1 text eol=crlf`）
- **併せて**: ネイティブコマンドを呼ぶラッパーは `$LASTEXITCODE -eq $null`（= 一度も起動していない）を
  専用の失敗コードで落とす。「起動しなかった」を rc=0 で返してはいけない
- **注意**: Python の cp932 コーデックは改行を食わないので、Python で書いた検査では再現しない
- 詳細: [[../nodes/ps1-no-bom-lf-comment-swallows-next-line.md]]

---

## クイック参照テーブル

| 状況 | 適用するルール |
|---|---|
| PowerShell (.ps1) で git コマンドを書く | R1: 引数をダブルクォートで囲む |
| PowerShell で CLI ツールに `@`, `$`, `{` を渡す | R1: 必ずクォート |
| Windows 環境でスクリプトが ParserError を出す | R1: クォート漏れを確認 |
| Windows の .ps1 を新規作成・編集する | R2: UTF-8 BOM で保存（BOM 無し + LF は実行行が消える） |
| 定時タスクが rc=0 なのに何も起きていない | R2: ラッパーの符号化と $LASTEXITCODE=$null を確認 |

---

## このクラスターのノード一覧

- [[../nodes/powershell-hash-literal-git.md]] — `powershell`, `git`, `syntax-error`
- [[../nodes/ps1-no-bom-lf-comment-swallows-next-line.md]] — `powershell`, `encoding`, `cp932`, `task-scheduler`, `silent-failure`（BOM 無し + LF で実行行が消える）

---

*Last updated: 2026-09-09 | Node count: 3*
- [[../nodes/codex-image-tool-prompt-contract-multiline-and-attach-order.md]] — `codex`, `imagegen`, `cli-contract`, `silent-failure`（1 行契約・-i は後ろ）
- [[../nodes/heredoc-python-escapes-corrupted-regex-and-tmp-path-mismatch.md]] — `git-bash`, `heredoc`, `windows-path`, `commit-gate`（正規表現はリテラルのままファイルへ・/tmp を Python に渡さない・コミットは pytest の終了コードでゲート）
- [[../nodes/windows-cp932-print-crash-before-interactive-step.md]] — `cp932`, `print`, `interactive-tool`（人間操作 CLI の案内 print が「—」で落ちて操作に到達しない → main 冒頭で stdout.reconfigure(utf-8)）
