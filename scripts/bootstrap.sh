#!/bin/bash
# =============================================================================
# Bootstrap script - 新しいマシンでの初回セットアップ
# 使い方:
#   git clone git@github.com:aigentcraft/claude-dotfiles.git ~/claude-dotfiles
#   bash ~/claude-dotfiles/scripts/bootstrap.sh
# =============================================================================

set -e

CLAUDE_DOTFILES_REPO="git@github.com:aigentcraft/claude-dotfiles.git"
ANTIGRAVITY_REPO="git@github.com:aigentcraft/antigravity-dotfiles.git"

CLAUDE_DOTFILES_DIR="$HOME/claude-dotfiles"
ANTIGRAVITY_DIR="$HOME/antigravity-dotfiles"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}   Antigravity Bootstrap              ${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""

# --- 1. claude-dotfiles ---
if [ -d "$CLAUDE_DOTFILES_DIR/.git" ]; then
  echo -e "${YELLOW}[claude-dotfiles] Already cloned. Pulling latest...${NC}"
  cd "$CLAUDE_DOTFILES_DIR" && git pull --rebase 2>/dev/null || git pull
else
  echo -e "${YELLOW}[claude-dotfiles] Cloning...${NC}"
  git clone "$CLAUDE_DOTFILES_REPO" "$CLAUDE_DOTFILES_DIR"
fi

# --- 2. antigravity-dotfiles ---
if [ -d "$ANTIGRAVITY_DIR/.git" ]; then
  echo -e "${YELLOW}[antigravity-dotfiles] Already cloned. Pulling latest...${NC}"
  cd "$ANTIGRAVITY_DIR" && git pull --rebase 2>/dev/null || git pull
else
  echo -e "${YELLOW}[antigravity-dotfiles] Cloning...${NC}"
  git clone "$ANTIGRAVITY_REPO" "$ANTIGRAVITY_DIR"
fi

# --- 3. setup.sh でシンボリックリンクを作成 ---
echo ""
echo -e "${YELLOW}[setup] Creating symlinks for ~/.claude/ ...${NC}"
bash "$CLAUDE_DOTFILES_DIR/scripts/setup.sh"

# --- 4. sync.sh pull で knowledge/skills をブリッジ ---
echo ""
echo -e "${YELLOW}[sync] Pulling latest knowledge from all sources...${NC}"
bash "$CLAUDE_DOTFILES_DIR/scripts/sync.sh" pull

# --- 5. シェル起動時の自動 pull を提案 ---
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}   Bootstrap complete!                ${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "以下を ~/.zshrc または ~/.bashrc に追加すると、シェル起動時に自動同期されます:"
echo ""
echo "  # Antigravity auto-sync"
echo "  bash ~/claude-dotfiles/scripts/sync.sh pull"
echo ""
echo "手動で追加しますか? [y/N]"
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
  RC_FILE="$HOME/.zshrc"
  [ -f "$HOME/.bashrc" ] && [ ! -f "$HOME/.zshrc" ] && RC_FILE="$HOME/.bashrc"
  echo "" >> "$RC_FILE"
  echo "# Antigravity auto-sync" >> "$RC_FILE"
  echo "bash ~/claude-dotfiles/scripts/sync.sh pull" >> "$RC_FILE"
  echo -e "${GREEN}[done] Added to $RC_FILE${NC}"
fi
