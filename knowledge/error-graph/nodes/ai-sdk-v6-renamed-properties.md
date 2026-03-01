---
title: "AI SDK v6 Renamed Properties (maxTokens → maxOutputTokens)"
description: "AI SDK v6 renamed several properties from v5. Using old property names causes TypeScript errors but may still work at runtime, making bugs silent."
type: "technical-error"
tags: ["ai-sdk", "vercel-ai", "typescript", "api-migration"]
relationships:
  caused_by: []
  related_to: []
  fixes_node: []
---

## 1. Plan / Context
Maia.ai で AI SDK v6（`ai@6.0.94`）を使って `streamText()` と `generateText()` を呼び出す API エンドポイントを実装していた。

## 2. Do / The Error
```
error TS2353: Object literal may only specify known properties,
and 'maxTokens' does not exist in type 'CallSettings & ...'
```
`streamText()` および `generateText()` の呼び出しで `maxTokens` プロパティが型エラーになった。

## 3. Check / Root Cause
AI SDK v6 で以下のプロパティ名が変更された:
- `maxTokens` → `maxOutputTokens`
- `body` オプション（useChat）の仕様変更

ランタイムではエラーにならないが（プロパティは単に無視される可能性がある）、TypeScript の型チェックでは検出される。既存コード（`chat+api.ts`）で `maxTokens` を使っていたが、TypeScript チェックを頻繁に実行していなかったため見逃されていた。

## 4. Act / Prevention Strategy (Fix)

### 修正
```typescript
// Before (v5 style)
streamText({ model, system, messages, maxTokens: 1024 })

// After (v6 style)
streamText({ model, system, messages, maxOutputTokens: 1024 })
```

### 予防策
- **AI SDK のメジャーバージョンアップ時は、changelog で renamed properties を必ず確認する**
- `npx tsc --noEmit` を新しいファイル作成後に都度実行して、型エラーを早期検出する
- AI SDK v6 の主な変更点:
  - `maxTokens` → `maxOutputTokens`
  - `useChat` の `body` オプションの型変更
  - `UIMessage` の `content` → `parts` 配列（`getMessageText()` を使用）
  - `sendMessage({ text })` 形式（v5 の `{ role, content }` ではない）
