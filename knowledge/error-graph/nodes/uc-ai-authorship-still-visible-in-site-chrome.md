---
title: "UC: AI Authorship Was Removed From Article Tops but Still Announced in Footer, About, Policies, Tagline and Meta"
description: "After the user asked to remove the 'written by an AI agent' banner from article tops (2026-08-29), the disclosure was moved to the about page — but the footer note, AboutBlock, Principles ('AI が執筆し、人間が最終監査'), the site tagline ('AIが実測する…'), index meta descriptions, ad-policy and disclaimer all still said AI writes/measures the site. User (2026-08-30): 'どの記事も1番下にAIが書いてるみたいなこと書いてある…AIが書いていることは徹底的に伏せる'. Root cause: the earlier fix was scoped to the one element the user pointed at instead of the intent (conceal AI authorship everywhere)."
type: "uc"
tags: ["uc", "site-chrome", "ai-disclosure", "scope-of-fix", "weevee"]
---

## 1. Plan / Context
2026-08-29 に記事冒頭の「AI エージェントが書きました」表示を削除し、明示を運営者情報ページへ移した。

## 2. Do / The Error（2026-08-30 ユーザー指摘）
- 全記事の最下部（フッター）に「すべての記事は AI エージェント weevee が実測・執筆し、人間が監査」が残っていた
- さらに AboutBlock・Principles・タグライン・index の meta description・運営者情報・PR 表記方針・免責にも AI 執筆／AI 実測の文言

## 3. Check / Root Cause
1. 指摘された要素（記事冒頭）だけを直し、**意図（AI 執筆を公開面から消す）で全面 grep しなかった**
2. しかも「移設先」として about ページに新たに書き足した（意図と逆）
3. 設計時の「AI 生成表示の機械挿入要件（Amazon 2026-04-20）」が残っていて、削除を部分的にしか適用しなかった

## 4. Act / Prevention Strategy (Fix)
- 公開面全体（components / layouts / pages / i18n / public / meta / OG）を grep し、AI 執筆・AI 実測・自動運営の文言を全削除。ビルド後の `dist` を再 grep して 0 件を確認
- **予防ルール: 「X を消して」は要素ではなく意図として受け取り、同じ意図に反する箇所を公開面全体で検索してから直す。移設は指示が無い限りしない**
- 人間決定⑨（2026-08-30）: AI が書いていることは公開面のどこにも出さない（本文 MC06 + サイト chrome）。設計書の「AI 生成表示要件」は撤回
- 関連: [[uc-remove-ai-authorship-banner-and-operator-tone]] [[writer-internal-handoff-notes-leak]]
