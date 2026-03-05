# validate-devlog.ps1 — DEV_LOG.md の追記専用ルールを検証する (Windows版)
# push 前に実行して、過去のエントリが改ざんされていないことを確認
#
# Usage: pwsh validate-devlog.ps1 [project-root]
# Exit codes: 0=OK, 1=violation detected, 2=no DEV_LOG.md

param(
    [string]$ProjectRoot = "."
)

$DevLog = Join-Path $ProjectRoot "DEV_LOG.md"

# --- Check existence ---
if (-not (Test-Path $DevLog)) {
    Write-Host "[validate-devlog] WARN: DEV_LOG.md not found at $DevLog"
    exit 2
}

# --- Check if file is tracked by git ---
$tracked = git -C $ProjectRoot ls-files --error-unmatch DEV_LOG.md 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[validate-devlog] INFO: DEV_LOG.md is new (not yet tracked). OK."
    exit 0
}

# --- Check staged changes are append-only ---
$diff = git -C $ProjectRoot diff HEAD -- DEV_LOG.md 2>$null

if (-not $diff) {
    Write-Host "[validate-devlog] OK: DEV_LOG.md unchanged."
    exit 0
}

$deleted = ($diff | Where-Object { $_ -match "^-[^-]" }).Count
$added = ($diff | Where-Object { $_ -match "^\+[^\+]" }).Count

if ($deleted -gt 0) {
    Write-Host "[validate-devlog] ERROR: DEV_LOG.md has $deleted deleted line(s)."
    Write-Host "  DEV_LOG.md is append-only. Past entries must not be modified."
    Write-Host "  To restore: git checkout -- DEV_LOG.md"
    Write-Host ""
    Write-Host "  Deleted lines:"
    $diff | Where-Object { $_ -match "^-[^-]" } | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" }
    exit 1
}

if ($added -gt 0) {
    Write-Host "[validate-devlog] OK: DEV_LOG.md has $added new line(s) appended."
}

exit 0
