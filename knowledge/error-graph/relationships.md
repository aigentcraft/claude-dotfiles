---
title: "Error Graph: Relationships (Thinking Pattern Flags)"
description: "エラーノード間のエッジ定義。状況 → 関連する思考パターンフラグを辿るための中央グラフ。"
tags: ["error-graph", "graph", "traversal", "thinking-patterns"]
---

# Error Graph: Relationships

## AIへの指示（必読）

エラー発生時・ユーザー指摘時・アクション実行前に、**このファイルを参照してトラバーサルを行うこと**。

### トラバーサルプロトコル

1. **今の状況の「アクション種別」を特定する**（下の種別テーブルを見る）
2. 種別に対応する**思考パターンフラグ**をすべてロードする
3. フラグの「正しい考え方」を適用してから実行する

> ルールを「覚えて適用する」ではなく、**グラフを辿ることで状況に応じたフラグが自動的に浮かび上がる**設計

---

## アクション種別 → 思考パターンフラグ（エッジ）

### 🔴 OUTPUT アクション（push / deploy / send / post）

| フラグ | 参照先 | 意味 |
|---|---|---|
| `exit-condition` | [[nodes/ai-instruction-enforcement.md]] | pushの前に「出口条件」を確認したか？ |
| `known-constraint` | [[nodes/uc-repeat-master-push-despite-known-403.md]] | このセッションで同種の失敗はあったか？ |
| `uc-scan` | moc.md Quick Rule #8 | ユーザー指摘はあったか？UCノードは作成済みか？ |

### 🟡 CREATE アクション（ファイル・ディレクトリ・モジュール作成）

| フラグ | 参照先 | 意味 |
|---|---|---|
| `project-map-first` | [[nodes/ai-context-blindness-at-scale.md]] | PROJECT_MAP.md を先に読んだか？ |
| `no-abstract-label` | [[nodes/uc-abstract-knowledge-label.md]] | 抽象的な名前・説明になっていないか？ |
| `edge-type` | [[nodes/semantic-graph-relationships.md]] | グラフ追加時はエッジタイプを明記したか？ |

### 🟠 COMMIT アクション（git commit）

| フラグ | 参照先 | 意味 |
|---|---|---|
| `exit-condition` | [[nodes/ai-instruction-enforcement.md]] | fix: の場合、エラーノード作成は完了したか？ |
| `uc-scan` | moc.md Quick Rule #8 | UCノードが未作成のまま fix: しようとしていないか？ |

### 🔵 DESIGN / PLAN アクション（設計・提案・ルール追加）

| フラグ | 参照先 | 意味 |
|---|---|---|
| `no-abstract-label` | [[nodes/uc-abstract-knowledge-label.md]] | 「誰が・いつ・何をトリガーに・何を」まで具体化されているか？ |
| `system-not-promise` | [[nodes/uc-session-promise-vs-system.md]] | 宣言だけで終わらず、今すぐファイルに書くか？ |
| `rule-vs-code` | このファイル（下のメタフラグ参照） | ルールで解決しようとしていないか？コードで自動化できないか？ |

### 🟣 KNOWLEDGE UPDATE アクション（ノード・クラスター・MOC更新）

| フラグ | 参照先 | 意味 |
|---|---|---|
| `edge-type` | [[nodes/semantic-graph-relationships.md]] | エッジタイプを明記したか？ |
| `traversal-update` | このファイル | relationships.md のエッジも更新したか？ |

---

## メタフラグ（特定アクションに依存しない、常時適用）

| フラグ ID | 内容 | 参照先 |
|---|---|---|
| `rule-vs-code` | ルールを追加しようとしている → 本当にコードで自動化できないか先に考える | [[nodes/uc-repeat-master-push-despite-known-403.md]] |
| `system-not-promise` | 「次回からやります」と言いそうになったら → 今この瞬間にファイルへ書く | [[nodes/uc-session-promise-vs-system.md]] |
| `exit-condition` | 重要な後処理は「完了の出口条件」として設計する | [[nodes/ai-instruction-enforcement.md]] |

---

## ノード間エッジ（直接的な関係）

```
ai-instruction-enforcement
  ├─[same-root-cause]→ uc-repeat-master-push-despite-known-403
  │   (どちらも「後処理・制約確認を習慣に任せた」同じ根本原因)
  └─[same-root-cause]→ uc-session-promise-vs-system
      (「後でやる」=「忘れる」という同じパターン)

uc-repeat-master-push-despite-known-403
  └─[prevented-by]→ pre-bash-git-push.sh フック
      (ルールではなくコードで自動強制 — rule-vs-code メタフラグの実例)

ai-context-blindness-at-scale
  └─[same-cluster]→ semantic-graph-relationships
      (プロジェクトが大きくなるほど関係性が見えなくなる)
```

---

## メンテナンスルール

| 条件 | アクション |
|---|---|
| 新しいエラーノードを作成した | このファイルの「アクション種別テーブル」に関連エッジを追加する |
| ユーザーが指摘した内容がルール追加で解決しようとしていた | `rule-vs-code` メタフラグを参照し、コード化を先に検討する |
| 同じ根本原因のノードが2件以上になった | ノード間に `same-root-cause` エッジを追加する |

### Append-Only ルール（マルチエージェント競合防止）
このファイルは複数のAIエージェントが junction 経由で共有している。
- **既存フラグ・エッジの書き換え・並べ替え禁止** — 新しいフラグは各アクション種別テーブルの末尾に追加する
- **新しいアクション種別は末尾に追加する** — 既存テーブルの順序を変更しない
- **ノード間エッジは末尾に追記する** — 既存のツリー構造を書き換えない

---

*Note: このファイルが error-graph のグラフ構造の核心。ノードを作っただけではグラフにならない。エッジを定義して初めてトラバーサルが機能する。*
