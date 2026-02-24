---
name: hyperbrowser-reference
description: Contextual knowledge base and reference guide using the hyperbrowser-app-examples repository for building AI agents, web scrapers, and Next.js applications with Hyperbrowser SDK and Serper API.
---

# Hyperbrowser Reference Skill

This skill provides access to a comprehensive repository of production-ready web applications built using the Hyperbrowser SDK, Serper API, and OpenAI. It acts as a knowledge management system to surface best practices, code patterns, and UI/UX implementations for AI-driven applications.

## Location
The example repository is permanently stored at:
`c:\Users\user\.gemini\antigravity\skills\skill-hyperbrowser-reference\repo\`

## When to Use This Skill
You MUST consult this skill whenever the user asks you to:
- Build an AI agent that searches the web or scrapes data.
- Integrate the `Hyperbrowser SDK` or `Serper API`.
- Build a Next.js application involving AI generation or extraction (e.g., job matchers, reddit researchers, podcast generators).
- Implement batch web scraping or parallel processing workflows.

## How to Search the Knowledge Base
Do not guess how to implement Hyperbrowser or Serper API functionality. First, search this repository for relevant examples.

1. **List available examples:** Use the `list_dir` tool on the `repo/` directory to see all available applications.
2. **Find specific implementations:** Use the `find_by_name` tool or `grep_search` to locate specific configurations or code logic.
   - Example to find scraping logic: `grep_search` for `"@hyperbrowser/sdk"` or `"client.scrape"` in the `repo/` directory.
   - Example to find search logic: `grep_search` for `"serper"` or `"https://google.serper.dev/search"` in the `repo/` directory.
3. **Review project structure:** Once you find a relevant example (e.g., `skills-generator` or `deep-reddit-researcher`), use `list_dir` to understand its architecture (usually Next.js app router structure under `/app`, components under `/components`, and API integrations under `/lib`).
4. **Adapt and Apply:** Read the specific files (e.g., `lib/hyperbrowser.ts`, `lib/openai.ts`) using `view_file` to understand the exact implementation patterns. Adapt these patterns to the user's specific request.

## Key Concepts and Patterns to Look For
- **Single Page vs. Batch Scraping:** Look for `client.scrape.startAndWait` for single URLs and `client.scrape.batch.startAndWait` for multiple URLs.
- **Markdown Extraction:** Note the use of `scrapeOptions: { formats: ["markdown"], onlyMainContent: true }` to extract clean text suitable for LLMs.
- **Next.js API Routes:** Examples often use serverless API routes (`app/api/...`) to handle the heavy lifting of searching, scraping, and prompting.
- **UI Components:** Look into the `components/` directory of examples for modern, responsive UI patterns (often using Tailwind CSS and Lucide React).

## Example Query
If the user asks: "How do I use Hyperbrowser to scrape multiple pages at once?"
Your immediate action should be:
1. `grep_search` for `"client.scrape.batch"` in `c:\Users\user\.gemini\antigravity\skills\skill-hyperbrowser-reference\repo\`.
2. Review the resulting code snippets to provide a precise, contextually optimized answer.
