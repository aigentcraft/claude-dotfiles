# System Architecture — claude-dotfiles

> claude-dotfiles は「もう1人の土屋健太」を実現するための AI インフラシステム。
> 設定・知識・スキルを Git で管理し、Windows / Mac / スマホ間で永続化・同期する。

---

## 1. 全体像（Three-Layer Architecture）

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AI Runtime Layer                             │
│                                                                     │
│   ┌───────────────┐  ┌────────────────┐  ┌─────────────────────┐   │
│   │  ~/.claude/    │  │ Claude Code    │  │ Session Context     │   │
│   │  settings.json │──│ (CLI/Web)      │──│ (対話・実行)        │   │
│   │  CLAUDE.md     │  │                │  │                     │   │
│   │  skills/       │  │  Hooks:        │  │  me.md → 人物理解   │   │
│   │  knowledge/    │  │  SessionStart  │  │  moc.md → 失敗知識  │   │
│   └───────┬───────┘  │  PreToolUse    │  │  skills → 能力     │   │
│           │          └────────────────┘  └─────────────────────┘   │
│           │                                                         │
│   symlink (Mac/Linux) │ copy (Windows/Web)                          │
│           │                                                         │
├───────────┼─────────────────────────────────────────────────────────┤
│           ▼                                                         │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              claude-dotfiles (このリポジトリ = Hub)          │   │
│  │                                                              │   │
│  │  settings.json ─── フック定義・モデル設定                     │   │
│  │  CLAUDE.md ──────── ルール・作業状態・セッション引継ぎ        │   │
│  │  GRAPH_RAG.md ───── プロジェクト構造グラフ                    │   │
│  │  skills/ ────────── 13スキル（SNS・画像生成・開発・ガバナンス）│   │
│  │  knowledge/ ─────── 知識ベース（error-graph, skills-graph）   │   │
│  │  scripts/ ───────── 同期・セットアップスクリプト               │   │
│  │  templates/ ─────── GitHub Actions ワークフローテンプレート    │   │
│  │  .claude/hooks/ ─── セッション開始・push防止フック            │   │
│  └─────────────────────────────┬─────────────────────────────────┘   │
│                                │                                    │
│                bridge_from/to_antigravity()                         │
│                                │                                    │
│  ┌─────────────────────────────▼─────────────────────────────────┐  │
│  │           antigravity-dotfiles (Upstream Source)               │  │
│  │                                                                │  │
│  │  knowledge/ ─── エラーノード・スキルグラフの上流               │  │
│  │  skills/ ────── npx skills でインストールされたスキルの原本    │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. 同期パスウェイ（4経路）

```
                    ┌──────────────────────────────┐
                    │     antigravity-dotfiles      │
                    │        (upstream)              │
                    └──────────┬───────────────────-┘
                               │
                  bridge_from_antigravity()
                  bridge_to_antigravity()
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                    claude-dotfiles                           │
│                      (Git Hub)                               │
│                                                              │
│   master ◄──── auto-merge ◄──── claude/* branches            │
│     │              │                    ▲                     │
│     │         GitHub Actions            │                    │
│     │              │                    │ git push            │
│     │              │                    │                     │
└─────┼──────────────┼────────────────────┼────────────────────┘
      │              │                    │
      │              │                    │
┌─────▼──────┐  ┌────▼─────┐   ┌─────────┴──────────┐
│            │  │          │   │                      │
│  Pathway 1 │  │Pathway 3 │   │    Pathway 4         │
│  Mac/Linux │  │ Windows  │   │    Web/Smartphone     │
│            │  │          │   │                       │
│ setup.sh   │  │sync.sh   │   │ ┌───────────────────┐│
│ creates    │  │copies    │   │ │ Session on Web    ││
│ symlinks   │  │files     │   │ │                   ││
│            │  │          │   │ │ Option A:          ││
│ ~/.claude/ │  │~/.claude/│   │ │  Push to claude/  ││
│ ↕ (live)   │  │(snapshot)│   │ │  branch           ││
│ claude-    │  │          │   │ │                   ││
│ dotfiles   │  │          │   │ │ Option B:          ││
│            │  │          │   │ │  Push to staging  ││
│            │  │          │   │ │  (.claude-         ││
│            │  │          │   │ │   knowledge-       ││
│            │  │          │   │ │   staging/)        ││
└────────────┘  └──────────┘   │ └───────────────────┘│
                               │                       │
                               └───────────────────────┘

─────────────────────────────────────────────────────────

 Pathway 1: Mac/Linux（symlink方式）
   setup.sh → ~/.claude/ に symlink 作成
   変更は即座に双方向反映

 Pathway 2: antigravity-dotfiles（bridge方式）
   sync.sh pull → antigravity → claude-dotfiles
   sync.sh push → claude-dotfiles → antigravity

 Pathway 3: Windows（copy方式）
   bootstrap.ps1 / sync.sh → ファイルをコピー
   sync.sh push で逆方向に回収

 Pathway 4: Web/Smartphone（間接方式）
   A) claude/* ブランチ → GitHub Actions auto-merge → master
   B) .claude-knowledge-staging/ → GitHub Actions sync → claude-dotfiles
```

---

## 3. 知識システム（Knowledge Architecture）

```
┌──────────────────────────────────────────────────────────┐
│                    Knowledge Layer                        │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │                   me.md                              │ │
│  │            Personal Memory                           │ │
│  │                                                      │ │
│  │  Profile ─── キャリア・家族・思考スタイル              │ │
│  │  Goals ────── 短期/中期/長期の目標                    │ │
│  │  Tech Stack ─ 技術スキル一覧                          │ │
│  │  Conv Log ─── セッション間の記憶の連鎖                │ │
│  │  Growth Map ─ 成長の軌跡                              │ │
│  │                                                      │ │
│  │  ※ セッション開始時に最優先で読み込み                 │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌──────────────────────┐  ┌──────────────────────────┐ │
│  │   Error Graph (PDCA) │  │   Skills Graph           │ │
│  │                      │  │                          │ │
│  │  moc.md              │  │  skills-moc.md           │ │
│  │    │                 │  │    │                     │ │
│  │    ├── clusters/     │◄─┼────┤                     │ │
│  │    │   ├ ai-behavior │  │    │  relationships.md   │ │
│  │    │   ├ api-network │  │    │    │                │ │
│  │    │   ├ copywriting │  │    │    ├── X/SNS        │ │
│  │    │   ├ platform    │  │    │    ├── Image Gen    │ │
│  │    │   └ shell-hook  │  │    │    ├── Proj Mgmt   │ │
│  │    │                 │  │    │    ├── Dev          │ │
│  │    └── nodes/        │  │    │    └── Governance   │ │
│  │        (18 nodes)    │  │    │                     │ │
│  │                      │  │    └── 13 Skills         │ │
│  │  relationships.md    │  │                          │ │
│  │  (action→flag map)   │  │                          │ │
│  └──────────────────────┘  └──────────────────────────┘ │
│                                                          │
│  ┌──────────────────────────────────────────────────────┐│
│  │            Escalation Pipeline                       ││
│  │                                                      ││
│  │  Error発生 → node作成 → 3+同種 → cluster rule化      ││
│  │  → 5+ cluster rules → Quick Rule昇格                 ││
│  │  → 10+ Quick Rules → SKILL.md昇格                    ││
│  │                                                      ││
│  │  ※ 失敗知識は自動的に「より目立つ場所」へ昇格する     ││
│  └──────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────┘
```

---

## 4. フック & ガバナンス（Hook & Governance System）

```
┌─────────────────────────────────────────────────────────────┐
│                     Hook System                              │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  SessionStart Hook                                    │   │
│  │  (.claude/hooks/session-start.sh)                     │   │
│  │                                                       │   │
│  │  CLAUDE_CODE_REMOTE=true の場合のみ実行               │   │
│  │                                                       │   │
│  │  1. settings.json → ~/.claude/ にコピー               │   │
│  │  2. CLAUDE.md → ~/.claude/ にコピー                   │   │
│  │  3. skills/ → ~/.claude/skills/ にコピー              │   │
│  │  4. knowledge/ → ~/.claude/knowledge/ にコピー        │   │
│  │  5. workflow テンプレート → 対象プロジェクトに自動設置 │   │
│  │  6. PAT 未登録なら注意喚起バナー表示                  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  PreToolUse Hook (Bash matcher)                       │   │
│  │  (.claude/hooks/pre-bash-git-push.sh)                 │   │
│  │                                                       │   │
│  │  git push コマンドを検知 → master への直接 push を    │   │
│  │  プログラム的にブロック（claude/ ブランチが存在時）    │   │
│  │                                                       │   │
│  │  ※ rule-vs-code 原則の実装例                          │   │
│  │    「ルールで覚えさせる」ではなく「コードで強制する」  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│                  Governance Mechanisms                        │
│                                                              │
│  ┌────────────────┐ ┌──────────────────┐ ┌───────────────┐  │
│  │ UC Detection   │ │ Exit Conditions  │ │ Push前スキャン │  │
│  │                │ │                  │ │               │  │
│  │ トリガーワード:│ │ fix: コミット時  │ │ 自問:         │  │
│  │ 「足りない」   │ │ → error node必須 │ │ 「指摘は      │  │
│  │ 「まずい」     │ │ → cluster更新    │ │  あったか？」 │  │
│  │ 「そうじゃない」│ │ → moc追記       │ │ → UC node確認 │  │
│  │                │ │                  │ │               │  │
│  │ → 返答前に     │ │ ナレッジ蓄積なし │ │ 未対応なら    │  │
│  │   node作成開始 │ │ = 不完全コミット │ │ push禁止      │  │
│  └────────────────┘ └──────────────────┘ └───────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Meta-Principles (設計原則)                           │   │
│  │                                                       │   │
│  │  rule-vs-code ────── ルールよりコードで強制            │   │
│  │  system-not-promise ─ 宣言はファイルに書いて初めて有効 │   │
│  │  exit-condition ──── 重要な後処理は完了条件にする      │   │
│  │  lateral-expansion ─ 1箇所で実装→全体の横展開チェック  │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

---

## 5. スキルシステム（Skills Architecture）

```
┌──────────────────────────────────────────────────────────────────┐
│                        Skills Layer (13 skills)                   │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  X/SNS Cluster                                               │ │
│  │                                                              │ │
│  │  x-viral-writing ◄──補完──► x-image-prompt                  │ │
│  │       │                          │                           │ │
│  │       ▼                          ▼                           │ │
│  │  copywriting              nanobanana / gpt-image-1-5         │ │
│  │       │                          ▲                           │ │
│  │       ▼                          │                           │ │
│  │  ai-social-media-content   nano-banana-pro-prompts           │ │
│  │                          -recommend-skill                    │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌──────────────────────┐  ┌────────────────────────────────┐   │
│  │  Project Management  │  │  Development & Operations      │   │
│  │                      │  │                                │   │
│  │  skill-pdca-error    │  │  slack-remote-run              │   │
│  │  -graph              │  │       │                        │   │
│  │       │              │  │       ├──► auto-sync-rule      │   │
│  │       ▼              │  │       │                        │   │
│  │  skill-project-map   │  │  skill-hyperbrowser-reference  │   │
│  └──────────────────────┘  └────────────────────────────────┘   │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  System / Governance Cluster                                 │ │
│  │                                                              │ │
│  │  skill-installer ◄──補完──► auto-sync-rule                  │ │
│  │  (インストール後に即同期ルール適用)                          │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  Synthesis Protocol                                          │ │
│  │                                                              │ │
│  │  Simple task ──── +1 complementary skill                     │ │
│  │  Complex task ─── All skills in cluster                      │ │
│  │  "Best/Perfect" ─ All available skills                       │ │
│  │                                                              │ │
│  │  ※ 1スキル即実行は禁止。必ず relationships.md を確認         │ │
│  └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

---

## 6. GitHub Actions パイプライン

```
┌──────────────────────────────────────────────────────────────────┐
│                   CI/CD & Automation                              │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │  auto-merge-knowledge-from-claude-branches.yml            │   │
│  │  (claude-dotfiles リポジトリ内)                            │   │
│  │                                                            │   │
│  │  Trigger: push to claude/** branch                         │   │
│  │                                                            │   │
│  │  claude/* branch ─── diff分析 ──┬── knowledge-only changes │   │
│  │                                  │   → auto-merge to master │   │
│  │                                  │                          │   │
│  │                                  └── non-knowledge files    │   │
│  │                                      → skip (manual PR)    │   │
│  └───────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │  sync-knowledge-to-dotfiles.yml                           │   │
│  │  (各プロジェクトに自動インストール)                       │   │
│  │                                                            │   │
│  │  Trigger: push to .claude-knowledge-staging/**             │   │
│  │                                                            │   │
│  │  staging/ ─── .md files ──────► knowledge/error-graph/nodes│   │
│  │           │                                                │   │
│  │           ├── moc-updated.md ─► knowledge/error-graph/moc  │   │
│  │           │                                                │   │
│  │           └── subdirectories ─► knowledge/<dirname>/        │   │
│  │                                                            │   │
│  │  完了後: staging ディレクトリを削除 + claude-dotfiles push  │   │
│  │  ※ CLAUDE_DOTFILES_PAT シークレット必須                    │   │
│  └───────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │  Auto-Install Mechanism                                    │   │
│  │                                                            │   │
│  │  session-start.sh ─── プロジェクトに workflow がなければ   │   │
│  │                       templates/ からコピー → commit → push │   │
│  │                       (4回リトライ・指数バックオフ)         │   │
│  │                                                            │   │
│  │  PAT Reminder ──────── workflow あり + .knowledge-sync-    │   │
│  │                         ready なし → バナー表示            │   │
│  └───────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

---

## 7. セッションライフサイクル

```
Session Start
    │
    ▼
┌─────────────────────────────────────┐
│  1. SessionStart Hook 実行          │
│     (Web: ファイルコピー)            │
│     (Local: symlink済みなのでスキップ)│
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  2. セッション開始時読み込み        │
│     ① me.md (人物・目標・文脈)      │
│     ② error-graph/moc.md (Quick Rules)│
│     ③ skills-moc.md (スキル一覧)    │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  3. git pull (最新コード取得)       │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  4. 開発作業                        │
│                                     │
│  ・error-graph/relationships.md の  │
│    Action→Flag マップに従い行動     │
│  ・スキル使用時は補完グラフ確認     │
│  ・UC トリガーワード検出で即node作成│
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  5. Commit & Push                   │
│                                     │
│  ┌─ fix: コミットの場合 ──────────┐ │
│  │  ① error node 作成             │ │
│  │  ② cluster 更新                │ │
│  │  ③ moc 追記                    │ │
│  │  → これなしでは不完全コミット  │ │
│  └────────────────────────────────┘ │
│                                     │
│  ┌─ push 前 ─────────────────────┐  │
│  │  UC スキャン: 指摘あったか？  │  │
│  │  → あれば UC node 確認        │  │
│  └───────────────────────────────┘  │
│                                     │
│  CLAUDE.md 作業状態更新             │
│  GRAPH_RAG.md 更新                  │
│  me.md 更新（気づき・成長があれば）  │
└─────────────────────────────────────┘
```

---

## 8. ファイルツリー（全体構造）

```
claude-dotfiles/
├── .claude/
│   ├── hooks/
│   │   ├── session-start.sh      ← Web セッション初期化
│   │   └── pre-bash-git-push.sh  ← master push 防止フック
│   └── settings.json             ← プロジェクトレベル設定
│
├── .github/
│   └── workflows/
│       └── auto-merge-knowledge-from-claude-branches.yml
│
├── scripts/
│   ├── bootstrap.sh              ← 初回セットアップ (Mac/Linux)
│   ├── bootstrap.ps1             ← 初回セットアップ (Windows)
│   ├── setup.sh                  ← symlink 作成
│   └── sync.sh                   ← 3層同期エンジン
│
├── templates/
│   └── sync-knowledge-to-dotfiles.yml  ← 他プロジェクト向けワークフロー
│
├── skills/                        ← 13 スキル
│   ├── ai-social-media-content/
│   ├── auto-sync-rule/
│   ├── copywriting/
│   ├── gpt-image-1-5/
│   ├── nanobanana/
│   ├── nano-banana-pro-prompts-recommend-skill/
│   ├── skill-hyperbrowser-reference/
│   ├── skill-installer/
│   ├── skill-pdca-error-graph/
│   ├── skill-project-map/
│   ├── slack-remote-run/
│   ├── x-image-prompt/
│   └── x-viral-writing/
│
├── knowledge/
│   ├── me.md                      ← Personal Memory
│   ├── skills-moc.md              ← スキル MOC
│   ├── skills-graph/
│   │   └── relationships.md       ← スキル補完グラフ
│   └── error-graph/
│       ├── moc.md                 ← エラー MOC
│       ├── relationships.md       ← Action→Flag マップ
│       ├── timestamps.json
│       ├── clusters/              ← 5 クラスター
│       │   ├── ai-behavior.md
│       │   ├── api-network.md
│       │   ├── copywriting-psychology.md
│       │   ├── platform-syntax.md
│       │   └── shell-hook-env.md
│       └── nodes/                 ← 18 エラーノード
│
├── settings.json                  ← グローバル設定 (→ ~/.claude/)
├── CLAUDE.md                      ← マスタールールブック
├── GRAPH_RAG.md                   ← プロジェクト構造グラフ
└── SYSTEM_ARCHITECTURE.md         ← このファイル
```

---

## 9. 設計原則

| 原則 | 内容 | 実装例 |
|------|------|--------|
| **rule-vs-code** | ルールより先にコードで強制 | pre-bash-git-push.sh |
| **system-not-promise** | 宣言はファイルに書いて初めて有効 | UC node 即時作成 |
| **exit-condition** | 重要な後処理は完了の出口条件に | fix: コミットの3ステップ |
| **lateral-expansion** | 1箇所で実装→全体の横展開チェック | パターン適用後の全体確認 |
| **escalation** | 頻出パターンはより目立つ場所へ昇格 | node → cluster → Quick Rule → SKILL |
| **knowledge-never-lost** | 学んだことは必ずファイルに残す | PDCA Error Graph + me.md |
| **multi-device-sync** | どのデバイスからでも同じ知識にアクセス | 4経路の同期パスウェイ |

---

*最終更新: 2026-02-28 | 作成者: claude-dotfiles system architecture documentation*
