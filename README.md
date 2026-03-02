# claude-dotfiles

**布団の中から本番バグを直す**ための、Claude Code 設定一式。

Windows / Mac のマルチマシン同期 ＋ スマホ・ブラウザでの Web セッション対応。
Gemini（Antigravity）との知識共有にも対応したマルチエージェント構成。

---

## できること

| 機能 | 説明 |
|---|---|
| **マルチマシン同期** | Windows / Mac で同じ設定・スキル・知識ベースを共有 |
| **Web セッション自動設定** | スマホブラウザから開くとルール・スキル・知識が自動ロード |
| **スキル管理** | 14 個のカスタムスキルをリポジトリで管理・同期 |
| **PDCA 知識ベース** | エラーグラフ（21 ノード / 5 クラスター）をセッション横断で蓄積 |
| **マルチエージェント共有** | Gemini（Antigravity）と junction 経由で knowledge / skills / scripts を共有 |
| **コミットメッセージ PDCA 抽出** | `fix:` コミットに `PDCA:` ブロックを書くだけでノードが自動生成 |

---

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────┐
│                    claude-dotfiles                       │
│              （Source of Truth リポジトリ）               │
│                                                         │
│   knowledge/          skills/          scripts/         │
│   ├── error-graph/    ├── 14 skills    ├── sync.sh/ps1  │
│   │   ├── nodes/      └── ...          ├── extract-pdca │
│   │   ├── clusters/                    ├── generate-moc │
│   │   ├── moc.md                       ├── validate-nodes│
│   │   └── relationships.md             └── bootstrap    │
│   ├── skills-graph/                                     │
│   │   └── relationships.md                              │
│   └── me.md                                             │
└──────────────┬──────────────────────┬───────────────────┘
               │ junction             │ junction
               ▼                      ▼
┌──────────────────────┐   ┌──────────────────────┐
│  Antigravity         │   │  ~/.claude/           │
│  (.gemini/antigravity)│   │  (Claude Code local) │
│  Gemini エージェント  │   │  symlink で参照      │
└──────────────────────┘   └──────────────────────┘
               │                      │
               ▼                      ▼
         PDCA ノード自動生成    セッション開始時に自動適用
         コミットメッセージ経由   session-start.sh フック
```

### Append-Only ルール

複数エージェントが同じファイルを編集するため、以下のファイルは **追記のみ・書き換え禁止**：

- `knowledge/me.md` — ユーザーの個人コンテキスト
- `knowledge/skills-graph/relationships.md` — スキル補完グラフ
- `knowledge/error-graph/relationships.md` — エラートラバーサルグラフ

---

## セットアップ

### 新しいマシンで初回のみ

```bash
git clone https://github.com/aigentcraft/claude-dotfiles.git ~/claude-dotfiles
bash ~/claude-dotfiles/scripts/bootstrap.sh
```

bootstrap.sh が以下を実行：
- `~/.claude/` に settings.json / CLAUDE.md のシンボリックリンクを作成
- skills / knowledge ディレクトリをリンク

### 手動同期

```bash
bash ~/claude-dotfiles/scripts/sync.sh pull   # 最新を取得
bash ~/claude-dotfiles/scripts/sync.sh push   # ローカルの変更を送信
```

push 時に自動実行される安全チェック：
1. `validate-nodes.sh` — 全 PDCA ノードの YAML frontmatter 検証
2. コンフリクトマーカー検出 — `<<<<<<< ` が残っていたら push ブロック
3. `extract-pdca.sh` — 直近コミットから PDCA ノード自動抽出
4. `generate-moc.sh` — MOC（目次）の自動再生成

### 自動同期（30 秒ごと）

```bash
bash ~/claude-dotfiles/scripts/sync.sh watch
```

---

## PDCA ナレッジシステム

エラーや失敗を構造化して蓄積し、再発防止に活用する仕組み。

### 構造

```
knowledge/error-graph/
├── moc.md              # 全ノードの目次（自動生成）
├── relationships.md    # アクション種別 → 思考パターンフラグ（トラバーサルグラフ）
├── nodes/              # 個別のエラー / ユーザー指摘ノード（21 件）
├── clusters/           # トピック別サマリー（5 クラスター）
└── timestamps.json     # ノード抽出の重複防止用タイムスタンプ
```

### ノードの作り方

手動作成は不要。コミットメッセージに `PDCA:` ブロックを書くだけ：

```
fix: APIタイムアウトを修正

PDCA:
  node: api-timeout-missing-race
  type: technical-error
  tags: api, timeout, async
  cluster: api-network
  symptom: 外部API呼び出しがハングした
  root-cause: Promise.race でタイムアウトを設定していなかった
  fix: 30秒タイムアウトを追加
  prevention: 外部APIの await には必ずタイムアウトを設定する
```

`sync.sh push` 時に `extract-pdca.sh` がコミットログを解析し、`nodes/` にノードファイルを自動生成。

### スケールルール

| 条件 | アクション |
|---|---|
| クラスターに 3 件以上追加 | クラスターサマリーを更新 |
| 蒸留ルールが 5 件以上 | Quick Rules に昇格 |
| Quick Rules が 10 件以上 | SKILL.md に昇格して MOC から削除 |

---

## スキル一覧（14 個）

| カテゴリ | スキル | 概要 |
|---|---|---|
| **SNS / コピー** | `x-viral-writing` | X バイラル投稿・スレッド |
| | `x-image-prompt` | X 投稿用アイキャッチ画像プロンプト |
| | `ai-social-media-content` | TikTok / Instagram / YouTube / X 向けコンテンツ |
| | `copywriting` | Web ページのマーケティングコピー |
| **画像生成** | `nanobanana` | Gemini 画像生成（Nano Banana Pro） |
| | `gpt-image-1-5` | OpenAI GPT Image 1.5 |
| | `nano-banana-pro-prompts-recommend-skill` | 6000+ プロンプトから最適推薦 |
| **開発** | `skill-hyperbrowser-reference` | Hyperbrowser SDK リファレンス |
| | `slack-remote-run` | Slack 経由リモートコマンド実行 |
| | `skill-installer` | skills.sh レジストリからスキル検索・インストール |
| **管理** | `skill-pdca-error-graph` | PDCA エラーグラフの自動記録 |
| | `skill-project-map` | PROJECT_MAP.md 自動維持 |
| | `auto-sync-rule` | マルチデバイス同期ルールの自動適用 |

スキル間の補完関係は `knowledge/skills-graph/relationships.md` で管理。

---

## スマホから使う

1. このリポジトリを fork する
2. `CLAUDE.md` に自分のルールを書く
3. `claude.ai` のブラウザでそのリポジトリを開く
4. スマホで指示を打つだけ

セッション開始時に `.claude/hooks/session-start.sh` が自動実行され、設定・スキル・知識がすべて適用された状態でスタートする（`CLAUDE_CODE_REMOTE=true` の場合のみ）。

### 知識ベースの間接同期（スマホ → claude-dotfiles）

スマホからは直接 push できないため、GitHub Actions 経由で間接同期する。

```
スマホセッション
  └─ .claude-knowledge-staging/ に push
       └─ GitHub Actions（sync-knowledge-to-dotfiles.yml）が起動
            └─ CLAUDE_DOTFILES_PAT を使って claude-dotfiles に書き込む
```

対象リポジトリの Settings > Secrets に `CLAUDE_DOTFILES_PAT`（`repo` スコープの PAT）を登録する必要がある。ワークフローファイル自体は `session-start.sh` がセッション開始時に自動インストールする。

---

## PAT（Personal Access Token）の管理

### PAT の作成

1. GitHub → Settings → Developer settings → Personal access tokens → **Tokens (classic)**
2. **Generate new token (classic)**
3. Scope: `repo` にチェック → 生成

### GitHub Secrets への登録

```
リポジトリ → Settings → Secrets and variables → Actions
→ New repository secret
  Name:  CLAUDE_DOTFILES_PAT
  Value: ghp_xxxxxxxxxxxxxxxxxx
```

登録後、Claude に「PAT 登録済み」と伝えると `.claude/.knowledge-sync-ready` が自動作成され、リマインドが止まる。

### 有効期限切れ時の更新

1. GitHub で新しい PAT を生成
2. 登録先リポジトリの Secrets を更新（古い値を上書き）

---

## リポジトリ構成

```
claude-dotfiles/
├── .claude/
│   ├── hooks/
│   │   └── session-start.sh       # Web セッション開始時に自動実行
│   └── settings.json              # フック登録
├── settings.json                  # Claude Code 設定（モデル・effort 等）
├── CLAUDE.md                      # グローバルルール（AI への指示）
├── GRAPH_RAG.md                   # プロジェクト構造グラフ
├── skills/                        # カスタムスキル集（14 個）
│   ├── x-viral-writing/
│   ├── skill-pdca-error-graph/
│   ├── nanobanana/
│   └── ...
├── knowledge/
│   ├── me.md                      # ユーザー個人コンテキスト
│   ├── skills-moc.md              # スキルナレッジグラフ目次
│   ├── skills-graph/
│   │   └── relationships.md       # スキル間補完エッジ
│   └── error-graph/
│       ├── moc.md                 # エラーグラフ目次（自動生成）
│       ├── relationships.md       # トラバーサルグラフ
│       ├── nodes/                 # PDCA ノード（21 件）
│       └── clusters/              # クラスターサマリー（5 件）
├── scripts/
│   ├── bootstrap.sh / .ps1        # 新マシンの初回セットアップ
│   ├── sync.sh / .ps1             # 双方向同期（安全チェック付き）
│   ├── extract-pdca.sh / .ps1     # コミットメッセージから PDCA ノード抽出
│   ├── generate-moc.sh / .ps1     # MOC 目次の自動生成
│   ├── validate-nodes.sh / .ps1   # ノード YAML frontmatter 検証
│   └── setup.sh                   # シンボリックリンク作成
└── templates/
    └── sync-knowledge-to-dotfiles.yml  # スマホ間接同期用 GitHub Actions
```

---

## ライセンス

MIT
