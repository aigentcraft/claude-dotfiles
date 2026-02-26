---
title: "Skills Knowledge Graph (MOC)"
description: "Central index mapping all installed Antigravity Skills. AIはスキル使用前に skills-graph/relationships.md も参照すること。"
tags: ["skills", "moc", "system-components"]
relationships:
  related_to: ["[[error-graph/moc.md]]", "[[skills-graph/relationships.md]]"]
---

# Skills Knowledge Graph (MOC)

## AIへの必須手順

1. タスクに合うスキルをこの MOC で特定する
2. **[[skills-graph/relationships.md]] を読んで補完スキルを確認する**
3. 補完スキルを基準に従って読み込む
4. 複数スキルを統合してアウトプットを生成する

> 1スキル発見→即実行は禁止。必ずグラフを確認すること。

---

## Core Configuration Skills
- [[../skills/auto-sync-rule/SKILL.md|auto-sync-rule]] : Enforces global synchronization rules.
- [[../skills/skill-installer/SKILL.md|skill-installer]] : Auto-searches and installs skills from GitHub.

## Knowledge & Debugging
- [[../skills/skill-pdca-error-graph/SKILL.md|skill-pdca-error-graph]] : The self-correction engine powering the error graph.
- [[../skills/skill-project-map/SKILL.md|skill-project-map]] : Maintains PROJECT_MAP.md for AI context awareness at scale.
  - 補完: `skill-pdca-error-graph`

## Development & Operations
- [[../skills/slack-remote-run/SKILL.md|slack-remote-run]] : Remote command execution proxy.
- [[../skills/skill-hyperbrowser-reference/SKILL.md|skill-hyperbrowser-reference]] : Reference for scraping and Next.js applications.
  - 補完: `skill-project-map`

## Copywriting & SNS
- [[../skills/copywriting/SKILL.md|copywriting]] : Marketing copy for web pages.
- [[../skills/x-viral-writing/SKILL.md|x-viral-writing]] : X(Twitter) viral posts and threads.
  - 補完: `x-image-prompt`, `copywriting`
- [[../skills/ai-social-media-content/SKILL.md|ai-social-media-content]] : AI-powered content for TikTok, Instagram, YouTube, X.
  - 補完: `x-viral-writing`, `x-image-prompt`

## Image Generation
- [[../skills/nanobanana/SKILL.md|nanobanana]] : Gemini image generation (Nano Banana Pro).
  - 補完: `nano-banana-pro-prompts-recommend-skill`
- [[../skills/gpt-image-1-5/SKILL.md|gpt-image-1-5]] : OpenAI GPT Image 1.5 generation & editing.
  - 補完: `nano-banana-pro-prompts-recommend-skill`
- [[../skills/nano-banana-pro-prompts-recommend-skill/SKILL.md|nano-banana-pro-prompts-recommend-skill]] : Recommends from 6000+ image prompts.
  - 補完: `nanobanana`
- [[../skills/x-image-prompt/SKILL.md|x-image-prompt]] : X post eye-catch image prompt generator.
  - 補完: `nanobanana`, `nano-banana-pro-prompts-recommend-skill`

---

**Graph Connections:**
[[skills-graph/relationships.md|Skills Complement Graph（補完関係の詳細）]]
[[error-graph/moc.md|Error PDCA MOC（失敗の知識）]]
