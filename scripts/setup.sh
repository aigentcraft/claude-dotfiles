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

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Auto-sync (optional):"
echo "  bash $DOTFILES_DIR/scripts/sync.sh watch"
echo ""
echo "Or add to shell startup (~/.bashrc or ~/.zshrc):"
echo "  bash $DOTFILES_DIR/scripts/sync.sh pull"
