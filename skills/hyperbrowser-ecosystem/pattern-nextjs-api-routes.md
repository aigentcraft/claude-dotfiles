---
id: pattern-nextjs-api-routes
type: pattern
description: "Standard Next.js App Router API route pattern used across all projects"
---
# Pattern: Next.js API Routes

All web projects in the ecosystem use Next.js App Router API routes as their backend. This pattern defines the standard structure that appears in every `app/api/*/route.ts` file.

## When to Apply

This is not a choice — it's the **default architecture** for every Hyperbrowser web project. Use it whenever building a new web-based tool.

## How It Works

**Standard API route** (consistent across all projects):
```typescript
// app/api/{action}/route.ts
import { NextRequest, NextResponse } from 'next/server';
import Hyperbrowser from '@hyperbrowser/sdk';

export const maxDuration = 300; // Extend timeout for long scraping operations

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { url, ...options } = body;

    // Validate input
    if (!url) {
      return NextResponse.json({ error: 'URL is required' }, { status: 400 });
    }

    // Initialize SDK
    const hb = new Hyperbrowser({
      apiKey: process.env.HYPERBROWSER_API_KEY!,
    });

    // Do the work (scrape, extract, crawl, etc.)
    const result = await hb.scrape.startAndWait({ url, ... });

    // Return result
    return NextResponse.json({ success: true, data: result.data });

  } catch (error: any) {
    console.error('API error:', error);
    return NextResponse.json(
      { error: error.message || 'Operation failed' },
      { status: 500 }
    );
  }
}
```

**With SSE streaming** (see [[pattern-sse-streaming]]):
```typescript
export async function POST(request: NextRequest) {
  const encoder = new TextEncoder();
  const stream = new TransformStream();
  const writer = stream.writable.getWriter();

  (async () => { /* background processing */ })();

  return new Response(stream.readable, {
    headers: { 'Content-Type': 'text/event-stream' },
  });
}
```

**Client-provided API keys** (from `hyper-research/`):
```typescript
const { urls, question, hyperbrowserKey, anthropicKey } = body;
const client = new Hyperbrowser({ apiKey: hyperbrowserKey });
```

## What Breaks It

- **Missing `maxDuration`**: Next.js defaults to 10s timeout. Scraping operations often take 30-60s. Always set `export const maxDuration = 300`.
- **API key in client bundle**: Never import the SDK or reference `process.env` keys in client components. Keep all SDK usage in `route.ts` files.
- **CORS issues**: App Router routes handle same-origin by default. For external consumers, add CORS headers.
- **Request body size**: Large payloads (e.g., full HTML) may exceed default body size limits.

## Reference Projects

Every web project uses this pattern. Notable variations:
- **Client-provided keys**: `hyper-research/` lets users input their own API keys
- **Rate limiting**: `deep-crawler-bot/` implements IP-based rate limiting in the route
- **Multiple routes**: `hyperbuild/` has separate routes for scrape, extract, and crawl
