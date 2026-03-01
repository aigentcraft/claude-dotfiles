# CHANGELOG — claude-dotfiles

> CLAUDE.md の「完了済み」から溢れた過去のタスクをここにアーカイブする。
> CLAUDE.md には直近5件のみ残し、古いものはここに移動する。

---

## 2026-02-24

### スマホ・Web対応 SessionStart フック実装
- `.claude/hooks/session-start.sh`: Webセッション開始時に settings.json / CLAUDE.md / skills / knowledge を自動適用
- `.claude/settings.json`: フックを SessionStart イベントに登録
- `CLAUDE_CODE_REMOTE=true` の場合のみ実行（ローカル環境は影響なし）

## 2026-02-26

### Skills GraphRAG 実装
- `knowledge/skills-graph/relationships.md`: スキル間補完エッジの中央グラフ
- `knowledge/skills-moc.md`: 合成プロトコル追加（1スキル即実行禁止ルール）
- `GRAPH_RAG.md`: プロジェクト構造グラフ新設
- 4クラスター（X/SNS・画像生成・プロジェクト管理・開発）の補完関係を定義

### Personal Memory 実装
- `knowledge/me.md`: ユーザー（土屋健太）の人物・キャリア・目標・会話ログを記録する個人コンテキストファイル
- CLAUDE.md に `Personal Memory ルール` 追加（セッション開始時の読み込み・更新ルール）
- 読み込み順序の更新: me.md → error-graph → skills-moc の順に

### スマホ→claude-dotfiles 間接同期システム実装
- `templates/sync-knowledge-to-dotfiles.yml`: GitHub Actions ワークフローテンプレート
  - `.claude-knowledge-staging/` への push をトリガーに claude-dotfiles へ自動同期
  - HANDOFF- / moc- / README ファイルはノードにコピーしない除外ルール
  - `[knowledge-sync]` コミットでの再実行防止
  - push リトライ4回・指数バックオフ対応
- CLAUDE.md「知識ベース自動同期」をローカル／Web の2方式に分けて更新
- エラーノード2件追加: `supabase-v2-types-resolve-never.md`・`ai-sdk-v6-renamed-properties.md`
- MOC に `database-orm`・`sdk-migration` クラスター追加

### ワークフロー自動インストール機能実装
- `session-start.sh` 改修: セッション開始時に対象プロジェクトへ `sync-knowledge-to-dotfiles.yml` を自動コピー・commit・push
- `settings.json`（root）にフック追加: `~/.claude/settings.json` 経由で全プロジェクトのセッション開始時にフックが動くよう設定
- DOTFILES_DIR をスクリプト位置から固定パスで取得するよう refactor
- 手動コピー作業を完全撤廃（PAT シークレット登録のみ残る）

### PAT セットアップリマインダー実装
- `session-start.sh`: workflow 存在 + `.claude/.knowledge-sync-ready` 未存在の場合に起動時リマインドを表示
- `CLAUDE.md`: AI が会話冒頭でリマインド → ユーザー確認後にマーカーファイルを作成するルール追加
- 一度登録すれば以降リマインド非表示（マーカーファイルで管理）

## 2026-02-27

### UCスルー防止・仕組み化
- `error-graph/moc.md` Quick Rules #7: UC検出トリガーワード一覧（「足りない」「まずい」「そうじゃない」等）→ 返答前にノード作成開始
- Quick Rules #8: push前UCスキャン（自問チェック）
- `CLAUDE.md` Git同期ルールに push前UCスキャンと UC検出トリガーを追記

### Skills GraphRAG 整備
- `relationships.md` に「システム・ガバナンスクラスター」新設（auto-sync-rule / skill-installer）
- 未登録スキル（slack-remote-run, auto-sync-rule, skill-installer）の補完エッジを追加
- `skills-moc.md` の全エントリに補完スキル情報を追記
