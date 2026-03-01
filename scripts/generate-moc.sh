#!/usr/bin/env bash

# Auto-generates the MOC (Map of Content) for the Error Graph.
# This eliminates git merge conflicts caused by two AI agents manually appending to the MOC index.

set -e

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KNOWLEDGE_DIR="$WORKSPACE_DIR/knowledge/error-graph"
NODES_DIR="$KNOWLEDGE_DIR/nodes"
MOC_FILE="$KNOWLEDGE_DIR/moc.md"

if [ ! -f "$MOC_FILE" ]; then
    echo "Error: moc.md not found at $MOC_FILE"
    exit 1
fi

TEMP_FILE=$(mktemp)

# 1. Read the existing MOC to preserve everything BEFORE the index section
awk '/^## 全ノードインデックス（nodes\/\）/ {exit} {print}' "$MOC_FILE" > "$TEMP_FILE"

# Append the header
echo -e "## 全ノードインデックス（nodes/）\n" >> "$TEMP_FILE"
echo -e "> 通常はクラスター経由でアクセスする。完全参照が必要な時のみこちらを使う。\n" >> "$TEMP_FILE"
echo -e "### [Type A] Technical Errors" >> "$TEMP_FILE"

TYPE_A_FILES=$(mktemp)
TYPE_B_FILES=$(mktemp)

# 2. Scan all nodes and parse frontmatter
for node_path in "$NODES_DIR"/*.md; do
    filename=$(basename "$node_path")
    if [[ "$filename" == "HANDOFF-TO-DOTFILES.md" ]]; then continue; fi
    
    # Defaults
    type="technical-error"
    cluster_match="unknown"
    
    # Parse YAML frontmatter
    # Extract type
    parsed_type=$(awk '/^type:/ {gsub(/type:[ \t]*"?'\''?|"?\r?$/, ""); print; exit}' "$node_path")
    if [ -n "$parsed_type" ]; then type="$parsed_type"; fi
    
    # Extract tags
    parsed_tags=$(awk '/^tags:/ {
        sub(/^tags:[ \t]*\[/, "");
        sub(/\]\r?$/, "");
        print
    }' "$node_path")
    
    if [ -n "$parsed_tags" ]; then
        # Parse first tag as cluster (skipping generic ones)
        IFS=',' read -ra TAGS <<< "$parsed_tags"
        declare -a clusters
        for tag in "${TAGS[@]}"; do
            # trim whitespace/quotes
            t=$(echo "$tag" | xargs | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
            if [[ "$t" != "user-correction" && "$t" != *"pdca"* ]]; then
                clusters+=("$t")
            fi
        done
        
        if [ ${#clusters[@]} -gt 0 ]; then
            cluster_match="\`${clusters[0]}\` cluster"
            if [ ${#clusters[@]} -gt 1 ]; then
                extra=$(IFS=, ; echo "${clusters[*]:1}")
                extra=$(echo "$extra" | sed 's/, /`, `/g')
                cluster_match="\`${clusters[0]}\` cluster (\`${extra}\`)"
            fi
        fi
    fi
    
    entry="- [[nodes/$filename]] — $cluster_match"
    
    if [[ "$type" == *"user-correction"* || "$filename" == uc-* ]]; then
        echo "$entry" >> "$TYPE_B_FILES"
    else
        echo "$entry" >> "$TYPE_A_FILES"
    fi
done

# Sort and append Technical Errors
sort "$TYPE_A_FILES" >> "$TEMP_FILE"
echo "" >> "$TEMP_FILE"

# Append User Corrections
echo -e "### [Type B] User Corrections (uc-)" >> "$TEMP_FILE"
sort "$TYPE_B_FILES" >> "$TEMP_FILE"
echo -e "\n---\n" >> "$TEMP_FILE"
echo -e "*Note: 新しいノードを作成したら (1) nodes/ にファイルを作る → (2) 該当クラスターのサマリーを更新する → (3) このインデックスは自動生成コマンド(\`scripts/generate-moc.ps1\`)で生成されます。*" >> "$TEMP_FILE"

# Overwrite moc.md
mv "$TEMP_FILE" "$MOC_FILE"
rm -f "$TYPE_A_FILES" "$TYPE_B_FILES"

echo "[Antigravity] Successfully auto-generated moc.md index (Bash)."
