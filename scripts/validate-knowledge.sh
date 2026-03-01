#!/bin/bash
# validate-knowledge.sh — ナレッジの整合性をチェックするバリデーションスクリプト
# Usage: bash scripts/validate-knowledge.sh [--fix]
#
# Checks:
#   1. error-graph/nodes/ のノードが moc.md に索引されているか
#   2. moc.md のリンク先ノードが実際に存在するか
#   3. ノードがいずれかの cluster に所属しているか
#   4. エスカレーション閾値（Fix 8 で使用）
#
# Exit code: 0 = OK, 1 = 問題あり

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
NODES_DIR="$DOTFILES_DIR/knowledge/error-graph/nodes"
MOC_FILE="$DOTFILES_DIR/knowledge/error-graph/moc.md"
CLUSTERS_DIR="$DOTFILES_DIR/knowledge/error-graph/clusters"

# 除外パターン（ノードではないメタファイル）
EXCLUDE_PATTERN="^(HANDOFF-|test-|README)"

ERRORS=0
WARNINGS=0

echo "=== Knowledge Validation ==="
echo ""

# --- Check 1: orphan nodes (on disk but not in MOC) ---
echo "[Check 1] Orphan nodes (not indexed in MOC)..."
for node_file in "$NODES_DIR"/*.md; do
  [ -f "$node_file" ] || continue
  filename=$(basename "$node_file")

  # 除外パターンに一致するものはスキップ
  if echo "$filename" | grep -qE "$EXCLUDE_PATTERN"; then
    continue
  fi

  if ! grep -q "$filename" "$MOC_FILE" 2>/dev/null; then
    echo "  ERROR: $filename is NOT in moc.md"
    ERRORS=$((ERRORS + 1))
  fi
done

# --- Check 2: phantom links (in MOC but not on disk) ---
echo "[Check 2] Phantom links (in MOC but file missing)..."
grep -oP 'nodes/[a-zA-Z0-9_-]+\.md' "$MOC_FILE" 2>/dev/null | sort -u | while read -r link; do
  node_path="$DOTFILES_DIR/knowledge/error-graph/$link"
  if [ ! -f "$node_path" ]; then
    echo "  ERROR: MOC references $link but file does not exist"
    # Can't increment ERRORS in subshell, use file marker
    echo "1" >> /tmp/validate-knowledge-errors
  fi
done
if [ -f /tmp/validate-knowledge-errors ]; then
  ERRORS=$((ERRORS + $(wc -l < /tmp/validate-knowledge-errors)))
  rm -f /tmp/validate-knowledge-errors
fi

# --- Check 3: nodes not in any cluster ---
echo "[Check 3] Nodes not assigned to any cluster..."
for node_file in "$NODES_DIR"/*.md; do
  [ -f "$node_file" ] || continue
  filename=$(basename "$node_file")

  if echo "$filename" | grep -qE "$EXCLUDE_PATTERN"; then
    continue
  fi

  FOUND_IN_CLUSTER=false
  for cluster_file in "$CLUSTERS_DIR"/*.md; do
    [ -f "$cluster_file" ] || continue
    if grep -q "$filename" "$cluster_file" 2>/dev/null; then
      FOUND_IN_CLUSTER=true
      break
    fi
  done

  if [ "$FOUND_IN_CLUSTER" = "false" ]; then
    echo "  WARNING: $filename is not referenced by any cluster"
    WARNINGS=$((WARNINGS + 1))
  fi
done

# --- Check 4: escalation threshold ---
echo "[Check 4] Escalation threshold check..."

# 4a: 同じクラスターに3+ノードがあるのにクラスターファイルがないカテゴリ
# （MOC のカテゴリ見出しごとにノード数をカウント）
TOTAL_NODES=$(find "$NODES_DIR" -name "*.md" | grep -vcE "$EXCLUDE_PATTERN" 2>/dev/null || echo 0)
echo "  Total nodes: $TOTAL_NODES"

# 4b: クラスター内ノード数による昇格チェック
for cluster_file in "$CLUSTERS_DIR"/*.md; do
  [ -f "$cluster_file" ] || continue
  cluster_name=$(basename "$cluster_file" .md)
  node_count=$(grep -c 'nodes/' "$cluster_file" 2>/dev/null || echo 0)

  if [ "$node_count" -ge 5 ]; then
    echo "  ACTION: Cluster '$cluster_name' has $node_count nodes (≥5) → Quick Rule 昇格を検討"
    echo "         → moc.md のエントリーポイントにこのクラスターの要約ルールを追加すべき"
    WARNINGS=$((WARNINGS + 1))
  elif [ "$node_count" -ge 3 ]; then
    echo "  INFO: Cluster '$cluster_name' has $node_count nodes (≥3) → cluster summary が最新か確認"
  fi
done

# 4c: MOC に Quick Rules セクションがあるか確認
if ! grep -q "Quick Rule" "$MOC_FILE" 2>/dev/null; then
  echo "  INFO: moc.md に Quick Rules セクションがありません（閾値到達時に作成を検討）"
fi

# --- Summary ---
echo ""
echo "=== Validation Summary ==="
echo "  Errors:   $ERRORS"
echo "  Warnings: $WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "FAILED: Fix errors above before pushing."
  exit 1
fi

if [ "$WARNINGS" -gt 0 ]; then
  echo ""
  echo "PASSED with warnings."
  exit 0
fi

echo ""
echo "ALL CHECKS PASSED."
exit 0
