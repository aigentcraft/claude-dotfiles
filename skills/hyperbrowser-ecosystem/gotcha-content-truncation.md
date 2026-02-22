---
id: gotcha-content-truncation
type: gotcha
description: "LLM context limits can truncate scraped content. onlyMainContent is essential."
---
# Gotcha: Content Truncation

## Why the Mistake

A typical web page's full HTML is 200-500KB. Even markdown format can be 50-100KB for content-rich pages. LLM context windows are large but not unlimited, and sending too much content leads to truncation, increased costs, and slower responses. Developers often forget to limit what they send.

## Correct Mental Model

Think of the [[pattern-scrape-then-llm]] pipeline as having a **bottleneck** at the LLM step. The scrape can return unlimited data, but the LLM can only process a fixed window. Design for the bottleneck:

1. **Scrape-time filtering**: `onlyMainContent: true` strips navigation, footers, sidebars
2. **Post-scrape truncation**: `content.substring(0, 15000)` caps per-source length
3. **Format selection**: `markdown` is ~5x smaller than `html` for the same content

## How to Detect

- LLM responses that reference content from the beginning of a page but miss details from the end
- API costs higher than expected (tokens proportional to input length)
- Slow response times on content-heavy pages
- LLM returning "I can see the page mentions..." without specific details

## How to Fix

**Layer 1 — Scrape options**:
```typescript
// Always use onlyMainContent for LLM pipelines
const result = await hb.scrape.startAndWait({
  url,
  scrapeOptions: {
    formats: ["markdown"],      // Not "html" — markdown is more compact
    onlyMainContent: true,       // Strip nav, footer, sidebar
  },
});
```

**Layer 2 — Post-scrape truncation** (from `hyper-research/`):
```typescript
content: scrapeResult.data.markdown?.substring(0, 15000) || ''
```

**Layer 3 — Minimum content filter** (from `hypergraph/`):
```typescript
if (r.markdown.length >= 100) results.push(r);
// Skip pages that returned too little content (error pages, redirects)
```

**Layer 4 — Chunking for large content** (from `site-to-dataset/`):
```typescript
const chunks = splitIntoChunks(content, maxChunkSize);
for (const chunk of chunks) {
  await processWithLLM(chunk);
}
```

**Evidence from the codebase**:

| Project | Strategy | Value |
|---------|----------|-------|
| `hypergraph/` | `onlyMainContent: true` | Markdown only |
| `hyper-research/` | `substring(0, 15000)` | 15KB per source |
| `assets-optimizer/` | `onlyMainContent: false` | Intentionally full page (needs all assets) |
| `hypervision/` | `onlyMainContent: false` | Intentionally full page (visual analysis) |
| `skills-generator/` | `onlyMainContent: true` | Documentation content only |
