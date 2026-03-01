param([string]$Since = "1.day.ago")

$WorkspaceDir = (Resolve-Path "$PSScriptRoot\..").Path
$NodesDir = "$WorkspaceDir\knowledge\error-graph\nodes"

$commits = git -C $WorkspaceDir log "--since=$Since" --format='%H' --grep='PDCA:'
if (-not $commits) {
    Write-Host "[extract-pdca] No PDCA commits found." -ForegroundColor Cyan
    return
}

$createdCount = 0

foreach ($hash in $commits) {
    $msg = git -C $WorkspaceDir log -1 --format='%B' $hash
    $date = git -C $WorkspaceDir log -1 --format='%cs' $hash

    # PDCA: ブロック解析
    $inPdca = $false
    $fields = @{}
    foreach ($line in $msg -split "`n") {
        $cleanLine = $line.TrimEnd("`r")
        if ($cleanLine -match '^PDCA:') { $inPdca = $true; continue }
        if ($inPdca -and $cleanLine -match '^\s{2}(\S+):\s*(.+)$') {
            $fields[$Matches[1]] = $Matches[2].Trim()
        }
        if ($inPdca -and $cleanLine -match '^\S' -and $cleanLine -notmatch '^PDCA:') { break }
    }

    if (-not $fields['node'] -or -not $fields['type'] -or -not $fields['tags']) {
        Write-Host "[extract-pdca] WARN: Commit $hash has incomplete PDCA block, skipping." -ForegroundColor Yellow
        continue
    }

    $nodeName = $fields['node']
    $nodePath = "$NodesDir\$nodeName.md"
    if (Test-Path $nodePath) {
        Write-Host "[extract-pdca] SKIP: $($nodeName).md already exists." -ForegroundColor Cyan
        continue
    }

    # tags を YAML 配列に変換
    $tagsArray = ($fields['tags'] -split ',\s*' | ForEach-Object { "`"$_`"" }) -join ', '
    $tagsYaml = "[$tagsArray]"
    $type = $fields['type']

    $content = ""
    if ($type -eq "user-correction") {
        $content = @"
---
title: "$nodeName"
type: "$type"
tags: $tagsYaml
correction_category: "auto-extracted"
date: "$date"
source_commit: "$hash"
---

# UC: $nodeName

## Correction
$($fields['correction'])

## Root Cause
$($fields['root-cause'])

## Prevention Rule
$($fields['prevention'])

## Source
Auto-extracted from commit $hash on $date.
"@
    }
    else {
        $content = @"
---
title: "$nodeName"
type: "$type"
tags: $tagsYaml
date: "$date"
source_commit: "$hash"
---

# Node: $nodeName

## Symptom
$($fields['symptom'])

## Root Cause
$($fields['root-cause'])

## Fix
$($fields['fix'])

## Prevention Rule
$($fields['prevention'])

## Source
Auto-extracted from commit $hash on $date.
"@
    }

    Set-Content -Path $nodePath -Value $content -Encoding UTF8
    Write-Host "[extract-pdca] CREATED: $($nodeName).md (from commit $($hash.Substring(0,7)))" -ForegroundColor Green
    $createdCount++
}

Write-Host "[extract-pdca] Done. $createdCount new node(s) created." -ForegroundColor Green
