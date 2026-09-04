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

### R11: LLM検閲の判定基準には「充足される層」を併記する
多層パイプライン（ドラフト→テンプレ→ビルド）で、要件だけを列挙した checklist を渡すと
LLM は「ドラフトに無い＝NG」と判定し、別層が保証する項目で差し戻しループを起こす。
- **対策**: チェック項目ごとに「どの層・どの成果物で満たされるか」と逆条件（手書きなら二重挿入NG）を明記する
- **対策**: 同様に「適用条件」（記事タイプ・案件アサイン有無・フェーズ）も併記する。無条件の項目は該当しない対象にも減点され、score 床で破棄が連鎖する
  - 詳細: [[../nodes/reviewer-checklist-without-applicability-conditions.md]]
- **対策**: LLM 生応答を常時ダンプ（gitignore下）し、誤判定の一次証拠を残す。推測での修正は空振りする
- 詳細: [[../nodes/llm-reviewer-false-ng-on-template-layer-items.md]]

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
| テスト・動作確認の結果を報告する | R10: 「はずです」禁止。`gh run list` / `ls` / `git show` で実測してから報告する |
| LLM に検閲/判定用チェックリストを渡す | R11: 各項目に「充足される層」を併記し、生応答ダンプを残す |

---

## このクラスターのノード一覧

- [[../nodes/ai-context-blindness-at-scale.md]] — `ai-behavior`, `scaling`, `system-design`
- [[../nodes/ai-instruction-enforcement.md]] — `ai-behavior`, `prompt-engineering`, `pdca`
- [[../nodes/uc-abstract-knowledge-label.md]] — `user-correction`, `too-abstract`, `knowledge-design`
- [[../nodes/semantic-graph-relationships.md]] — `system-design`, `knowledge-graph`, `semantics`
- [[../nodes/uc-session-promise-vs-system.md]] — `user-correction`, `too-ephemeral`, `system-design`
- [[../nodes/uc-repeat-master-push-despite-known-403.md]] — `user-correction`, `repeat-known-constraint`, `git`
- [[../nodes/uc-local-pattern-no-generalization.md]] — `user-correction`, `local-pattern`, `no-generalization`
- [[../nodes/uc-knowledge-branch-isolation.md]] — `user-correction`, `branch-isolation`, `knowledge-propagation`
- [[../nodes/uc-partial-solution-without-automation-path.md]] — `user-correction`, `partial-solution`, `automation`
- [[../nodes/uc-unverified-hazudesu-reporting.md]] — `user-correction`, `unverified-claim`, `hazudesu`, `test-verification`
- [[../nodes/uc-visualization-without-audit-purpose.md]] — `user-correction`, `dashboard`, `requirements`, `verification`
- [[../nodes/llm-reviewer-false-ng-on-template-layer-items.md]] — `ai-behavior`, `llm-pipeline`, `reviewer`, `checklist`, `audit-log`
- [[../nodes/reviewer-checklist-without-applicability-conditions.md]] — `ai-behavior`, `llm-pipeline`, `reviewer`, `checklist`, `scoring`

---

## 昇格候補（SKILL.md へ昇格すべきルール）

> Node count が 10 に達した。次回レビュー時に R1〜R4 を SKILL.md の "行動ルール" セクションへ昇格し、クラスターを再整理する

### R12: 母数が足りないままLLMに判定させない（意見が知識に化ける）
LLMは判定を求められれば必ず何か答える — 「データが足りないので判断できません」とは自発的に
言わない。だから自律学習ループでは、**配管を通した瞬間に意見が「検証済み知識」へ化ける**。
- 判定肢に**「判断保留（insufficient_data）」を必ず用意し、それを既定にする**
- LLMに渡す前に、**機械が「判定に足る母数か」を判定する**（最低試行数ゲート）
- 知識ベースには増やす役と同じだけ**「疑う・減らす役」**を置く。昇格しかしない知識ベースは
  時間とともに剥がしにくい誤りを蓄積する（実例: 307件中 retired 1件）
- 薄い母数では学習目標を「勝ちパターンの発見」から**「負けパターンの排除」**へ振る
  （n=3で「効いた」は言えないが「91件中84件が0」は言える）
- 例: いいね1件を根拠に「エンゲージ率は部門平均の2倍」が verified 昇格し全エージェントへ注入
  （[[../nodes/underpowered-verdicts-become-doctrine.md]]）
- 兆候: 実験が紐づいていない仮説が judgment 期限を迎えている／知識の退役件数がほぼゼロ

### R13: 不可逆性には「速い」と「遅い」がある
優先順位づけで見落とされるのは**遅い不可逆性** — 放置すると時間とともに剥がしにくくなるもの。
- 速い: 失敗が外部に出る（公開・投稿・課金）。目立つので優先されやすい
- 遅い: 何も止まらないので気づけないが、汚染が蓄積して直すコストが増え続ける
- **静かに悪くなるものを先に止める。** 痛みの大きさと取り返しのつかなさは別の軸

### R10: 実測報告の義務（R-HAZUDESU）
テスト・動作確認タスクでは「〜のはずです」「〜されます」は報告ではない。実測結果のみが報告。
- **禁止**: 「はずです」「されるはずです」「確認してください」で終わる
- **必須**: `gh run list` / `ls` / `git show` 等で実測してから状態を報告する
- **確認不可の場合**: 「確認できない理由」を明記し、ユーザーが実行できる具体的コマンドを提示する
- 詳細: [[../nodes/uc-unverified-hazudesu-reporting.md]]

*Last updated: 2026-08-27 | Node count: 13*
- [[../nodes/writer-output-truncated-by-code-fence-misparse.md]] — `parsing`, `llm-output`, `regex`, `silent-degradation`（フォールバック段が一次パーサと同じバグを共有）
- [[../nodes/reviewer-send-back-loop-on-unfixable-screenshot-item.md]] — `reviewer`, `send-back-loop`, `structural-constraint`（差し戻し理由は次ラウンドで解消可能なものに限る）
- [[../nodes/reviewer-flagged-machine-rendered-log-image-as-fabricated.md]] — `reviewer`, `false-positive`, `provenance`（検閲者に成果物の出所メタデータを渡す）
- [[../nodes/writer-internal-handoff-notes-leak.md]] — `writer`, `public-tone`, `mechanical-strip`（禁止事項は検査ではなく決定論的除去で担保）
