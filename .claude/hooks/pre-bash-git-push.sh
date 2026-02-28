#!/bin/bash
# PreToolUse hook: git push のブランチ制約を自動チェック
# AIのルール記憶に依存せず、コードで強制する

TOOL_INPUT=$(cat)
COMMAND=$(echo "$TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('command',''))" 2>/dev/null || echo "")

# git push を含むコマンドのみ対象
if ! echo "$COMMAND" | grep -qE '(^|\s)git push'; then
  exit 0
fi

# masterへのpushを検知（ブランチマッピングなし）
if echo "$COMMAND" | grep -qE 'origin master$|origin master\s|push master$'; then
  # リモートに claude/ ブランチが存在するか確認
  CLAUDE_BRANCH=$(git branch -r 2>/dev/null | grep -E 'origin/claude/' | sed 's|.*origin/||' | head -1 | tr -d ' \n')

  if [ -n "$CLAUDE_BRANCH" ]; then
    echo "BLOCKED: masterへの直接pushは禁止です。"
    echo "このリポジトリには claude/ ブランチが存在します: $CLAUDE_BRANCH"
    echo "正しいコマンド: git push -u origin master:$CLAUDE_BRANCH"
    exit 1
  fi
fi

exit 0
