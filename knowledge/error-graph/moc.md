# PDCA Error Knowledge Graph: Map of Content (MOC)

## エントリーポイント（セッション開始時はここだけ読む）

1. **[[relationships.md]]** — アクション種別→思考パターンフラグのトラバーサルグラフ。**実行前に辿る**
2. **[[clusters/]]** — カテゴリ別サマリー（各クラスターに Quick Rules あり）
3. 以下のノード索引は**検索・参照用**。全件読み込みは不要

*Related*: [[../skills-moc.md|Skills MOC]] | [[../skills-graph/relationships.md|Skills Complement Graph]]

---

## トラバーサルプロトコル（全件読みではなく辿る）

```
アクションを実行しようとしている
    │
    ▼
relationships.md で「アクション種別」を特定
    │
    ▼
対応する「思考パターンフラグ」をロード
    │
    ▼
フラグの参照先ノードを必要に応じて読む
    │
    ▼
フラグの「正しい考え方」を適用して実行
```

> 設計思想: 「全ノードを読んでから考える」のは通常RAG。
> GraphRAG は「状況→エッジ→必要なノードだけに到達する」。

---

## ノード索引（検索・参照用 — 全件読み込み不要）

### System Architecture & Configuration
- [[nodes/ai-instruction-enforcement.md]] - AI Instruction Adherence & Checkpoint Enforcement
- [[nodes/semantic-graph-relationships.md]] - Semantic Graph Relationships vs Untyped Links
- [[nodes/ai-context-blindness-at-scale.md]] - AI Context Window Blindness at Scale

### Shell & Hook Environment
- [[nodes/claude-hook-env-project-dir.md]] - Claude Hook ENV: CLAUDE_PROJECT_DIR の取得方法

### API & Network
- [[nodes/api-rate-limit-exceeded.md]] - Mock Test: API Rate Limit Exceeded
- [[nodes/slack-api-silent-hang.md]] - Slack API postMessage Silent Hang

### Database & ORM
- [[nodes/supabase-v2-types-resolve-never.md]] - Supabase v2 TypeScript types resolve to `never`

### Programming & Syntax
- [[nodes/powershell-hash-literal-git.md]] - PowerShell Hash Table Literal parsing in Git commands

### SDK & Framework Migration
- [[nodes/ai-sdk-v6-renamed-properties.md]] - AI SDK v6 renamed properties (maxTokens → maxOutputTokens)

### Copywriting & Content
- [[nodes/copywriting-indirect-motivation.md]] - Indirect Motivation (Self-Determination x Future Pacing)

### User Correction (UC) — AI行動パターンの失敗
- [[nodes/uc-abstract-knowledge-label.md]] - 抽象ラベルでナレッジ設計を提案
- [[nodes/uc-knowledge-branch-isolation.md]] - claude/ブランチのナレッジがmasterに届かない
- [[nodes/uc-local-pattern-no-generalization.md]] - パターンの局所実装、横展開なし
- [[nodes/uc-partial-solution-without-automation-path.md]] - 自動化要求に手動対応で終了
- [[nodes/uc-repeat-master-push-despite-known-403.md]] - 既知の403制約を無視してpush
- [[nodes/uc-session-promise-vs-system.md]] - セッション宣言をシステム化せず忘却

---
*Note: 新ノード作成時は必ずここに wikilink を追加すること（`scripts/validate-knowledge.sh` がpush前に検証）*
