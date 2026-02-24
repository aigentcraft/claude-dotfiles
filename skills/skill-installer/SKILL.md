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

## インストール後の同期

インストール後は必ず claude-dotfiles と antigravity-dotfiles に同期すること：

```bash
bash ~/claude-dotfiles/scripts/sync.sh push
```

これにより knowledge/skills-moc.md も含めて GitHub に反映され、
他のデバイスや他のツールでも同じスキルが使えるようになります。

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
