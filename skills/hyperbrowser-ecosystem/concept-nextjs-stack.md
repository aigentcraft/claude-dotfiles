---
id: concept-nextjs-stack
type: concept
description: "Common tech stack: Next.js + React + TypeScript + Tailwind CSS"
---
# Concept: Next.js Stack

28 of 30 projects share the same tech stack, making it the de facto standard for Hyperbrowser applications.

## Stack Components

| Layer | Technology | Version Range |
|-------|-----------|--------------|
| Framework | Next.js | 14 – 16 |
| UI | React | 18 – 19 |
| Language | TypeScript | 5.x |
| Styling | Tailwind CSS | 3.x – 4.x |
| Core | @hyperbrowser/sdk | 0.49 – 0.83 |

Additional libraries commonly used:
- **AI**: OpenAI SDK, @anthropic-ai/sdk, Together AI
- **Data processing**: Zod (schema validation), Cheerio (HTML parsing), Sharp (images)
- **UI components**: shadcn/ui, Lucide icons, Recharts

## Version Ranges

Most projects use App Router (Next.js 14+). Key differences by Next.js version:
- **Next.js 14**: Most common. Uses `app/` directory, `route.ts` for API routes.
- **Next.js 15**: Some newer projects. Minor API changes.
- **Next.js 16**: Only the newest projects (hypergraph, hyperskills).

## Project Variations

Two projects deviate from the web stack:
- **churnhunter** — CLI tool using Node.js directly with chalk, cli-table3, and yargs. No Next.js or React. See [[concept-cli-vs-webapp]].
- **competitor-tracker** — Includes CLI components alongside the web interface.

When starting a new project, use the latest Next.js version with App Router. The standard project setup:
```bash
npx create-next-app@latest my-project --typescript --tailwind --app --src-dir
cd my-project
npm install @hyperbrowser/sdk
```

All web projects follow [[pattern-nextjs-api-routes]] for their backend logic.
