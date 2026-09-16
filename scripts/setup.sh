#!/bin/bash
# claude-dotfiles setup script
# Creates hard links (files) and NTFS junctions (dirs) on Windows,
# symlinks on Unix, from ~/.claude/ to this repo.
# Run once on each machine after cloning.

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"

# Detect Windows (Git Bash / MSYS / Cygwin)
IS_WINDOWS=false
if [[ "$(uname -s)" =~ MINGW|MSYS|CYGWIN ]] || [ -n "${WINDIR:-}" ]; then
  IS_WINDOWS=true
fi

# Convert MSYS path to Windows path for mklink
to_win_path() {
  local p="$1"
  # /c/Users/... -> C:\Users\...
  p=$(echo "$p" | sed -E 's|^/([a-zA-Z])/|\U\1:\\|; s|/|\\|g')
  echo "$p"
}

# Link a directory (junction on Windows, symlink on Unix)
link_dir() {
  local source="$1"
  local target="$2"

  if [ "$IS_WINDOWS" = true ]; then
    local win_src=$(to_win_path "$source")
    local win_tgt=$(to_win_path "$target")
    cmd //c "mklink /J \"$win_tgt\" \"$win_src\"" > /dev/null 2>&1
  else
    ln -sf "$source" "$target"
  fi
}

# Link a file (hard link on Windows, symlink on Unix)
link_file() {
  local source="$1"
  local target="$2"

  if [ "$IS_WINDOWS" = true ]; then
    local win_src=$(to_win_path "$source")
    local win_tgt=$(to_win_path "$target")
    cmd //c "mklink /H \"$win_tgt\" \"$win_src\"" > /dev/null 2>&1
  else
    ln -sf "$source" "$target"
  fi
}

echo "=== Claude Code Dotfiles Setup ==="
echo "Dotfiles dir: $DOTFILES_DIR"
echo "Claude dir:   $CLAUDE_DIR"
echo "Platform:     $([ "$IS_WINDOWS" = true ] && echo "Windows (junctions + hard links)" || echo "Unix (symlinks)")"
echo ""

# Ensure .claude directory exists
mkdir -p "$CLAUDE_DIR/skills"

# --- settings.json ---
if [ -f "$CLAUDE_DIR/settings.json" ] && [ ! -L "$CLAUDE_DIR/settings.json" ]; then
  # Check if already a hard link to the same file (link count > 1)
  link_count=$(stat -c '%h' "$CLAUDE_DIR/settings.json" 2>/dev/null || stat -f '%l' "$CLAUDE_DIR/settings.json" 2>/dev/null || echo "1")
  if [ "$link_count" -gt 1 ]; then
    echo "[skip] settings.json (already hard-linked)"
  else
    echo "[backup] settings.json -> settings.json.bak"
    cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak"
    rm "$CLAUDE_DIR/settings.json"
    link_file "$DOTFILES_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    echo "[link] settings.json"
  fi
elif [ -L "$CLAUDE_DIR/settings.json" ]; then
  rm "$CLAUDE_DIR/settings.json"
  link_file "$DOTFILES_DIR/settings.json" "$CLAUDE_DIR/settings.json"
  echo "[link] settings.json (replaced old symlink)"
else
  link_file "$DOTFILES_DIR/settings.json" "$CLAUDE_DIR/settings.json"
  echo "[link] settings.json"
fi

# --- CLAUDE.md (global) ---
if [ -f "$CLAUDE_DIR/CLAUDE.md" ] && [ ! -L "$CLAUDE_DIR/CLAUDE.md" ]; then
  link_count=$(stat -c '%h' "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null || stat -f '%l' "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null || echo "1")
  if [ "$link_count" -gt 1 ]; then
    echo "[skip] CLAUDE.md (already hard-linked)"
  else
    echo "[backup] CLAUDE.md -> CLAUDE.md.bak"
    cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak"
    rm "$CLAUDE_DIR/CLAUDE.md"
    link_file "$DOTFILES_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    echo "[link] CLAUDE.md"
  fi
elif [ -L "$CLAUDE_DIR/CLAUDE.md" ]; then
  rm "$CLAUDE_DIR/CLAUDE.md"
  link_file "$DOTFILES_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
  echo "[link] CLAUDE.md (replaced old symlink)"
else
  link_file "$DOTFILES_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
  echo "[link] CLAUDE.md"
fi

# --- knowledge (single junction/symlink for entire directory) ---
if [ -d "$DOTFILES_DIR/knowledge" ]; then
  if [ -d "$CLAUDE_DIR/knowledge" ] && [ ! -L "$CLAUDE_DIR/knowledge" ]; then
    echo "[backup] knowledge/ -> knowledge.bak"
    [ -d "$CLAUDE_DIR/knowledge.bak" ] && rm -rf "$CLAUDE_DIR/knowledge.bak"
    mv "$CLAUDE_DIR/knowledge" "$CLAUDE_DIR/knowledge.bak"
    link_dir "$DOTFILES_DIR/knowledge" "$CLAUDE_DIR/knowledge"
    echo "[link] knowledge/"
  elif [ -L "$CLAUDE_DIR/knowledge" ]; then
    echo "[skip] knowledge/ (already linked)"
  else
    link_dir "$DOTFILES_DIR/knowledge" "$CLAUDE_DIR/knowledge"
    echo "[link] knowledge/"
  fi
fi

# --- skills (individual junctions/symlinks per skill) ---
for skill_dir in "$DOTFILES_DIR/skills"/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name=$(basename "$skill_dir")
  target="$CLAUDE_DIR/skills/$skill_name"

  # Skip if already linked
  if [ -L "$target" ]; then
    echo "[skip] skills/$skill_name (already linked)"
    continue
  fi

  # Backup physical directory
  if [ -d "$target" ]; then
    echo "[backup] skills/$skill_name"
    [ -d "${target}.bak" ] && rm -rf "${target}.bak"
    mv "$target" "${target}.bak" 2>/dev/null || rm -rf "$target"
  fi

  link_dir "$DOTFILES_DIR/skills/$skill_name" "$target"
  echo "[link] skills/$skill_name"
done

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Next: pull latest knowledge from all sources:"
echo "  bash $DOTFILES_DIR/scripts/sync.sh pull"
