---
id: pattern-structured-extraction
type: pattern
description: "Typed data extraction using Extract API with JSON schema"
---
# Pattern: Structured Extraction

Instead of scraping raw content and parsing it with custom code, use [[sdk-extract-api]] to get typed data directly. The API applies an LLM internally to extract data matching your JSON schema.

## When to Apply

Use this pattern when:
- You need specific fields from a page (not full content)
- The data structure is well-defined and consistent
- You want type safety in your pipeline
- Manual parsing of HTML/markdown would be fragile

Prefer [[pattern-scrape-then-llm]] when you need free-form analysis or the output format isn't a fixed schema.

## How It Works

```typescript
// From hyperbuild/lib/hyperbrowser.ts
import Hyperbrowser from "@hyperbrowser/sdk";

const hb = new Hyperbrowser({ apiKey: process.env.HYPERBROWSER_API_KEY! });

// Define your schema
const companySchema = {
  type: "object",
  properties: {
    name: { type: "string" },
    description: { type: "string" },
    features: { type: "array", items: { type: "string" } },
    pricing: { type: "string" },
  },
  required: ["name", "description"],
};

// Extract typed data
const resp = await hb.extract.startAndWait({
  urls: ["https://example.com"],
  schema: companySchema,
});

const data = resp.data; // Matches schema structure
```

**With TypeScript generics** (from `hyperbuild/lib/hyperbrowser.ts`):
```typescript
export async function hbExtract<T>(params: {
  url: string;
  schema: object;
}): Promise<T | null> {
  const resp = await hb.extract.startAndWait({
    urls: [params.url],
    schema: params.schema as object,
  });
  return (resp?.data as T) ?? null;
}
```

## What Breaks It

- **Overly complex schemas**: The extraction LLM has limits. Keep schemas focused with 5-10 fields max.
- **Dynamic content**: Extract API may not wait for JS-rendered content. For SPAs, use [[pattern-puppeteer-session]] to render first, then extract.
- **Cost**: Each extraction uses LLM tokens. For bulk extraction across many pages, consider [[pattern-scrape-then-llm]] with batch processing.
- **Schema validation**: The API returns best-effort extraction — fields may be null even if marked required. Always validate.

## Reference Projects

| Project | What It Extracts |
|---------|------------------|
| `hyperbuild/` | Company info, features, pricing from URLs |
| `hb-job-matcher/` | Professional profile from portfolio URLs |
