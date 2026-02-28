---
name: skill-installer
description: ユーザーの目的に合わせて skills.sh レジストリから有用なスキルを検索・インストールします。「〇〇のスキルを探して」「〇〇できるスキルある？」「スキルをインストールして」などと言われたら使用してください。
---

# Skill Installer

`npx skills` CLI（skills.sh）を使ってスキルを検索・インストールします。

## スキル検索

```bash
# キーワードで検索
npx skills search <keyword>

# 例
npx skills search copywriting
npx skills search testing
npx skills search nextjs
```

検索結果には `owner/repo@skill名` と install数が表示されます。人気順に表示されるので、上位のものが信頼性が高い傾向にあります。

## スキルのインストール

```bash
# グローバルインストール（推奨: Claude Code + Antigravity 両方に反映）
npx skills add <owner/repo> --skill <skill名> --global --yes

# 例
npx skills add coreyhaines31/marketingskills --skill copywriting --global --yes

# GitHub URL でも可
npx skills add https://github.com/coreyhaines31/marketingskills --skill copywriting --global --yes

# リポジトリ内の全スキルをインストール
npx skills add <owner/repo> --all
```

## インストール後の必須手順（順番通りに実行すること）

### 1. 新スキルの内容を読む
```bash
cat ~/.claude/skills/<スキル名>/SKILL.md
```

### 2. Skills GraphRAG を更新する

**`~/claude-dotfiles/knowledge/skills-graph/relationships.md` を読み**、新スキルと既存スキルの補完関係を判断して追記する。

判断基準:
- 「一緒に使うとアウトプットが良くなるか？」→ 補完エッジを追加
- どのクラスターに属するか？ → 既存クラスターに追記 or 新クラスター作成

**`~/claude-dotfiles/knowledge/skills-moc.md` にも新スキルのエントリを追記する:**
```markdown
- [[../skills/<スキル名>/SKILL.md|<スキル名>]] : <概要1行>
  - 補完: `<関連スキル名>`  ← あれば
```

### 3. GRAPH_RAG.md を更新する

`~/claude-dotfiles/GRAPH_RAG.md` のノード一覧に新スキルを追記する。

### 4. claude-dotfiles と antigravity-dotfiles に同期する
```bash
bash ~/claude-dotfiles/scripts/sync.sh push
```

これにより他のデバイス・他のセッションでも即座に新スキルとグラフが使えるようになります。

## インストール済みスキルの確認

```bash
npx skills list
```

## スキルの更新

```bash
npx skills update
```

## 注意事項

- `--global` フラグを付けると `~/.agents/skills/` にインストールされ、Claude Code・Antigravity・Gemini CLI などに自動でシンボリックリンクされます
- インストール時にセキュリティリスク評価（Gen/Socket/Snyk）が自動で行われます
- スキルはエージェントにフルパーミッションで渡されるため、インストール前に概要を確認してください
