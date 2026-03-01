---
title: "AI Instruction Adherence & Checkpoint Enforcement"
description: "AI agents tend to forget post-task administrative instructions (like documentation) when hyper-focused on solving immediate errors. Enforce behavior via hard checkpoints before task completion constraints."
type: "technical-error"
tags: ["ai-behavior", "prompt-engineering", "system-design", "pdca"]
---

## 1. Plan / Context
We created a comprehensive PDCA (Plan-Do-Check-Act) knowledge graph system (`skill-pdca-error-graph`) to prevent repeating mistakes. The instruction explicitly told the AI: "Whenever you successfully fix a bug... you MUST document it."

## 2. Do / The Error
While debugging a complex Slack API timeout and a PowerShell syntax error, the AI successfully solved both problems. However, immediately after verifying the fix, the AI reported task completion to the user and completely forgot to execute the PDCA documentation steps.

## 3. Check / Root Cause
This is a known limitation in LLM agent behavior based on context prioritization:
1. **Hyper-focus on the immediate goal:** The immediate problem ("fix the bug") consumes the agent's attention and working memory. 
2. **The "Done" Trigger:** Once the immediate problem is solved, the agent's dominant drive is to report success. Detached administrative instructions (like "write documentation afterwards") are easily ignored in the rush to call the `notify_user` or `task_completion` boundaries.
3. **Weak Prompts:** Telling an AI to "remember to do X" is a weak constraint. 

## 4. Act / Prevention Strategy (Fix)
**Fix Applied**: We changed the system architecture from a *passive instruction* to an *active checkpoint constraint*.
In the most global files (`ANTIGRAVITY.md` and the `auto-sync-rule` skill), we added a "PDCA Reflection Checkpoint" directly *blocking* the exit paths. The prompt was rewritten to state:
`Before you are allowed to tell the user a task is complete (or run the final push), you MUST pause and reflect. If you debugged an error... you MUST document it... No exceptions.`

**Future AI Instruction**: 
When designing skills, workflows, or rules for AI agents (including yourself or Claude Code), **never rely on expected sequential memory** for crucial administrative tasks. 
- **DO NOT** write: "Do X, then remember to do Y later."
- **DO** write: "You cannot execute the final Completion Tool until you verify Y is done."
Attach critical administrative steps as hard dependencies to the final exit boundaries (Push, Notify, Complete).
