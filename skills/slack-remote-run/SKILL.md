---
name: slack-remote-run
description: Use this skill to execute terminal commands via a remote Slack proxy so the user can approve them from their phone without being at their PC.
---

# Slack Remote Run Skill

This skill allows you to run terminal commands in a way that sends an approval request to the user's Slack instead of showing the standard IDE approval popup.

## When to Use This Skill

Use this skill when:
- The user explicitly asks to run commands remotely or via Slack.
- The user mentions they are stepping away from their PC but still want you to continue working on tasks that require command execution approval.
- You need to run a command that is NOT safe to auto-run (`SafeToAutoRun: false`), but you want the user to be able to approve it from their phone.

## How to Use This Skill

Do **NOT** use the standard `run_command` tool for commands that require user approval.

Instead, you must use the **`request_remote_approval`** tool provided by the `slack-approval-proxy` MCP server.

### 1. Call the MCP Tool

Call the `request_remote_approval` tool with the following arguments:
- `command` (string): The actual terminal command you want to execute (e.g., `npm install axios`).
- `cwd` (string): The absolute path to the directory where the command should be executed.
- `project` (string): The name of the current project or workspace (in Japanese). Example: `Slack連携プロキシ開発`
- `task` (string): What you are currently trying to accomplish overall (in Japanese). Example: `Slackのボタン反応エラーの修正`
- `reason` (string): Why you need to execute this specific command (in Japanese). Example: `エラー原因を特定するため、詳細ログを出力できる状態でもう一度テストサーバーを起動する必要があります。`

### 2. Wait for the Result

The `request_remote_approval` tool is designed specifically for infinite long-polling. 

**CRITICAL INSTRUCTION FOR AI:**
When calling this tool, you **MUST NOT** set a `timeout` parameter in your tool call settings. The user explicitly requested that the wait time be unlimited because they might not be able to check their phone for hours. You must allow the tool call to block execution indefinitely until the user clicks Approve or Reject.

When the user eventually takes action on Slack, the tool will automatically execute the command (if approved) and return the exact stdout/stderr back directly to you. You can then smoothly continue the task based on that output.
