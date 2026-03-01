---
title: "Semantic Graph Relationships vs Untyped Links"
description: "Basic markdown wikilinks [[node]] lack semantic meaning (edge labels). To ensure the AI truly understands correlations and to enable advanced visualization, we must use typed relationships."
type: "technical-error"
tags: ["system-design", "knowledge-graph", "semantics", "obsidian"]
---

## 1. Plan / Context
We built a PDCA knowledge graph using standard Obsidian wikilinks (e.g., `[[api-rate-limit-exceeded.md]]`). The goal was to connect concepts for both the AI's understanding and the user's visual reference.

## 2. Do / The Error
The user noticed that the Obsidian graph view produced floating balls and lines, but *no text on the lines*. The relationship types (e.g., "causes", "fixes", "is an alternative to") were completely lost in the visual representation. The user questioned if the AI itself could truly grasp the correlations if the graph structure lacked explicit relationship definitions.

## 3. Check / Root Cause
Standard Markdown and native Obsidian wikilinks are **"untyped edges"**. They only signal *that* two files are connected, not *why* they are connected. 
While an LLM can infer the relationship by reading the surrounding text, relying on inference is brittle. For robust, machine-readable (and user-visualizable) knowledge graphs, we need **Semantic Links (Typed Edges)**.

## 4. Act / Prevention Strategy (Fix)
**Fix Applied**: 
1. We must explicitly define relationships.
2. From now on, all PDCA nodes must include a `relationships` section in their YAML frontmatter, utilizing explicit keys (e.g., `caused_by`, `related_to`, `fixes`).
3. We will also use inline semantic fields (e.g., `[relationship_type:: [[Link]]]`) if the user installs Obsidian plugins like **Juggl**, **ExcaliBrain**, or **Breadcrumbs/Dataview** to visualize text on lines.
4. I have updated the `skill-pdca-error-graph` template to enforce semantic linking.

**Future AI Instruction**:
When building or traversing knowledge graphs, do not settle for simple `[[links]]`. Always annotate *why* a link exists so both the structural parser and the AI agent can precisely map the causal network.
