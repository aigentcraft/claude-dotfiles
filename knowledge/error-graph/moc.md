# PDCA Error Knowledge Graph: Map of Content (MOC)

This is the central index (MOC) for the PDCA Error Knowledge Graph. 
**Agent Instruction**: You MUST read this file whenever you encounter an error or bug, and before starting a complex task to avoid repeating past mistakes.

*Related MOC*: [[../skills-moc.md|Skills Knowledge Graph (MOC)]]

## Structure
- All failure examples and their post-mortems are stored as individually traversable Markdown nodes in the `./nodes/` directory.
- Each node uses YAML frontmatter (title, description, tags) and documents the PDCA cycle (Plan/Do/Check/Act - Reason, Fix, Prevention).

## Knowledge Graph Index

### [Type A] Technical Errors

#### System Architecture & Configuration
- [[nodes/ai-instruction-enforcement.md]] - AI Instruction Adherence & Checkpoint Enforcement
- [[nodes/semantic-graph-relationships.md]] - Semantic Graph Relationships vs Untyped Links
- [[nodes/ai-context-blindness-at-scale.md]] - AI Context Window Blindness at Scale

#### API & Network
- [[nodes/api-rate-limit-exceeded.md]] - Mock Test: API Rate Limit Exceeded
- [[nodes/slack-api-silent-hang.md]] - Slack API postMessage Silent Hang

#### Browser Automation & Scraping
(No entries yet)

#### Programming & Syntax
- [[nodes/powershell-hash-literal-git.md]] - PowerShell Hash Table Literal parsing in Git commands

---

### [Type B] User Corrections (AI Behavior Failures)

> Recorded when the user had to correct, redirect, or add requirements after Claude's output.
> Node files are prefixed with `uc-` (User Correction).

#### too-abstract (具体性不足)
- [[nodes/uc-abstract-knowledge-label.md]] - "重要な知見" という抽象ラベルでナレッジ設計を提案してしまった

#### misunderstood-requirements (要件誤解)
(No entries yet)

#### over-engineered (過剰設計)
(No entries yet)

#### missed-explicit-instruction (指示の見落とし)
(No entries yet)

#### wrong-assumption (無確認の思い込み)
(No entries yet)

---
*Note: When a new error is resolved, create a node in `./nodes/` and add a wikilink above.*
*Type B nodes: filename prefix `uc-`, correction_category tag required.*
