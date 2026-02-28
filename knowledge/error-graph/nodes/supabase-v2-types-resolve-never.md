---
title: "Supabase v2 Manual Database Type Resolves Insert/Update to never"
description: "Supabase v2 の型システムで手動定義した Database 型を使うと、Insert/Update の型が never に解決されテーブル操作が型エラーになる。"
tags: ["supabase", "typescript", "database", "types", "never"]
---

## 1. Plan / Context
Supabase v2 プロジェクトで TypeScript の型安全を確保するため、`Database` 型を手動で定義していた。`Row` のみを定義し、`Insert` と `Update` は省略した。

## 2. Do / The Error
```typescript
// 手動定義（不完全な例）
export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          name: string
        }
        // Insert / Update を省略
      }
    }
  }
}
```
この状態で `supabase.from('profiles').insert(...)` を呼ぶと、`Insert` 型が `never` に解決され、引数の型が `never` となってコンパイルエラーが発生する。

```
Argument of type '{ id: string; name: string; }' is not assignable to parameter of type 'never'.
```

## 3. Check / Root Cause
Supabase v2 の型システムは `Row`・`Insert`・`Update` を明確に区別する。`Tables[T]` の型が `Insert` キーを持たない場合、SDK 内部の型演算が `never` にフォールバックする。`Insert` や `Update` を省略すると「存在しない型 = 何も代入できない = never」として扱われる。

## 4. Act / Prevention Strategy (Fix)
**Fix Applied**: `Insert` と `Update` も明示的に定義した。

```typescript
export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          name: string
        }
        Insert: {
          id?: string
          name: string
        }
        Update: {
          id?: string
          name?: string
        }
      }
    }
  }
}
```

**推奨**: 手動定義はメンテナンスコストが高いため、可能な限り `supabase gen types typescript` で自動生成すること。

```bash
npx supabase gen types typescript --project-id <project-id> > src/types/supabase.ts
```

**Future AI Instruction**: Supabase v2 で `Database` 型を手動定義する場合、必ず `Row`・`Insert`・`Update` の3つすべてを定義すること。`Insert` または `Update` を省略すると SDK の型演算が `never` に解決され、テーブルの書き込み操作が型エラーになる。
