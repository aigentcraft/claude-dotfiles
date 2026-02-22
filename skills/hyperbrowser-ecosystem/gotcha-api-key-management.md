---
id: gotcha-api-key-management
type: gotcha
description: "Multiple API keys across services require careful .env.local management"
---
# Gotcha: API Key Management

## Why the Mistake

Every project requires a `HYPERBROWSER_API_KEY`, but most also need AI provider keys (OpenAI, Anthropic, Together AI). Developers forget to set up all required keys, or accidentally commit `.env.local` files, or mix up which project needs which keys.

## Correct Mental Model

Typical key requirements by project type:

| Project Type | Required Keys |
|-------------|---------------|
| Scrape-only | `HYPERBROWSER_API_KEY` |
| Scrape + GPT analysis | `HYPERBROWSER_API_KEY` + `OPENAI_API_KEY` |
| Scrape + Claude analysis | `HYPERBROWSER_API_KEY` + `ANTHROPIC_API_KEY` |
| Client-provided keys | None in `.env.local` (keys passed in request body) |

Projects using specific AI providers:
- **OpenAI**: Most projects (GPT-4/4o) — churnhunter, deep-reddit-researcher, yc-research-bot, openai-source-forge, etc.
- **Anthropic**: hyper-research (Claude)
- **Together AI**: web-to-agent
- **Client-provided**: hyper-research also supports user-provided keys in the request body

## How to Detect

- `Error: HYPERBROWSER_API_KEY is not set` or `is not configured` — missing from `.env.local`
- `Error: Incorrect API key provided` — wrong key value
- LLM calls silently failing with "Analysis unavailable" — missing AI provider key
- Project works for scraping but not for analysis — Hyperbrowser key is set but AI key isn't

## How to Fix

1. **Copy the example env file** (most projects include one):
```bash
cp .env.example .env.local
```

2. **Standard `.env.local` template**:
```bash
# Required for all projects
HYPERBROWSER_API_KEY=your_key_here

# Required for most projects (check which AI provider the project uses)
OPENAI_API_KEY=your_key_here
ANTHROPIC_API_KEY=your_key_here

# Optional (only specific projects)
TOGETHER_AI_API_KEY=your_key_here
HYPERBROWSER_MAX_CONCURRENCY=1  # Increase for paid plans
```

3. **Check which keys a project needs** by searching its codebase:
```bash
grep -r "process.env" ~/hyperbrowser-app-examples/{project}/  --include="*.ts" | grep -i "key\|api"
```

4. **Never commit `.env.local`** — it should be in `.gitignore` (all projects include this).

5. **For client-provided key projects** (like hyper-research), the UI provides input fields for API keys, so no server-side `.env.local` is needed for those keys.
