#!/usr/bin/env bash
# sync-graph.sh — Detect new projects in hyperbrowser-app-examples and update the skill graph
# Usage: bash ~/.claude/skills/hyperbrowser-ecosystem/sync-graph.sh
set -euo pipefail

EXAMPLES_DIR="$HOME/hyperbrowser-app-examples"
GRAPH_DIR="$HOME/.claude/skills/hyperbrowser-ecosystem"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Hyperbrowser Skill Graph Sync ==="
echo ""

# ── 1. Collect all project directories ──────────────────────────
if [ ! -d "$EXAMPLES_DIR" ]; then
  echo -e "${RED}ERROR: $EXAMPLES_DIR not found${NC}"
  exit 1
fi

mapfile -t projects < <(find "$EXAMPLES_DIR" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | grep -v '^\.' | sort)

echo "Found ${#projects[@]} project directories in $EXAMPLES_DIR"

# ── 2. Collect all registered nodes (from Category MOCs) ───────
# Extract project directory names mentioned in category MOCs
registered=()
for moc in "$GRAPH_DIR"/scraping-data-extraction.md \
           "$GRAPH_DIR"/research-intelligence.md \
           "$GRAPH_DIR"/job-matching.md \
           "$GRAPH_DIR"/chatbot-conversational.md \
           "$GRAPH_DIR"/content-generation.md \
           "$GRAPH_DIR"/ux-analysis-testing.md \
           "$GRAPH_DIR"/agent-developer-tools.md; do
  if [ -f "$moc" ]; then
    # Extract project paths like ~/hyperbrowser-app-examples/{name}/
    while IFS= read -r match; do
      registered+=("$match")
    done < <(grep -oP 'hyperbrowser-app-examples/\K[^/]+(?=/)' "$moc" 2>/dev/null || true)
  fi
done

# Deduplicate
mapfile -t registered < <(printf '%s\n' "${registered[@]}" | sort -u)

echo "Found ${#registered[@]} registered projects in Category MOCs"
echo ""

# ── 3. Find unregistered projects ──────────────────────────────
new_projects=()
for proj in "${projects[@]}"; do
  found=0
  for reg in "${registered[@]}"; do
    if [ "$proj" = "$reg" ]; then
      found=1
      break
    fi
  done
  if [ "$found" -eq 0 ]; then
    new_projects+=("$proj")
  fi
done

if [ ${#new_projects[@]} -eq 0 ]; then
  echo -e "${GREEN}All projects are registered. Skill graph is up to date.${NC}"
  exit 0
fi

echo -e "${YELLOW}Found ${#new_projects[@]} unregistered project(s):${NC}"
for proj in "${new_projects[@]}"; do
  echo "  - $proj"
done
echo ""

# ── 4. Generate skeleton files for new projects ────────────────
for proj in "${new_projects[@]}"; do
  echo -e "Processing ${YELLOW}$proj${NC}..."

  # Read description from README.md if it exists
  description=""
  readme="$EXAMPLES_DIR/$proj/README.md"
  if [ -f "$readme" ]; then
    # Extract first non-empty, non-heading line as description
    description=$(grep -m1 -vE '^\s*$|^#' "$readme" | head -c 200 || true)
  fi

  # Read package.json name for fallback
  if [ -z "$description" ]; then
    pkgjson="$EXAMPLES_DIR/$proj/package.json"
    if [ -f "$pkgjson" ]; then
      description=$(grep -oP '"description"\s*:\s*"\K[^"]+' "$pkgjson" 2>/dev/null || echo "Hyperbrowser project")
    fi
  fi

  # Detect SDK APIs used
  apis=""
  proj_dir="$EXAMPLES_DIR/$proj"
  if grep -rq 'scrape\.startAndWait' "$proj_dir" --include="*.ts" --include="*.tsx" 2>/dev/null; then
    apis="${apis}scrape, "
  fi
  if grep -rq 'extract\.startAndWait' "$proj_dir" --include="*.ts" --include="*.tsx" 2>/dev/null; then
    apis="${apis}extract, "
  fi
  if grep -rq 'sessions\.create' "$proj_dir" --include="*.ts" --include="*.tsx" 2>/dev/null; then
    apis="${apis}session, "
  fi
  if grep -rq 'crawl\.startAndWait' "$proj_dir" --include="*.ts" --include="*.tsx" 2>/dev/null; then
    apis="${apis}crawl, "
  fi
  if grep -rq 'agents\.' "$proj_dir" --include="*.ts" --include="*.tsx" 2>/dev/null; then
    apis="${apis}agent, "
  fi
  apis="${apis%, }"  # Remove trailing comma
  [ -z "$apis" ] && apis="unknown"

  # Determine likely category
  category="agent-developer-tools"  # Default category
  proj_lower=$(echo "$proj" | tr '[:upper:]' '[:lower:]')
  if echo "$proj_lower" | grep -qE 'scrape|crawl|data|dataset|asset'; then
    category="scraping-data-extraction"
  elif echo "$proj_lower" | grep -qE 'research|track|monitor|intel|reddit|idea'; then
    category="research-intelligence"
  elif echo "$proj_lower" | grep -qE 'job|match|hire|resume'; then
    category="job-matching"
  elif echo "$proj_lower" | grep -qE 'chat|buddy|convers'; then
    category="chatbot-conversational"
  elif echo "$proj_lower" | grep -qE 'generat|page|pitch|podcast|content'; then
    category="content-generation"
  elif echo "$proj_lower" | grep -qE 'ux|ui|test|flow|churn|analyz'; then
    category="ux-analysis-testing"
  fi

  # Create skeleton node file (only if it doesn't exist)
  node_file="$GRAPH_DIR/project-${proj}.md"
  if [ ! -f "$node_file" ]; then
    cat > "$node_file" << SKELETON
---
id: project-${proj}
type: project
description: "${description}"
category: ${category}
sdk_apis: [${apis}]
---
# ${proj}

**Path**: \`~/hyperbrowser-app-examples/${proj}/\`

## Overview

${description}

## SDK APIs Used

${apis}

## Patterns

<!-- TODO: Identify patterns used by this project -->

## Notes

<!-- TODO: Add implementation notes -->
SKELETON
    echo -e "  ${GREEN}Created${NC} $node_file"
  else
    echo -e "  Skipped (file already exists)"
  fi

  # Append to category MOC (if not already mentioned)
  moc_file="$GRAPH_DIR/${category}.md"
  if [ -f "$moc_file" ]; then
    if ! grep -q "$proj" "$moc_file" 2>/dev/null; then
      # Append before the last section
      cat >> "$moc_file" << ENTRY

### ${proj} (auto-detected)
- **Path**: \`~/hyperbrowser-app-examples/${proj}/\`
- **Description**: ${description}
- **SDK APIs**: ${apis}
- **Status**: Needs manual review and wikilink integration
ENTRY
      echo -e "  ${GREEN}Appended${NC} to $moc_file"
    fi
  fi
done

echo ""

# ── 5. Update project count in Root MOC ────────────────────────
total_projects=${#projects[@]}
root_moc="$GRAPH_DIR/hyperbrowser-ecosystem.md"
if [ -f "$root_moc" ]; then
  # Update the description line with the new count
  sed -i "s/[0-9]\+ projects across/$(echo $total_projects) projects across/" "$root_moc" 2>/dev/null || true
  echo -e "${GREEN}Updated project count to $total_projects in root MOC${NC}"
fi

# ── 6. Summary ─────────────────────────────────────────────────
echo ""
echo "=== Sync Summary ==="
echo "  Total projects: $total_projects"
echo "  Previously registered: ${#registered[@]}"
echo "  Newly detected: ${#new_projects[@]}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review generated skeleton files in $GRAPH_DIR/project-*.md"
echo "  2. Fill in patterns, wikilinks, and implementation notes"
echo "  3. Verify category assignments are correct"
echo "  4. Update the root MOC description if needed"
