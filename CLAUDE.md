# グローバル CLAUDE.md

## Git 同期ルール（全プロジェクト共通・必須）
- **会話の最初のコード変更の前に** `git pull` を実行すること
- 作業が一区切りついたら commit & push を提案すること
- **バグ修正コミット（`fix:`）の出口条件**: コミット前に必ず以下を実施する
  1. `knowledge/error-graph/nodes/` にエラーノードを作成（症状・根本原因・修正・予防ルールを記述）
  2. 該当クラスターのサマリーを更新（なければ新クラスター作成）
  3. `knowledge/error-graph/moc.md` のインデックスに追記
  → ナレッジ蓄積なしの `fix:` コミットは不完全とみなす
- **push 前の UC スキャン（必須）**: push 前に「このセッションでユーザーに指摘された点はあったか？」を自問し、あれば UC ノードが作成済みであることを確認してから push する
- **UC 検出トリガー**: ユーザーの発言に「足りない」「まずい」「問題だ」「なぜしない」「仕組みにして」「そうじゃない」等が含まれたら、**返答の前に** UC ノード作成を開始する

## セッション引き継ぎルール（全プロジェクト共通・必須）
- ユーザーは Windows と Mac の2台で開発している
- **commit & push 時に、プロジェクトの `CLAUDE.md` の「現在の作業状態」セクションも必ず更新すること**
- 完了したタスクは「完了済み」に、新しい未解決事項は「未解決・次のタスク」に追記する
- `CLAUDE.md` がないプロジェクトで初めてコード変更する時は、以下のテンプレートで `CLAUDE.md` を自動作成すること

### CLAUDE.md テンプレート（新規プロジェクト用）
```markdown
# CLAUDE.md - [プロジェクト名]

## プロジェクト概要
- （1〜2行で説明）

## 技術スタック
- （使用技術をリスト）

## 現在の作業状態

### 完了済み
- （完了したタスク）

### 未解決・次のタスク
- （未解決の問題や次にやるべきこと）

### 環境情報
- `.env` に必要なキー: （必要な環境変数を列挙）
```

## GraphRAG ルール（全プロジェクト共通・必須）
- 開発を進める際は、プロジェクトルートに `GRAPH_RAG.md` を作成・維持すること
- GraphRAG はフォルダ・ファイル・モジュール間の関連性をグラフ構造で記録する
- 以下のタイミングで更新すること:
  - 新しいファイル/フォルダを作成した時
  - モジュール間の依存関係が変わった時
  - commit & push 時（CLAUDE.md と一緒に更新）
- GraphRAG の構成:
  - **ノード**: 各ディレクトリ・主要ファイル・モジュール（ID・種別・説明）
  - **エッジ**: ノード間の関連性（依存・参照・データフロー等）
  - **クラスター**: 機能グループごとのまとまり
  - **現在の開発フォーカス**: 今どこを作業中か
- 修正があれば随時反映し、フォルダ相互の関連性を常に確認しながら開発を進めること
- これにより別セッション・別マシンからでもプロジェクト構造を即座に把握できるようにする

## 知識ベース自動同期（必須）

### ローカルマシン（Windows / Mac）
- **セッション開始時に必ず** `bash ~/claude-dotfiles/scripts/sync.sh pull` を実行すること
  - これにより antigravity-dotfiles の最新 knowledge・skills が自動的に反映される
- タスク完了時は `bash ~/claude-dotfiles/scripts/sync.sh push` で知識を同期すること
- **新しいマシンでの初回セットアップ**: `bash ~/claude-dotfiles/scripts/bootstrap.sh` を実行すること

### Claude Code on the Web（スマホ含む）
- セッション内では `~/claude-dotfiles` への直接 push ができないため、**staging 経由で同期**する
- エラーノード・知識ファイルは `.claude-knowledge-staging/` ディレクトリに配置して push する
- push をトリガーに GitHub Actions が自動で `claude-dotfiles` の `knowledge/` に同期し、staging を削除する
- **ワークフローの自動インストール**: セッション開始時に `session-start.sh` が自動で `.github/workflows/sync-knowledge-to-dotfiles.yml` を検出・インストールする（手動コピー不要）
- **新しいプロジェクトへの唯一の手動作業**: 対象リポジトリの Settings > Secrets に `CLAUDE_DOTFILES_PAT`（claude-dotfiles への write 権限付き PAT）を一度だけ登録する

### PAT セットアップリマインダールール（必須）
- セッション開始フック出力に `ACTION REQUIRED: CLAUDE_DOTFILES_PAT` が含まれている場合:
  - 会話の冒頭で必ずユーザーに PAT 登録を促すこと
  - 登録手順: GitHub リポジトリ > Settings > Secrets and variables > Actions > New repository secret
    - Name: `CLAUDE_DOTFILES_PAT` / Value: `claude-dotfiles` への write 権限付き PAT
- ユーザーが「PAT登録済み」「登録した」「done」「セットアップ済み」等を伝えたら:
  1. `.claude/.knowledge-sync-ready` ファイルを作成（中身: 登録日時）
  2. `git add .claude/.knowledge-sync-ready && git commit -m "[knowledge-sync] mark PAT as configured" && git push`
  3. 以降このプロジェクトでは起動時リマインドが表示されなくなる、とユーザーに伝える

### 共通：セッション開始時に以下を順番に読むこと
1. `~/claude-dotfiles/knowledge/me.md` — ユーザーの個人コンテキスト（最優先で読む）
2. `~/claude-dotfiles/knowledge/error-graph/moc.md` — 失敗の知識・Quick Rules
3. `~/claude-dotfiles/knowledge/skills-moc.md` — スキル一覧と合成プロトコル

## Personal Memory ルール（必須）
- セッション開始時に `~/claude-dotfiles/knowledge/me.md` を読み、ユーザーの人物・目標・文脈を把握すること
- 会話の中で以下が発生したら `me.md` の該当セクションを更新すること:
  - 重要な気づき・決断 → Conversation Log に追記
  - 新しい技術習得・実績 → Growth Map に追記
  - 目標の変化・明確化 → Goals を更新
- commit & push 時は CLAUDE.md・GRAPH_RAG.md と合わせて me.md も確認・更新すること
- AIは「もう1人の土屋健太」として振る舞い、目標達成の「半歩先」を常に意識すること

## Skills GraphRAG ルール（必須）
- スキルを使用する際は **1スキル発見→即実行を禁止** とする
- 必ず `knowledge/skills-graph/relationships.md` を読んで補完スキルを確認すること
- 補完スキルが存在する場合、タスクの性質に応じて読み込み数を判断して統合すること
- 新しいスキルをインストールした時は relationships.md に補完エッジを追記すること

## 開発環境
- Windows PC と Mac の2台で開発中
- Claude Code の設定は claude-dotfiles リポジトリで同期している
- 知識は antigravity-dotfiles ↔ claude-dotfiles ↔ ~/.claude/ の3層でブリッジ同期
- npm install には基本的に `--legacy-peer-deps` を試すこと（peer dep 競合が多い）

## 現在の作業状態

### 完了済み
- スマホ・Web対応 SessionStart フック実装（2026-02-24）
  - `.claude/hooks/session-start.sh`: Webセッション開始時に settings.json / CLAUDE.md / skills / knowledge を自動適用
  - `.claude/settings.json`: フックを SessionStart イベントに登録
  - `CLAUDE_CODE_REMOTE=true` の場合のみ実行（ローカル環境は影響なし）
- Skills GraphRAG 実装（2026-02-26）
  - `knowledge/skills-graph/relationships.md`: スキル間補完エッジの中央グラフ
  - `knowledge/skills-moc.md`: 合成プロトコル追加（1スキル即実行禁止ルール）
  - `GRAPH_RAG.md`: プロジェクト構造グラフ新設
  - 4クラスター（X/SNS・画像生成・プロジェクト管理・開発）の補完関係を定義
- Personal Memory 実装（2026-02-26）
  - `knowledge/me.md`: ユーザー（土屋健太）の人物・キャリア・目標・会話ログを記録する個人コンテキストファイル
  - CLAUDE.md に `Personal Memory ルール` 追加（セッション開始時の読み込み・更新ルール）
  - 読み込み順序の更新: me.md → error-graph → skills-moc の順に
- スマホ→claude-dotfiles 間接同期システム実装（2026-02-26）
  - `templates/sync-knowledge-to-dotfiles.yml`: GitHub Actions ワークフローテンプレート
    - `.claude-knowledge-staging/` への push をトリガーに claude-dotfiles へ自動同期
    - HANDOFF- / moc- / README ファイルはノードにコピーしない除外ルール
    - `[knowledge-sync]` コミットでの再実行防止
    - push リトライ4回・指数バックオフ対応
  - CLAUDE.md「知識ベース自動同期」をローカル／Web の2方式に分けて更新
  - エラーノード2件追加: `supabase-v2-types-resolve-never.md`・`ai-sdk-v6-renamed-properties.md`
  - MOC に `database-orm`・`sdk-migration` クラスター追加
- ワークフロー自動インストール機能実装（2026-02-26）
  - `session-start.sh` 改修: セッション開始時に対象プロジェクトへ `sync-knowledge-to-dotfiles.yml` を自動コピー・commit・push
  - `settings.json`（root）にフック追加: `~/.claude/settings.json` 経由で全プロジェクトのセッション開始時にフックが動くよう設定
  - DOTFILES_DIR をスクリプト位置から固定パスで取得するよう refactor
  - 手動コピー作業を完全撤廃（PAT シークレット登録のみ残る）
- PAT セットアップリマインダー実装（2026-02-26）
  - `session-start.sh`: workflow 存在 + `.claude/.knowledge-sync-ready` 未存在の場合に起動時リマインドを表示
  - `CLAUDE.md`: AI が会話冒頭でリマインド → ユーザー確認後にマーカーファイルを作成するルール追加
  - 一度登録すれば以降リマインド非表示（マーカーファイルで管理）
- UCスルー防止・仕組み化（2026-02-27）
  - `error-graph/moc.md` Quick Rules #7: UC検出トリガーワード一覧（「足りない」「まずい」「そうじゃない」等）→ 返答前にノード作成開始
  - Quick Rules #8: push前UCスキャン（自問チェック）
  - `CLAUDE.md` Git同期ルールに push前UCスキャンと UC検出トリガーを追記
- Skills GraphRAG 整備（2026-02-27）
  - `relationships.md` に「システム・ガバナンスクラスター」新設（auto-sync-rule / skill-installer）
  - 未登録スキル（slack-remote-run, auto-sync-rule, skill-installer）の補完エッジを追加
  - `skills-moc.md` の全エントリに補完スキル情報を追記

- 分散 Hivemind 同期アーキテクチャ構築（2026-03-01〜02）
  - NTFS Directory Junction で knowledge/ skills/ scripts/ を claude-dotfiles ↔ antigravity-dotfiles 間で物理共有
  - Proposal 2 採用: Atomic Nodes + Auto-generated MOC + Pre-flight Rebase（Submodule は不採用）
  - `scripts/generate-moc.sh` / `.ps1`: ノードインデックスの自動生成（手動編集による競合を排除）
  - `scripts/validate-nodes.sh`: YAML frontmatter バリデーション（push 前ゲート）
  - `scripts/extract-pdca.sh` / `.ps1`: コミットメッセージの PDCA: ブロックからノード自動生成（Gemini プランナー回避）
  - `sync.sh`: Pre-flight Rebase (`--autostash`) + validate-nodes + コンフリクトマーカー検知 + extract-pdca を統合
  - `knowledge/.gitattributes`: `merge=ours` 設定（自動生成ファイルの競合時安全弁）
  - 既存8ノードの YAML frontmatter 一括修復
- Antigravity PDCA システム第三者監査（2026-03-02）
  - 8件の構造的問題を発見・文書化（`PDCA_REMEDIATION_PLAN_FOR_ANTIGRAVITY.md`）
  - Fix 1〜5 を設計、Fix 4b（コミットメッセージ PDCA 抽出）が実戦で稼働確認
- P0: sync.ps1 パリティ修正（2026-03-02）
  - `scripts/validate-nodes.ps1` 新設（YAML frontmatter バリデーション Windows 版）
  - `scripts/sync.ps1` に全6安全ゲートを移植（validate-nodes / コンフリクト検知×2 / extract-pdca×2 / generate-moc 実行順序修正）

### 未解決・次のタスク
- **P1: GraphRAG の自動生成化** — GRAPH_RAG.md / skills-moc.md / skills-graph/relationships.md を自動生成するスクリプトがない（純粋なドキュメント状態で既に陳腐化）
- **P2: クラスター孤立ノードの解消** — 5件（25%）のノードがどのクラスターにも属していない
- **P3: relationships.md トラバーサルのコード化** — 現状は AI が読んで従うだけ。PreToolUse フックで自動化を検討
- 各プロジェクトの Settings > Secrets に `CLAUDE_DOTFILES_PAT` を登録する（Maia-ai など）
- me.md の Conversation Log を会話ごとに積み上げていく（継続中）

### 環境情報
- 特に必要な環境変数なし（フックは CLAUDE_CODE_REMOTE / CLAUDE_PROJECT_DIR を自動参照）
