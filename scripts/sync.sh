#!/bin/bash
# claude-dotfiles auto-sync script
# Usage: bash sync.sh [push|pull|watch]

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DOTFILES_DIR"

sync_pull() {
  echo "[claude-dotfiles] Pulling latest..."
  git pull --rebase 2>/dev/null || git pull
  echo "[claude-dotfiles] Pull complete."
}

sync_push() {
  cd "$DOTFILES_DIR"
  if [ -n "$(git status --porcelain)" ]; then
    echo "[claude-dotfiles] Changes detected, pushing..."
    git add -A
    git commit -m "auto-sync: $(date '+%Y-%m-%d %H:%M:%S')"
    git push
    echo "[claude-dotfiles] Push complete."
  else
    echo "[claude-dotfiles] No changes to push."
  fi
}

sync_watch() {
  echo "[claude-dotfiles] Watching for changes... (Ctrl+C to stop)"
  sync_pull
  while true; do
    sleep 30
    cd "$DOTFILES_DIR"
    if [ -n "$(git status --porcelain)" ]; then
      sync_push
    fi
  done
}

case "${1:-pull}" in
  pull)  sync_pull ;;
  push)  sync_push ;;
  watch) sync_watch ;;
  *)     echo "Usage: sync.sh [pull|push|watch]" ;;
esac
