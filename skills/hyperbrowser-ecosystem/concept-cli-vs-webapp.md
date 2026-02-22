---
id: concept-cli-vs-webapp
type: concept
description: "Web app vs CLI: choosing the right form factor for the use case"
---
# Concept: CLI vs Web App

28 of 30 projects are web apps (Next.js), while 2 are CLI tools. The form factor affects architecture, SDK usage, and user experience.

## Decision Matrix

| Criterion | Web App | CLI |
|-----------|---------|-----|
| User interaction | Browser UI with real-time feedback | Terminal with prompts/flags |
| Progress display | SSE streaming to React components | Console output (chalk, spinners) |
| API key handling | `.env.local` or user input fields | `.env` file or environment variables |
| Deployment | Vercel, serverless | Local execution, npm scripts |
| Best for | Interactive exploration, multi-step workflows | Automation, CI/CD, scripting |
| SDK timeout | Limited by `maxDuration` (300s typical) | Unlimited |

## Web App Projects (28)

All use [[concept-nextjs-stack]] with [[pattern-nextjs-api-routes]]. The Hyperbrowser SDK runs server-side in API routes, and results stream to the client via [[pattern-sse-streaming]] or JSON responses.

Standard structure:
```
app/
  api/
    {action}/
      route.ts    ← Hyperbrowser SDK + LLM calls
  page.tsx         ← React UI
lib/
  hyperbrowser.ts  ← SDK wrapper/helpers
```

## CLI Projects (2)

### churnhunter
- Uses yargs for argument parsing, chalk for colored output, cli-table3 for tables
- Direct SDK usage without Next.js wrapping
- Interactive readline prompt for URL input
- Outputs analysis as formatted table to terminal

### competitor-tracker
- Hybrid — has both web interface and CLI notification components
- CLI component handles scheduled monitoring via cron or manual execution

## When to Choose CLI

Prefer CLI when:
- The tool is for developers/automation (not end users)
- No interactive UI is needed — output is structured data or reports
- The operation runs as a scheduled job or CI/CD step
- You need unlimited execution time (no serverless timeouts)

Prefer Web App for everything else — the [[concept-nextjs-stack]] is well-proven and provides better UX for exploratory tasks.
