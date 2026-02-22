---
id: concept-session-options
type: concept
description: "Session configuration: useStealth, useProxy, solveCaptchas, adblock etc."
---
# Concept: Session Options

Session options control how Hyperbrowser's cloud browser behaves. They apply to both [[sdk-session-api]] (direct Puppeteer) and the `sessionOptions` parameter on [[sdk-scrape-api]], [[sdk-crawl-api]], and [[sdk-hyperagent-api]].

## Available Options

| Option | Type | Default | Effect |
|--------|------|---------|--------|
| `useStealth` | boolean | false | Hides automation signals (webdriver flag, HeadlessChrome UA, etc.) |
| `useProxy` | boolean | false | Routes through residential proxy for IP masking |
| `solveCaptchas` | boolean | false | Auto-solves CAPTCHAs encountered during browsing |
| `acceptCookies` | boolean | false | Auto-dismisses cookie consent banners |
| `adblock` | boolean | false | Blocks ads and trackers |

## Common Combinations

From analysis of all 30 projects, these are the standard configurations:

### No options (cooperative sites)
```typescript
// hypergraph, universal-chatbot, hyperpages
await hb.scrape.startAndWait({ url, scrapeOptions: { formats: ["markdown"] } });
```
Use for: documentation sites, public APIs, known-friendly targets.

### Stealth only (most common)
```typescript
// assets-optimizer, documentation-buddy, scrape-to-api
sessionOptions: { useStealth: true }
```
Use for: most sites that might detect automation. Safe default.

### Stealth + proxy (anti-bot sites)
```typescript
// deep-crawler-bot, flow-mapper
sessionOptions: { useStealth: true, useProxy: true }
```
Use for: sites that block datacenter IPs. Warning: adds latency and may cause tunnel errors (see [[gotcha-stealth-proxy]]).

### Full protection (unknown targets)
```typescript
// hypervision, yc-research-bot
sessionOptions: { useStealth: true, useProxy: true, solveCaptchas: true }
```
Use for: sites with aggressive anti-bot, CAPTCHAs. Most expensive option.

### Agent sessions
```typescript
// churnhunter
sessionOptions: { acceptCookies: true }
```
Use for: agent-driven flows where cookie banners interfere with navigation.

## Gotchas

- `useProxy: true` can cause "tunnel connection failed" errors — see [[gotcha-stealth-proxy]]
- Stealth mode changes the browser fingerprint — cached sessions may behave differently
- `solveCaptchas` adds 5-15 seconds per CAPTCHA — only enable when needed
- Options add up: stealth + proxy + captcha can add 10-30 seconds of overhead per page
