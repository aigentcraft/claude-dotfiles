---
id: pattern-code-generation
type: pattern
description: "Web analysis → code artifact generation (tests, agents, APIs)"
---
# Pattern: Code Generation

A specialized form of [[pattern-scrape-then-llm]] where the LLM output is executable code rather than natural language. The scraped web content provides context for what code to generate.

## When to Apply

Use this pattern when:
- The user wants to generate code based on a website's structure or API
- You're building tools that produce Playwright tests, agent definitions, or API specs
- The output should be a runnable artifact, not just analysis

## How It Works

```
URL → scrape/crawl → analyze structure → LLM prompt with code examples → generated code
```

The key difference from [[pattern-scrape-then-llm]] is the LLM prompt: it includes code templates/examples and asks for code output rather than prose.

**Agent tool generation** (from `web-to-agent/`):
```typescript
// 1. Scrape the target site
const content = await scrapeUrl(url);

// 2. Analyze with LLM, requesting code output
const prompt = `Based on this website content, generate AI agent tool definitions
that can interact with this site's functionality.

Website content:
${content}

Generate TypeScript tool definitions in this format:
{ name: string, description: string, parameters: ZodSchema, execute: Function }`;

// 3. Stream the generated code back via SSE
sendSSE({ type: 'code', content: generatedCode });
```

**Playwright test generation** (from `flow-mapper/`):
```typescript
// 1. Crawl site to map navigation flows
// 2. Generate flow diagram from discovered paths
// 3. Generate Playwright test code for each flow
const testCode = await generatePlaywrightTests(flowMap);
```

## What Breaks It

- **Hallucinated APIs**: The LLM may generate code that calls APIs or uses selectors that don't exist. Always validate generated code.
- **Framework mismatch**: Generated code may use wrong framework version syntax. Specify versions in the prompt.
- **Over-complex output**: LLMs tend to generate over-engineered code. Constrain with explicit templates.

## Reference Projects

| Project | Generated Artifact |
|---------|-------------------|
| `web-to-agent/` | AI agent tool definitions |
| `flow-mapper/` | Playwright test scripts |
| `scrape-to-api/` | Postman collections from discovered APIs |
| `hyperskills/` | SKILL.md files |
| `skills-generator/` | SKILL.md files |
