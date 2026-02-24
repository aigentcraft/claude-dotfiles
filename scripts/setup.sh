#!/bin/bash
# claude-dotfiles setup script
# Creates symlinks from ~/.claude/ to this repo
# Run once on each machine after cloning

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=== Claude Code Dotfiles Setup ==="
echo "Dotfiles dir: $DOTFILES_DIR"
echo "Claude dir:   $CLAUDE_DIR"
echo ""

# Ensure .claude directory exists
mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/knowledge"

# --- settings.json ---
if [ -f "$CLAUDE_DIR/settings.json" ] && [ ! -L "$CLAUDE_DIR/settings.json" ]; then
  echo "[backup] settings.json -> settings.json.bak"
  cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak"
  rm "$CLAUDE_DIR/settings.json"
fi
ln -sf "$DOTFILES_DIR/settings.json" "$CLAUDE_DIR/settings.json"
echo "[link] settings.json"

# --- CLAUDE.md (global) ---
if [ -f "$CLAUDE_DIR/CLAUDE.md" ] && [ ! -L "$CLAUDE_DIR/CLAUDE.md" ]; then
  echo "[backup] CLAUDE.md -> CLAUDE.md.bak"
  cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak"
  rm "$CLAUDE_DIR/CLAUDE.md"
fi
ln -sf "$DOTFILES_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "[link] CLAUDE.md"

# --- skills ---
for skill_dir in "$DOTFILES_DIR/skills"/*/; do
  skill_name=$(basename "$skill_dir")
  target="$CLAUDE_DIR/skills/$skill_name"

  if [ -d "$target" ] && [ ! -L "$target" ]; then
    echo "[backup] skills/$skill_name -> skills/${skill_name}.bak"
    mv "$target" "${target}.bak"
  fi

  # Remove existing symlink if any
  [ -L "$target" ] && rm "$target"

  ln -sf "$DOTFILES_DIR/skills/$skill_name" "$target"
  echo "[link] skills/$skill_name"
done

# --- knowledge (symlink dir if exists, otherwise leave for sync to populate) ---
if [ -d "$DOTFILES_DIR/knowledge" ]; then
  if [ -d "$CLAUDE_DIR/knowledge" ] && [ ! -L "$CLAUDE_DIR/knowledge" ]; then
    echo "[backup] knowledge/ -> knowledge.bak"
    mv "$CLAUDE_DIR/knowledge" "$CLAUDE_DIR/knowledge.bak"
  fi
  [ -L "$CLAUDE_DIR/knowledge" ] && rm "$CLAUDE_DIR/knowledge"
  ln -sf "$DOTFILES_DIR/knowledge" "$CLAUDE_DIR/knowledge"
  echo "[link] knowledge/"
fi

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Next: pull latest knowledge from all sources:"
echo "  bash $DOTFILES_DIR/scripts/sync.sh pull"
echo ""
echo "Auto-sync in background (optional):"
echo "  bash $DOTFILES_DIR/scripts/sync.sh watch"
echo ""
echo "Or add to shell startup (~/.zshrc or ~/.bashrc):"
echo "  bash $DOTFILES_DIR/scripts/sync.sh pull"
