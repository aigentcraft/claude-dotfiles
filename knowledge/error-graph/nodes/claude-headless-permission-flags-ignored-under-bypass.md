---
title: "claude -p: --permission-mode / --allowedTools Do Not Restrict Tools Under Project bypassPermissions; Use a PreToolUse Hook with JSON deny"
description: "Tried to sandbox a headless researcher agent with --permission-mode default + --allowedTools 'Bash(docker:*)'. Measured: whoami still ran (project .claude/settings.json defaultMode=bypassPermissions wins), the Windows headless shell tool is PowerShell not Bash, and a hook that only exits 2 was logged but not enforced. What works: a PreToolUse hook injected via --settings <file> that prints {hookSpecificOutput:{permissionDecision:'deny'}}."
type: "technical-error"
tags: ["claude-headless", "permissions", "hooks", "sandbox", "windows", "weevee"]
---

## 1. Plan / Context
weevee の researcher（`claude -p` ヘッドレス）に Bash を許可して実測ラボを作る。ただし人間決定「料金が発生する操作は一切禁止」を**ハーネス側で強制**したい。

## 2. Do / The Error（すべて実測・2026-08-27）
1. `--permission-mode default --allowedTools "Bash(echo:*)"` で `whoami` を指示 → **実行された**（拒否されず）
2. `--settings '{"permissions":{"defaultMode":"default"}}'` を追加 + `--disallowedTools PowerShell` → 「No such tool available: Bash」— **Windows ヘッドレスのシェルツールは PowerShell** で、Bash は存在しなかった
3. `--allowedTools "PowerShell(echo:*)"` に変更 → それでも `whoami` が実行された
4. PreToolUse フック（exit 2 + stderr）を `--settings` JSON 文字列で注入 → 監査ログすら残らず（発火せず）
5. フックを `--settings <file.json>` で注入 → 発火した（監査ログあり）が、**exit 2 でも実行は継続**
6. フックが stdout に `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"…"}}` を返す → **拒否成功**（モデルに理由が返り、回避せず「未実測」に切替）

## 3. Check / Root Cause
- プロジェクトの `.claude/settings.json` に `permissions.defaultMode: bypassPermissions` があり、ヘッドレス実行でも cwd 配下（リポジトリ内）ではこれが適用される。CLI の `--permission-mode` / `--allowedTools` は**許可を増やす**方向には効くが、bypass を**打ち消して制限する**方向には効かない
- Windows のヘッドレス実行はシェルツール名が `PowerShell`。`Bash(...)` 形式の許可ルールは対象外
- フックの拒否は exit code ではなく JSON の `permissionDecision` で伝えるのが確実（bypass 下では exit 2 が無視される挙動）
- `--settings` はインライン JSON より**ファイルパス**の方が確実に読まれた（Windows のクォート事情）

## 4. Act / Prevention Strategy (Fix)
- ヘッドレスのサブエージェントを制限したい時は、**PreToolUse フック（決定論スクリプト）を `--settings <lab_dir>/settings.json` でそのエージェント実行にだけ注入**する。フックは tool_name（Bash/PowerShell 両方）で自己判定し、JSON deny を返し、全呼び出しを監査ログに残す
- `--permission-mode` / `--allowedTools` を「サンドボックス」と信じない。**必ず `whoami` 等の非許可コマンドで拒否を実測してから本番に使う**（R-HAZUDESU）
- Windows では `Bash|PowerShell` 両方を想定し、プロンプト側にも「PowerShell の場合がある（`timeout` は待機コマンド）」と書く
- 補助策を併用する: 子プロセス環境から秘密情報を除去（`scrub_secrets`）・cwd を隔離ディレクトリに・Write/Edit/Task を `--disallowedTools`・終了時にコンテナを機械回収
- 関連: [[uc-approval-request-local-path-instead-of-url]]（同日の HITL 改善）・[[windows-claude-cli-subprocess-needs-cmd-and-gitbash]]
- 追記（同日の誤ブロック）: 複合コマンドを `&&`/`;`/`|` で単純分割すると `docker exec c bash -c "apt-get update && …"` の引用符内が先頭コマンドとして検査され `apt-get` を誤拒否した。**分割は引用符の内側では行わない**（状態機械で quote 追跡）。禁止パターンは分割前の全文に対して検査するので、引用符内の危険な内容は引き続き捕捉できる
