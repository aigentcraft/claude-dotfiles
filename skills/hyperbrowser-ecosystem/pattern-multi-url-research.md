---
id: pattern-multi-url-research
type: pattern
description: "Parallel analysis of multiple URLs → integrated report generation"
---
# Pattern: Multi-URL Research

An extension of [[pattern-scrape-then-llm]] that handles multiple URLs as input, scrapes them (often in parallel via [[pattern-parallel-scraping]]), and produces a single synthesized report.

## When to Apply

Use this pattern when:
- The user provides multiple URLs to compare or analyze together
- You need to cross-reference information across sources
- The output is a unified report, not per-URL results

## How It Works

```
[URL1, URL2, ...URLn] → parallel scrape → merge content → single LLM call → unified report
```

**Canonical implementation** (from `hyper-research/app/api/research/route.ts`):
```typescript
// 1. Parallel scrape all URLs
const scrapePromises = urls.map(async (url: string) => {
  const scrapeResult = await client.scrape.startAndWait({
    url,
    scrapeOptions: { formats: ['markdown', 'html'] }
  });
  return {
    url,
    title: scrapeResult.data?.metadata?.title || url,
    content: scrapeResult.data?.markdown?.substring(0, 15000) || '',
  };
});
const scrapedResults = await Promise.all(scrapePromises);

// 2. Build merged context
const context = scrapedResults
  .map((r, i) => `\n[Source ${i + 1}: ${r.title}]\nURL: ${r.url}\n${r.content}`)
  .join('\n');

// 3. Single LLM call for synthesis
const message = await anthropic.messages.create({
  model: 'claude-opus-4-5-20251101',
  messages: [{ role: 'user', content: `${question}\n\nSources:\n${context}` }]
});
```

**With partial failure tolerance** (from `yc-research-bot/`):
```typescript
const [websiteAnalysis, socialPresence, competitiveIntel, founderIntel] =
  await Promise.allSettled([...analyses]);
// Check each: if (result.status === 'fulfilled') use result.value
```

## What Breaks It

- **Context overflow**: 5 URLs × 15KB = 75KB of content. Truncate per-source to stay within LLM limits. See [[gotcha-content-truncation]].
- **All sources failing silently**: `Promise.all` with try/catch inside can return all empty results. Check that at least one source succeeded.
- **Source attribution lost**: When merging content, always tag each source (`[Source N: title]`) so the LLM can cite correctly.
- **Uneven quality**: Some sources may return minimal content. Filter by minimum length (e.g., `markdown.length >= 100`).

## Reference Projects

| Project | Input | Output |
|---------|-------|--------|
| `hyper-research/` | User-provided URLs | Comparative analysis with scores |
| `yc-research-bot/` | Company URL → derived URLs | Multi-angle company research |
| `mediresearch/` | Medical research URLs | Health analysis report |
| `hyperpages/` | Research URLs | Generated content page |
