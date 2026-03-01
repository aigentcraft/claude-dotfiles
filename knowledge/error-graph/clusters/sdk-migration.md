# Cluster: SDK / ライブラリ移行エラー

> Layer 1 Community Summary — SDK・ORM・ライブラリのバージョン移行で発生するエラーの蒸留サマリー。
> 依存パッケージのメジャーアップデート・型定義の変更を伴うタスク時にロードする。

**対象タグ**: `sdk-migration`, `typescript`, `supabase`, `ai-sdk`, `type-safety`, `api-migration`

---

## 蒸留ルール（Distilled Rules）

### R1: 手動型定義は必ず Insert/Update/Row の3型を揃える
ORMが期待する型構造が不完全だと、全操作が `never` に解決される。
- **対策**: 可能な限り CLI による自動生成（`supabase gen types`）を使う
- **禁止**: Row 型だけ定義して Insert/Update を省略すること
- **参照**: [[nodes/supabase-v2-types-resolve-never.md]]

### R2: メジャーバージョンアップ時は renamed properties を確認
プロパティ名の変更はランタイムではエラーにならず（無視される）、TypeScript でのみ検出される。
- **対策**: changelog の "Breaking Changes" セクションを必ず読む。`npx tsc --noEmit` で型チェック
- **典型例**: AI SDK v6 の `maxTokens` → `maxOutputTokens`
- **参照**: [[nodes/ai-sdk-v6-renamed-properties.md]]

---

## 所属ノード（2件）

| ノード | 概要 |
|---|---|
| [[nodes/supabase-v2-types-resolve-never.md]] | Supabase v2 で型が `never` に解決される |
| [[nodes/ai-sdk-v6-renamed-properties.md]] | AI SDK v6 のプロパティ名変更 |

---

*Last updated: 2026-03-01 | Node count: 2*
