---
id: pattern-sse-streaming
type: pattern
description: "SSE-based real-time progress streaming from API routes to UI"
---
# Pattern: SSE Streaming

Long-running operations (crawling, multi-URL scraping, LLM processing) need real-time progress feedback. The ecosystem standardizes on Server-Sent Events (SSE) via `TransformStream` in Next.js API routes.

## When to Apply

Use this pattern when:
- An operation takes more than 2-3 seconds
- You want to show step-by-step progress to the user
- The client needs intermediate results before the final response

## How It Works

**Server side** (Next.js API route):
```typescript
// From site-to-dataset/app/api/generate/route.ts
export async function POST(request: NextRequest) {
  const encoder = new TextEncoder();
  const stream = new TransformStream();
  const writer = stream.writable.getWriter();

  const safeWrite = async (data: string) => {
    try { await writer.write(encoder.encode(data)); } catch { /* stream closed */ }
  };

  // Start processing in background
  (async () => {
    await safeWrite(JSON.stringify({ type: 'log', message: 'Starting...' }) + '\n');
    await safeWrite(JSON.stringify({ type: 'progress', value: 25 }) + '\n');
    // ... do work ...
    await safeWrite(JSON.stringify({ type: 'result', data: finalResult }) + '\n');
    await writer.close();
  })();

  return new Response(stream.readable, {
    headers: { 'Content-Type': 'text/event-stream' },
  });
}
```

**Client side** (React component):
```typescript
const response = await fetch('/api/generate', { method: 'POST', body: JSON.stringify(params) });
const reader = response.body!.getReader();
const decoder = new TextDecoder();

while (true) {
  const { done, value } = await reader.read();
  if (done) break;
  const lines = decoder.decode(value).split('\n').filter(Boolean);
  for (const line of lines) {
    const event = JSON.parse(line);
    if (event.type === 'progress') setProgress(event.value);
    if (event.type === 'log') addLog(event.message);
    if (event.type === 'result') setResult(event.data);
  }
}
```

**SSE helper function** (from `deep-crawler-bot/app/api/crawl/route.ts`):
```typescript
function sendSSE(data: object) {
  const encoded = encoder.encode(JSON.stringify(data) + '\n');
  writer.write(encoded);
}
sendSSE({ type: 'log', message: 'Browser session created' });
```

## What Breaks It

- **Forgetting `safeWrite`**: If the client disconnects mid-stream, writing to a closed writer throws. Always wrap writes in try/catch.
- **Missing `Content-Type` header**: Without `'text/event-stream'`, some clients won't process the stream correctly.
- **No `maxDuration`**: Next.js API routes timeout at 10s by default. Add `export const maxDuration = 300;` for long operations.
- **JSON parsing errors**: If a chunk boundary splits a JSON line, the client parser breaks. Use newline-delimited JSON and filter empty lines.

## Reference Projects

| Project | SSE Event Types |
|---------|-----------------|
| `site-to-dataset/` | log, progress, result, error |
| `deep-crawler-bot/` | log, endpoint, complete, error |
| `scrape-to-api/` | log, progress, complete |
| `flow-mapper/` | log, result |
| `web-to-agent/` | log, code, complete |
