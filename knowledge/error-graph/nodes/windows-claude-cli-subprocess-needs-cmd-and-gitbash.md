---
title: "windows-claude-cli-subprocess-needs-cmd-and-gitbash"
type: "error"
tags: ["windows", "claude-code", "subprocess", "python", "headless", "npm"]
date: "2026-08-07"
---

## 症状（Symptom）

Pythonワーカーから `subprocess.Popen(["claude", "-p", ...])` でヘッドレスClaude Codeを呼ぶと、Windowsで2段階の失敗が起きた:

1. `FileNotFoundError` — `claude` が見つからない
2. 1を直した後、exit=1で `Claude Code on Windows requires git-bash ... set CLAUDE_CODE_GIT_BASH_PATH=...`

## 根本原因（Root Cause）

- npmグローバルの `claude` の実体は **`claude.cmd`（npmシム）**。Windowsの `CreateProcess` は拡張子なし `claude` を解決しない（PATHEXT解決はシェルの機能）
- Windows版claude CLIは内部でgit-bashを要求する。対話セッション内では設定済みでも、**サブプロセスには `CLAUDE_CODE_GIT_BASH_PATH` が引き継がれない**環境があり、GitがProgram Files以外（例: `C:\Git`）だと自動検出も失敗する

## 修正（Fix）

`workers/shared/claude_client.py`:

1. `shutil.which("claude")` でフルパス（claude.cmd）に展開してからPopenする
2. `os.name == "nt"` かつ `CLAUDE_CODE_GIT_BASH_PATH` 未設定なら、既知の候補
   （`C:\Git\bin\bash.exe` / `C:\Git\usr\bin\bash.exe` / `C:\Program Files\Git\bin\bash.exe`）
   から実在するものをPopenのenvに注入

## 予防ルール（Prevention）

1. **npm製CLIをPythonのsubprocessで呼ぶ時は必ず `shutil.which()` で解決する**（Windowsの実体は .cmd）
2. Windowsでclaudeヘッドレスを呼ぶコードは `CLAUDE_CODE_GIT_BASH_PATH` の注入まで面倒を見る（bash.exeの場所はマシン依存 — Program Files直下とは限らない）
3. 「Macで動いた実機テスト」はWindowsの動作保証にならない。両OSがある運用では各マシンで最低1回スモークを打つ
