# Cluster: shell-hook-env — Claude Code フック・シェル環境変数

**ロード条件**: Claude Code フック・session-start.sh・シェルスクリプトを書く時

---

## 蒸留ルール

1. **フック内のプロジェクトパス取得**: `${CLAUDE_PROJECT_DIR:-$PWD}` を使う。`DOTFILES_DIR` へのフォールバックは禁止（常に dotfiles 自身と判定されてしまう）
2. **フック環境変数のログ出力**: 取得した環境変数の値（未設定時のフォールバック先）をログに出力して検証しやすくする

---

## ノード

- [[../nodes/claude-hook-env-project-dir.md]] — `CLAUDE_PROJECT_DIR` 未設定によるプロジェクト判定バグ

### R2: ヘッドレス（claude -p）のサンドボックスは PreToolUse フック + JSON deny でしか効かない
プロジェクトの bypassPermissions 下では `--permission-mode default` / `--allowedTools "Bash(x:*)"` は制限方向に効かない
（whoami が素通り）。Windows ヘッドレスのシェルツールは `PowerShell`。フックは `--settings <file>` で注入し、
exit 2 ではなく stdout の `{"hookSpecificOutput":{"permissionDecision":"deny"}}` で拒否する。
- **対策**: サブエージェントを制限したら、必ず非許可コマンドで拒否を実測してから本番投入する
- 詳細: [[../nodes/claude-headless-permission-flags-ignored-under-bypass.md]]

## このクラスターのノード一覧

- [[../nodes/claude-headless-permission-flags-ignored-under-bypass.md]] — `claude-headless`, `permissions`, `hooks`, `sandbox`, `windows`
- [[../nodes/lab-guard-blocked-readonly-utils-and-own-volume.md]] — `lab-guard`, `allowlist`, `false-block`, `docker`（PreToolUse 許可リストは初回実走の監査ログで補正する）
- [[../nodes/payment-gate-false-positive-stripe-hidden-iframe.md]] — `payment-gate`, `stripe`, `false-positive`（可視・サイズありの決済要素だけで止める）
- [[../nodes/headless-browser-blank-app-screens-bot-detection.md]] — `playwright`, `headless`, `bot-detection`（受け入れ基準は認証画面に入力欄が見えること・UA 偽装しない）
- [[../nodes/xmcp-venv-python-exe-lookup-windows.md]] — `windows`, `venv`, `path-exists`, `xmcp`（Windows の venv 実行ファイルは `python.exe`。拡張子なしの `Path.exists()` は False）
- [[../nodes/claude-in-chrome-secret-exposure-find-tool-values.md]] — `claude-in-chrome`, `secrets`, `find-tool`, `screenshot`（秘密値モーダルでは find に「値を引用しない」を明示・コピーボタン ref クリック → クリップボード CLI・露出したら再生成）
