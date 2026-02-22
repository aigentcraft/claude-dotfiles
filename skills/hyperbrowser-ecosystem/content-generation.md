---
id: content-generation
type: moc
description: "Content generation projects (3): hyperpages, hb-pitchdeck, podcast-generator-ai"
---
# Content Generation

Three projects that transform web research into creative output artifacts — pages, slide decks, and podcasts. All follow [[pattern-scrape-then-llm]] but diverge in their output format, making [[concept-export-artifacts]] the key differentiator.

## Projects

### hyperpages
- **Path**: `~/hyperbrowser-app-examples/hyperpages/`
- **What it does**: Researches a topic by scraping multiple URLs, then generates a polished content page with AI.
- **SDK APIs**: [[sdk-scrape-api]] (parallel via `Promise.all`)
- **Key patterns**: [[pattern-parallel-scraping]], [[pattern-scrape-then-llm]], [[pattern-code-generation]]
- **Use when**: You need to auto-generate a content page from web research.

### hb-pitchdeck
- **Path**: `~/hyperbrowser-app-examples/hb-pitchdeck/`
- **What it does**: Scrapes a company website using the browserUse agent, extracts company info, and generates a pitch deck.
- **SDK APIs**: [[sdk-hyperagent-api]] (`agents.browserUse`), [[sdk-session-api]]
- **Key patterns**: [[pattern-puppeteer-session]], [[pattern-code-generation]], [[concept-export-artifacts]] (PDF output)
- **Use when**: You need to auto-generate a presentation from a company's web presence.

### podcast-generator-ai
- **Path**: `~/hyperbrowser-app-examples/podcast-generator-ai/`
- **What it does**: Scrapes web content and converts it into a podcast script with AI-generated audio.
- **SDK APIs**: [[sdk-scrape-api]]
- **Key patterns**: [[pattern-scrape-then-llm]], [[concept-export-artifacts]] (audio output)
- **Use when**: You need to convert web content into audio/podcast format.

## Common Patterns

The scrape → LLM → artifact pipeline is consistent across all three. What varies is the final artifact: HTML pages (hyperpages), PDF slides (hb-pitchdeck), and audio files (podcast-generator-ai). The hb-pitchdeck is notable for using the `browserUse` agent API rather than the simpler scrape API, because it needs to navigate through complex company sites interactively.

## When to Use

Choose this cluster when the user wants to **create something new** from web content — documents, presentations, or media. If the goal is just analysis without artifact generation, see [[research-intelligence]].
