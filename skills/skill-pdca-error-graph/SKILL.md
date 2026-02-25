---
name: pdca-error-graph
description: An automated self-correction system that instructs the AI to record failures, root causes, and prevention strategies into a Markdown Knowledge Graph (PDCA cycle) to avoid repeating mistakes.
---

# PDCA Error Knowledge Graph Skill

This skill implements the "Plan, Do, Check, Act" (PDCA) cycle for AI self-correction.
Instead of making the same mistake twice, proactively consult past failures before acting and automatically document new failures when they occur.

## The Knowledge Graph Directory

```
~/claude-dotfiles/knowledge/error-graph/
  moc.md          ← Index of all nodes
  nodes/          ← Individual markdown files per failure case
  timestamps.json ← Last-updated tracking
```

---

## PDCA Record Types

### Type A: Technical Error
**When to record**: A code error, build failure, API limit, or tool issue required multiple steps to resolve and was not immediately obvious.

### Type B: User Correction
**When to record**: The user had to correct, redirect, or add requirements AFTER Claude produced output — meaning Claude failed to fulfill the intent on the first attempt.

Common triggers for Type B:
- User says "そうじゃなくて" / "それは違う" / "〜してほしかった"
- User adds follow-up requirements that should have been addressed upfront
- User repeats an instruction Claude already received but ignored
- Claude over-engineered when simplicity was asked
- Claude used abstract/vague language when specificity was needed

---

## Phase 1: CHECK (Before starting any complex task)

1. Read `~/claude-dotfiles/knowledge/error-graph/moc.md`
2. Identify nodes relevant to current task or error
3. Read relevant nodes
4. **Apply Prevention Strategies** before acting

---

## Phase 2: ACT / RECORD

### Template A: Technical Error Node

File: `nodes/[descriptive-slug].md`

```markdown
---
title: "[Short title of the error]"
type: "technical-error"
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
[What was the explicit error message, stack trace, or failure behavior?]

## 3. Check / Root Cause
[Why did it fail?]

## 4. Act / Prevention Strategy
[How did you fix it? What must the AI do differently next time?]
```

---

### Template B: User Correction Node

File: `nodes/uc-[descriptive-slug].md`  (prefix `uc-` for User Correction)

```markdown
---
title: "[Short title of the misalignment]"
type: "user-correction"
description: "[What the user had to correct and what the correct intent was]"
tags: ["user-correction", "[context-tag]"]
correction_category: "[see categories below]"
---

## 1. Plan / What was asked
[What the user originally requested]

## 2. Do / What Claude actually produced
[What Claude said or did that fell short of the intent]

## 3. Check / Why the user had to correct
[The specific gap. Classify by correction_category:]
- `misunderstood-requirements` — Claude misread what was wanted
- `over-engineered` — Claude added unnecessary complexity
- `missed-explicit-instruction` — User had already said it; Claude ignored it
- `wrong-assumption` — Claude assumed without confirming
- `too-abstract` — Claude used vague language when concrete specifics were needed
- `incomplete-output` — Only part of the request was fulfilled

## 4. Act / Behavioral Rule for Next Time
[Specific, concrete rule: "Next time when X, I must Y. Never do Z."]
```

---

## Phase 3: END-OF-SESSION CHECKPOINT (Mandatory)

**Before completing any task or pushing code**, pause and reflect:

> "Did the user have to correct me or add follow-up requirements during this session?"

- If YES → Create a Type B node documenting the correction
- If a technical error was encountered → Create a Type A node

**This reflection CANNOT be skipped. It is a hard prerequisite to marking any task as complete.**

---

## Updating the MOC

After creating any node, add a wikilink to `moc.md` under the relevant category:

```
- [[nodes/uc-abstract-knowledge-label.md]] - uc: Used abstract "重要な知見" instead of concrete categories
```
