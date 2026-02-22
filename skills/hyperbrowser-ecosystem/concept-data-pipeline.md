---
id: concept-data-pipeline
type: concept
description: "Common data pipeline structure across all projects"
---
# Concept: Data Pipeline

Every Hyperbrowser project follows a variation of the same 4-stage data pipeline. Understanding this structure makes it easy to navigate any project and identify where to make changes.

## Pipeline Stages

```
[1. Acquire] → [2. Transform] → [3. Analyze] → [4. Deliver]
```

### Stage 1: Acquire (Web Data)
Get content from the web using one of the [[sdk-scrape-api]], [[sdk-crawl-api]], [[sdk-session-api]], or [[sdk-hyperagent-api]].

### Stage 2: Transform (Data Prep)
Clean, filter, chunk, or restructure the raw data for the next stage:
- Truncation: `content.substring(0, 15000)` — see [[gotcha-content-truncation]]
- Format selection: markdown vs HTML vs screenshot — see [[concept-scrape-formats]]
- Chunking: Split large content into processable pieces
- Deduplication: Remove redundant content from crawls

### Stage 3: Analyze (LLM Processing)
Feed transformed data to an AI provider for analysis, following [[pattern-scrape-then-llm]]:
- Synthesis: Merge multiple sources into a report
- Extraction: Pull structured data from unstructured content
- Generation: Create new content based on the data

### Stage 4: Deliver (Output)
Return results to the user in the appropriate format — see [[concept-export-artifacts]]:
- JSON API response (most common)
- SSE stream (long-running operations) — see [[pattern-sse-streaming]]
- File download (ZIP, PDF, JSONL, audio)
- Interactive chat response

## Variations

| Variation | Projects | Difference |
|-----------|----------|------------|
| Skip Stage 3 | assets-optimizer, competitor-tracker | No LLM — pure data extraction |
| Stage 1 = Agent | churnhunter, hb-ui-bot-app | Agent autonomously acquires data |
| Stage 2 = Schema | hb-job-matcher, hyperbuild | [[sdk-extract-api]] handles transform + analyze |
| Iterative | deep-reddit-researcher | Multiple acquire-transform cycles |

## Anti-Patterns

- **No Transform stage**: Sending full HTML directly to an LLM wastes tokens and hits context limits.
- **Skipping error handling in Acquire**: Web scraping is inherently unreliable — always handle failures.
- **Synchronous Deliver**: Long operations (>3s) should use [[pattern-sse-streaming]], not synchronous responses.
