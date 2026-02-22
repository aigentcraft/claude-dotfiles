---
id: gotcha-sdk-version-drift
type: gotcha
description: "SDK version differences (0.49-0.83) across projects cause API incompatibilities"
---
# Gotcha: SDK Version Drift

## Why the Mistake

The 30 example projects were created over time and each pins a different version of `@hyperbrowser/sdk`. Copying code from one project to another without checking SDK versions can lead to runtime errors from changed APIs.

## Correct Mental Model

The SDK versions across the ecosystem span a wide range:

| Version Range | Projects | Notable APIs |
|--------------|----------|--------------|
| `^0.49.0 - ^0.51.0` | documentation-buddy, hb-job-matcher, Idea-generator-reddit, podcast-generator-ai, deep-crawler-bot, flow-mapper, yc-research-bot, competitor-tracker, openai-source-forge, scrape-to-api | Oldest API surface |
| `^0.53.0 - ^0.59.0` | assets-optimizer, churnhunter, deep-job-researcher, deep-reddit-researcher, hb-pitchdeck, hb-ui-bot-app, hyperdatalab, web-to-agent, universal-chatbot | Middle era |
| `^0.60.0 - ^0.74.0` | mediresearch, sora-research, hyperbuild, hypervision | Agent APIs stabilized |
| `^0.78.0 - ^0.83.3` | hyper-research, hyperpages, hyperskills, skills-generator, hypergraph | Latest APIs, import style may differ |
| `latest` | site-to-dataset | Always latest (risky) |

## How to Detect

- `TypeError: hb.scrape.startAndWait is not a function` → SDK version too old for this API
- Different import styles: `import Hyperbrowser from "@hyperbrowser/sdk"` (default) vs `import { Hyperbrowser } from "@hyperbrowser/sdk"` (named)
- Agent APIs (`hb.agents.hyperAgent`, `hb.agents.browserUse`) may not exist in versions < 0.54

## How to Fix

1. **Check the source project's `package.json`** before copying code:
```bash
grep "@hyperbrowser/sdk" ~/hyperbrowser-app-examples/{project}/package.json
```

2. **Pin to the latest stable version** for new projects:
```bash
npm install @hyperbrowser/sdk@latest
```

3. **Watch for import style differences**:
```typescript
// Older projects (default export):
import Hyperbrowser from "@hyperbrowser/sdk";

// Some newer projects (named export):
import { Hyperbrowser } from "@hyperbrowser/sdk";
```

4. **When mixing code from different projects**, always test the specific API calls you're using against the SDK version you've installed.
