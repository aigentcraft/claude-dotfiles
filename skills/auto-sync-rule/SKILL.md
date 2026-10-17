---
name: auto-sync-rule
description: Enforces global synchronization rules for Antigravity across multiple devices. Triggers automatically on any new task or instruction to guarantee code consistency before changing anything.
---

# Auto-Sync Rule for Cross-Device Development

The USER is working on this same workspace from both a Windows PC and a MacBook. To prevent merge conflicts and lost work, you must perfectly synchronize the environment at the beginning and end of your tasks.

## 1. PRE-FLIGHT CHECK (PULL FIRST)
Before you read files, analyze code, or write any new code, you MUST pull the latest changes from Github.
Command to run:
- On Windows (PowerShell): `.\scripts\sync.ps1 pull`
- On Mac/Linux (Bash): `bash scripts/sync.sh pull`

Do not assume the code is up to date just because the session just started. The user may have just pushed changes from their other device 5 seconds ago!

## 2. PHASE 2: POST-FLIGHT PUSH
When you have finished addressing the user's prompt (right before calling `notify_user` or finishing your task boundary), push your changes.

> **停止中（2026-10-17〜）**: 以前ここにあった PDCA Reflection Checkpoint（push 前にエラーノードを作る振り返り）は、ユーザーの判断で止めている。ノードは作らずにそのまま push する。元の手順と再開手順は `knowledge/error-graph/PAUSED.md`。

### The Final Push
You MUST push your changes to sync the hive mind.
Command to run:
- On Windows (PowerShell): `.\scripts\sync.ps1 push`
- On Mac/Linux (Bash): `bash scripts/sync.sh push`

This ensures the user's MacBook inherits both your code changes AND your newly recorded knowledge.
