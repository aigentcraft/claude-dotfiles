# UC: claude/ブランチで作ったナレッジがmasterに届かず他端末・antigravityに伝播しない

## Type
User Correction — `uc-knowledge-branch-isolation`
**Date**: 2026-02-28
**Cluster**: `ai-behavior`

---

## ユーザーの指摘

> いちいちメインにマージしないと、他の端末やantigravityにナレッジが共有されないのも大きな問題

---

## 何が起きているか

| レイヤー | 問題 |
|---|---|
| ブランチ制約 | Web/スマホセッションでは `claude/` ブランチへしか push できない（サーバー側で403強制） |
| 同期の期待 | `scripts/sync.sh pull` / `session-start.sh` / antigravity同期 は全て `master` を参照 |
| 結果 | `claude/` ブランチのナレッジ変更は PR マージまで他端末・antigravity に届かない |

---

## 根本原因

**2つの要件が矛盾している**:

```
要件A: Web Claude Code は claude/ ブランチにしか push できない（サーバー制約）
要件B: 知識の伝播は master ブランチを前提に設計されている
```

これは「1ブランチ = 1セッション」という git ブランチ運用と、「master = 正規の知識ベース」という知識同期設計が噛み合っていない構造的問題。

---

## 影響範囲

- Windows / Mac からセッション開始時に最新ナレッジを読めない
- antigravity への知識伝播が止まる
- エラーノードを作っても「セッション内の局所メモリ」で終わってしまう

これはR6（知識と適用の分離）・R9（局所実装の横展開欠如）と同種の問題を **インフラレベル** で再現している。

---

## 解決策（候補）

### A: GitHub Actions で claude/ブランチのナレッジを master に自動マージ
```yaml
# claude-dotfiles に追加するワークフロー
on:
  push:
    branches: ['claude/**']
    paths: ['knowledge/**', 'CLAUDE.md', 'GRAPH_RAG.md']
# → knowledge/ のみ触った場合は master に自動マージ
```
- **長所**: 完全自動。手作業ゼロ
- **短所**: ワークフロー追加が必要。コード変更も混入していた場合の判定が必要

### B: sync.sh に「最新 claude/ ブランチも pull する」ロジックを追加
```bash
# fetch して最新の claude/ ブランチの knowledge/ を cherry-pick
git fetch origin 'refs/heads/claude/*:refs/remotes/origin/claude/*'
# 最新ブランチから knowledge/ だけを取り込む
```
- **長所**: ワークフロー不要
- **短所**: 複数ブランチが存在した場合の競合リスク

### C: ナレッジを `.claude-knowledge-staging/` 経由で別途 push（現行の staging システムを活用）
- claude-dotfiles repo 内のナレッジも、staging 経由で master に入れる二重経路を持つ
- **長所**: 既存の仕組みを使う
- **短所**: 二重管理が煩雑

### **推奨: A（Actions自動マージ）**
- `paths` フィルタで `knowledge/**` のみ対象にする
- コード変更は通常の PR フローを維持
- ナレッジのみ master への自動マージを許可

---

## 予防ルール

- **Web/スマホセッションでナレッジを変更したら**: 自動マージ対応が完了するまでの暫定対応として、PRを即時作成してmergeする（放置しない）
- **インフラ設計時**: 「このフローはWeb（claude/ブランチ制約あり）でも動くか？」を常にチェックする

---

## 関連ノード

- `uc-session-promise-vs-system.md` — 知識は構造に埋め込まれないと消える
- `uc-local-pattern-no-generalization.md` — staging系とbranch系で設計が噛み合っていない構造問題
