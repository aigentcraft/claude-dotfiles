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

### R3: 常駐から外部 CLI を起動する時は PATH に頼らない
Claude Code が npm 版からネイティブ版（`~/.local/bin/claude.exe`）に自動で切り替わり、npm の `claude.cmd` が消えた。
前日から動いている常駐の PATH には新しい置き場所が無く、claude の呼び出しが全部「認識されていません」になった（fukugyo-hootl 2026-10-04）。
- **対策**: 既知の置き場所を順に確かめ（ネイティブ版 → npm 版）、見つからない時だけ PATH に任せる。起動箇所は 1 つの関数に揃える
- 「全部が同じ時刻から一斉に失敗」は、個々の処理より起動の土台（PATH・認証・実体）を先に疑う
- **PC 全体の変化が根の障害は、同じ CLI を起動している全プロジェクトを洗う** — 同じ日に weevee でも全担当が 7 時間止まり
  （217 回・知らせ 0 件）、このノードがあったのに当てはめられていなかった。全担当が止まる失敗は起動の口で人に知らせる
- 3 件目は pullie（12:00 の記事企画の補充と 18:30 の交流が空振り）。洗い出しは手順で行う: タスクスケジューラの一覧から定時起動の
  プロジェクトを列挙 → 各プロジェクトの CLI 起動箇所を検索。この PC で該当したのは fukugyo-hootl・weevee・pullie の 3 つ
- 詳細: [[../nodes/claude-cli-native-migration-breaks-resident-path.md]]

## このクラスターのノード一覧

- [[../nodes/claude-headless-permission-flags-ignored-under-bypass.md]] — `claude-headless`, `permissions`, `hooks`, `sandbox`, `windows`
- [[../nodes/lab-guard-blocked-readonly-utils-and-own-volume.md]] — `lab-guard`, `allowlist`, `false-block`, `docker`（PreToolUse 許可リストは初回実走の監査ログで補正する）
- [[../nodes/payment-gate-false-positive-stripe-hidden-iframe.md]] — `payment-gate`, `stripe`, `false-positive`（可視・サイズありの決済要素だけで止める）
- [[../nodes/headless-browser-blank-app-screens-bot-detection.md]] — `playwright`, `headless`, `bot-detection`（受け入れ基準は認証画面に入力欄が見えること・UA 偽装しない）
- [[../nodes/xmcp-venv-python-exe-lookup-windows.md]] — `windows`, `venv`, `path-exists`, `xmcp`（Windows の venv 実行ファイルは `python.exe`。拡張子なしの `Path.exists()` は False）
- [[../nodes/claude-in-chrome-secret-exposure-find-tool-values.md]] — `claude-in-chrome`, `secrets`, `find-tool`, `screenshot`（秘密値モーダルでは find に「値を引用しない」を明示・コピーボタン ref クリック → クリップボード CLI・露出したら再生成）
- [[../nodes/claude-cli-native-migration-breaks-resident-path.md]] — `windows`, `claude-cli`, `path`, `resident`（常駐から CLI を起動する時は既知の置き場所を順に確かめる。npm→ネイティブ版の切り替えで実体が引っ越す）
