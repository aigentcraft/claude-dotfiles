# Error Knowledge Graph: MOC (Global Index) — Layer 2

**AIへの指示**: アクション実行前・エラー発生時・ユーザー指摘時に以下を順番に行う。
1. [[relationships.md]] を読み、今の**アクション種別**に対応するフラグをトラバーサルする
2. 該当フラグを適用してからアクションを実行する
3. Quick Rules は頻出パターンのショートカット（relationships.md の補完）

*Related MOC*: [[../skills-moc.md|Skills Knowledge Graph (MOC)]]

---

## Quick Rules（最重要ルール — 毎回適用）

> クラスターから昇格した、最も頻繁に必要なルール

1. **ファイル作成・変更前**: `PROJECT_MAP.md` を読んで重複・依存関係を確認する
2. **後処理の強制設計**: 重要な後処理（ドキュメント・記録）は「完了の出口条件」にする。"後でやる"は機能しない
3. **外部APIの `await`**: 必ずタイムアウトで包む（`Promise.race` 等）。タイムアウトなし `await` は禁止
4. **設計提案の具体化**: 「誰が・いつ・何をトリガーに・何を書くか」まで具体化する。抽象ラベル（「重要な知見」等）禁止
5. **バグ修正コミットの出口条件**: バグ修正コミットを作る前に必ずエラーノード（`nodes/` + クラスター更新 + MOC 追記）を作成する。コミットメッセージに `fix:` が含まれる場合は必須
6. **セッション宣言は無効**: 「次回からやります」は何も変えない。宣言したい内容は **今すぐ** CLAUDE.md か error-graph に書いてコミットする
7. **UC検出トリガー（即時反応）**: ユーザーの発言に以下のパターンが含まれたら、返答より先に UC ノード作成を開始する
   - 「〜は足りない」「〜では足りない」「〜が抜けている」「〜はまずい」「〜は問題だ」
   - 「なぜ〜しない」「〜すべきだ」「〜してくれないと」
   - 「仕組みにして」「ルールにして」「構造にして」「埋め込んで」
   - 「そうじゃない」「違う」「ちがう」「それは違います」
   → UCノード（`uc-*.md`）を nodes/ に作り、クラスターと MOC を更新してからコミット
8. **コミット前 UC スキャン**: push 前に「このセッションでユーザー指摘はあったか？」を必ず自問する。あれば UC ノードが作成済みか確認する
   ※ git push のブランチ制約は `pre-bash-git-push.sh` フックが自動強制 — ルールではなくコードで解決済み
9. **パターン実装後の横展開チェック**: 新しい構造・ファイル・パターンを「ある場所に」実装したら必ず自問する
   > 「これは局所要件か、この種の構造すべてに必要な汎用要件か？」
   > 同種の構造が他にあれば、同じパターンを即座に展開する（例: relationships.md → 全グラフ構造）
10. **R-HAZUDESU（実測報告の義務）**: テスト・動作確認タスクでは「〜のはずです」「〜されます」で終わらず、必ずコマンド実行結果（`gh run list` / `ls` / `git show` 等）を添えて実測値を報告する。確認コマンドが使えない場合は「確認できない理由」を明記する

---

## Clusters（Layer 1 — トピック別コミュニティサマリー）

| クラスター | 内容 | ノード数 | ロード条件 |
|---|---|---|---|
| [[clusters/ai-behavior.md]] | AI行動パターン・システム設計・知識グラフ設計 | 10 | AI設計・スケール・ナレッジシステム系タスク |
| [[clusters/api-network.md]] | API/ネットワーク・非同期・タイムアウト | 2 | 外部API・ネットワークリクエストを書く時 |
| [[clusters/platform-syntax.md]] | PowerShell/Windows固有の構文エラー | 1 | PowerShell・Windowsスクリプト作業時 |
| [[clusters/copywriting-psychology.md]] | コピーライティング心理学・間接的動機づけ設計 | 1 | 記事・LP・SNS投稿のコピーを書く時 |
| `database-orm` | Database/ORM の型・スキーマ・クエリエラー | 1 | Supabase・Prisma・ORM を使う時 |
| `sdk-migration` | SDK バージョンアップグレード時のブレーキングチェンジ | 1 | ライブラリをアップグレードする時 |
| [[clusters/shell-hook-env.md]] | Claude Code フック・シェル環境変数の落とし穴 | 1 | Claude Code フック・session-start.sh・シェルスクリプトを書く時 |

---

## スケールメンテナンスルール

このシステムが機能し続けるために以下を守る:

| 条件 | アクション |
|---|---|
| 同クラスターに **3件以上** ノードが追加された | クラスターサマリーを更新し蒸留ルールを追加する |
| クラスターの蒸留ルールが **5件以上** になった | 上位ルールを Quick Rules セクションへ昇格する |
| Quick Rules が **10件以上** になった | SKILL.md（Procedural Memory）へ昇格し MOC から削除する |
| 既存クラスターに収まらない新ノード | 新クラスターを `clusters/` に作成し、この表に追加する |

---

## 全ノードインデックス（nodes/）

> 通常はクラスター経由でアクセスする。完全参照が必要な時のみこちらを使う。

### [Type A] Technical Errors
- [[nodes/ai-context-blindness-at-scale.md]] — `ai-behavior` cluster
- [[nodes/ai-instruction-enforcement.md]] — `ai-behavior` cluster
- [[nodes/api-rate-limit-exceeded.md]] — `api-network` cluster
- [[nodes/powershell-hash-literal-git.md]] — `platform-syntax` cluster
- [[nodes/semantic-graph-relationships.md]] — `ai-behavior` cluster
- [[nodes/slack-api-silent-hang.md]] — `api-network` cluster
- [[nodes/supabase-v2-types-resolve-never.md]] — `database-orm` cluster
- [[nodes/ai-sdk-v6-renamed-properties.md]] — `sdk-migration` cluster
- [[nodes/claude-hook-env-project-dir.md]] — `shell-hook-env` cluster

### [Type B] User Corrections (uc-)
- [[nodes/uc-abstract-knowledge-label.md]] — `ai-behavior` cluster (`too-abstract`)
- [[nodes/copywriting-indirect-motivation.md]] — `copywriting-psychology` cluster
- [[nodes/uc-session-promise-vs-system.md]] — `ai-behavior` cluster (`too-ephemeral`)
- [[nodes/uc-repeat-master-push-despite-known-403.md]] — `ai-behavior` cluster (`repeat-known-constraint`)
- [[nodes/uc-local-pattern-no-generalization.md]] — `ai-behavior` cluster (`local-pattern`, `no-generalization`)
- [[nodes/uc-knowledge-branch-isolation.md]] — `ai-behavior` cluster (`branch-isolation`, `knowledge-propagation`)
- [[nodes/uc-partial-solution-without-automation-path.md]] — `ai-behavior` cluster (`partial-solution`, `automation`)
- [[nodes/uc-unverified-hazudesu-reporting.md]] — `ai-behavior` cluster (`unverified-claim`, `hazudesu`, `test-verification`)

---

*Note: 新しいノードを作成したら (1) nodes/ にファイルを作る → (2) 該当クラスターのサマリーを更新する → (3) この全ノードインデックスに追記する*
