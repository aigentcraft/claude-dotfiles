---
id: concept-ai-provider-choices
type: concept
description: "AI provider choices: OpenAI GPT-4, Anthropic Claude, Together AI"
---
# Concept: AI Provider Choices

Most projects combine Hyperbrowser (for web data) with an AI provider (for analysis). The choice of provider affects API keys needed ([[gotcha-api-key-management]]), cost, and capabilities.

## Provider Landscape

| Provider | Model | Env Variable | Package |
|----------|-------|-------------|---------|
| OpenAI | GPT-4, GPT-4o, GPT-4o-mini | `OPENAI_API_KEY` | `openai` |
| Anthropic | Claude Opus, Sonnet | `ANTHROPIC_API_KEY` | `@anthropic-ai/sdk` |
| Together AI | Various open models | `TOGETHER_AI_API_KEY` | `together-ai` |

## Project Usage Map

**OpenAI (majority)**:
- churnhunter, deep-reddit-researcher, deep-job-researcher, hb-job-matcher
- yc-research-bot, openai-source-forge, mediresearch, sora-research
- hyperpages, hb-pitchdeck, podcast-generator-ai
- hb-ui-bot-app, flow-mapper, hyperdatalab
- hyperbuild, hypergraph, hyperskills, skills-generator

**Anthropic**:
- hyper-research (Claude as primary analysis engine)

**Together AI**:
- web-to-agent (for open model code generation)

**No AI provider** (scrape only):
- assets-optimizer, competitor-tracker (monitoring only)

## Selection Criteria

| Criterion | OpenAI | Anthropic | Together AI |
|-----------|--------|-----------|-------------|
| Best for | General analysis, vision | Long-context analysis, reasoning | Cost-effective, open models |
| Vision | GPT-4V for screenshots | Claude Vision | Limited |
| Context | 128K tokens | 200K tokens | Varies by model |
| Cost | Medium-High | Medium-High | Low |
| Streaming | Supported | Supported | Supported |

When building new projects, default to the provider the user already has keys for. If starting fresh, OpenAI is the safest choice given the ecosystem's overwhelming preference.
