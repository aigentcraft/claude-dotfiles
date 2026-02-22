# claude-dotfiles

Claude Code の設定を複数マシン間で同期するリポジトリ。

## セットアップ（新しいマシンで1回だけ実行）

```bash
git clone https://github.com/aigentcraft/claude-dotfiles.git ~/claude-dotfiles
bash ~/claude-dotfiles/scripts/setup.sh
```

## 自動同期

30秒ごとに変更を検知して自動 push：

```bash
bash ~/claude-dotfiles/scripts/sync.sh watch
```

## 手動同期

```bash
bash ~/claude-dotfiles/scripts/sync.sh pull   # 最新を取得
bash ~/claude-dotfiles/scripts/sync.sh push   # 変更をアップロード
```

## 同期される設定

| ファイル | 内容 |
|---|---|
| `settings.json` | Claude Code の設定（モデル、effort等） |
| `CLAUDE.md` | グローバルルール |
| `skills/` | スキルグラフ |
