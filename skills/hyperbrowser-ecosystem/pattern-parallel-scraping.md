---
id: pattern-parallel-scraping
type: pattern
description: "Worker queue-based parallel scraping with concurrency control"
---
# Pattern: Parallel Scraping

When you need to scrape multiple URLs, running them sequentially is slow but running them all at once can hit [[gotcha-concurrency-limits]]. This pattern provides controlled parallelism with graceful degradation.

## When to Apply

Use this pattern when:
- You have 3+ URLs to scrape
- User experience requires faster-than-sequential processing
- You need to handle free-plan (1 concurrent session) and paid-plan (multiple sessions) users

## How It Works

Three approaches exist in the ecosystem, in order of sophistication:

### 1. Simple Promise.all (many projects)
Fire all requests simultaneously. Simple but dangerous on free plans.

```typescript
// From hyper-research/app/api/research/route.ts
const scrapePromises = urls.map(async (url) => {
  const result = await client.scrape.startAndWait({ url, scrapeOptions: { formats: ['markdown'] } });
  return { url, content: result.data?.markdown ?? '' };
});
const results = await Promise.all(scrapePromises);
```

### 2. Promise.allSettled (yc-research-bot)
Partial failure tolerance — some scrapes can fail without killing the whole batch.

```typescript
// From yc-research-bot/app/api/deep-research/route.ts
const [websiteAnalysis, socialPresence, competitiveIntel, founderIntel] =
  await Promise.allSettled([analyzeWebsite(), analyzeSocial(), analyzeCompetitors(), analyzeFounders()]);
```

### 3. Worker Queue with Concurrency Cap (hypergraph — best practice)
Environment-configurable concurrency with error classification.

```typescript
// From hypergraph/lib/hyperbrowser.ts
const MAX_CONCURRENCY = Math.max(1, parseInt(process.env.HYPERBROWSER_MAX_CONCURRENCY ?? "1", 10));

// Sequential for free plan
if (MAX_CONCURRENCY === 1) {
  for (const url of urls) { results.push(await scrapeOne(hb, url)); }
  return results;
}

// Parallel with worker queue for paid plans
const queue = [...urls];
async function worker() {
  while (queue.length > 0) {
    const url = queue.shift();
    if (!url) break;
    try {
      const r = await scrapeOne(hb, url);
      if (r.markdown.length >= 100) results.push(r);
    } catch (err) {
      if (err instanceof ConcurrencyPlanError) throw err;
      console.warn(`Failed to scrape ${url}:`, err);
    }
  }
}
await Promise.all(Array.from({ length: MAX_CONCURRENCY }, () => worker()));
```

## What Breaks It

- **Free plan concurrency**: Launching `Promise.all` with 5+ URLs on a free plan will fail. Always use the worker queue pattern or sequential fallback. See [[gotcha-concurrency-limits]].
- **No individual error handling**: `Promise.all` rejects on first failure. Use `Promise.allSettled` or try/catch inside map callbacks.
- **Memory exhaustion**: Scraping 50+ pages simultaneously can exhaust memory. Cap concurrent requests.
- **Rate limiting**: Even paid plans have limits. The worker queue pattern naturally throttles requests.

## Reference Projects

| Project | Approach | Concurrency |
|---------|----------|-------------|
| `hypergraph/` | Worker queue | Env-configurable, free-plan safe |
| `hyper-research/` | Promise.all | Unbounded (assumes paid) |
| `yc-research-bot/` | Promise.allSettled | 4 parallel (fixed) |
| `universal-chatbot/` | Promise.all | Per-request URLs |
| `hyperskills/` | Promise.all | Per-batch URLs |
