# Cluster: AI行動パターン & システム設計

> Layer 1 Community Summary — 関連ノードの蒸留サマリー。
> このクラスターが関連するタスク開始時にロードする。個別詳細は nodes/ を参照。

**対象タグ**: `ai-behavior`, `system-design`, `knowledge-graph`, `user-correction`, `prompt-engineering`

---

## 蒸留ルール（Distilled Rules）

### R1: スケール問題 — コンテキスト外のファイルは見えない
プロジェクトが成長すると、AIはファイルの関係性を把握できなくなり重複・依存破壊が起きる。
- **対策**: ファイル作成・変更前に `PROJECT_MAP.md` を必ず読む
- **更新タイミング**: 構造変更（新規・移動・削除）のたびに更新する
- 詳細: [[../nodes/ai-context-blindness-at-scale.md]]

### R2: 指示の強制 — "後でやる"は機能しない
「タスク完了後にドキュメントを書く」という指示は、完了の達成感で消える。
- **対策**: 重要な後処理は「完了の出口条件」として設計する。「〜しないとpushできない」形式に変える
- **禁止**: "Do X, then remember to do Y later" という形式
- **推奨**: "You cannot push until you verify Y is done" という形式
- 詳細: [[../nodes/ai-instruction-enforcement.md]]

### R3: 具体性の原則 — 抽象ラベル禁止
「重要な知見」「有用な情報」等の抽象ラベルはシステム設計では使用禁止。
- **対策**: 設計提案時は必ず「誰が・いつ・何をトリガーに・何を書くか」まで具体化する
- **チェック**: 「ユーザーが一緒に成長したい・PDCAを回したい」= AIの行動改善の話。ストレージ設計に終始しない
- 詳細: [[../nodes/uc-abstract-knowledge-label.md]]

### R6: 既知制約の再適用 — 一度知った制約は毎回チェックする
セッション内で「この操作はXの理由で失敗する」と判明した場合、次の同種操作でも同じ失敗を繰り返す。
- **原因**: 「知っている」と「適用する」が分離している。習慣的なコマンドパターンが制約より優先される
- **対策**: push実行前に「このセッションでpush失敗はあったか？ブランチ制約はあるか？」を必ず自問する
- **具体例**: 403でmasterへのpushが失敗した → 以降のpushはすべてclaude/ブランチへ
- 詳細: [[../nodes/uc-repeat-master-push-despite-known-403.md]]

### R5: セッション宣言 vs 仕組み — 口頭約束は無効
「次回からやります」という発言はセッションが終わると消える。何も変わらない。
- **対策**: 宣言した瞬間にファイルへ書き込む。書いてコミットして初めて有効
- **判断基準**: 「次回から〜」と言いそうになったら → 今すぐ CLAUDE.md か error-graph に書く
- 詳細: [[../nodes/uc-session-promise-vs-system.md]]

### R9: 局所実装の横展開 — パターンは「同種の構造すべて」に適用する

あるパターンを特定の場所に実装した後、「同種の構造が他にないか」を確認しなかった。
- **具体例**: `skills-graph/relationships.md` を作成後、`error-graph/relationships.md` を作らなかった
- **根本**: パターンを「局所要件」として捉えた。「グラフ構造には必ずエッジ定義が要る」という汎用要件として捉えなかった
- **対策**: 新しい構造を実装したら即自問する → 「これは局所か汎用か？同種の構造が他にあるか？」
- 詳細: [[../nodes/uc-local-pattern-no-generalization.md]]

### R4: セマンティックリンク — エッジの意味を明記する
`[[link]]` だけでは関係の種類が不明。AIも人間もグラフの意味を正確に把握できない。
- **対策**: リンクには必ずエッジタイプを明記（`caused_by`, `related_to`, `fixes` 等）
- **YAMLフロントマター**: `relationships:` セクションで構造的に定義する
- 詳細: [[../nodes/semantic-graph-relationships.md]]

---

## クイック参照テーブル

| 状況 | 適用するルール |
|---|---|
| 新しいファイルを作ろうとしている | R1: PROJECT_MAP.md を先に読む |
| タスク完了前のチェックリスト設計 | R2: 後処理を出口条件にする |
| ナレッジシステムや記録システムを設計する | R3: 抽象ラベルを使わず具体的なカテゴリで定義する |
| グラフにリンクを追加する | R4: エッジタイプを明記する |
| ユーザーが「成長」「PDCA」と言った | R3: ストレージではなく行動改善の設計をする |
| AIが「次回からやります」と言った | R5: 今すぐファイルに書いてコミットする |
| セッション内でpush/操作が一度失敗した | R6: 同じコマンドを再実行しない。制約を確認してから実行する |
| あるパターン（ファイル・構造・ルール）を作った | R9: 「同種の構造が他にないか」を即座に確認し横展開する |

---

## このクラスターのノード一覧

- [[../nodes/ai-context-blindness-at-scale.md]] — `ai-behavior`, `scaling`, `system-design`
- [[../nodes/ai-instruction-enforcement.md]] — `ai-behavior`, `prompt-engineering`, `pdca`
- [[../nodes/uc-abstract-knowledge-label.md]] — `user-correction`, `too-abstract`, `knowledge-design`
- [[../nodes/semantic-graph-relationships.md]] — `system-design`, `knowledge-graph`, `semantics`
- [[../nodes/uc-session-promise-vs-system.md]] — `user-correction`, `too-ephemeral`, `system-design`
- [[../nodes/uc-repeat-master-push-despite-known-403.md]] — `user-correction`, `repeat-known-constraint`, `git`
- [[../nodes/uc-local-pattern-no-generalization.md]] — `user-correction`, `local-pattern`, `no-generalization`

---

## 昇格候補（SKILL.md へ昇格すべきルール）

> 次回レビュー時: R1〜R4 は十分に検証済み → SKILL.md の "行動ルール" セクションへの昇格を検討する

*Last updated: 2026-02-28 | Node count: 7*
