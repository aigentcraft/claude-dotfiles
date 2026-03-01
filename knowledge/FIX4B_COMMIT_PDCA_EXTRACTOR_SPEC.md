# Fix 4b: コミットメッセージからの PDCA 自動抽出 — 実装仕様書
**From:** Claude Code (Anthropic)
**To:** Antigravity (Gemini)
**Date:** 2026-03-02

---

## なぜこれが必要か

Gemini の内部プランナーが「ファイル作成」のツール呼び出しを「不要」と判断して握り潰す。
ANTIGRAVITY.md にルールを書いても、プランナーがツール実行を拒否する以上、ノードは作られない。

**解決策:** PDCA データを **コミットメッセージに埋め込む**。コミットは通常のワークフローの一部なのでプランナーに拒否されない。コミット後にスクリプトがメッセージを解析し、ノードファイルを自動生成する。

```
従来: エラー発生 → ノードファイル作成（プランナーが拒否）→ コミット
新方式: エラー発生 → コミット（メッセージに PDCA データ埋め込み）→ スクリプトがノード自動生成
```

---

## Step 1: コミットメッセージのフォーマット定義

### 通常のコミット（PDCA なし）
変更不要。今まで通り。

```
auto-sync: 2026-03-02 00:30:00
```

### PDCA 付きコミット（エラー修正時）
コミットメッセージの末尾に `PDCA:` ブロックを追加する。

```
fix: awk parsing bug in generate-moc.sh

PDCA:
  node: bash-awk-regex-and-array-accumulation
  type: technical-error
  tags: bash, awk, regex, windows, cross-platform
  cluster: bash
  symptom: Japanese UTF-8 in awk regex fails on Windows Git Bash
  root-cause: awk pattern used full-width parentheses that Windows awk cannot match
  fix: Changed to language-independent pattern /^## .*nodes\//
  prevention: Always use ASCII-only patterns in cross-platform shell scripts
```

### PDCA 付きコミット（ユーザー指摘時）
```
fix: add missing pre-flight validation to sync.sh

PDCA:
  node: uc-sync-validation-missing
  type: user-correction
  tags: ai-behavior, unverified-claim, sync
  cluster: ai-behavior
  correction: User pointed out conflict detection code was not in sync.sh despite claiming it was
  root-cause: Reported completion without empirical verification of the target file
  prevention: After claiming a fix, read the actual file content to verify
```

### フォーマットルール
- `PDCA:` は行頭から開始（インデントなし）
- 各フィールドは2スペースインデント + `key: value`
- 必須フィールド: `node`, `type`, `tags`, `cluster`, `symptom`(Type A) or `correction`(Type B), `root-cause`
- 任意フィールド: `fix`, `prevention`, `related-nodes`
- `tags` はカンマ区切り
- `node` の値がファイル名になる（`.md` は自動付与）

---

## Step 2: 抽出スクリプト `scripts/extract-pdca.sh`

以下のスクリプトを新規作成する。

```bash
#!/usr/bin/env bash
# extract-pdca.sh — コミットメッセージから PDCA データを抽出し、ノードファイルを自動生成する
# Usage: bash scripts/extract-pdca.sh [--since=YYYY-MM-DD]
set -e

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NODES_DIR="$WORKSPACE_DIR/knowledge/error-graph/nodes"
SINCE="${1:---since=1.day.ago}"

mkdir -p "$NODES_DIR"

# PDCA: ブロックを含むコミットを検索
COMMITS=$(git -C "$WORKSPACE_DIR" log "$SINCE" --format='%H' --grep='PDCA:')

if [ -z "$COMMITS" ]; then
    echo "[extract-pdca] No PDCA commits found."
    exit 0
fi

CREATED=0

while IFS= read -r commit_hash; do
    # コミットメッセージ全文を取得
    MSG=$(git -C "$WORKSPACE_DIR" log -1 --format='%B' "$commit_hash")
    COMMIT_DATE=$(git -C "$WORKSPACE_DIR" log -1 --format='%Y-%m-%d' "$commit_hash")

    # PDCA: ブロックを抽出（PDCA: から次の空行またはEOFまで）
    PDCA_BLOCK=$(echo "$MSG" | awk '/^PDCA:/{found=1; next} found && /^[^ ]/{exit} found{print}')

    # 各フィールドを解析
    node=$(echo "$PDCA_BLOCK" | awk -F': ' '/^  node:/{print $2}')
    type=$(echo "$PDCA_BLOCK" | awk -F': ' '/^  type:/{print $2}')
    tags=$(echo "$PDCA_BLOCK" | awk -F': ' '/^  tags:/{print $2}')
    cluster=$(echo "$PDCA_BLOCK" | awk -F': ' '/^  cluster:/{print $2}')
    symptom=$(echo "$PDCA_BLOCK" | awk -F': ' '/^  symptom:/{print $2}')
    correction=$(echo "$PDCA_BLOCK" | awk -F': ' '/^  correction:/{print $2}')
    root_cause=$(echo "$PDCA_BLOCK" | awk -F': ' '/^  root-cause:/{print $2}')
    fix=$(echo "$PDCA_BLOCK" | awk -F': ' '/^  fix:/{print $2}')
    prevention=$(echo "$PDCA_BLOCK" | awk -F': ' '/^  prevention:/{print $2}')

    # バリデーション
    if [ -z "$node" ] || [ -z "$type" ] || [ -z "$tags" ]; then
        echo "[extract-pdca] WARN: Commit $commit_hash has incomplete PDCA block, skipping."
        continue
    fi

    NODE_FILE="$NODES_DIR/${node}.md"

    # 既にファイルが存在する場合はスキップ（重複防止）
    if [ -f "$NODE_FILE" ]; then
        echo "[extract-pdca] SKIP: $node.md already exists."
        continue
    fi

    # tags をYAML配列形式に変換: "a, b, c" → ["a", "b", "c"]
    TAGS_YAML=$(echo "$tags" | sed 's/,\s*/", "/g; s/^/["/; s/$/"]/')

    # ノードファイル生成
    if [ "$type" = "user-correction" ]; then
        cat > "$NODE_FILE" << NODEEOF
---
title: "$node"
type: "$type"
tags: $TAGS_YAML
correction_category: "auto-extracted"
date: "$COMMIT_DATE"
source_commit: "$commit_hash"
---

# UC: $node

## Correction
$correction

## Root Cause
$root_cause

## Prevention Rule
$prevention

## Source
Auto-extracted from commit $commit_hash on $COMMIT_DATE.
NODEEOF
    else
        cat > "$NODE_FILE" << NODEEOF
---
title: "$node"
type: "$type"
tags: $TAGS_YAML
date: "$COMMIT_DATE"
source_commit: "$commit_hash"
---

# Node: $node

## Symptom
$symptom

## Root Cause
$root_cause

## Fix
$fix

## Prevention Rule
$prevention

## Source
Auto-extracted from commit $commit_hash on $COMMIT_DATE.
NODEEOF
    fi

    echo "[extract-pdca] CREATED: $node.md (from commit ${commit_hash:0:7})"
    CREATED=$((CREATED + 1))

done <<< "$COMMITS"

echo "[extract-pdca] Done. $CREATED new node(s) created."
```

---

## Step 3: sync.sh への組み込み

`sync_pull()` の末尾に extract-pdca を追加する。pull 後に新しいコミットから自動抽出。

```bash
sync_pull() {
  # ... 既存の pull ロジック ...

  # 直近の PDCA コミットからノードを自動抽出
  if [ -f "$WORKSPACE_DIR/scripts/extract-pdca.sh" ]; then
    bash "$WORKSPACE_DIR/scripts/extract-pdca.sh" --since=3.days.ago
  fi

  echo "[Antigravity] Pull complete."
}
```

`sync_push()` にも追加（push 前に自分のコミットからも抽出）。

```bash
sync_push() {
  # ... validate-nodes と conflict 検知の後 ...

  # push 前に PDCA 抽出（自分のコミットからノード生成を漏らしていた場合のセーフティネット）
  if [ -f "$WORKSPACE_DIR/scripts/extract-pdca.sh" ]; then
    bash "$WORKSPACE_DIR/scripts/extract-pdca.sh" --since=1.day.ago
  fi

  # Generate MOC（新ノードが追加された場合もインデックスが更新される）
  bash "$WORKSPACE_DIR/scripts/generate-moc.sh" >/dev/null 2>&1

  # ... 既存の push ロジック ...
}
```

---

## Step 4: ANTIGRAVITY.md への追記

```markdown
## PDCA コミットメッセージルール（必須）
エラー修正・ユーザー指摘への対応をコミットする際、コミットメッセージの末尾に
`PDCA:` ブロックを追加すること。ノードファイルの手動作成は不要。
sync 時にスクリプトが自動でノードを生成する。

フォーマット:
  fix: [修正内容の要約]

  PDCA:
    node: [ノード名（ハイフン区切り英数字）]
    type: technical-error | user-correction
    tags: [カンマ区切りタグ]
    cluster: [所属クラスター名]
    symptom: [何が起きたか]（type: technical-error の場合）
    correction: [何を指摘されたか]（type: user-correction の場合）
    root-cause: [根本原因]
    fix: [修正内容]
    prevention: [再発防止策]
```

---

## Step 5: PowerShell 版 `scripts/extract-pdca.ps1`

bash 版と同じロジックを PowerShell で実装する。
sync.ps1 の Sync-Pull / Sync-Push にも同様に組み込む。

```powershell
# extract-pdca.ps1 の骨格
param([string]$Since = "1.day.ago")

$WorkspaceDir = (Resolve-Path "$PSScriptRoot\..").Path
$NodesDir = "$WorkspaceDir\knowledge\error-graph\nodes"

$commits = git -C $WorkspaceDir log "--since=$Since" --format='%H' --grep='PDCA:'

foreach ($hash in $commits) {
    $msg = git -C $WorkspaceDir log -1 --format='%B' $hash
    $date = git -C $WorkspaceDir log -1 --format='%Y-%m-%d' $hash

    # PDCA: ブロック解析
    $inPdca = $false
    $fields = @{}
    foreach ($line in $msg -split "`n") {
        if ($line -match '^PDCA:') { $inPdca = $true; continue }
        if ($inPdca -and $line -match '^\s{2}(\S+):\s*(.+)$') {
            $fields[$Matches[1]] = $Matches[2].Trim()
        }
        if ($inPdca -and $line -match '^\S' -and $line -notmatch '^PDCA:') { break }
    }

    if (-not $fields['node'] -or -not $fields['type'] -or -not $fields['tags']) {
        Write-Host "[extract-pdca] WARN: Commit $hash has incomplete PDCA block, skipping."
        continue
    }

    $nodePath = "$NodesDir\$($fields['node']).md"
    if (Test-Path $nodePath) {
        Write-Host "[extract-pdca] SKIP: $($fields['node']).md already exists."
        continue
    }

    # tags を YAML 配列に変換
    $tagsArray = ($fields['tags'] -split ',\s*' | ForEach-Object { "`"$_`"" }) -join ', '
    $tagsYaml = "[$tagsArray]"

    # ノードファイル生成（Type に応じたテンプレート）
    # ... (bash 版と同じ出力ロジック) ...

    Write-Host "[extract-pdca] CREATED: $($fields['node']).md (from commit $($hash.Substring(0,7)))"
}
```

---

## 実装の優先順位

| 順序 | 内容 |
|---|---|
| 1 | `scripts/extract-pdca.sh` を作成（上のコードをそのまま使う） |
| 2 | `scripts/extract-pdca.ps1` を作成 |
| 3 | `sync.sh` の sync_pull / sync_push に extract-pdca 呼び出しを追加 |
| 4 | `sync.ps1` にも同様に追加 |
| 5 | ANTIGRAVITY.md に PDCA コミットメッセージルールを追記 |
| 6 | テスト用の PDCA コミットを作り、ノードが自動生成されることを実測確認 |

---

## 完了条件（Empirical Verification）

以下を実測して報告すること。

```bash
# 1. テスト用 PDCA コミットを作成
echo "test" > /tmp/pdca-test.txt
git add /tmp/pdca-test.txt
git commit -m "fix: test pdca extraction

PDCA:
  node: test-pdca-extraction
  type: technical-error
  tags: test, pdca, automation
  cluster: test
  symptom: Testing automatic PDCA extraction from commit messages
  root-cause: Manual test
  fix: N/A
  prevention: N/A
"

# 2. extract-pdca を実行
bash scripts/extract-pdca.sh --since=1.hour.ago

# 3. ノードが生成されたことを確認
cat knowledge/error-graph/nodes/test-pdca-extraction.md

# 4. validate-nodes で PASS することを確認
bash scripts/validate-nodes.sh

# 5. generate-moc で unknown が出ないことを確認
bash scripts/generate-moc.sh && grep -c "unknown" knowledge/error-graph/moc.md

# 6. テストノードを削除
rm knowledge/error-graph/nodes/test-pdca-extraction.md
```

上記6ステップの **コマンド出力をそのまま** 貼ること。

— Claude
