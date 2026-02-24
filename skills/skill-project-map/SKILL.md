---
name: project-map
description: Maintains a lightweight PROJECT_MAP.md at the root of every project, giving the AI a bird's-eye view of the directory structure, key files, and inter-file dependencies. Prevents duplicate file creation and cascading errors in large codebases.
---

# Project Architecture Map Skill

## Purpose
As projects grow, the AI's context window cannot hold all files simultaneously. Without a compact overview, the AI will:
- Create files that already exist elsewhere.
- Modify a file without realizing it breaks dependents.
- Lose track of which directories serve what purpose.

This skill solves that by maintaining a **single, lightweight `PROJECT_MAP.md`** at the project root.

## Phase 1: READ BEFORE ACTING (MANDATORY)
Before creating a new file, moving files, or making structural changes to a project, you MUST:
1. Check if a `PROJECT_MAP.md` exists at the project root.
2. If it exists, read it using `view_file` to understand the current architecture.
3. Verify that the file you are about to create does not already exist (or has a near-equivalent).
4. Verify that modifying a file won't break its listed dependents.

## Phase 2: UPDATE AFTER ACTING (MANDATORY)
After creating, deleting, moving, or renaming files, you MUST update `PROJECT_MAP.md` to reflect the change. Specifically:
1. Add new files/directories with a short description of their purpose.
2. Remove deleted entries.
3. Update dependency chains if imports or references changed.

## Phase 3: INITIAL CREATION
If a project does not yet have a `PROJECT_MAP.md`, and the project contains more than ~10 files, you SHOULD proactively create one by scanning the directory tree and summarizing the architecture.

## PROJECT_MAP.md Format
The file should be compact and scannable. Use the following structure:

```markdown
# Project Architecture Map
> Auto-maintained by AI. Last updated: [date]

## Directory Structure
- `src/` — Application source code
  - `components/` — Reusable UI components
  - `utils/` — Shared utility functions
- `scripts/` — Build and automation scripts
- `config/` — Configuration files

## Key Files & Responsibilities
| File | Purpose | Imported By |
|------|---------|-------------|
| `src/config.js` | Central configuration | `server.js`, `api.js`, `auth.js` |
| `src/utils/db.js` | Database connection pool | `api.js`, `models/*.js` |

## Dependency Chains (Critical)
- Changing `config.js` affects: `server.js`, `api.js`, `auth.js`
- Changing `db.js` affects: `api.js`, all files in `models/`
```

Keep the file under 100 lines. It is a quick-reference index, not full documentation.
