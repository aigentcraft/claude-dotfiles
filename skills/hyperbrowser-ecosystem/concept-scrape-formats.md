---
id: concept-scrape-formats
type: concept
description: "Output formats: markdown / HTML / screenshot — when to use each"
---
# Concept: Scrape Formats

The [[sdk-scrape-api]] supports three output formats. Choosing the right one directly impacts token usage, data quality, and what you can do with the content.

## Format Options

| Format | Size | Best For | Projects Using |
|--------|------|----------|---------------|
| `markdown` | Small (~5-20KB) | LLM analysis, text processing | 25+ projects |
| `html` | Large (~100-500KB) | DOM parsing, asset extraction, rendering | assets-optimizer, deep-crawler-bot, deep-reddit-researcher |
| `screenshot` | Medium (~50-200KB base64) | Visual analysis, UI audits, evidence | deep-reddit-researcher, hb-ui-bot-app, hypervision |

## When to Use Each

**Markdown** is the default choice for [[pattern-scrape-then-llm]]:
```typescript
scrapeOptions: { formats: ["markdown"], onlyMainContent: true }
```
- Most token-efficient format for LLM input
- Preserves text structure (headings, lists, links)
- Loses visual layout, CSS, images

**HTML** when you need DOM structure:
```typescript
scrapeOptions: { formats: ["html"], onlyMainContent: false }
```
- Required for asset extraction (images, fonts, scripts)
- Required for network request analysis
- Needed when you'll parse with Cheerio or similar tools
- assets-optimizer uses `onlyMainContent: false` because it needs all asset references

**Screenshot** for visual analysis:
```typescript
scrapeOptions: { formats: ["screenshot"] }
// Returns base64-encoded PNG in result.data.screenshot
```
- deep-reddit-researcher captures both HTML and screenshots for complete evidence
- Vision models (GPT-4V) can analyze screenshots directly

**Multi-format** when you need both text and visuals:
```typescript
scrapeOptions: { formats: ["html", "screenshot"] }
```
- deep-reddit-researcher uses this for comprehensive thread analysis
- hypervision compares markdown content to screenshot perception

## Examples

See [[sdk-scrape-api]] for code examples of each format combination.
