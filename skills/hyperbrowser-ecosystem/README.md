# Hyperbrowser Ecosystem Skill Graph

A navigable knowledge graph for the 30 Hyperbrowser example projects.
Entry point: `[[hyperbrowser-ecosystem]]`

## Node Inventory (35 nodes)

| ID | Type | File |
|----|------|------|
| **Root MOC** | | |
| `hyperbrowser-ecosystem` | moc | `hyperbrowser-ecosystem.md` |
| **Category MOCs** | | |
| `scraping-data-extraction` | moc | `scraping-data-extraction.md` |
| `research-intelligence` | moc | `research-intelligence.md` |
| `job-matching` | moc | `job-matching.md` |
| `chatbot-conversational` | moc | `chatbot-conversational.md` |
| `content-generation` | moc | `content-generation.md` |
| `ux-analysis-testing` | moc | `ux-analysis-testing.md` |
| `agent-developer-tools` | moc | `agent-developer-tools.md` |
| **SDK Core Concepts** | | |
| `sdk-scrape-api` | concept | `sdk-scrape-api.md` |
| `sdk-extract-api` | concept | `sdk-extract-api.md` |
| `sdk-session-api` | concept | `sdk-session-api.md` |
| `sdk-crawl-api` | concept | `sdk-crawl-api.md` |
| `sdk-hyperagent-api` | concept | `sdk-hyperagent-api.md` |
| **Patterns** | | |
| `pattern-scrape-then-llm` | pattern | `pattern-scrape-then-llm.md` |
| `pattern-parallel-scraping` | pattern | `pattern-parallel-scraping.md` |
| `pattern-sse-streaming` | pattern | `pattern-sse-streaming.md` |
| `pattern-puppeteer-session` | pattern | `pattern-puppeteer-session.md` |
| `pattern-structured-extraction` | pattern | `pattern-structured-extraction.md` |
| `pattern-multi-url-research` | pattern | `pattern-multi-url-research.md` |
| `pattern-crawl-then-process` | pattern | `pattern-crawl-then-process.md` |
| `pattern-code-generation` | pattern | `pattern-code-generation.md` |
| `pattern-nextjs-api-routes` | pattern | `pattern-nextjs-api-routes.md` |
| `pattern-retry-concurrency` | pattern | `pattern-retry-concurrency.md` |
| **Gotchas** | | |
| `gotcha-concurrency-limits` | gotcha | `gotcha-concurrency-limits.md` |
| `gotcha-stealth-proxy` | gotcha | `gotcha-stealth-proxy.md` |
| `gotcha-content-truncation` | gotcha | `gotcha-content-truncation.md` |
| `gotcha-sdk-version-drift` | gotcha | `gotcha-sdk-version-drift.md` |
| `gotcha-api-key-management` | gotcha | `gotcha-api-key-management.md` |
| **Cross-Cutting Concepts** | | |
| `concept-nextjs-stack` | concept | `concept-nextjs-stack.md` |
| `concept-scrape-formats` | concept | `concept-scrape-formats.md` |
| `concept-session-options` | concept | `concept-session-options.md` |
| `concept-ai-provider-choices` | concept | `concept-ai-provider-choices.md` |
| `concept-data-pipeline` | concept | `concept-data-pipeline.md` |
| `concept-cli-vs-webapp` | concept | `concept-cli-vs-webapp.md` |
| `concept-export-artifacts` | concept | `concept-export-artifacts.md` |

## Maintenance

Run `bash ~/.claude/skills/hyperbrowser-ecosystem/sync-graph.sh` to detect new projects and generate skeleton nodes.
