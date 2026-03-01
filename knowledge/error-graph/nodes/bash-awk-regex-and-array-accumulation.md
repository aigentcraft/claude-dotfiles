---
title: "Bash: awk regex multi-byte failure and array accumulation loop bug"
type: "technical-error"
tags: ["bash", "awk", "regex", "arrays", "windows", "git-bash", "cross-platform"]
---

## 1. What was the intention?
I wrote `generate-moc.sh` for Claude Code to execute on Git Bash (Windows). The intention was to parse markdown files, extract YAML frontmatter, and rebuild `moc.md`.

## 2. What actually happened? (The Error)
Two critical bugs occurred upon execution in Git Bash:
1. **Data Loss (AWK):** `awk '/^## 全ノードインデックス（nodes\/\）/ {exit} {print}'` failed to match the Japanese text/full-width parentheses in Git Bash. As a result, the script truncated the file, deleting 60 lines of critical Quick Rules and Cluster definitions.
2. **Data Corruption (Bash Arrays):** Inside a loop processing markdown files, I used `declare -a clusters`. In Bash, relying on `declare` inside a loop without explicit re-initialization causes the array elements to accumulate across loop iterations. The tags from previous nodes were appended to subsequent nodes.

## 3. How did we fix it?
1. **Regex Fix:** Changed the `awk` pattern to be language-agnostic and avoid wide characters: `awk '/^## .*nodes\// {exit} {print}'`.
2. **Array Fix:** Replaced `declare -a clusters` with explicit variable resetting: `clusters=()`.

## 4. Why did it happen? (Root Cause)
1. I assumed `awk` in Windows Git bash environment handles UTF-8 wide characters exactly as modern Linux equivalents do. It frequently fails on multi-byte boundaries depending on the system locale settings.
2. I assumed `declare -a var` acts identically to local scoping in higher-level languages (re-initializing the variable on each loop execution). In bash, it just declares the type, and does not wipe the existing contents of the global-esque variable.

## 5. Generalization & Systemic Impact
**Cognitive Bias (Systemic Lesson 1):** "Cross-Platform Scripting Blindness." When writing shell scripts intended to bridge platforms (Windows/Mac/Linux), relying on multi-byte characters (like Japanese or emojis) inside standard CLI tools (awk, sed, grep) is extremely brittle and guarantees eventual execution failure. **Always use ASCII-only, language-agnostic structural markers for regex anchors.**
**Bash Knowledge Gap (Systemic Lesson 2):** "Bash Loop State Assumptions." Always explicitly set `array=()`, `string=""`, or `var=0` at the very top of a bash loop if the state should not carry over. Never rely on `declare` or `local` to magically reset variables inside standard loops.
**Process Bypass (Systemic Lesson 3):** I fixed these two bugs instantly but *failed to proactively create this PDCA node* until the user prompted me, directly violating my own recently established rule (`uc-skipped-pdca-on-pivot.md`) to document assumptions that fail mid-task. The impulse to "just fix the code and move on" is still overpowering the strict requirement to document the failure.
