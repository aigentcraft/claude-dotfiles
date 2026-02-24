---
title: "AI Context Window Blindness at Scale"
description: "As projects grow beyond what fits in the AI's working memory, it loses track of file relationships and creates duplicates or breaks dependencies. A 'Project Architecture Map' must be maintained as a lightweight index."
tags: ["ai-behavior", "scaling", "system-design", "architecture"]
relationships:
  caused_by: []
  related_to: ["[[ai-instruction-enforcement.md]]", "[[semantic-graph-relationships.md]]"]
  fixes_node: []
---

## 1. Plan / Context
As the user and AI collaboratively build more features, the workspace accumulates dozens to hundreds of files across nested directories. The AI is expected to understand how all files relate to each other when making changes.

## 2. Do / The Error
The user predicted (correctly) that the AI will:
1. **Create duplicate or unnecessary files** because it forgets a similar utility already exists elsewhere.
2. **Break existing functionality** because it doesn't realize that modifying File A silently affects File B, C, and D.
3. **Lose the mental model of the project** as the number of files exceeds what can be held in working context.

## 3. Check / Root Cause
LLM agents operate within a finite context window. They can only "see" a limited number of files at once. As the project scales:
- The AI relies on tools like `list_dir` and `grep_search` to explore, but these are reactive (search after the fact), not proactive (understand before acting).
- There is no single lightweight document that gives the AI a "bird's eye view" of the entire project architecture and inter-file dependencies.
- Without this map, every task starts from a partial, fragmented understanding.

## 4. Act / Prevention Strategy (Fix)
**Fix Applied**: Created a new skill (`skill-project-map`) that maintains a living `PROJECT_MAP.md` file at the root of every project. This file is a compact, always-up-to-date index of:
- All major directories and their purposes
- Key files and what they do
- Critical dependency chains (e.g., "config.js is imported by server.js, api.js, and auth.js")

**Future AI Instruction**:
- Before making ANY file creation or structural change, the AI MUST read `PROJECT_MAP.md` first.
- After making structural changes (new files, moved files, deleted files), the AI MUST update `PROJECT_MAP.md`.
- This ensures the AI always has a compact, up-to-date mental model without needing to re-explore the entire directory tree.
