#!/bin/bash
# claude-dotfiles auto-sync script
# Usage: bash sync.sh [push|pull|watch]

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"
ANTIGRAVITY_DIR="$HOME/antigravity-dotfiles"
AGENTS_DIR="$HOME/.agents/skills"

# Copy files from dotfiles repo to ~/.claude/ (for Windows where symlinks may not work)
apply_to_claude() {
  cp -f "$DOTFILES_DIR/settings.json" "$CLAUDE_DIR/settings.json" 2>/dev/null
  cp -f "$DOTFILES_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null
  # Skills: copy entire directory
  for skill_dir in "$DOTFILES_DIR/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    mkdir -p "$CLAUDE_DIR/skills/$skill_name"
    cp -rf "$skill_dir"* "$CLAUDE_DIR/skills/$skill_name/" 2>/dev/null
  done
  # Knowledge: copy to ~/.claude/knowledge/
  if [ -d "$DOTFILES_DIR/knowledge" ]; then
    mkdir -p "$CLAUDE_DIR/knowledge"
    cp -Rf "$DOTFILES_DIR/knowledge/"* "$CLAUDE_DIR/knowledge/" 2>/dev/null
  fi
}

# Bridge: pull latest knowledge/skills from antigravity-dotfiles into claude-dotfiles
bridge_from_antigravity() {
  if [ -d "$ANTIGRAVITY_DIR" ]; then
    echo "[claude-dotfiles] Bridging knowledge from antigravity-dotfiles..."
    cd "$ANTIGRAVITY_DIR"
    git pull --rebase 2>/dev/null || git pull
    mkdir -p "$DOTFILES_DIR/knowledge" "$DOTFILES_DIR/skills"
    [ -d "$ANTIGRAVITY_DIR/knowledge" ] && cp -Rf "$ANTIGRAVITY_DIR/knowledge/"* "$DOTFILES_DIR/knowledge/" 2>/dev/null
    [ -d "$ANTIGRAVITY_DIR/skills" ]   && cp -Rf "$ANTIGRAVITY_DIR/skills/"*   "$DOTFILES_DIR/skills/"   2>/dev/null
    # skills-lock.json も同期（npx skills でインストールされたスキルの記録）
    [ -f "$ANTIGRAVITY_DIR/skills-lock.json" ] && cp -f "$ANTIGRAVITY_DIR/skills-lock.json" "$DOTFILES_DIR/skills-lock.json" 2>/dev/null
    echo "[claude-dotfiles] Bridge complete."
  fi
}

# Copy files from ~/.claude/ back to dotfiles repo (detect local changes)
# ※ symlink環境では不要だが Windows のコピー運用向けに knowledge も回収する
collect_from_claude() {
  cp -f "$CLAUDE_DIR/settings.json" "$DOTFILES_DIR/settings.json" 2>/dev/null
  cp -f "$CLAUDE_DIR/CLAUDE.md" "$DOTFILES_DIR/CLAUDE.md" 2>/dev/null
  # Knowledge: ~/.claude/knowledge/ に追記された内容を claude-dotfiles に回収
  if [ -d "$CLAUDE_DIR/knowledge" ] && [ ! -L "$CLAUDE_DIR/knowledge" ]; then
    mkdir -p "$DOTFILES_DIR/knowledge"
    cp -Rf "$CLAUDE_DIR/knowledge/"* "$DOTFILES_DIR/knowledge/" 2>/dev/null
  fi
  # npx skills (skills.sh) でインストールされたスキルを回収
  # ~/.agents/skills/* → claude-dotfiles/skills/
  if [ -d "$AGENTS_DIR" ]; then
    for skill_dir in "$AGENTS_DIR"/*/; do
      [ -d "$skill_dir" ] || continue
      skill_name=$(basename "$skill_dir")
      mkdir -p "$DOTFILES_DIR/skills/$skill_name"
      cp -rf "$skill_dir"* "$DOTFILES_DIR/skills/$skill_name/" 2>/dev/null
    done
  fi
}

# Bridge: claude-dotfiles の knowledge/skills を antigravity-dotfiles に書き戻す
bridge_to_antigravity() {
  if [ -d "$ANTIGRAVITY_DIR" ]; then
    echo "[claude-dotfiles] Bridging knowledge back to antigravity-dotfiles..."
    mkdir -p "$ANTIGRAVITY_DIR/knowledge" "$ANTIGRAVITY_DIR/skills"
    [ -d "$DOTFILES_DIR/knowledge" ] && cp -Rf "$DOTFILES_DIR/knowledge/"* "$ANTIGRAVITY_DIR/knowledge/" 2>/dev/null
    [ -d "$DOTFILES_DIR/skills" ]   && cp -Rf "$DOTFILES_DIR/skills/"*   "$ANTIGRAVITY_DIR/skills/"   2>/dev/null
    # skills-lock.json を antigravity にも同期
    [ -f "$DOTFILES_DIR/skills-lock.json" ] && cp -f "$DOTFILES_DIR/skills-lock.json" "$ANTIGRAVITY_DIR/skills-lock.json" 2>/dev/null
    cd "$ANTIGRAVITY_DIR"
    if [ -n "$(git status --porcelain)" ]; then
      git add -A
      git commit -m "auto-sync (from Claude Code): $(date '+%Y-%m-%d %H:%M:%S')"
      git push
      echo "[claude-dotfiles] antigravity-dotfiles push complete."
    else
      echo "[claude-dotfiles] No changes to push to antigravity-dotfiles."
    fi
  fi
}

sync_pull() {
  echo "[claude-dotfiles] Pulling latest..."
  cd "$DOTFILES_DIR"
  git pull --rebase 2>/dev/null || git pull
  bridge_from_antigravity
  apply_to_claude
  echo "[claude-dotfiles] Pull & apply complete."
}

sync_push() {
  cd "$DOTFILES_DIR"
  collect_from_claude
  # 1. claude-dotfiles を GitHub に push
  if [ -n "$(git status --porcelain)" ]; then
    echo "[claude-dotfiles] Changes detected, pushing..."
    git add -A
    git commit -m "auto-sync: $(date '+%Y-%m-%d %H:%M:%S')"
    git push
    echo "[claude-dotfiles] Push complete."
  else
    echo "[claude-dotfiles] No changes to push."
  fi
  # 2. antigravity-dotfiles にも書き戻して push（双方向 HIVEMIND）
  bridge_to_antigravity
}

sync_watch() {
  echo "[claude-dotfiles] Watching for changes... (Ctrl+C to stop)"
  sync_pull
  while true; do
    sleep 30
    cd "$DOTFILES_DIR"
    collect_from_claude
    if [ -n "$(git status --porcelain)" ]; then
      sync_push
    fi
    # Also check for remote changes
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
  *)     echo "Usage: sync.sh [pull|push|watch]" ;;
esac
