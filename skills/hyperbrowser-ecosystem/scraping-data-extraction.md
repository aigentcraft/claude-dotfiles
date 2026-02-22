---
id: scraping-data-extraction
type: moc
description: "Web scraping & data extraction projects (5): scrape-to-api, site-to-dataset, hyperdatalab, deep-crawler-bot, assets-optimizer"
---
# Scraping & Data Extraction

This cluster contains the most technically diverse projects — from simple single-page scrapes to full Puppeteer-based crawlers. They demonstrate the full range of [[sdk-scrape-api]] and [[sdk-session-api]] usage.

## Projects

### scrape-to-api
- **Path**: `~/hyperbrowser-app-examples/scrape-to-api/`
- **What it does**: Crawls a website via Puppeteer session, discovers API endpoints from network traffic, and generates a Postman collection.
- **SDK APIs**: [[sdk-session-api]] (Puppeteer connection for network interception)
- **Key patterns**: [[pattern-puppeteer-session]], [[pattern-sse-streaming]], [[pattern-code-generation]]
- **Use when**: You need to reverse-engineer a site's hidden API endpoints.

### site-to-dataset
- **Path**: `~/hyperbrowser-app-examples/site-to-dataset/`
- **What it does**: Crawls a documentation site and converts content into Q&A pair datasets (JSONL) for LLM fine-tuning.
- **SDK APIs**: [[sdk-scrape-api]], [[sdk-crawl-api]]
- **Key patterns**: [[pattern-crawl-then-process]], [[pattern-sse-streaming]]
- **Use when**: You need to generate training data from web content.

### hyperdatalab
- **Path**: `~/hyperbrowser-app-examples/hyperdatalab/`
- **What it does**: Scrapes web pages and uses LLMs to generate Q&A pairs for dataset creation.
- **SDK APIs**: [[sdk-scrape-api]]
- **Key patterns**: [[pattern-scrape-then-llm]]
- **Use when**: You want a simpler alternative to site-to-dataset for single-page data extraction.

### deep-crawler-bot
- **Path**: `~/hyperbrowser-app-examples/deep-crawler-bot/`
- **What it does**: Deep-crawls sites using Puppeteer sessions to discover hidden API endpoints by monitoring network requests.
- **SDK APIs**: [[sdk-session-api]] (full Puppeteer control with stealth + proxy)
- **Key patterns**: [[pattern-puppeteer-session]], [[pattern-sse-streaming]]
- **Use when**: You need advanced crawling with network interception that the Scrape API can't handle.

### assets-optimizer
- **Path**: `~/hyperbrowser-app-examples/assets-optimizer/`
- **What it does**: Scrapes a page's full HTML, extracts all assets (images, fonts, videos), downloads and optimizes them, then packages as ZIP.
- **SDK APIs**: [[sdk-scrape-api]] (HTML format, `onlyMainContent: false`)
- **Key patterns**: [[pattern-scrape-then-llm]], [[concept-export-artifacts]]
- **Use when**: You need to extract and optimize web assets from a page.

## Common Patterns

All five projects follow [[pattern-scrape-then-llm]] at their core but diverge in how they acquire content. The simpler projects (hyperdatalab, assets-optimizer) use the Scrape API directly, while the advanced crawlers (scrape-to-api, deep-crawler-bot) use [[pattern-puppeteer-session]] for network interception. The [[pattern-sse-streaming]] pattern appears in 3 of 5 projects because crawling operations are long-running. Be especially aware of [[gotcha-stealth-proxy]] — deep-crawler-bot enables both `useStealth` and `useProxy` while scrape-to-api explicitly disables proxy to avoid tunnel errors.

## When to Use

Choose this cluster when the user needs to **extract raw data** from websites. If the goal is analysis or intelligence rather than data extraction, look at [[research-intelligence]] instead. If the user wants to build an interactive chatbot on top of scraped data, see [[chatbot-conversational]].
