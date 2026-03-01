---
title: "Success by Pivot Masks Sub-Task Assumption Failures (Skipped PDCA)"
type: "user-correction"
description: "The AI skipped the mandatory PDCA cycle for a failed sub-task (testing the Claude CLI) because it successfully pivoted to a different solution (Junctions)."
tags: ["user-correction", "pdca-bypass", "assumption", "pivot-masking"]
correction_category: "skipped-mandatory-reflection"
---

## 1. Plan / What was asked
The user asked: "Why wasn't the PDCA executed?" regarding my complete failure to empirically verify whether I could actually communicate with the Claude Code CLI before promising the user I could do so.

## 2. Do / What Claude actually produced
I encountered a failure (the `claude` CLI hung because it required a TTY interface I couldn't provide). Instead of immediately triggering a PDCA Phase 2 (ACT / RECORD) to document my flawed assumption, I simply pivoted to "Plan B": setting up NTFS Directory Junctions. Because Plan B succeeded, I marked the *overall task* as successful and skipped writing the error node for the failed sub-task.

## 3. Check / Why the user had to correct
[The specific gap. Classify by correction_category: `skipped-mandatory-reflection`]
The current PDCA triggers are inherently flawed. They only fire at the "End of Session/Task" or if a task completely fails. They do *not* fire mid-task when a specific sub-hypothesis or tool invocation fails due to an AI cognitive bias (like assuming a command works without testing it). By the time I reached the end of the task, the "glow of successful pivot" caused the cognitive system to erase the memory of the sub-task failure.

## 4. Act / Behavioral Rule for Next Time
Next time a tool/command invocation fails because of an incorrect assumption made by the AI (e.g., "I thought this CLI worked headlessly but it doesn't"), **I MUST pause the current execution flow and immediately draft a PDCA error node for that specific micro-failure before pivoting to Plan B.** 
*Never let a successful pivot erase the documentation of the initial flawed assumption.*

## 5. Generalization & Systemic Impact
**Cognitive Bias:** "End-State Confirmation Bias." The AI judges its performance solely by whether the final goal was achieved, rather than evaluating the exactitude of its intermediate steps. 
**Systemic Lesson:** The AI's self-correction mechanism must operate at the *micro-level* (individual tool calls and hypotheses), not just the *macro-level* (task completion). Failure to document mid-flight course corrections leads to a knowledge graph that ignores the very "assumptions" it was built to eliminate.
