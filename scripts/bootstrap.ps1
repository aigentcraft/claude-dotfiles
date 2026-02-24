# =============================================================================
# Bootstrap script (Windows PowerShell) - 新しいマシンでの初回セットアップ
# 使い方:
#   git clone git@github.com:aigentcraft/claude-dotfiles.git ~\claude-dotfiles
#   powershell -ExecutionPolicy Bypass -File ~\claude-dotfiles\scripts\bootstrap.ps1
# =============================================================================

$CLAUDE_DOTFILES_REPO = "git@github.com:aigentcraft/claude-dotfiles.git"
$ANTIGRAVITY_REPO     = "git@github.com:aigentcraft/antigravity-dotfiles.git"

$CLAUDE_DOTFILES_DIR  = "$HOME\claude-dotfiles"
$ANTIGRAVITY_DIR      = "$HOME\antigravity-dotfiles"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "   Antigravity Bootstrap (Windows)   " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# --- 1. claude-dotfiles ---
if (Test-Path "$CLAUDE_DOTFILES_DIR\.git") {
  Write-Host "[claude-dotfiles] Already cloned. Pulling latest..." -ForegroundColor Yellow
  Set-Location $CLAUDE_DOTFILES_DIR
  git pull
} else {
  Write-Host "[claude-dotfiles] Cloning..." -ForegroundColor Yellow
  git clone $CLAUDE_DOTFILES_REPO $CLAUDE_DOTFILES_DIR
}

# --- 2. antigravity-dotfiles ---
if (Test-Path "$ANTIGRAVITY_DIR\.git") {
  Write-Host "[antigravity-dotfiles] Already cloned. Pulling latest..." -ForegroundColor Yellow
  Set-Location $ANTIGRAVITY_DIR
  git pull
} else {
  Write-Host "[antigravity-dotfiles] Cloning..." -ForegroundColor Yellow
  git clone $ANTIGRAVITY_REPO $ANTIGRAVITY_DIR
}

# --- 3. Windows 用: シンボリックリンクの代わりにコピーで同期 ---
Write-Host ""
Write-Host "[sync] Applying claude-dotfiles to AppData..." -ForegroundColor Yellow

$CLAUDE_DIR = "$HOME\AppData\Roaming\Claude"
New-Item -ItemType Directory -Force -Path "$CLAUDE_DIR\skills"   | Out-Null
New-Item -ItemType Directory -Force -Path "$CLAUDE_DIR\knowledge" | Out-Null

Copy-Item -Force "$CLAUDE_DOTFILES_DIR\settings.json" "$CLAUDE_DIR\settings.json" -ErrorAction SilentlyContinue
Copy-Item -Force "$CLAUDE_DOTFILES_DIR\CLAUDE.md"     "$CLAUDE_DIR\CLAUDE.md"     -ErrorAction SilentlyContinue

# Skills
Get-ChildItem "$CLAUDE_DOTFILES_DIR\skills" -Directory | ForEach-Object {
  $skillName = $_.Name
  New-Item -ItemType Directory -Force -Path "$CLAUDE_DIR\skills\$skillName" | Out-Null
  Copy-Item -Recurse -Force "$($_.FullName)\*" "$CLAUDE_DIR\skills\$skillName\" -ErrorAction SilentlyContinue
  Write-Host "[copy] skills\$skillName"
}

# --- 4. antigravity の knowledge/skills をブリッジ ---
Write-Host ""
Write-Host "[bridge] Copying knowledge from antigravity-dotfiles..." -ForegroundColor Yellow

if (Test-Path "$ANTIGRAVITY_DIR\knowledge") {
  New-Item -ItemType Directory -Force -Path "$CLAUDE_DOTFILES_DIR\knowledge" | Out-Null
  Copy-Item -Recurse -Force "$ANTIGRAVITY_DIR\knowledge\*" "$CLAUDE_DOTFILES_DIR\knowledge\" -ErrorAction SilentlyContinue
  Copy-Item -Recurse -Force "$ANTIGRAVITY_DIR\knowledge\*" "$CLAUDE_DIR\knowledge\"           -ErrorAction SilentlyContinue
  Write-Host "[bridge] knowledge/ synced."
}
if (Test-Path "$ANTIGRAVITY_DIR\skills") {
  Copy-Item -Recurse -Force "$ANTIGRAVITY_DIR\skills\*" "$CLAUDE_DOTFILES_DIR\skills\" -ErrorAction SilentlyContinue
  Write-Host "[bridge] skills/ synced."
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "   Bootstrap complete!               " -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "PowerShell プロファイル ($PROFILE) に以下を追加すると起動時に自動同期されます:"
Write-Host ""
Write-Host "  # Antigravity auto-sync"
Write-Host "  bash ~/claude-dotfiles/scripts/sync.sh pull"
Write-Host ""
