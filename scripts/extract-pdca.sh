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
    COMMIT_DATE=$(git -C "$WORKSPACE_DIR" log -1 --format='%cs' "$commit_hash")

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

    # Windowsの改行コード(CR)を除去
    node=$(echo "$node" | tr -d '\r')
    type=$(echo "$type" | tr -d '\r')
    tags=$(echo "$tags" | tr -d '\r')

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
