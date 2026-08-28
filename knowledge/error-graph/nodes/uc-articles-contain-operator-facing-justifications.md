---
title: "UC: Articles Explained to the Operator Why Measurements Could Not Be Done (Report Tone in Public Content)"
description: "User: '検証ができなかった理由を私向けに書いてあるものがあるが、私への報告書ではなく公に向けた記事なので不適切'. Writers copied factsheet justifications ('本ラボでは外部サインアップが禁止されているため', 'ラボの許可コマンド外', 'ダウンロード予算の制約', '検証環境側の制約') into public articles. Root cause: the factsheet is an internal report, the writer treated it as source text, and no check distinguished internal vocabulary from reader-facing prose. Fix: writer rule to state unmeasured scope in neutral reader terms, deterministic MC05 check for internal vocabulary, and the AI-authored banner moved from every article to the about page (MC06 forbids in-body AI notes)."
type: "user-correction"
tags: ["user-correction", "editorial", "tone", "internal-leak", "compliance", "weevee"]
---

## 1. Plan / Context
researcher の factsheet には「なぜ実測できなかったか」（禁止事項・予算・許可コマンド）を正直に書かせている。writer は factsheet を唯一の事実源として書く。

## 2. Do / The Error（ユーザー指摘 2026-08-29）
- 「どの記事にも、AIエージェントが書きましたというのが冒頭にあるから消して」
- 「検証ができなかった理由を私向けに書いてあるものがあるが、私への報告書ではなく公に向けた記事なので不適切」
- 実物: 「本ラボでは外部サインアップが禁止されているため、この手順は実演していません」「`nvidia-smi` はラボの許可コマンド外のため実行できず」「ダウンロード予算（合計 3GB 以内）の制約で本ラボでは実行しておらず」「今回のラボの制約（ログイン操作を伴う検証の禁止）では確認できていません」

## 3. Check / Root Cause
1. **内部報告書（factsheet）を読者向け文章の素材にするとき、語彙の翻訳工程が無かった** — 「禁止」「予算」「ラボ」「許可コマンド」は運営者にしか意味がない
2. writer の「実測ログにない体験を書かない」規則が「なぜ無いかを説明せよ」と誤って作用し、弁明が増えた
3. AI 執筆表示は「ASP の表示要件の先回り」として記事冒頭に機械挿入していたが、読者体験として不要と人間が判断（表示義務はサイト単位で満たす）

## 4. Act / Prevention Strategy (Fix)
- writer agent.md / 04: 運営側の事情（ラボ・禁止・許可コマンド・予算・方針・researcher/ファクトシート/検閲）を書かない。未実施は読者向けの中立な一文（「本記事では実際のアカウント登録・利用は行っていません。公式サイトの記載（確認日付き）に基づきます」）に置換。理由の弁明はしない
- 06_review: **MC05**（内部語の決定論検出 → C 系不合格）/ **MC06**（本文の「AI が書いた」断り）。checklist C02 は「運営者情報ページで明示・本文には書かない」に、C11 を追加
- ArticleLayout の ai-notice を撤去（PR 表記は維持）、運営者情報ページに明示を移動。06b の必須ブロック検査から ai-notice を外す
- **予防ルール: 内部文書（factsheet・検閲コメント・E01）を素材にする工程では「読者に無関係な語彙」を機械で検出する。正直さは「何をしたか/していないか」で示し、「なぜできなかったか（運営事情）」は書かない**
- 関連: [[uc-articles-too-advanced-for-beginner-readers]] [[reviewer-flagged-machine-rendered-log-image-as-fabricated]]
