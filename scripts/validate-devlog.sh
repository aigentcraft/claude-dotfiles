#!/usr/bin/env bash
# validate-devlog.sh — DEV_LOG.md の追記専用ルールを検証する
# push 前に実行して、過去のエントリが改ざんされていないことを確認
#
# Usage: bash validate-devlog.sh [project-root]
# Exit codes: 0=OK, 1=violation detected, 2=no DEV_LOG.md

set -euo pipefail

PROJECT_ROOT="${1:-.}"
DEVLOG="$PROJECT_ROOT/DEV_LOG.md"

# --- Check existence ---
if [ ! -f "$DEVLOG" ]; then
  echo "[validate-devlog] WARN: DEV_LOG.md not found at $DEVLOG"
  exit 2
fi

# --- Check if file is tracked by git ---
if ! git -C "$PROJECT_ROOT" ls-files --error-unmatch DEV_LOG.md &>/dev/null; then
  echo "[validate-devlog] INFO: DEV_LOG.md is new (not yet tracked). OK."
  exit 0
fi

# --- Check staged changes are append-only ---
# Get the diff of DEV_LOG.md (staged or unstaged)
DIFF=$(git -C "$PROJECT_ROOT" diff HEAD -- DEV_LOG.md 2>/dev/null || true)

if [ -z "$DIFF" ]; then
  echo "[validate-devlog] OK: DEV_LOG.md unchanged."
  exit 0
fi

# Count deleted lines (lines starting with -) excluding diff headers
DELETED=$(echo "$DIFF" | grep -c "^-[^-]" || true)
ADDED=$(echo "$DIFF" | grep -c "^+[^+]" || true)

if [ "$DELETED" -gt 0 ]; then
  echo "[validate-devlog] ERROR: DEV_LOG.md has $DELETED deleted line(s)."
  echo "  DEV_LOG.md is append-only. Past entries must not be modified."
  echo "  To restore: git checkout -- DEV_LOG.md"
  echo ""
  echo "  Deleted lines:"
  echo "$DIFF" | grep "^-[^-]" | head -5
  exit 1
fi

if [ "$ADDED" -gt 0 ]; then
  echo "[validate-devlog] OK: DEV_LOG.md has $ADDED new line(s) appended."
fi

exit 0
