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


### R-HEREDOC: Bash ツールのヒアドキュメントは長いファイルで終端ごと切れる
Claude Code の Bash ツールは、おおよそ **150〜180 行を超えるヒアドキュメント**でコマンドが
途中で切られ、bash が「unexpected EOF while looking for matching quote」で落ちる（ファイルは作られない）。
エラー文言はクォート不整合を指すが、原因は中身のエスケープではなく**長さ**。
- **対策**: 長いファイルは Write ツールで書く。既存ファイルの部分変更は
  `python - <<'EOF'` で「読む→`assert` で対象確認→置換→書く」（短く収まる）
- 詳細: [[../nodes/bash-heredoc-truncates-long-files.md]]

### R3: Windows の `spawn(shell:true)` — 引数は cmd.exe が解釈する。定数だけ渡し、本文は stdin。停止は `taskkill /T`
npm シム（`claude.cmd` 等）を Node から起動するには shell が要るが、引数は cmd.exe に再解釈される
（`()=>{}` の `>` がリダイレクトになり `{}` ファイルが出来た）。`child.kill()` は cmd.exe しか殺さない。
- 詳細: [[../nodes/win32-shell-spawn-args-parsed-by-cmd-exe.md]]

### R4: Git Bash は `/` 始まりの引数を Windows パスに変換する — Windows ネイティブの道具は PowerShell / cmd で検証
`cmdkey ... /pass` が `C:/Git/pass` になり、エラーにならず別の意味で成功する。`MSYS_NO_PATHCONV=1` で回避。
- 詳細: [[../nodes/git-bash-msys-path-conversion-mangles-slash-args.md]]

### R5: Windows PowerShell 5.1 の `curl` は Invoke-WebRequest の別名 — `.ps1` では `curl.exe` と書く
pwsh 7 には別名が無いので、pwsh で通っても 5.1 で落ちる。両方で実行する。
- 詳細: [[../nodes/powershell51-curl-alias-shadows-curl-exe.md]]

| 状況 | 適用するルール |
|---|---|
| Node/Python から npm 製 CLI（.cmd）を Windows で呼ぶ | R3: shell 経由・引数は定数・本文は stdin・停止は taskkill /T |
| cmdkey / schtasks / reg 等を Git Bash から叩いて変な結果になる | R4: PowerShell / cmd で再実行（MSYS のパス変換） |
| `.ps1` で curl / wget を呼ぶ | R5: `curl.exe` と書き、PowerShell 5.1 でも実行して確かめる |

- [[../nodes/win32-shell-spawn-args-parsed-by-cmd-exe.md]] — `windows`, `node`, `cmd.exe`, `taskkill`（shell 経由の引数再解釈・ツリー kill）
- [[../nodes/git-bash-msys-path-conversion-mangles-slash-args.md]] — `git-bash`, `msys`, `cmdkey`（`/pass` → `C:/Git/pass`）
- [[../nodes/powershell51-curl-alias-shadows-curl-exe.md]] — `powershell`, `curl`, `alias`（5.1 の別名）

*Last updated: 2026-09-19 | Node count: 9*

### R6: `node -e "…"` を使わない。スクリプトはクォート付きヒアドキュメントでファイルに書く
二重引用符の中のバッククォートはコマンド置換になる。**説明文として書いたコマンド例が実行される。**
実例: 文書更新のつもりの `node -e "…"` が `npm run login -- indeed --manual` を実行し、
画面付きブラウザを 10 分間開いた（利用者が「ホーム画面に勝手に戻る」と報告して発覚）。
- 対策は構文の注意ではなく**手順の固定**: `cat > file <<'EOF'` で書いてから `node file`
- 詳細: [[../nodes/win32-shell-spawn-args-parsed-by-cmd-exe.md]]（2 例目の節）

### R7: PowerShell 5.1 のリダイレクト（`*>>` / `>>`）は UTF-16 で書く — ログは `Out-File -Encoding utf8`
常駐のログが全部化けた。`[Console]::OutputEncoding` を UTF-8 にしても、**書き出し側の既定は別**。
- 対策: `& $cmd 2>&1 | Out-File -LiteralPath $log -Append -Encoding utf8`
- 併せて: タスクスケジューラで常駐させる時は `-LogonType Interactive` が必須。
  「ログオンしていなくても実行」にすると DPAPI が開かず、**資格情報が全て「未登録」に見える**

### R8: 「どの層で文字列になったか」を意識する — 子プロセスの出力は既に復号済み
`curl` の出力を文字列で受けた後にバイト列へ戻すと二重復号になり、UTF-8 の日本語が壊れる。
ISO-2022-JP は 7 ビットの範囲だけなので往復でき、**片方だけ壊れて気づきにくい**。
- 符号化の検査は複数の組み合わせで行う（base64×UTF-8 / base64×ISO-2022-JP / 7bit×UTF-8）
- 詳細: [[../nodes/mime-7bit-body-is-already-decoded.md]]

### R9: コード片は平文ファイルに書いて読み込む（3 度踏んだ）
ヒアドキュメントの中の JS 文字列でエスケープが失われ、生成したコードが壊れた。
`cat > block.txt <<'EOF'` で本文を書き、スクリプトは `readFileSync` で差し込むだけにする。
- 詳細: [[../nodes/win32-shell-spawn-args-parsed-by-cmd-exe.md]]（3 例目の節）
