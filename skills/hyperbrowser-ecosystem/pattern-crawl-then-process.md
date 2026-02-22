---
id: pattern-crawl-then-process
type: pattern
description: "Site crawl → chunk processing → LLM batch processing"
---
# Pattern: Crawl-then-Process

For processing entire websites (documentation, blogs, knowledge bases), crawl multiple pages first with [[sdk-crawl-api]], then process each page through an LLM pipeline. This extends [[pattern-scrape-then-llm]] to multi-page scale.

## When to Apply

Use this pattern when:
- You need content from an entire site section, not just one page
- The output is a dataset or knowledge base derived from many pages
- Pages share a common structure that can be batch-processed

## How It Works

```
Seed URL → hb.crawl.startAndWait() → [page1, page2, ...] → chunk → LLM batch → aggregate
```

**Crawl + concatenate** (from `hyperbuild/lib/hyperbrowser.ts`):
```typescript
const resp = await hb.crawl.startAndWait({
  url: params.seedUrls[0],
  maxPages: params.maxPages,
});

let markdown = "";
if (Array.isArray(resp?.data)) {
  for (const page of resp.data) {
    if (page?.markdown) {
      markdown += `\n-----\nUrl: ${page.url}\n${page.markdown}`;
    }
  }
}
```

**Crawl + per-page Q&A generation** (from `site-to-dataset/`):
```typescript
// 1. Crawl the site
const crawlResults = await crawlAndScrape(url, crawlOptions);

// 2. Chunk each page
const chunks = crawlResults.flatMap(page => splitIntoChunks(page.content));

// 3. Batch-process chunks through LLM
for (const batch of batches) {
  const batchResults = await Promise.all(
    batch.map(chunk => generateQAPairs(chunk, template))
  );
  allPairs.push(...batchResults.flat());
}
```

## What Breaks It

- **`maxPages` too high**: Crawling 100+ pages is slow and can timeout. Start with 10-30 and increase if needed.
- **Duplicate content**: Crawlers may hit the same content through different URL paths. Deduplicate by content hash.
- **Memory pressure**: Holding 50 page contents in memory while batch-processing can exceed limits. Process in chunks.
- **Crawl scope**: Without URL pattern filtering, the crawler may follow links to external sites or unrelated sections.

## Reference Projects

| Project | Crawl Target | Processing |
|---------|-------------|------------|
| `site-to-dataset/` | Documentation sites | Q&A pair generation per chunk |
| `documentation-buddy/` | Documentation sites | Index for chat Q&A |
| `hyperbuild/` | Any site | Concatenate for agent context |
