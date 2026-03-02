<#
.SYNOPSIS
Validates YAML frontmatter on all error-graph nodes.
.DESCRIPTION
Checks that every node file in knowledge/error-graph/nodes/ has:
1. YAML frontmatter delimiters (---)
2. Required fields: title, type, tags
Returns exit code 1 if any validation errors found.
#>

$NodesDir = (Resolve-Path "$PSScriptRoot\..\knowledge\error-graph\nodes").Path
$Errors = 0

Get-ChildItem -Path $NodesDir -Filter "*.md" | ForEach-Object {
    if ($_.Name -match 'HANDOFF-TO-DOTFILES') { return }

    $lines = Get-Content $_.FullName -Encoding UTF8
    $filename = $_.Name

    # frontmatter existence check
    if ($lines.Count -eq 0 -or $lines[0] -notmatch '^---') {
        Write-Host "[FAIL] ${filename}: YAML frontmatter missing" -ForegroundColor Red
        $script:Errors++
        return
    }

    # Extract frontmatter (between first and second ---)
    $inFrontmatter = $false
    $frontmatter = @()
    foreach ($line in $lines) {
        if ($line -match '^---') {
            if ($inFrontmatter) { break }
            $inFrontmatter = $true
            continue
        }
        if ($inFrontmatter) {
            $frontmatter += $line
        }
    }

    $fmText = $frontmatter -join "`n"

    # Required fields check
    foreach ($field in @('title:', 'type:', 'tags:')) {
        if ($fmText -notmatch [regex]::Escape($field)) {
            Write-Host "[FAIL] ${filename}: missing field '$field'" -ForegroundColor Red
            $script:Errors++
        }
    }
}

if ($Errors -gt 0) {
    Write-Host ""
    Write-Host "[RESULT] $Errors validation errors found." -ForegroundColor Red
    exit 1
} else {
    Write-Host "[RESULT] All nodes passed validation." -ForegroundColor Green
    exit 0
}
