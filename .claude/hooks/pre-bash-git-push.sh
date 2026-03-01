#!/bin/bash
# PreToolUse hook: git push のブランチ制約 + ナレッジ整合性を自動チェック
# AIのルール記憶に依存せず、コードで強制する

TOOL_INPUT=$(cat)
COMMAND=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('command',''))" 2>/dev/null || echo "")

# git push を含むコマンドのみ対象
if ! echo "$COMMAND" | grep -qE '(^|\s)git push'; then
  exit 0
fi

# --- Check 1: master への直接 push を検知 ---
# origin master, HEAD:master, branch:master, refs/heads/master を全てキャッチ
if echo "$COMMAND" | grep -qE '(origin\s+master(\s|$))|(push\s+master(\s|$))|(:master(\s|$))|(:refs/heads/master)'; then
  # リモートに claude/ ブランチが存在するか確認
  CLAUDE_BRANCH=$(git branch -r 2>/dev/null | grep -E 'origin/claude/' | sed 's|.*origin/||' | head -1 | tr -d ' \n')

  if [ -n "$CLAUDE_BRANCH" ]; then
    echo "BLOCKED: masterへの直接pushは禁止です。"
    echo "このリポジトリには claude/ ブランチが存在します: $CLAUDE_BRANCH"
    echo "正しいコマンド: git push -u origin $CLAUDE_BRANCH"
    exit 1
  fi
fi

# --- Check 2: claude-dotfiles へのpush時はナレッジ整合性を検証 ---
DOTFILES_DIR="$HOME/claude-dotfiles"
VALIDATE_SCRIPT="$DOTFILES_DIR/scripts/validate-knowledge.sh"

# 現在のリポジトリが claude-dotfiles の場合のみ実行
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [ "$REPO_ROOT" = "$DOTFILES_DIR" ] && [ -f "$VALIDATE_SCRIPT" ]; then
  if ! bash "$VALIDATE_SCRIPT" 2>&1; then
    echo ""
    echo "BLOCKED: ナレッジの整合性チェックに失敗しました。"
    echo "上記のエラーを修正してから push してください。"
    exit 1
  fi
fi

exit 0
