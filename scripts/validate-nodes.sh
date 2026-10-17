#!/usr/bin/env bash
# validate-nodes.sh — ノードファイルの YAML frontmatter を検証
set -e

# エラーナレッジノードは停止中（再開手順: knowledge/error-graph/PAUSED.md）
if [ -f "$(dirname "${BASH_SOURCE[0]}")/../knowledge/error-graph/PAUSED.md" ]; then
    echo "[validate-nodes] error-graph は停止中のためスキップ"
    exit 0
fi

NODES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../knowledge/error-graph/nodes" && pwd)"
ERRORS=0

for node in "$NODES_DIR"/*.md; do
    # Check if empty or no files match
    [[ -e "$node" ]] || continue
    
    filename=$(basename "$node")
    [[ "$filename" == "HANDOFF-TO-DOTFILES.md" ]] && continue

    # frontmatter の存在チェック
    if ! head -1 "$node" | grep -q '^---'; then
        echo "[FAIL] $filename: YAML frontmatter missing"
        ERRORS=$((ERRORS + 1))
        continue
    fi

    # 必須フィールドのチェック
    frontmatter=$(awk '/^---/{n++} n==1{print} n==2{exit}' "$node")

    for field in "title:" "type:" "tags:"; do
        if ! echo "$frontmatter" | grep -q "$field"; then
            echo "[FAIL] $filename: missing field '$field'"
            ERRORS=$((ERRORS + 1))
        fi
    done
done

if [ "$ERRORS" -gt 0 ]; then
    echo ""
    echo "[RESULT] $ERRORS validation errors found."
    exit 1
else
    echo "[RESULT] All nodes passed validation."
    exit 0
fi
