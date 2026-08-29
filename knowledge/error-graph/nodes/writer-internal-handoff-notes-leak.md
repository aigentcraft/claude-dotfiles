---
title: "Writer Leaked Internal Handoff Notes into the Public Article Body"
description: "weevee writer repeatedly appended an '**editor-in-chief への申し送り**' paragraph and '<!-- CTA: 案件未アサインのため保留 -->' HTML comments to public drafts (38 such comments were found across published content). Prompt-level prohibitions and the MC05/C11 checks only caught it after the fact, burning 2 of 3 review rounds on article 7. Fix: mechanical strip_internal_notes() in 04 (after CTA injection) and 05 (after hint extraction), keeping only the <!-- 図解: --> hints 05 consumes."
type: "bug"
tags: ["writer", "public-tone", "mechanical-strip", "llm-behavior", "weevee"]
---

## 1. Plan / Context
記事本文は公に向けたもの（人間決定: 運営側の事情・報告書調を書かない）。writer agent.md で禁止し、06 に MC05（内部語）/C11 を置いていた。

## 2. Do / The Error（2026-08-29 記事 7 リライト）
- ラウンド 1・3 で末尾に「**editor-in-chief への申し送り**: 案件未アサインのため {{affil:}} を…」段落と `<!-- CTA: 案件未アサインのため保留 -->` コメントが入り C11/MC05 で差し戻し（3 ラウンド中 2 回）
- 公開済み記事・下書き全体で同種コメントが 38 件（ページソースに残っていた）

## 3. Check / Root Cause
1. LLM は「案件未アサイン」という判断の説明責任を感じ、指示に無くても編集者宛のメモを書く（禁止しても再発）
2. 検査（MC05/C11）は**検出**するだけで、除去は次ラウンドの writer 任せ → ラウンドを消費するだけ
3. HTML コメントは「読者に見えない」と writer が判断し置き続ける（ソースには残る）

## 4. Act / Prevention Strategy (Fix)
- `_lib.strip_internal_notes()`: HTML コメント（許可プレフィックス以外）と、段落先頭が太字の「申し送り／editor-in-chief／編集長へ」で始まる段落を空行まで除去。コードフェンス内は不変。04（CTA 注入後・`図解:` は残す）と 05（ヒント抽出後・全部）で適用
- **予防ルール: LLM の出力に「決して含めてはいけないもの」があるなら、プロンプト禁止 + 検査ではなく、後工程の決定論的除去を置く。検査だけの禁止事項はラウンドを浪費する**
- 関連: [[preview-built-published-md-instead-of-rewrite-draft]] [[reviewer-flagged-machine-rendered-log-image-as-fabricated]]
