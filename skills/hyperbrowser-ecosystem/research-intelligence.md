---
id: research-intelligence
type: moc
description: "Research & competitive intelligence projects (8): hyper-research, competitor-tracker, yc-research-bot, deep-reddit-researcher, Idea-generator-reddit, openai-source-forge, mediresearch, sora-research"
---
# Research & Intelligence

The largest cluster, with 8 projects that all share the [[pattern-scrape-then-llm]] pipeline but target different domains. The key differentiator is **what gets scraped** and **how the LLM synthesizes** the results.

## Projects

### hyper-research
- **Path**: `~/hyperbrowser-app-examples/hyper-research/`
- **What it does**: Takes multiple URLs, scrapes them in parallel, then uses Claude to produce a comparative analysis with scores.
- **SDK APIs**: [[sdk-scrape-api]] (markdown + HTML formats)
- **Key patterns**: [[pattern-multi-url-research]], [[pattern-parallel-scraping]]
- **Use when**: You need to compare and analyze content across multiple URLs.

### competitor-tracker
- **Path**: `~/hyperbrowser-app-examples/competitor-tracker/`
- **What it does**: Monitors competitor websites for changes by periodically scraping and diffing content.
- **SDK APIs**: [[sdk-scrape-api]] (HTML format)
- **Key patterns**: [[pattern-scrape-then-llm]]
- **Use when**: You need to detect changes on competitor or target websites over time.

### yc-research-bot
- **Path**: `~/hyperbrowser-app-examples/yc-research-bot/`
- **What it does**: Deep-researches Y Combinator companies with parallel analysis of website, social presence, competitive landscape, and founder intel.
- **SDK APIs**: [[sdk-scrape-api]] (with `useStealth: true`, `solveCaptchas: true`)
- **Key patterns**: [[pattern-multi-url-research]], [[pattern-parallel-scraping]] (via `Promise.allSettled`)
- **Use when**: You need comprehensive company research from multiple angles simultaneously.

### deep-reddit-researcher
- **Path**: `~/hyperbrowser-app-examples/deep-reddit-researcher/`
- **What it does**: Deep-dives into Reddit, scraping search results, threads, and screenshots for comprehensive topic research.
- **SDK APIs**: [[sdk-scrape-api]] (HTML + screenshot formats)
- **Key patterns**: [[pattern-scrape-then-llm]], [[concept-scrape-formats]] (screenshot usage)
- **Use when**: You need to mine Reddit for user opinions, pain points, or market signals.

### Idea-generator-reddit
- **Path**: `~/hyperbrowser-app-examples/Idea-generator-reddit/`
- **What it does**: Scrapes Reddit to discover business ideas and user pain points, then generates startup concepts.
- **SDK APIs**: [[sdk-scrape-api]]
- **Key patterns**: [[pattern-scrape-then-llm]]
- **Use when**: You want to generate business ideas from Reddit discussions.

### openai-source-forge
- **Path**: `~/hyperbrowser-app-examples/openai-source-forge/`
- **What it does**: Builds a Q&A system grounded in academic sources — scrapes papers/articles, then answers questions with citations.
- **SDK APIs**: [[sdk-scrape-api]] (with `onlyMainContent` toggling)
- **Key patterns**: [[pattern-scrape-then-llm]], [[pattern-sse-streaming]]
- **Use when**: You need citation-grounded answers from scraped academic content.

### mediresearch
- **Path**: `~/hyperbrowser-app-examples/mediresearch/`
- **What it does**: Analyzes blood test results by scraping medical research and synthesizing findings with AI.
- **SDK APIs**: [[sdk-scrape-api]]
- **Key patterns**: [[pattern-scrape-then-llm]], [[pattern-parallel-scraping]] (via `Promise.all`)
- **Use when**: You need medical/health data analysis backed by web research.

### sora-research
- **Path**: `~/hyperbrowser-app-examples/sora-research/`
- **What it does**: Analyzes AI-generated videos by extracting frames and using vision models to estimate prompts.
- **SDK APIs**: [[sdk-scrape-api]]
- **Key patterns**: [[pattern-scrape-then-llm]]
- **Use when**: You need to reverse-engineer or analyze AI-generated video content.

## Common Patterns

The universal pattern is [[pattern-scrape-then-llm]]: fetch web content, feed it to an LLM, return structured analysis. Projects that handle multiple URLs (hyper-research, yc-research-bot, mediresearch) add [[pattern-parallel-scraping]] on top. The yc-research-bot is noteworthy for using `Promise.allSettled` instead of `Promise.all` — this ensures partial results are returned even when some scrapes fail, which is essential for [[pattern-multi-url-research]]. Content truncation via `substring(0, 15000)` in hyper-research is a practical workaround for [[gotcha-content-truncation]].

## When to Use

Choose this cluster when the user wants to **understand, analyze, or monitor** web content rather than just extract it. The distinction from [[scraping-data-extraction]] is that research projects always include an LLM analysis step that produces insights, not just raw data.
