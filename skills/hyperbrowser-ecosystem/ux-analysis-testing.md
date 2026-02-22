---
id: ux-analysis-testing
type: moc
description: "UX analysis & testing automation projects (3): hb-ui-bot-app, churnhunter, flow-mapper"
---
# UX Analysis & Testing

Three projects that use browser automation to analyze and test web user experiences. These are the most agent-heavy projects, making heavy use of [[sdk-hyperagent-api]] to simulate real user behavior.

## Projects

### hb-ui-bot-app
- **Path**: `~/hyperbrowser-app-examples/hb-ui-bot-app/`
- **What it does**: Uses the browserUse agent to navigate a website, take screenshots, and provide AI-powered UI/UX analysis.
- **SDK APIs**: [[sdk-hyperagent-api]] (`agents.browserUse`)
- **Key patterns**: [[pattern-scrape-then-llm]], [[concept-scrape-formats]] (screenshot analysis)
- **Use when**: You need automated UI/UX audit with visual analysis.

### churnhunter
- **Path**: `~/hyperbrowser-app-examples/churnhunter/`
- **What it does**: CLI tool that uses HyperAgent to simulate a signup flow, then analyzes friction points that cause user churn.
- **SDK APIs**: [[sdk-hyperagent-api]] (`agents.hyperAgent` with `maxSteps: 20`)
- **Key patterns**: [[pattern-puppeteer-session]], [[concept-cli-vs-webapp]] (CLI tool)
- **Use when**: You need to analyze signup/onboarding flow friction from a user's perspective.

### flow-mapper
- **Path**: `~/hyperbrowser-app-examples/flow-mapper/`
- **What it does**: Crawls a site to map user flows, generates flow diagrams, and auto-generates Playwright test code.
- **SDK APIs**: [[sdk-session-api]] (Puppeteer with stealth + proxy)
- **Key patterns**: [[pattern-puppeteer-session]], [[pattern-code-generation]] (Playwright tests), [[pattern-sse-streaming]]
- **Use when**: You need to map site navigation flows and generate automated test scripts.

## Common Patterns

These projects need **interactive** browser access — they can't just scrape static content. The hb-ui-bot-app and churnhunter both use [[sdk-hyperagent-api]] to autonomously navigate sites like a real user would. Churnhunter is one of only two CLI tools in the ecosystem (see [[concept-cli-vs-webapp]]), using chalk + cli-table3 for terminal output instead of a web UI. Flow-mapper uses [[sdk-session-api]] directly because it needs fine-grained control over page navigation to build accurate flow maps. All three feed their observations into LLMs for analysis, following [[pattern-scrape-then-llm]] at the macro level.

## When to Use

Choose this cluster when the user wants to **evaluate, test, or understand** how a website works from a user experience perspective. If they just want content from the site, see [[scraping-data-extraction]]. If they want to build an agent that does tasks (not analysis), see [[agent-developer-tools]].
