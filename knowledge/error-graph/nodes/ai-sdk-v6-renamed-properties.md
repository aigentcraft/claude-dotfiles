---
title: "AI SDK v5→v6: maxTokens Renamed to maxOutputTokens"
description: "AI SDK v5 から v6 へのアップグレードで maxTokens プロパティが maxOutputTokens にリネームされ、旧プロパティ名を使うとランタイムエラーまたは無視される。"
tags: ["ai-sdk", "vercel", "migration", "v6", "maxTokens", "maxOutputTokens"]
---

## 1. Plan / Context
Vercel AI SDK を使ったプロジェクトで v5 から v6 へアップグレードした際に、LLM 呼び出しのオプションが変更されていた。

## 2. Do / The Error
v5 のコードで `maxTokens` を指定していた箇所がそのまま残っており、v6 環境で実行すると期待通りに出力トークン数が制限されない、またはプロパティ不明の型エラーが発生する。

```typescript
// v5 の書き方（v6 では動作しない）
const result = await generateText({
  model: openai('gpt-4o'),
  prompt: 'Hello',
  maxTokens: 1000,  // ← v6 では無効
})
```

TypeScript を使っている場合:
```
Object literal may only specify known properties, and 'maxTokens' does not exist in type 'GenerateTextOptions'.
```

## 3. Check / Root Cause
AI SDK v6 のブレーキングチェンジで `maxTokens` が `maxOutputTokens` にリネームされた。SDK 内部でモデルの入力トークン数（`maxInputTokens`）と出力トークン数（`maxOutputTokens`）を明確に区別するための変更。旧プロパティ名は v6 では型定義から削除されている。

## 4. Act / Prevention Strategy (Fix)
**Fix Applied**: プロパティ名を `maxTokens` → `maxOutputTokens` に変更するだけ。

```typescript
// v6 の書き方
const result = await generateText({
  model: openai('gpt-4o'),
  prompt: 'Hello',
  maxOutputTokens: 1000,  // ← 正しいプロパティ名
})
```

**一括置換コマンド**:
```bash
# プロジェクト全体で置換
find src -name "*.ts" -o -name "*.tsx" | xargs sed -i 's/maxTokens:/maxOutputTokens:/g'
```

**Future AI Instruction**: AI SDK を v5 → v6 にアップグレードする際は `maxTokens` を `maxOutputTokens` にリネームすること。他のリネームも確認するために [AI SDK v6 Migration Guide](https://sdk.vercel.ai/docs/migration-guides) を参照すること。
