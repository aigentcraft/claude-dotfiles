# Cluster: shell-hook-env — Claude Code フック・シェル環境変数

**ロード条件**: Claude Code フック・session-start.sh・シェルスクリプトを書く時

---

## 蒸留ルール

1. **フック内のプロジェクトパス取得**: `${CLAUDE_PROJECT_DIR:-$PWD}` を使う。`DOTFILES_DIR` へのフォールバックは禁止（常に dotfiles 自身と判定されてしまう）
2. **フック環境変数のログ出力**: 取得した環境変数の値（未設定時のフォールバック先）をログに出力して検証しやすくする

---

## ノード

- [[../nodes/claude-hook-env-project-dir.md]] — `CLAUDE_PROJECT_DIR` 未設定によるプロジェクト判定バグ
