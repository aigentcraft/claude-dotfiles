---
title: "Supabase v2 TypeScript Types Resolve to `never` for Ungenerated Schemas"
description: "When using @supabase/supabase-js v2 with a manually defined Database type that lacks proper Insert/Update row types, all .insert() and .update() calls resolve to `never`, causing TypeScript errors."
tags: ["supabase", "typescript", "database", "type-safety"]
relationships:
  caused_by: []
  related_to: ["ai-context-blindness-at-scale"]
  fixes_node: []
---

## 1. Plan / Context
Maia.ai プロジェクトで Supabase v2 の `@supabase/supabase-js` を使い、`chat_sessions`、`messages`、`user_insights` テーブルへの CRUD 操作を実装しようとした。

## 2. Do / The Error
```
error TS2769: No overload matches this call.
  Overload 1 of 2: Argument of type '{ user_id: string; framework_type: FrameworkType; }'
  is not assignable to parameter of type 'never'.
```
`.insert()`, `.update()`, `.select()` の全操作で戻り値の型が `never` に解決され、TypeScript が全フィールドアクセスを拒否。

## 3. Check / Root Cause
`lib/types/database.ts` で `Database` 型を手動定義していたが、Supabase v2 の型システムが期待する **`Insert`・`Update`・`Row`** 型定義が不完全だった。Supabase CLI の `supabase gen types typescript` で自動生成していないため、内部の型解決が `never` にフォールバックした。

## 4. Act / Prevention Strategy (Fix)

### 即時対処（今回採用）
型アサーション `as any` を使用して回避:
```typescript
// Insert
await supabase.from('chat_sessions').insert({ ... } as any)

// Update（チェーン全体をキャスト）
await (supabase.from('chat_sessions') as any).update({ ... }).eq('id', id)

// Select（戻り値をキャスト）
return (data ?? []) as unknown as ChatSession[];
```

### 恒久対策（将来）
- `supabase gen types typescript --project-id <id> > lib/types/database.ts` で自動生成する
- または `Database` 型に `Insert`/`Update` 型を明示的に定義する
- 自動生成すれば `as any` は不要になる

### 予防策
- **Supabase プロジェクトで手動型定義を使う場合、必ず Insert/Update/Row の3つを定義する**
- 可能な限り `supabase gen types` による自動生成を優先する
