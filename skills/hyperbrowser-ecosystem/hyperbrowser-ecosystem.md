---
id: hyperbrowser-ecosystem
type: moc
description: "Root entry point for the Hyperbrowser ecosystem skill graph — 30 projects across 7 domains"
---
# Hyperbrowser Ecosystem

All 30 example projects at `~/hyperbrowser-app-examples/` share a common foundation: the Hyperbrowser SDK turns any URL into structured data via cloud-managed browsers. Understanding the [[sdk-scrape-api]] is the single most important starting point because 25+ projects use it as their primary data acquisition method. The [[sdk-extract-api]] adds LLM-powered structured extraction on top, while [[sdk-session-api]] gives you full Puppeteer control when the high-level APIs aren't enough. For multi-page jobs, [[sdk-crawl-api]] handles pagination and link following, and [[sdk-hyperagent-api]] enables autonomous browser agents that execute natural-language tasks.

## SDK Foundation

The five core APIs form a capability ladder — each level adds power but also complexity:

1. **Scrape** — `hb.scrape.startAndWait()` returns markdown/HTML/screenshot for a single URL. See [[sdk-scrape-api]].
2. **Extract** — `hb.extract.startAndWait()` applies a prompt + JSON schema to pull typed data. See [[sdk-extract-api]].
3. **Crawl** — `hb.crawl.startAndWait()` follows links across a site. See [[sdk-crawl-api]].
4. **Session** — `hb.sessions.create()` gives a `wsEndpoint` for Puppeteer/Playwright. See [[sdk-session-api]].
5. **Agent** — `hb.agents.hyperAgent.startAndWait()` executes high-level tasks autonomously. See [[sdk-hyperagent-api]].

## Domain Clusters

The 30 projects organize into 7 domains. Each Category MOC lists its projects with paths, SDK APIs used, and recommended entry points:

| Domain | Projects | MOC |
|--------|----------|-----|
| Web Scraping & Data Extraction | 5 | [[scraping-data-extraction]] |
| Research & Intelligence | 8 | [[research-intelligence]] |
| Job Matching & HR | 2 | [[job-matching]] |
| Chatbot & Conversational UI | 2 | [[chatbot-conversational]] |
| Content Generation | 3 | [[content-generation]] |
| UX Analysis & Testing | 3 | [[ux-analysis-testing]] |
| AI Agent & Developer Tools | 6 | [[agent-developer-tools]] |

## Cross-Cutting Concerns

Several concepts and patterns span all categories. Start here when building something new:

- Every project uses the [[concept-nextjs-stack]] (Next.js + React + TypeScript + Tailwind) — deviations exist only in CLI tools like churnhunter.
- The [[pattern-scrape-then-llm]] pipeline (scrape → transform → respond) is the most common architecture, appearing in 20+ projects.
- [[pattern-sse-streaming]] is the standard approach for long-running operations that need progress feedback.
- [[pattern-nextjs-api-routes]] defines the standard App Router `route.ts` structure shared across all web projects.
- When scraping multiple pages, understand [[pattern-parallel-scraping]] and [[gotcha-concurrency-limits]] before choosing between sequential and parallel execution.
- Format choices ([[concept-scrape-formats]]) and session configuration ([[concept-session-options]]) affect every project.
- Read [[gotcha-api-key-management]] before setting up any project — most require 2-3 API keys.

## Explorations Needed

- SDK version alignment: projects range from `@hyperbrowser/sdk@0.51` to `0.83`. See [[gotcha-sdk-version-drift]].
- Some projects use `browserUse` agent while others use `hyperAgent` — the relationship between these APIs needs tracking.
- No project currently demonstrates WebSocket-based real-time patterns (all use SSE).
