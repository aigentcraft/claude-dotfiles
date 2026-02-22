---
id: gotcha-concurrency-limits
type: gotcha
description: "Free plan allows only 1 concurrent session. Parallel processing requires caution."
---
# Gotcha: Concurrency Limits

## Why the Mistake

Developers naturally reach for `Promise.all` when scraping multiple URLs ([[pattern-parallel-scraping]]). This works perfectly on paid plans but immediately fails on free plans, which allow only **1 concurrent browser session**. The error message isn't always obvious — it may appear as "session limit", "too many", "rate limit", or "upgrade".

## Correct Mental Model

Think of Hyperbrowser sessions like database connections in a pool. Free plans have a pool of 1. Every `hb.scrape.startAndWait()`, `hb.sessions.create()`, or `hb.crawl.startAndWait()` acquires one session for the duration. On a free plan, a second concurrent call will fail.

**Safe default**: Always code for `MAX_CONCURRENCY = 1` and allow paid users to opt into higher parallelism via configuration.

## How to Detect

Look for these error patterns (from `hypergraph/lib/hyperbrowser.ts`):
```typescript
function isConcurrencyError(err: unknown): boolean {
  const msg = err instanceof Error ? err.message.toLowerCase() : String(err).toLowerCase();
  return (
    msg.includes("concurrent") ||
    msg.includes("concurrency") ||
    msg.includes("session limit") ||
    msg.includes("too many") ||
    msg.includes("rate limit") ||
    msg.includes("upgrade") ||
    msg.includes("plan")
  );
}
```

## How to Fix

1. **Environment-configurable concurrency** (best practice from `hypergraph/`):
```typescript
const MAX_CONCURRENCY = Math.max(1, parseInt(process.env.HYPERBROWSER_MAX_CONCURRENCY ?? "1", 10));
```

2. **Sequential fallback**:
```typescript
if (MAX_CONCURRENCY === 1) {
  for (const url of urls) {
    results.push(await scrapeOne(hb, url));
  }
} else {
  // Worker queue with concurrency cap
}
```

3. **Clear error messaging** via `ConcurrencyPlanError` (see [[pattern-retry-concurrency]]).

4. **Avoid retry on concurrency errors** — retrying won't help if the plan limit is reached. Fail fast with upgrade instructions.
