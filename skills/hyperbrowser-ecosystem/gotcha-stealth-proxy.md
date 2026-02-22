---
id: gotcha-stealth-proxy
type: gotcha
description: "Misuse of stealth/proxy options causes unexpected errors"
---
# Gotcha: Stealth & Proxy Pitfalls

## Why the Mistake

Developers assume that enabling all protection options (`useStealth: true, useProxy: true, solveCaptchas: true`) is always better. In practice, enabling `useProxy` can cause **tunnel connection errors** on certain targets, and the combination of options varies by use case.

## Correct Mental Model

Each option adds a layer that can introduce latency and failure modes:

| Option | What It Does | Cost |
|--------|-------------|------|
| `useStealth` | Hides automation signals (webdriver flag, etc.) | Slight latency |
| `useProxy` | Routes through residential proxies | Significant latency + tunnel errors possible |
| `solveCaptchas` | Auto-solves CAPTCHAs | Adds wait time, not always reliable |
| `acceptCookies` | Auto-dismisses cookie banners | Minimal cost |

**Rule of thumb**: Start with `useStealth: true` only. Add `useProxy` only if the target actively blocks datacenter IPs. Add `solveCaptchas` only for sites with CAPTCHAs.

## How to Detect

- **Tunnel errors**: If you see "tunnel connection failed" or "ECONNRESET" errors, `useProxy: true` is likely the cause.
- **Timeouts on simple sites**: If scraping a simple documentation site takes >30s, excessive options may be slowing it down.
- **Inconsistent results**: Proxy routing can return different versions of a page (geo-specific content).

## How to Fix

**Evidence from the codebase** — projects handle this differently:

| Project | Options | Rationale |
|---------|---------|-----------|
| `scrape-to-api/` | `useStealth: true, useProxy: false` | Explicitly disables proxy to avoid tunnel errors |
| `deep-crawler-bot/` | `useStealth: true, useProxy: true` | Target sites actively block bots |
| `hypervision/` | `useStealth: true, useProxy: true, solveCaptchas: true` | Full protection for unknown targets |
| `hypervision/` (screenshot) | `useStealth: true, useProxy: false, solveCaptchas: true` | Proxy disabled for screenshot stability |
| `hypergraph/` | No session options | Simple docs sites don't need protection |

Start minimal and escalate:
```typescript
// Level 0: No options (simple, cooperative sites)
await hb.scrape.startAndWait({ url, scrapeOptions: { formats: ["markdown"] } });

// Level 1: Stealth only (most sites)
sessionOptions: { useStealth: true }

// Level 2: Stealth + proxy (hostile sites)
sessionOptions: { useStealth: true, useProxy: true }

// Level 3: Full protection (unknown/protected sites)
sessionOptions: { useStealth: true, useProxy: true, solveCaptchas: true }
```

See [[concept-session-options]] for the complete options reference.
