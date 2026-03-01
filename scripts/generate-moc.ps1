<#
.SYNOPSIS
Auto-generates the MOC (Map of Content) for the Error Graph.

.DESCRIPTION
This script scans all markdown files in knowledge/error-graph/nodes/,
extracts their YAML frontmatter (title, type, cluster/tags), and dynamically 
rebuilds the "All Nodes Index" section of the moc.md file. 
This structural change eliminates git merge conflicts caused by two AI agents 
manually appending to the MOC index at the same time.
#>

$WorkspaceDir = (Resolve-Path "$PSScriptRoot\..").Path
$KnowledgeDir = "$WorkspaceDir\knowledge\error-graph"
$NodesDir = "$KnowledgeDir\nodes"
$MocFile = "$KnowledgeDir\moc.md"

if (-not (Test-Path $MocFile)) {
    Write-Error "moc.md not found at $MocFile"
    exit 1
}

# 1. Read the existing MOC to preserve everything BEFORE the index section
$MocLines = Get-Content $MocFile -Encoding UTF8
$BeforeIndex = @()
foreach ($line in $MocLines) {
    if ($line -match '^## .*nodes/') {
        # We stop preserving here
        break
    }
    $BeforeIndex += $line
}

# 2. Scan all nodes and parse frontmatter
$TypeAFiles = @()
$TypeBFiles = @()

$RegexFrontmatter = '(?sm)^---\r?\n(.*?)\r?\n---'
$RegexType = '(?m)^type:\s*`?""?([^""\r\n]+)"?"?`?'
$RegexCluster = '(?m)^tags:\s*\[([^\]]+)\]'

$NodesPaths = Get-ChildItem -Path $NodesDir -Filter "*.md"
foreach ($NodePath in $NodesPaths) {
    if ($NodePath.Name -match 'HANDOFF-TO-DOTFILES') { continue }
    
    $Content = [System.IO.File]::ReadAllText($NodePath.FullName, [System.Text.Encoding]::UTF8)
    
    $type = 'technical-error'
    $tagsRaw = ''

    if ($Content -match $RegexFrontmatter) {
        $fm = $Matches[1]
        # title is not used in index yet
        if ($fm -match $RegexType) { $type = $Matches[1] }
        if ($fm -match $RegexCluster) { $tagsRaw = $Matches[1] }
    }
    
    # Try to extract the first tag as the cluster, or specifically related tags
    $clusterMatch = 'unknown'
    if ($tagsRaw) {
        $tagArray = $tagsRaw -split ',' | ForEach-Object { $_.Trim().Trim('`"''') }
        # find the cluster tag (filter out generic tags like 'user-correction')
        $clusters = $tagArray | Where-Object { $_ -ne 'user-correction' -and $_ -notmatch 'pdca' }
        $clustersArr = @($clusters)
        if ($clustersArr.Count -gt 0) {
            $clusterMatch = $clustersArr[0]
            # format remaining tags for display
            if ($clustersArr.Count -gt 1) {
                $extra = ($clustersArr[1..($clustersArr.Count - 1)] -join '`, `')
                $clusterMatch = "$clusterMatch`` cluster (``$extra``)"
            }
            else {
                $clusterMatch = "$clusterMatch`` cluster"
            }
        }
    }

    $Entry = "- [[nodes/$($NodePath.Name)]] — ``$clusterMatch"
    $Entry = $Entry.Replace('``', '`') # fix escaping

    if ($type -match 'user-correction' -or $NodePath.Name -match '^uc-') {
        $TypeBFiles += $Entry
    }
    else {
        $TypeAFiles += $Entry
    }
}

# 3. Build the new index content
$NewContent = [System.Collections.Generic.List[string]]::new()
$NewContent.AddRange([string[]]$BeforeIndex)

$NewContent.Add('## 全ノードインデックス（nodes/）')
$NewContent.Add('')
$NewContent.Add('> 通常はクラスター経由でアクセスする。完全参照が必要な時のみこちらを使う。')
$NewContent.Add('')
$NewContent.Add('### [Type A] Technical Errors')
$TypeAFiles | Sort-Object | ForEach-Object { $NewContent.Add($_) }
$NewContent.Add('')

$NewContent.Add('### [Type B] User Corrections (uc-)')
$TypeBFiles | Sort-Object | ForEach-Object { $NewContent.Add($_) }
$NewContent.Add('')
$NewContent.Add('---')
$NewContent.Add('')
$NewContent.Add('*Note: 新しいノードを作成したら (1) nodes/ にファイルを作る → (2) 該当クラスターのサマリーを更新する → (3) このインデックスは自動生成コマンド(`scripts/generate-moc.ps1`)で生成されます。*')

# 4. Overwrite moc.md
[System.IO.File]::WriteAllLines($MocFile, $NewContent, [System.Text.Encoding]::UTF8)
Write-Host '[Antigravity] Successfully auto-generated moc.md index.' -ForegroundColor Green
