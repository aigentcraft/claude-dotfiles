---
id: sdk-scrape-api
type: concept
description: "hb.scrape.startAndWait() — the most fundamental Hyperbrowser API, used in 25+ projects"
---
# SDK: Scrape API

The Scrape API is the workhorse of the Hyperbrowser ecosystem. It takes a URL and returns its content in one or more formats (markdown, HTML, screenshot). Every project except the pure-agent ones uses this API, making it the first thing to learn.

## Signature

```typescript
const result = await hb.scrape.startAndWait({
  url: string,
  scrapeOptions?: {
    formats: ("markdown" | "html" | "screenshot")[],
    onlyMainContent?: boolean,
  },
  sessionOptions?: {
    useStealth?: boolean,
    useProxy?: boolean,
    solveCaptchas?: boolean,
    acceptCookies?: boolean,
  }
});
// Returns: { data: { markdown?: string, html?: string, screenshot?: string, metadata?: {...} } }
```

## Options

| Option | Default | When to Use |
|--------|---------|-------------|
| `formats: ["markdown"]` | `["markdown"]` | LLM analysis — markdown is compact and preserves structure |
| `formats: ["html"]` | — | When you need DOM structure, CSS, or asset URLs |
| `formats: ["screenshot"]` | — | Visual analysis, UI/UX audits |
| `formats: ["html", "screenshot"]` | — | Reddit scraping, network analysis with visual proof |
| `onlyMainContent: true` | `true` | Strip nav, footer, sidebars — saves LLM tokens ([[gotcha-content-truncation]]) |
| `onlyMainContent: false` | — | Need full page: asset extraction, HTML analysis |

## Examples

**Basic markdown scrape** (from `hypergraph/lib/hyperbrowser.ts`):
```typescript
const result = await hb.scrape.startAndWait({
  url,
  scrapeOptions: { formats: ["markdown"], onlyMainContent: true },
});
return { url, markdown: result.data?.markdown ?? "" };
```

**HTML scrape with stealth** (from `assets-optimizer/lib/hyper.ts`):
```typescript
const scrapeResult = await hb.scrape.startAndWait({
  url,
  scrapeOptions: {
    formats: ['html'],
    onlyMainContent: false, // Need full page for assets
  },
  sessionOptions: {
    useStealth: true,
  }
});
```

**Multi-format scrape** (from `deep-reddit-researcher/lib/reddit.ts`):
```typescript
const result = await hb.scrape.startAndWait({
  url: usedUrl,
  scrapeOptions: {
    formats: ["html", "screenshot"]
  }
});
```

**Parallel scraping** (from `hyper-research/app/api/research/route.ts`):
```typescript
const scrapePromises = urls.map(async (url: string) => {
  const scrapeResult = await client.scrape.startAndWait({
    url,
    scrapeOptions: { formats: ['markdown', 'html'] }
  });
  return {
    url,
    content: scrapeResult.data.markdown?.substring(0, 15000) || '',
    metadata: scrapeResult.data.metadata
  };
});
const scrapedResults = await Promise.all(scrapePromises);
```

## Related

- [[concept-scrape-formats]] for guidance on choosing between markdown, HTML, and screenshot
- [[concept-session-options]] for stealth, proxy, and captcha options
- [[pattern-scrape-then-llm]] for the basic scrape → LLM pipeline
- [[pattern-parallel-scraping]] for scraping multiple URLs concurrently
- [[gotcha-content-truncation]] for managing LLM context limits
- [[gotcha-concurrency-limits]] for free plan session limits
