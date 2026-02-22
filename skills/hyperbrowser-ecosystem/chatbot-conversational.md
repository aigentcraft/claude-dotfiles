---
id: chatbot-conversational
type: moc
description: "Chatbot & conversational UI projects (2): universal-chatbot, documentation-buddy"
---
# Chatbot & Conversational UI

Two projects that turn web content into interactive chat experiences. They demonstrate [[pattern-crawl-then-process]] — scrape content first, then enable real-time Q&A against the scraped corpus.

## Projects

### universal-chatbot
- **Path**: `~/hyperbrowser-app-examples/universal-chatbot/`
- **What it does**: Scrapes any website and enables real-time conversational Q&A about its content.
- **SDK APIs**: [[sdk-scrape-api]] (with `onlyMainContent: true`, parallel via `Promise.all`)
- **Key patterns**: [[pattern-parallel-scraping]], [[pattern-scrape-then-llm]]
- **Use when**: You need a general-purpose chatbot that can answer questions about any website.

### documentation-buddy
- **Path**: `~/hyperbrowser-app-examples/documentation-buddy/`
- **What it does**: Crawls documentation sites (with stealth mode), indexes content, and provides a chat interface for Q&A.
- **SDK APIs**: [[sdk-scrape-api]], [[sdk-crawl-api]] (with `useStealth: true`)
- **Key patterns**: [[pattern-crawl-then-process]], [[concept-session-options]] (stealth for docs sites)
- **Use when**: You need a chatbot specifically for documentation or knowledge base sites.

## Common Patterns

Both projects need to first acquire content, then serve it through a chat UI. Universal-chatbot takes the simpler approach — parallel scrape multiple URLs, concatenate content, and use it as LLM context. Documentation-buddy uses [[sdk-crawl-api]] to systematically traverse a docs site with `onlyMainContent: true` to focus on documentation content and avoid navigation chrome. The stealth option in documentation-buddy is necessary because some documentation platforms block automated access (see [[gotcha-stealth-proxy]]).

## When to Use

Choose this cluster when the user wants to **talk to** or **ask questions about** web content rather than just extract or analyze it. The key distinction from [[research-intelligence]] is the interactive, multi-turn conversation interface.
