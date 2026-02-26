#!/bin/bash
set -euo pipefail

# Only run in web/remote environments (Claude Code on the web / smartphone)
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# claude-dotfiles は常に固定パス（スクリプト位置から2階層上）
DOTFILES_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
CLAUDE_DIR="$HOME/.claude"

# 現在開いているプロジェクト（Claude Code が CLAUDE_PROJECT_DIR にセット）
# 未設定の場合は claude-dotfiles 自身と見なす
CURRENT_PROJECT="${CLAUDE_PROJECT_DIR:-$DOTFILES_DIR}"

echo "=== claude-dotfiles: Setting up web session ==="
echo "Dotfiles dir:    $DOTFILES_DIR"
echo "Current project: $CURRENT_PROJECT"
echo "Claude dir:      $CLAUDE_DIR"

# Ensure ~/.claude directories exist
mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/knowledge"

# Apply settings.json (model, effort level etc.)
if [ -f "$DOTFILES_DIR/settings.json" ]; then
  cp -f "$DOTFILES_DIR/settings.json" "$CLAUDE_DIR/settings.json"
  echo "[OK] settings.json applied"
fi

# Apply global CLAUDE.md (rules, GraphRAG rules, sync rules)
if [ -f "$DOTFILES_DIR/CLAUDE.md" ]; then
  cp -f "$DOTFILES_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
  echo "[OK] CLAUDE.md applied"
fi

# Apply skills
SKILL_COUNT=0
for skill_dir in "$DOTFILES_DIR/skills"/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name=$(basename "$skill_dir")
  mkdir -p "$CLAUDE_DIR/skills/$skill_name"
  cp -rf "$skill_dir"* "$CLAUDE_DIR/skills/$skill_name/" 2>/dev/null || true
  SKILL_COUNT=$((SKILL_COUNT + 1))
done
echo "[OK] $SKILL_COUNT skills applied"

# Apply knowledge base
if [ -d "$DOTFILES_DIR/knowledge" ]; then
  mkdir -p "$CLAUDE_DIR/knowledge"
  cp -Rf "$DOTFILES_DIR/knowledge/"* "$CLAUDE_DIR/knowledge/" 2>/dev/null || true
  echo "[OK] knowledge base applied"
fi

# Export DOTFILES_DIR for the session
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export DOTFILES_DIR=\"$DOTFILES_DIR\"" >> "$CLAUDE_ENV_FILE"
fi

# ---------------------------------------------------------------
# Auto-install knowledge sync workflow in the current project
# (claude-dotfiles 自身はスキップ)
# ---------------------------------------------------------------
WORKFLOW_DEST="$CURRENT_PROJECT/.github/workflows/sync-knowledge-to-dotfiles.yml"
WORKFLOW_SRC="$DOTFILES_DIR/templates/sync-knowledge-to-dotfiles.yml"

if [ "$CURRENT_PROJECT" != "$DOTFILES_DIR" ] && \
   [ -f "$WORKFLOW_SRC" ] && \
   [ ! -f "$WORKFLOW_DEST" ]; then

  echo "[Knowledge Sync] Workflow not found in project. Auto-installing..."
  mkdir -p "$(dirname "$WORKFLOW_DEST")"
  cp "$WORKFLOW_SRC" "$WORKFLOW_DEST"

  cd "$CURRENT_PROJECT"
  git add ".github/workflows/sync-knowledge-to-dotfiles.yml"

  if git diff --cached --quiet; then
    echo "[Knowledge Sync] Already committed, skipping"
  else
    git commit -m "[knowledge-sync] auto-install sync workflow via session-start hook"

    # Push with exponential backoff retry (up to 4 times)
    PUSHED=false
    for attempt in 1 2 3 4; do
      echo "[Knowledge Sync] Push attempt $attempt..."
      if git push; then
        echo "[Knowledge Sync] Workflow installed and pushed successfully"
        PUSHED=true
        break
      fi
      if [ $attempt -lt 4 ]; then
        sleep_sec=$((2 ** attempt))
        echo "[Knowledge Sync] Push failed, retrying in ${sleep_sec}s..."
        sleep "$sleep_sec"
        git pull --rebase 2>/dev/null || true
      fi
    done

    if [ "$PUSHED" = "false" ]; then
      echo "[Knowledge Sync] WARNING: Push failed after 4 attempts. Workflow file is staged but not pushed."
    fi
  fi
fi

echo "=== claude-dotfiles: Web session setup complete ==="
