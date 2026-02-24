#!/bin/bash
set -euo pipefail

# Only run in web/remote environments (Claude Code on the web / smartphone)
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

DOTFILES_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
CLAUDE_DIR="$HOME/.claude"

echo "=== claude-dotfiles: Setting up web session ==="
echo "Dotfiles dir: $DOTFILES_DIR"
echo "Claude dir:   $CLAUDE_DIR"

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

# Export CLAUDE_PROJECT_DIR for the session
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export DOTFILES_DIR=\"$DOTFILES_DIR\"" >> "$CLAUDE_ENV_FILE"
fi

echo "=== claude-dotfiles: Web session setup complete ==="
