# グローバル CLAUDE.md

## Git 同期ルール（全プロジェクト共通・必須）
- **会話の最初のコード変更の前に** `git pull` を実行すること
- 作業が一区切りついたら commit & push を提案すること

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
- **新しいプロジェクトへの導入手順**:
  1. `claude-dotfiles/templates/sync-knowledge-to-dotfiles.yml` を対象リポジトリの `.github/workflows/` にコピーする
  2. 対象リポジトリの Settings > Secrets に `CLAUDE_DOTFILES_PAT`（claude-dotfiles への write 権限付き PAT）を登録する

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

### 未解決・次のタスク
- 各プロジェクトに `sync-knowledge-to-dotfiles.yml` をコピーして `CLAUDE_DOTFILES_PAT` シークレットを設定する（Maia-ai など）
- Skills GraphRAG の実際の挙動を検証し、補完エッジを調整する
- me.md の Conversation Log を会話ごとに積み上げていく（次セッション以降）

### 環境情報
- 特に必要な環境変数なし（フックは CLAUDE_CODE_REMOTE / CLAUDE_PROJECT_DIR を自動参照）
