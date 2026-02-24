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

## 2. PHASE 2: PDCA REFLECTION & POST-FLIGHT PUSH
When you have finished addressing the user's prompt (right before calling `notify_user` or finishing your task boundary), you are about to trigger the final push.
**STOP. DO NOT PUSH YET.**

### The PDCA Reflection Checkpoint (MANDATORY)
Before running the push script, you MUST explicitly ask yourself:
*"During this task, did I encounter any errors, bugs, or misunderstandings that cost me time to debug?"*
*"Did I learn a new rule about the user's preferences or environment?"*

- **If YES:** You MUST temporarily halt your completion sequence. Go to the `knowledge/error-graph/nodes/` directory, create a new PDCA markdown node documenting the fix, and link it in `knowledge/error-graph/moc.md` (as instructed in the `pdca-error-graph` skill).
- **If NO:** You may proceed directly.

### The Final Push
Only after clearing the PDCA Reflection checkpoint, you MUST push your changes to sync the hive mind.
Command to run:
- On Windows (PowerShell): `.\scripts\sync.ps1 push`
- On Mac/Linux (Bash): `bash scripts/sync.sh push`

This ensures the user's MacBook inherits both your code changes AND your newly recorded knowledge.
