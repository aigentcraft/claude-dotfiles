---
title: "Discord通知にMarkdown表を生のまま送信 — レンダリングされず読めない（UC）"
type: "user-correction"
tags: ["discord", "notification", "markdown", "report-formatting", "pullie"]
description: "週次/日次レポート（LLM生成Markdown）をnotify.discordへ素通しした結果、Discordは表記法（|---|）をレンダリングしないため生パイプ文字の羅列が届いていた。人間指摘「Discordのところだと表にならないし、見づらい」。修正は送信chokeポイント（notify.discord）での決定論変換 — 数値表は等幅コードブロック整列、文章表は行ごと箇条書き（全文保持）。"
---

## 1. Plan / Context
pullieの週次メディアレポート・X課週次/日次報告はLLMがMarkdownで執筆し、
`workers/shared/notify.discord()` でそのままDiscord embedへ送信していた。
Markdownファイルとしては表が正しい表現（エディタ/GitHubでは読める）。

## 2. Do / The Error
2026-08-31 人間指摘「Discordの報告の通知のところにマークダウン形式か何かの表を
入れてくれるんだけど、Discordのところだと表にならないし、見づらい」。
DiscordはMarkdownのうちbold/italic/コードブロック等の一部のみ対応で、
**表記法（| a | b | / |---|）は非対応** — 生のパイプ文字が改行で潰れて届く。

## 3. Check / Root Cause
1. 出力先の描画能力を確認せず「Markdownで書けばどこでも読める」と暗黙仮定した
2. レポートはLLMが自由記述するため、送信側でフォーマットを保証する層がなかった
   （書き手に「表を使うな」と指示しても、md成果物としては表が最適なので筋が悪い）

## 4. Act / Prevention Rule
- **通知は出力先の描画能力に合わせて送信chokeポイントで変換する**（書き手を縛らない）:
  `notify.md_tables_to_discord()` — 幅60桁以内に収まる表（数値系）は
  East Asian Width考慮の等幅コードブロック整列、収まらない表（文章セル）は
  行ごとの `**先頭列** — ヘッダ: 値 ／ …` 箇条書きで全文保持
- 新しい通知先（Slack等）を足す時も同様に「そのUIで実際にどう見えるか」を
  実物スクショ/実送信で確認してから運用に載せる
- 同族: utc-timestamps-render-as-last-night（生成物は正しいのに表示層で人間に誤って見える）
