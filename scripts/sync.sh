#!/bin/bash
# Antigravity auto-sync script
# Usage: bash scripts/sync.sh [push|pull|watch]

WORKSPACE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_DOTFILES_DIR="$HOME/claude-dotfiles"

sync_pull() {
  echo "[Antigravity] Pulling latest changes..."
  
  # Pull antigravity-dotfiles
  cd "$WORKSPACE_DIR"
  git pull --rebase --autostash 2>/dev/null || git pull

  # Bridge: Pull claude-dotfiles and copy to local
  if [ -d "$CLAUDE_DOTFILES_DIR" ]; then
    echo "[Antigravity] Bridging from claude-dotfiles..."
    cd "$CLAUDE_DOTFILES_DIR"
    git pull --rebase --autostash 2>/dev/null || git pull
    
    # Bridging copy logic removed. Rely on Directory Junctions / Symlinks.
  fi

  # Extract PDCA nodes from recent commit messages
  if [ -f "$WORKSPACE_DIR/scripts/extract-pdca.sh" ]; then
    bash "$WORKSPACE_DIR/scripts/extract-pdca.sh" --since=3.days.ago
  fi

  echo "[Antigravity] Pull complete."
}

sync_push() {
  has_changes=false
  current_date=$(date '+%Y-%m-%d %H:%M:%S')

  # Pre-flight: validate nodes
  if [ -f "$WORKSPACE_DIR/scripts/validate-nodes.sh" ]; then
    bash "$WORKSPACE_DIR/scripts/validate-nodes.sh" || {
      echo "[ERROR] Node validation failed. Fix before pushing."
      return 1
    }
  fi

  # Pre-flight: detect merge conflict markers (line-anchored to avoid false positives in docs)
  CONFLICT_FILES=$(grep -rl '^<<<<<<< ' "$WORKSPACE_DIR/knowledge/" "$WORKSPACE_DIR/skills/" 2>/dev/null || true)
  if [ -n "$CONFLICT_FILES" ]; then
    echo "[ERROR] Merge conflict markers detected in:"
    echo "$CONFLICT_FILES" | sed 's/^/  /'
    echo "Resolve before pushing."
    return 1
  fi

  # Extract PDCA nodes from recent commits before push (safety net)
  if [ -f "$WORKSPACE_DIR/scripts/extract-pdca.sh" ]; then
    bash "$WORKSPACE_DIR/scripts/extract-pdca.sh" --since=1.day.ago
  fi

  # Generate MOC before checking status to ensure index is up to date
  bash "$WORKSPACE_DIR/scripts/generate-moc.sh" >/dev/null 2>&1

  # Bridge: Copy local changes to claude-dotfiles
  if [ -d "$CLAUDE_DOTFILES_DIR" ]; then
    # Bridging copy logic removed. Rely on Directory Junctions / Symlinks.

    # Pre-flight: detect conflict markers in claude-dotfiles too
    CLAUDE_CONFLICTS=$(grep -rl '^<<<<<<< ' "$CLAUDE_DOTFILES_DIR/knowledge/" "$CLAUDE_DOTFILES_DIR/skills/" 2>/dev/null || true)
    if [ -n "$CLAUDE_CONFLICTS" ]; then
      echo "[ERROR] Merge conflict markers detected in claude-dotfiles:"
      echo "$CLAUDE_CONFLICTS" | sed 's/^/  /'
      echo "Resolve before pushing."
      return 1
    fi

    # Push claude-dotfiles
    cd "$CLAUDE_DOTFILES_DIR"
    if [ -n "$(git status --porcelain)" ]; then
      echo "[Antigravity] Pushing bridged changes to claude-dotfiles..."
      git add -A
      git commit -m "auto-sync (from Antigravity): $current_date"
      git push
    fi
  fi

  # Push antigravity-dotfiles
  cd "$WORKSPACE_DIR"
  if [ -n "$(git status --porcelain)" ]; then
    echo "[Antigravity] Changes detected, pushing..."
    git add -A
    git commit -m "auto-sync: $current_date"
    git push
    has_changes=true
  fi

  if [ "$has_changes" = true ]; then
    echo "[Antigravity] Push complete."
  else
    echo "[Antigravity] No changes to push."
  fi
}

sync_watch() {
  echo "[Antigravity] Watching for changes... (Ctrl+C to stop)"
  sync_pull
  while true; do
    sleep 30
    cd "$WORKSPACE_DIR"
    if [ -n "$(git status --porcelain)" ]; then
      sync_push
    fi
    # Check for remote changes
    git fetch --quiet 2>/dev/null
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse @{u} 2>/dev/null)
    if [ "$LOCAL" != "$REMOTE" ]; then
      sync_pull
    fi
  done
}

case "${1:-pull}" in
  pull)  sync_pull ;;
  push)  sync_push ;;
  watch) sync_watch ;;
  *)     echo "Usage: scripts/sync.sh [pull|push|watch]" ;;
esac
