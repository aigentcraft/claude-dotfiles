---
id: pattern-puppeteer-session
type: pattern
description: "Full browser control via Puppeteer connected to Hyperbrowser session"
---
# Pattern: Puppeteer Session

When [[sdk-scrape-api]] isn't enough — you need to interact with pages, intercept network requests, execute JavaScript, or control navigation — connect Puppeteer to a Hyperbrowser cloud session.

## When to Apply

Use this pattern when you need to:
- Intercept network requests (API discovery)
- Fill forms, click buttons, navigate interactively
- Execute custom JavaScript in the page context
- Take screenshots at specific moments
- Wait for dynamic content (SPAs, lazy-loaded elements)

## How It Works

```typescript
// From scrape-to-api/lib/crawl.ts — the canonical implementation
import { Hyperbrowser } from '@hyperbrowser/sdk';

const hb = new Hyperbrowser({ apiKey });

// 1. Create session
const session = await hb.sessions.create({
  useStealth: true,
  useProxy: false,
});

// 2. Connect Puppeteer
const { connect } = await import('puppeteer-core');
const browser = await connect({
  browserWSEndpoint: session.wsEndpoint,
  defaultViewport: null,
});

// 3. Use the browser
const [page] = await browser.pages();
await page.goto(url, { waitUntil: 'networkidle0', timeout: 15000 });

// 4. Interact (example: extract rendered HTML)
const html = await page.evaluate(() => document.documentElement.outerHTML);

// 5. Always clean up
try {
  await browser.close();
  if (session?.destroy) await session.destroy();
} catch (e) {
  console.error('Cleanup error:', e);
}
```

**With retry logic** (from `scrape-to-api/lib/crawl.ts`):
```typescript
let retries = 2;
while (retries > 0) {
  try {
    await page.goto(url, { waitUntil: 'networkidle0', timeout: 15000 });
    break;
  } catch (navError) {
    retries--;
    if (retries === 0) throw navError;
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
}
```

## What Breaks It

- **Missing cleanup**: Forgetting `browser.close()` + `session.destroy()` in finally blocks leaks sessions and hits [[gotcha-concurrency-limits]].
- **`useProxy: true` causing tunnel errors**: scrape-to-api explicitly sets `useProxy: false` to avoid this. See [[gotcha-stealth-proxy]].
- **`waitUntil: 'networkidle0'` timeout on SPAs**: Some SPAs never reach network idle. Use `'domcontentloaded'` or explicit waits instead.
- **Dynamic import of `puppeteer-core`**: Must use `await import('puppeteer-core')` in Next.js to avoid bundling issues.

## Reference Projects

| Project | Use Case |
|---------|----------|
| `scrape-to-api/` | Network interception for API discovery |
| `deep-crawler-bot/` | Deep crawling with stealth + proxy |
| `flow-mapper/` | Site navigation mapping |
| `hb-pitchdeck/` | Combined with browserUse agent |
