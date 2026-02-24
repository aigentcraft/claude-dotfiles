---
name: pdca-error-graph
description: An automated self-correction system that instructs the AI to record failures, root causes, and prevention strategies into a Markdown Knowledge Graph (PDCA cycle) to avoid repeating mistakes.
---

# PDCA Error Knowledge Graph Skill

This skill implements the "Plan, Do, Check, Act" (PDCA) cycle for AI self-correction. Instead of making the same mistake twice, you will proactively consult past failures before acting and automatically document new failures when they occur.

## The Knowledge Graph Directory
The error graph is located at:
`c:\Users\user\.gemini\antigravity\knowledge\error-graph\`

- `moc.md`: The Map of Content (Index).
- `nodes/`: The directory containing individual markdown files for each failure case.

## Phase 1: CHECK (Before starting a task or debugging an error)
Whenever you encounter an error (e.g., a crash, a build failure, API limit) or before starting a complex task:
1. Use `view_file` to read `c:\Users\user\.gemini\antigravity\knowledge\error-graph\moc.md`.
2. See if there are any linked nodes relevant to your current error or task.
3. If a relevant node exists, read it using `view_file`.
4. **Apply the Prevention Strategy** documented in that node to your current plan.

## Phase 2: ACT / RECORD (After resolving a new error)
Whenever you successfully fix a bug or resolve an error that cost you multiple steps or was not immediately obvious, you **MUST** document it so you do not repeat it.

1. **Create a Node:** Use `write_to_file` to create a new markdown file in `c:\Users\user\.gemini\antigravity\knowledge\error-graph\nodes\`.
   - Name the file descriptively (e.g., `api-rate-limit-exceeded.md`).
   - The file MUST contain YAML frontmatter and PDCA sections as shown below:

```markdown
---
title: "[Short title of the error]"
description: "[1-2 sentence description of what failed and the key takeaway]"
tags: ["[tag1]", "[tag2]"]
relationships:
  caused_by: []
  related_to: []
  fixes_node: []
---

## 1. Plan / Context
[What were you trying to do when the error occurred?]

## 2. Do / The Error
[What was the explicit error message, stack trace, or failure behavior? Include code snippets if helpful.]

## 3. Check / Root Cause
[Why did it fail? What was the underlying misunderstanding or missing configuration?]

## 4. Act / Prevention Strategy (Fix)
[How did you fix it? AND MORE IMPORTANTLY: What specific action should the AI take in the future to NEVER make this mistake again?]
```

2. **Update the MOC:** Use `replace_file_content` or `multi_replace_file_content` to add a wikilink to your new node in `c:\Users\user\.gemini\antigravity\knowledge\error-graph\moc.md`.
   - Add it under the relevant category heading.
   - Example format: `- [[nodes/api-rate-limit-exceeded.md]] - [Short title]`

By strictly adhering to this skill, you will continuously build a searchable, associative memory of past mistakes and drastically improve your efficiency.
