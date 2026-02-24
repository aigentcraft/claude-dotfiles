---
title: "Skills Knowledge Graph (MOC)"
description: "Central index mapping all installed Antigravity Skills for visual reference."
tags: ["skills", "moc", "system-components"]
relationships:
  related_to: ["[[error-graph/moc.md]]"]
---

# 🛠️ Installed Skills (Map of Content)

This graph visualizes the available system extensions (Skills) installed in the Antigravity workspace. 
*Note: The AI natively reads these skills directly from its system prompt upon initialization, but this MOC allows human users to visualize the architecture.*

## Core Configuration Skills
- [[../skills/auto-sync-rule/SKILL.md|auto-sync-rule]] : Enforces global synchronization rules.
- [[../skills/skill-installer/SKILL.md|skill-installer]] : Auto-searches and installs skills from GitHub.

## Knowledge & Debugging
- [[../skills/skill-pdca-error-graph/SKILL.md|skill-pdca-error-graph]] : The self-correction engine powering this very graph.

## Development & Operations
- [[../skills/slack-remote-run/SKILL.md|slack-remote-run]] : Remote command execution proxy.
- [[../skills/skill-hyperbrowser-reference/SKILL.md|skill-hyperbrowser-reference]] : Reference for scraping and Next.js applications.
- [[../skills/skill-project-map/SKILL.md|skill-project-map]] : Maintains PROJECT_MAP.md for AI context awareness at scale.

---
**Graph Connections:**
[[error-graph/moc.md|Return to Error PDCA MOC]]
