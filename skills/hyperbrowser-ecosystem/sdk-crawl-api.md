---
id: sdk-crawl-api
type: concept
description: "hb.crawl.startAndWait() — multi-page site crawling"
---
# SDK: Crawl API

The Crawl API handles multi-page scraping by following links from a seed URL. It returns an array of page results, each with its own content. Use this instead of manually discovering and scraping individual pages when you need content from an entire site or section.

## Signature

```typescript
const result = await hb.crawl.startAndWait({
  url: string,         // Seed URL to start crawling from
  maxPages?: number,   // Maximum pages to crawl
  scrapeOptions?: {
    formats: ("markdown" | "html")[],
    onlyMainContent?: boolean,
  }
});
// Returns: { data: Array<{ url: string, markdown?: string, html?: string }> }
```

## Options

| Parameter | Description | Typical Value |
|-----------|-------------|---------------|
| `url` | Starting URL for the crawl | Documentation root, site homepage |
| `maxPages` | Cap on total pages crawled | 10-50 for docs, 5-10 for targeted crawls |
| `scrapeOptions` | Same options as Scrape API | `{ formats: ["markdown"], onlyMainContent: true }` |

## Examples

**Basic site crawl** (from `hyperbuild/lib/hyperbrowser.ts`):
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

**Documentation crawl with stealth** (from `documentation-buddy/src/app/api/crawl/route.ts`):
```typescript
// Crawl API with session options for protected doc sites
const result = await hb.crawl.startAndWait({
  url: docUrl,
  maxPages: 30,
  scrapeOptions: {
    formats: ["markdown"],
    onlyMainContent: true,
  },
  sessionOptions: {
    useStealth: true,
  }
});
```

## Related

- [[pattern-crawl-then-process]] for the full crawl → chunk → process pipeline
- [[sdk-scrape-api]] for single-page scraping
- [[chatbot-conversational]] — documentation-buddy is the primary crawl consumer
- [[gotcha-concurrency-limits]] — crawling uses multiple sessions internally
