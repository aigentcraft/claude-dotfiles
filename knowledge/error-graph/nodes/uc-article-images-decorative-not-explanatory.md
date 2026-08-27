---
title: "UC: Article Images Were Low-Quality Decoration, Not Reader-Helping Visuals"
description: "User reviewed weevee's first articles: 'どれも挿入されている画像のクオリティが低い'. Images were generic illustrations with excessive whitespace, placed only where the writer left a marker, not per heading, and how-to steps had no screenshots. Required: one purposeful visual per heading; for setup/operation steps use real screenshots edited (zoom, click markers) via Codex + GPT Image; specify proper image sizes; no wasted margins."
type: "user-correction"
tags: ["user-correction", "images", "content-quality", "screenshots", "image-pipeline", "weevee"]
---

## 1. Plan / Context
weevee の 05_generate_images は writer が置いた `<!-- 図解: … -->` マーカーの箇所だけに designer プロンプト → Gemini 画像生成で図解を入れていた。実測スクショの取り込みは「Phase 1 で追加」として未実装。

## 2. Do / The Error（ユーザー指摘 2026-08-27）
- 「どれも挿入されている画像のクオリティが低い」「変に余白が多すぎたりしてクオリティが低い」
- 要求: **読者が内容を理解するのに役立つ視覚情報**を **見出し一つごとに**挿入する。構築/操作手順は**実スクショ**を使い、該当部分の**拡大**・クリック箇所の**マーカー**などの加工を GPT Image に依頼して挿入する。**適切な画像サイズを指定**する
- 生成手段の指定: Codex を起動して GPT Image 2 で生成・加工する

## 3. Check / Root Cause
1. **画像の役割定義が無かった** — 「マーカーがあれば図解を入れる」という供給側都合で、「この見出しを読む読者に何を見せれば理解が進むか」という読者側の目的が設計に無い
2. **配置単位が見出しでなく writer の裁量** — 図解の有無・数が記事ごとにばらつく
3. **手順記事に実物が無い** — スクショ取得経路（ブラウザ/ターミナル）を Phase 1 送りにし、代わりに抽象図解で埋めた。読者にとって「操作手順にスクショが無い」は致命的
4. **サイズ/余白の品質ゲートが無い** — 生成モデル任せで、余白トリミング・アスペクト比・表示幅の仕様が無い。06b の機械プローブは「画像が存在するか」しか見ていない
5. モデル選定が古い前提（Gemini）に固定され、ユーザーが使いたい経路（Codex + GPT Image）を確認していなかった

## 4. Act / Prevention Strategy (Fix)
- **画像仕様を「見出し単位」で機械化**: 05 は H2 ごとに「この節の理解を助ける視覚情報」を designer に企画させ（種別: 実スクショ加工 / 構造図 / 比較図 / フロー図）、1見出し1画像を必須にする（不要と判断した見出しは理由を記録）
- **手順系はスクショ必須**: researcher ラボで対象 UI/ターミナルを撮影（Playwright / ターミナル出力の画像化）→ GPT Image の編集で「該当部分の拡大・クリック箇所のマーカー・番号」を付ける
- **サイズ仕様を固定**: 生成は 3:2（1536×1024）基準・本文表示幅に合わせ最大 1200px・余白自動トリミング（決定論・PIL）・アスペクト比外/余白率高は不合格として再生成
- **生成経路**: Codex CLI + GPT Image（imagegen MCP）。モデル名・課金有無は導入前に確認する（課金禁止ルールとの整合）
- **予防ルール: 画像は「装飾」ではなく「読者の理解を進める情報」。企画時に『この画像が無いと読者は何が分からないか』に答えられない画像は入れない**
- 関連: [[uc-inspection-must-match-reader-conditions]]・[[image-dark-canvas-margin-passes-vision-review]]・[[uc-site-design-direction-before-content]]
