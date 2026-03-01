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

  echo "[Antigravity] Pull complete."
}

sync_push() {
  has_changes=false
  current_date=$(date '+%Y-%m-%d %H:%M:%S')

  # Generate MOC before checking status to ensure index is up to date
  bash "$WORKSPACE_DIR/scripts/generate-moc.sh" >/dev/null 2>&1

  # Bridge: Copy local changes to claude-dotfiles
  if [ -d "$CLAUDE_DOTFILES_DIR" ]; then
    # Bridging copy logic removed. Rely on Directory Junctions / Symlinks.
    
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
