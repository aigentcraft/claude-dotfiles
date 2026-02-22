---
id: pattern-scrape-then-llm
type: pattern
description: "Basic pipeline: Web scrape → LLM analysis/transformation"
---
# Pattern: Scrape-then-LLM

The most common architecture in the ecosystem, found in 20+ projects. Scrape web content with [[sdk-scrape-api]], then feed it to an LLM for analysis, transformation, or generation.

## When to Apply

Use this pattern when you need to:
- Analyze web content and produce structured insights
- Transform web data into a different format (Q&A pairs, summaries, pitch decks)
- Answer questions based on live web content

This pattern is the **default starting point** for any Hyperbrowser project. Only deviate when you need interactive browser control ([[pattern-puppeteer-session]]) or autonomous agent behavior ([[sdk-hyperagent-api]]).

## How It Works

```
URL → hb.scrape.startAndWait() → markdown/HTML → LLM API → structured output → response
```

1. **Scrape**: Call [[sdk-scrape-api]] with appropriate format (`markdown` for LLM input, `html` for DOM analysis)
2. **Truncate/filter**: Limit content size to avoid [[gotcha-content-truncation]] — most projects use `onlyMainContent: true` or `substring(0, 15000)`
3. **Prompt**: Build an LLM prompt that includes the scraped content as context
4. **Parse**: Extract structured data from the LLM response

**Canonical example** (from `hyper-research/app/api/research/route.ts`):
```typescript
// 1. Scrape
const scrapeResult = await client.scrape.startAndWait({
  url,
  scrapeOptions: { formats: ['markdown', 'html'] }
});

// 2. Truncate
const content = scrapeResult.data.markdown?.substring(0, 15000) || '';

// 3. Prompt
const message = await anthropic.messages.create({
  model: 'claude-opus-4-5-20251101',
  messages: [{
    role: 'user',
    content: `${question}\n\nHere are the sources:\n${context}`
  }]
});

// 4. Parse response
const synthesis = parts[0].replace('SYNTHESIS:', '').trim();
```

## What Breaks It

- **Content too large**: Raw HTML can be 500KB+. Always use `onlyMainContent: true` or truncate. See [[gotcha-content-truncation]].
- **Wrong format**: Using `html` format when `markdown` would be more token-efficient (or vice versa when you need structure).
- **No error handling on scrape**: The scrape can fail (timeout, blocked). Always handle `scrapeResult.data` being null.
- **LLM output parsing**: Freeform LLM responses are brittle to parse. Consider [[pattern-structured-extraction]] with [[sdk-extract-api]] for typed output.

## Reference Projects

| Project | Variation |
|---------|-----------|
| `hyper-research/` | Multi-URL scrape → Claude synthesis with scores |
| `competitor-tracker/` | Single URL scrape → diff detection |
| `hyperdatalab/` | Scrape → Q&A pair generation |
| `podcast-generator-ai/` | Scrape → podcast script → audio |
| `deep-reddit-researcher/` | Multi-format scrape (HTML + screenshot) → research |
