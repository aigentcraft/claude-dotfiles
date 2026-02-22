---
id: pattern-retry-concurrency
type: pattern
description: "Exponential backoff + concurrent session error detection"
---
# Pattern: Retry & Concurrency

The most robust error handling pattern in the ecosystem. Detects concurrency limit errors, provides clear user feedback, and implements safe retry logic.

## When to Apply

Use this pattern when:
- Your app supports both free-plan and paid-plan users
- You're scraping multiple URLs and need graceful degradation
- Navigation to pages may fail intermittently

## How It Works

### Concurrency Error Detection (from `hypergraph/lib/hyperbrowser.ts`)

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

class ConcurrencyPlanError extends Error {
  constructor() {
    super(
      "Your Hyperbrowser plan only supports 1 concurrent browser. " +
      "The app is running in sequential mode, but multiple scrapes still " +
      "exceeded the limit. Upgrade at https://hyperbrowser.ai to unlock parallel execution."
    );
    this.name = "ConcurrencyPlanError";
  }
}
```

### Navigation Retry (from `scrape-to-api/lib/crawl.ts`)

```typescript
let retries = 2;
while (retries > 0) {
  try {
    await page.goto(url, { waitUntil: 'networkidle0', timeout: 15000 });
    break;
  } catch (navError) {
    retries--;
    if (retries === 0) throw navError;
    onProgress?.(`⚠️ Navigation failed, retrying... (${retries} attempts left)`);
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
}
```

### Combined: Safe Scrape with Retry and Concurrency Detection

```typescript
async function scrapeOne(hb: Hyperbrowser, url: string) {
  try {
    const result = await hb.scrape.startAndWait({
      url,
      scrapeOptions: { formats: ["markdown"], onlyMainContent: true },
    });
    return { url, markdown: result.data?.markdown ?? "" };
  } catch (err) {
    if (isConcurrencyError(err)) throw new ConcurrencyPlanError();
    throw err;
  }
}
```

## What Breaks It

- **Retrying concurrency errors**: Concurrency errors won't resolve by retrying — the user needs to upgrade or reduce parallelism. Detect and fail fast with a helpful message.
- **Infinite retry loops**: Always cap retries (2-3 attempts) and add delays between them.
- **Silent failures**: Catching errors without logging loses debugging information. Always `console.warn` on retry.
- **Missing error classification**: Treating all errors the same misses the opportunity to give users actionable feedback (upgrade plan vs fix URL vs retry).

## Reference Projects

| Project | Retry Strategy | Concurrency Handling |
|---------|---------------|---------------------|
| `hypergraph/` | Per-scrape with error classification | Worker queue + ConcurrencyPlanError |
| `scrape-to-api/` | Navigation retry (2 attempts, 1s delay) | Single session (no parallel) |
| `yc-research-bot/` | Promise.allSettled for partial failure | Fixed 4 parallel analyses |
