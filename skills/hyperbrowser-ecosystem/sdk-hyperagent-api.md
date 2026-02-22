---
id: sdk-hyperagent-api
type: concept
description: "hb.agents.hyperAgent — autonomous agent that executes natural language tasks on the web"
---
# SDK: HyperAgent API

The HyperAgent API is the highest-level abstraction in the Hyperbrowser SDK. Instead of specifying what to scrape or where to navigate, you describe a **task** in natural language and the agent autonomously navigates, clicks, fills forms, and extracts information. Two variants exist: `hyperAgent` (general autonomous agent) and `browserUse` (browser-specific automation).

## Signature

```typescript
// HyperAgent variant
const result = await hb.agents.hyperAgent.startAndWait({
  task: string,        // Natural language task description
  maxSteps?: number,   // Maximum agent actions (default varies)
  sessionOptions?: {
    acceptCookies?: boolean,
    useStealth?: boolean,
  }
});
// Returns: { data: { finalResult?: string } }

// BrowserUse variant
const result = await hb.agents.browserUse.startAndWait({
  task: string,
  sessionId?: string,  // Optional: reuse an existing session
});
```

## Variants

| Variant | Used By | When to Use |
|---------|---------|-------------|
| `agents.hyperAgent` | churnhunter | Autonomous multi-step tasks with action limits |
| `agents.browserUse` | hb-pitchdeck, hb-ui-bot-app | Browser-specific tasks, can attach to existing sessions |

## Examples

**Autonomous signup flow analysis** (from `churnhunter/churnhunter.ts`):
```typescript
const task = `Navigate to ${url} and complete a typical user signup or demo flow.
Take actions like a new user would: look for signup buttons, fill forms,
navigate through onboarding steps, and explore key features.
Pay attention to any friction points, confusing UI elements,
slow loading times, or steps that might cause user drop-off.`;

const result = await this.hbClient.agents.hyperAgent.startAndWait({
  task: task,
  maxSteps: 20,
  sessionOptions: {
    acceptCookies: true,
  }
});
```

**Browser-based content extraction** (from `hb-pitchdeck/app/api/pitchdeck/route.ts`):
```typescript
const result = await hyperbrowser.agents.browserUse.startAndWait({
  task: `Visit ${url} and extract the page title and main content.`,
  sessionId: session.id,
});
```

**UI/UX analysis** (from `hb-ui-bot-app/app/api/analyze/route.ts`):
```typescript
const result = await hbClient.agents.browserUse.startAndWait({
  task: `Go to ${url} and analyze the UI/UX to identify why users might leave.
  Focus on visual analysis and actual observations:
  1. Look at the homepage design and layout
  2. Try clicking on navigation menu items and links
  3. Scroll through the page and observe the visual hierarchy`,
});
```

## Related

- [[ux-analysis-testing]] — the primary cluster using agent APIs
- [[sdk-session-api]] — agents can reuse sessions created via Session API
- [[pattern-puppeteer-session]] — when you need more control than agents provide
- [[concept-session-options]] — agent sessions support the same options
