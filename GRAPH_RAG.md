# GRAPH_RAG.md - claude-dotfiles

AIへの指示: 新しいセッション開始時・ファイル追加・構造変更時にこのファイルを読み、プロジェクト構造を即座に把握すること。

---

## ノード一覧

| ID | 種別 | パス | 説明 |
|---|---|---|---|
| N1 | dir | `/` | リポジトリルート |
| N2 | file | `CLAUDE.md` | グローバル設定・作業状態・ルール |
| N3 | file | `GRAPH_RAG.md` | このファイル。プロジェクト構造グラフ |
| N4 | file | `README.md` | 公開向けドキュメント |
| N5 | file | `settings.json` | **グローバル設定** → `~/.claude/settings.json` にコピーされる。model/effort/SessionStart+PreToolUse フック定義 |
| N5b | file | `.claude/settings.json` | **プロジェクトレベル設定** → claude-dotfiles リポジトリを開いた時のみ適用。SessionStart フックのみ（`$CLAUDE_PROJECT_DIR` 参照） |
| N6 | dir | `scripts/` | 同期・セットアップ・バリデーションスクリプト群 |
| N7 | file | `scripts/sync.sh` | antigravity-dotfiles との知識同期 |
| N8 | file | `scripts/bootstrap.sh` | 新マシン初回セットアップ |
| N20 | file | `scripts/validate-knowledge.sh` | ナレッジ整合性チェック（push前フック+セッション開始時に実行） |
| N21 | file | `CHANGELOG.md` | CLAUDE.md から溢れた完了済みタスクのアーカイブ |
| N22 | dir | `knowledge/conversation-archive/` | me.md から溢れた Conversation Log のアーカイブ |
| N9 | dir | `skills/` | インストール済みスキル群 |
| N10 | dir | `knowledge/` | 知識ベース（error-graph + skills-graph） |
| N11 | file | `knowledge/skills-moc.md` | スキル MOC（スキル一覧・手順・グラフへのリンク） |
| N12 | dir | `knowledge/skills-graph/` | スキル補完グラフ |
| N13 | file | `knowledge/skills-graph/relationships.md` | スキル間補完エッジの定義（中央グラフ） |
| N14 | dir | `knowledge/error-graph/` | PDCA エラー知識グラフ |
| N15 | file | `knowledge/error-graph/moc.md` | エラー MOC（Quick Rules + クラスター一覧） |
| N16 | dir | `knowledge/error-graph/clusters/` | トピック別クラスターサマリー |
| N17 | dir | `knowledge/error-graph/nodes/` | 個別エラーノード |
| N18 | file | `knowledge/me.md` | ユーザー個人コンテキスト（Profile・Goals・会話ログ・成長軌跡） |
| N19 | file | `SYSTEM_ARCHITECTURE.md` | システム全体のアーキテクチャ図（3層構造・同期経路・知識システム・フック・ガバナンス） |

---

## エッジ（関係性）

| From | To | 関係 | 説明 |
|---|---|---|---|
| N2 | N5 | 参照 | CLAUDE.md がフックのルールを定義 |
| N5 | N6 | 実行 | settings.json が scripts/ のフックを登録 |
| N7 | N10 | 同期 | sync.sh が knowledge/ を antigravity-dotfiles と同期 |
| N8 | N2 | 適用 | bootstrap.sh が CLAUDE.md を ~/.claude/ に配置 |
| N9 | N11 | 索引 | skills-moc.md が skills/ 全体を索引化 |
| N11 | N13 | 参照 | スキル使用時に補完グラフへ誘導 |
| N13 | N9 | 制御 | relationships.md がどのスキルを組み合わせるか定義 |
| N15 | N16 | 集約 | MOC がクラスターを集約・索引化 |
| N16 | N17 | 集約 | クラスターがノードを集約・要約 |
| N11 | N15 | 相互参照 | skills-moc ↔ error-moc で知識体系を横断 |
| N18 | N2 | 強化 | me.md が CLAUDE.md のルール適用を個人化・文脈化 |
| N10 | N18 | 包含 | knowledge/ が me.md を含む（セッション開始時一括適用） |
| N19 | N3 | 補完 | SYSTEM_ARCHITECTURE.md が GRAPH_RAG.md を視覚的に補完（全体像 vs 構造グラフ） |
| N19 | N2 | 参照 | SYSTEM_ARCHITECTURE.md が CLAUDE.md のルール・設計原則を図示 |
| N20 | N15 | 検証 | validate-knowledge.sh が MOC とノードの整合性を検証 |
| N20 | N17 | 検証 | validate-knowledge.sh がノードのクラスター所属を検証 |
| N21 | N2 | アーカイブ | CHANGELOG.md が CLAUDE.md の完了済みタスクを受け入れ |
| N22 | N18 | アーカイブ | conversation-archive/ が me.md の Conv Log を受け入れ |
| N5 | N5b | 上位 | グローバル settings.json がプロジェクト settings.json の上位設定 |

---

## クラスター（機能グループ）

```
[知識体系]
  knowledge/
    ├── me.md                 ← ユーザー個人コンテキスト（最優先で読む）
    ├── skills-moc.md         ← スキルの地図
    ├── skills-graph/         ← スキル間関係（補完グラフ）
    └── error-graph/          ← 失敗知識（PDCA）
          ├── moc.md
          ├── clusters/
          └── nodes/

[設定・同期]
  CLAUDE.md + settings.json + scripts/
    → Claude Code の動作ルールと環境同期を担う

[スキル実行層]
  skills/
    → 実際の機能を提供するスキルファイル群
    → skills-moc.md と relationships.md に索引・関係が記録される
```

---

## 現在の開発フォーカス

- **システム監査＆10項目改善**（2026-03-01）
  - MOC デ同期修正 + バリデーション仕組み化（push前自動検証）
  - スケーラビリティ改善（CLAUDE.md/me.md アーカイブ化、MOC トラバーサル化）
  - セキュリティ＆堅牢性改善（フック正規表現、session-start マージ化、sync.sh 安全化）
  - エスカレーション自動チェック、欠損クラスター作成、settings.json 明文化

---

## メンテナンスルール

| 条件 | アクション |
|---|---|
| 新しいファイル/ディレクトリを作成した | ノード一覧に追記し、関連エッジを追加 |
| スキルを追加した | N9 配下にノード追加・relationships.md に補完エッジ検討 |
| commit & push 時 | CLAUDE.md の作業状態と同時に更新 |
