---
title: "windows-python3-store-stub-silent-hook-failure"
type: "error"
tags: ["windows", "python", "hooks", "claude-code", "secrets", "silent-failure"]
date: "2026-08-06"
---

## 症状（Symptom）

pullie プロジェクトの秘密防御フック（`.claude/settings.json` の PreToolUse → `python3 protect_secrets.py`）が、Windows マシンでは**一度も発火していなかった**。`.env` を読むコマンドがブロックされずに素通りしていた（気づいたのは settings.json 修復作業中の pipe テスト）。

## 根本原因（Root Cause）

- Windows の `python3` コマンドは **Microsoft Store のスタブ**（実行すると "Python" と出力して exit 49、または Store を開くだけ）。実体の Python は `python` にしかない
- フックは非ゼロ exit（2以外）だと「非ブロックの警告」扱いで処理が素通りする — **防御層の失敗が無音**だった
- Mac（python3 実在）で書いたフック設定をそのまま Windows と共有し、両OSでの発火検証をしなかった

## 修正（Fix）

フックコマンドを実在チェック付きフォールバックに変更:

```bash
if python3 -c '' >/dev/null 2>&1; then python3 ".../protect_secrets.py"; else python ".../protect_secrets.py"; fi
```

実セッションで `.env` を含むコマンドが exit 2 でブロックされることを確認済み。

## 予防ルール（Prevention）

1. **クロスプラットフォーム共有するフック・スクリプトで `python3` を裸で呼ばない**。`python3 -c ''` の成否で分岐するか、ランチャー（`py`）を検討する
2. **ブロック系フックは「ブロックされること」を実地テストして初めて有効とみなす**（設定が書いてある≠動いている）。pipe テスト: `echo '{"tool_name":"Bash","tool_input":{"command":"cat .env"}}' | <hook-cmd>` で exit 2 を確認
3. 防御層を別マシンへ持ち込んだら、そのマシンでも発火テストを1回行う
