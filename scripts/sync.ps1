<#
.SYNOPSIS
Antigravity auto-sync script for Windows
.DESCRIPTION
Usage: .\scripts\sync.ps1 [push|pull|watch]
#>

param (
    [string]$Action = "pull"
)

$WorkspaceDir = (Resolve-Path "$PSScriptRoot\..").Path
$ClaudeDotfilesDir = [System.Environment]::ExpandEnvironmentVariables("%USERPROFILE%\claude-dotfiles")

Set-Location -Path $WorkspaceDir

function Sync-Pull {
    Write-Host "[Antigravity] Pulling latest changes..." -ForegroundColor Cyan

    # Pull antigravity-dotfiles
    git pull --rebase --autostash *>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        git pull *>&1 | Out-Null
    }

    # Bridge: Pull claude-dotfiles and copy to local
    if (Test-Path $ClaudeDotfilesDir) {
        Write-Host "[Antigravity] Bridging from claude-dotfiles..." -ForegroundColor Cyan
        Push-Location $ClaudeDotfilesDir
        git pull --rebase --autostash *>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { git pull *>&1 | Out-Null }
        Pop-Location

        # Bridging copy logic removed. Now relies on Directory Junctions.
    }

    # Extract PDCA nodes from recent commit messages
    if (Test-Path "$PSScriptRoot\extract-pdca.ps1") {
        & "$PSScriptRoot\extract-pdca.ps1" -Since "3.days.ago"
    }

    Write-Host "[Antigravity] Pull complete." -ForegroundColor Green
}

function Sync-Push {
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $hasChanges = $false

    # Pre-flight: validate nodes
    if (Test-Path "$PSScriptRoot\validate-nodes.ps1") {
        & "$PSScriptRoot\validate-nodes.ps1"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Node validation failed. Fix before pushing." -ForegroundColor Red
            return
        }
    }

    # Pre-flight: detect merge conflict markers (workspace)
    $conflictFiles = @()
    foreach ($dir in @("$WorkspaceDir\knowledge", "$WorkspaceDir\skills")) {
        if (Test-Path $dir) {
            Get-ChildItem -Path $dir -Recurse -Filter "*.md" | ForEach-Object {
                $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
                if ($content -and $content -match '(?m)^<<<<<<< ') {
                    $conflictFiles += $_.FullName
                }
            }
        }
    }
    if ($conflictFiles.Count -gt 0) {
        Write-Host "[ERROR] Merge conflict markers detected in:" -ForegroundColor Red
        $conflictFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        Write-Host "Resolve before pushing." -ForegroundColor Red
        return
    }

    # Extract PDCA nodes from recent commits before push (safety net)
    if (Test-Path "$PSScriptRoot\extract-pdca.ps1") {
        & "$PSScriptRoot\extract-pdca.ps1" -Since "1.day.ago"
    }

    # Generate MOC before checking status to ensure index is up to date
    & "$PSScriptRoot\generate-moc.ps1" *>&1 | Out-Null

    # Bridge: Copy local changes to claude-dotfiles
    if (Test-Path $ClaudeDotfilesDir) {
        # Bridging copy logic removed. Now relies on Directory Junctions.

        # Pre-flight: detect conflict markers in claude-dotfiles too
        $claudeConflicts = @()
        foreach ($dir in @("$ClaudeDotfilesDir\knowledge", "$ClaudeDotfilesDir\skills")) {
            if (Test-Path $dir) {
                Get-ChildItem -Path $dir -Recurse -Filter "*.md" | ForEach-Object {
                    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
                    if ($content -and $content -match '(?m)^<<<<<<< ') {
                        $claudeConflicts += $_.FullName
                    }
                }
            }
        }
        if ($claudeConflicts.Count -gt 0) {
            Write-Host "[ERROR] Merge conflict markers detected in claude-dotfiles:" -ForegroundColor Red
            $claudeConflicts | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
            Write-Host "Resolve before pushing." -ForegroundColor Red
            return
        }

        # Push claude-dotfiles
        Push-Location $ClaudeDotfilesDir
        $claudeStatus = git status --porcelain
        if (-not [string]::IsNullOrWhiteSpace($claudeStatus)) {
            Write-Host "[Antigravity] Pushing bridged changes to claude-dotfiles..." -ForegroundColor Yellow
            git add -A
            git commit -m "auto-sync (from Antigravity): $date" *>&1 | Out-Null
            git push *>&1 | Out-Null
        }
        Pop-Location
    }

    # Push antigravity-dotfiles
    $status = git status --porcelain
    if (-not [string]::IsNullOrWhiteSpace($status)) {
        Write-Host "[Antigravity] Changes detected, pushing..." -ForegroundColor Yellow
        git add -A
        git commit -m "auto-sync: $date" *>&1 | Out-Null
        git push *>&1 | Out-Null
        $hasChanges = $true
    }

    if ($hasChanges) {
        Write-Host "[Antigravity] Push complete." -ForegroundColor Green
    }
    else {
        Write-Host "[Antigravity] No changes to push." -ForegroundColor Cyan
    }
}

function Sync-Watch {
    Write-Host "[Antigravity] Watching for changes... (Ctrl+C to stop)" -ForegroundColor Cyan
    Sync-Pull
    while ($true) {
        Start-Sleep -Seconds 30

        $status = git status --porcelain
        if (-not [string]::IsNullOrWhiteSpace($status)) {
            Sync-Push
        }

        # Check for remote changes
        git fetch --quiet *>&1 | Out-Null
        $local = git rev-parse HEAD
        $remote = git rev-parse "@{u}" 2>$null

        if ($remote -and $local -ne $remote) {
            Sync-Pull
        }
    }
}

switch ($Action) {
    "pull" { Sync-Pull }
    "push" { Sync-Push }
    "watch" { Sync-Watch }
    default { Write-Host "Usage: .\scripts\sync.ps1 [pull|push|watch]" }
}
