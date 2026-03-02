#!/bin/bash
# PreToolUse hook: git push の前に PDCA パイプライン + ブランチ制約を自動実行
# Antigravity の sync.sh push と同じ安全チェックを Claude Code でも強制する

TOOL_INPUT=$(cat)
COMMAND=$(echo "$TOOL_INPUT" | python -c "import sys,json; d=json.load(sys.stdin); print(d.get('command',''))" 2>/dev/null \
  || echo "$TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('command',''))" 2>/dev/null \
  || echo "$TOOL_INPUT" | grep -oP '"command"\s*:\s*"\K[^"]+' 2>/dev/null \
  || echo "")

# git push を含むコマンドのみ対象
if ! echo "$COMMAND" | grep -qE '(^|\s)git push'; then
  exit 0
fi

# --- ブランチ制約チェック ---
if echo "$COMMAND" | grep -qE 'origin master$|origin master\s|push master$'; then
  CLAUDE_BRANCH=$(git branch -r 2>/dev/null | grep -E 'origin/claude/' | sed 's|.*origin/||' | head -1 | tr -d ' \n')
  if [ -n "$CLAUDE_BRANCH" ]; then
    echo "BLOCKED: masterへの直接pushは禁止です。"
    echo "このリポジトリには claude/ ブランチが存在します: $CLAUDE_BRANCH"
    echo "正しいコマンド: git push -u origin master:$CLAUDE_BRANCH"
    exit 1
  fi
fi

# --- PDCA パイプライン（sync.sh push と同等） ---
SCRIPTS_DIR="$HOME/claude-dotfiles/scripts"
KNOWLEDGE_DIR="$HOME/claude-dotfiles/knowledge"
SKILLS_DIR="$HOME/claude-dotfiles/skills"

# スクリプトが存在しない場合はスキップ（claude-dotfiles 未セットアップ環境）
if [ ! -d "$SCRIPTS_DIR" ]; then
  exit 0
fi

# 1. validate-nodes: YAML frontmatter 検証
if [ -f "$SCRIPTS_DIR/validate-nodes.sh" ]; then
  bash "$SCRIPTS_DIR/validate-nodes.sh" 2>&1
  if [ $? -ne 0 ]; then
    echo "BLOCKED: PDCA ノードのバリデーションに失敗しました。修正してから push してください。"
    exit 1
  fi
fi

# 2. コンフリクトマーカー検出
CONFLICT_FILES=$(grep -rl '^<<<<<<< ' "$KNOWLEDGE_DIR/" "$SKILLS_DIR/" 2>/dev/null || true)
if [ -n "$CONFLICT_FILES" ]; then
  echo "BLOCKED: マージコンフリクトマーカーが検出されました:"
  echo "$CONFLICT_FILES" | sed 's/^/  /'
  echo "解決してから push してください。"
  exit 1
fi

# 3. extract-pdca: コミットメッセージから PDCA ノード自動抽出
if [ -f "$SCRIPTS_DIR/extract-pdca.sh" ]; then
  bash "$SCRIPTS_DIR/extract-pdca.sh" --since=1.day.ago 2>&1
fi

# 4. generate-moc: MOC 目次を再生成
if [ -f "$SCRIPTS_DIR/generate-moc.sh" ]; then
  bash "$SCRIPTS_DIR/generate-moc.sh" >/dev/null 2>&1
fi

# 5. PDCA で新しいファイルが生成された場合、自動コミット
if [ -d "$KNOWLEDGE_DIR" ] && [ -n "$(cd "$HOME/claude-dotfiles" && git status --porcelain knowledge/ 2>/dev/null)" ]; then
  echo "[PDCA] 新しいノード/MOC更新を検出。claude-dotfiles に自動コミットします。"
  cd "$HOME/claude-dotfiles"
  git add knowledge/
  git commit -m "auto-pdca: extract nodes and regenerate MOC ($(date '+%Y-%m-%d %H:%M:%S'))" 2>&1
  git push 2>&1
  echo "[PDCA] claude-dotfiles の PDCA 更新を push しました。"
fi

exit 0
