---
id: agent-developer-tools
type: moc
description: "AI agent & developer tools projects (6): web-to-agent, hyperbuild, hypergraph, hypervision, hyperskills, skills-generator"
---
# AI Agent & Developer Tools

Six projects that either build AI agents from web content or provide developer tooling on top of Hyperbrowser. This cluster has the most variety in SDK usage, including the best examples of [[sdk-extract-api]], [[sdk-crawl-api]], and [[pattern-retry-concurrency]].

## Projects

### web-to-agent
- **Path**: `~/hyperbrowser-app-examples/web-to-agent/`
- **What it does**: Scrapes a website and auto-generates AI agent tool definitions from its content and functionality.
- **SDK APIs**: [[sdk-scrape-api]]
- **Key patterns**: [[pattern-code-generation]], [[pattern-sse-streaming]], [[pattern-scrape-then-llm]]
- **Use when**: You need to automatically create AI agent tools from a website's capabilities.

### hyperbuild
- **Path**: `~/hyperbrowser-app-examples/hyperbuild/`
- **What it does**: Visual AI agent builder — scrapes, extracts, and crawls to provide context for building agents.
- **SDK APIs**: [[sdk-scrape-api]], [[sdk-extract-api]], [[sdk-crawl-api]] (all three high-level APIs)
- **Key patterns**: [[pattern-scrape-then-llm]], [[pattern-structured-extraction]], [[pattern-crawl-then-process]]
- **Use when**: You need a reference for using all three Hyperbrowser APIs together.

### hypergraph
- **Path**: `~/hyperbrowser-app-examples/hypergraph/`
- **What it does**: Generates skill graphs from technical topics by scraping related content.
- **SDK APIs**: [[sdk-scrape-api]] (with bounded concurrency, `onlyMainContent: true`)
- **Key patterns**: [[pattern-parallel-scraping]], [[pattern-retry-concurrency]] (best example)
- **Use when**: You need the reference implementation for concurrency-safe parallel scraping.

### hypervision
- **Path**: `~/hyperbrowser-app-examples/hypervision/`
- **What it does**: Visualizes how AI perceives web pages by scraping with multiple formats (markdown + screenshot).
- **SDK APIs**: [[sdk-scrape-api]] (with stealth, proxy, solveCaptchas), [[sdk-session-api]]
- **Key patterns**: [[concept-scrape-formats]], [[concept-session-options]] (full options demonstration)
- **Use when**: You need a reference for session option combinations and multi-format scraping.

### hyperskills
- **Path**: `~/hyperbrowser-app-examples/hyperskills/`
- **What it does**: Scrapes documentation URLs and generates SKILL.md files for AI assistants.
- **SDK APIs**: [[sdk-scrape-api]] (parallel scraping with `onlyMainContent: true`)
- **Key patterns**: [[pattern-parallel-scraping]], [[pattern-code-generation]], [[pattern-scrape-then-llm]]
- **Use when**: You need to generate SKILL.md from documentation sites.

### skills-generator
- **Path**: `~/hyperbrowser-app-examples/skills-generator/`
- **What it does**: Web search + scraping pipeline to generate SKILL.md files.
- **SDK APIs**: [[sdk-scrape-api]] (parallel with `onlyMainContent: true`)
- **Key patterns**: [[pattern-parallel-scraping]], [[pattern-scrape-then-llm]]
- **Use when**: You need SKILL.md generation starting from web search rather than specific URLs.

## Common Patterns

Hyperbuild is the **Rosetta Stone** of this ecosystem — it's the only project that uses scrape, extract, and crawl APIs together, making it the best reference for understanding how the three APIs complement each other. Hypergraph provides the definitive implementation of [[pattern-retry-concurrency]] with its `ConcurrencyPlanError` class, worker queue pattern, and environment-based concurrency cap. The two skills generators (hyperskills and skills-generator) are nearly identical in architecture, differing only in their input source (URLs vs search).

## When to Use

Choose this cluster when the user wants to **build developer tools**, **generate code artifacts**, or **create AI agent infrastructure** from web content. If they want to analyze UX instead of build tools, see [[ux-analysis-testing]].
