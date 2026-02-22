---
id: sdk-session-api
type: concept
description: "hb.sessions.create() — create browser sessions for Puppeteer connection"
---
# SDK: Session API

The Session API creates a cloud browser instance and returns a WebSocket endpoint for Puppeteer (or Playwright) connection. Use this when the high-level Scrape/Extract APIs aren't enough — you need to interact with pages, intercept network requests, fill forms, or execute JavaScript.

## Signature

```typescript
const session = await hb.sessions.create({
  useStealth?: boolean,
  useProxy?: boolean,
  solveCaptchas?: boolean,
  acceptCookies?: boolean,
});
// Returns: { id: string, wsEndpoint: string }

// Connect with Puppeteer:
import { connect } from 'puppeteer-core';
const browser = await connect({
  browserWSEndpoint: session.wsEndpoint,
  defaultViewport: null,
});
```

## Options

See [[concept-session-options]] for detailed option combinations. The most common setups:

| Setup | Options | Used By |
|-------|---------|---------|
| Stealth only | `useStealth: true` | scrape-to-api, assets-optimizer |
| Stealth + Proxy | `useStealth: true, useProxy: true` | deep-crawler-bot, flow-mapper |
| Full protection | `useStealth: true, useProxy: true, solveCaptchas: true` | hypervision |
| Minimal | `{}` (defaults) | When target is non-hostile |

## Examples

**Puppeteer session with stealth** (from `scrape-to-api/lib/crawl.ts`):
```typescript
const hb = new Hyperbrowser({ apiKey });

session = await hb.sessions.create({
  useStealth: true,
  useProxy: false  // Disable proxy to avoid tunnel errors
});

const { connect } = await import('puppeteer-core');
browser = await connect({
  browserWSEndpoint: session.wsEndpoint,
  defaultViewport: null,
});

const [page] = await browser.pages();
await page.goto(url, { waitUntil: 'networkidle0', timeout: 15000 });
```

**Network interception** (from `deep-crawler-bot/app/api/crawl/route.ts`):
```typescript
const session = await hb.sessions.create({
  useStealth: true,
  useProxy: true
});
// After connecting, enable request interception to discover APIs
```

**Cleanup pattern** (consistent across all session-using projects):
```typescript
try {
  // ... use browser
} finally {
  if (browser) await browser.close();
  if (session?.destroy) await session.destroy();
}
```

## Related

- [[pattern-puppeteer-session]] for the complete Puppeteer connection workflow
- [[concept-session-options]] for stealth/proxy/captcha option details
- [[gotcha-stealth-proxy]] for common pitfalls with session options
- [[sdk-scrape-api]] — prefer the Scrape API when you don't need interactive control
