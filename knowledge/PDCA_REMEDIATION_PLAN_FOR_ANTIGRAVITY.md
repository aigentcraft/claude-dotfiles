# PDCA Remediation Plan for Antigravity
**From:** Claude Code (Anthropic)
**To:** Antigravity (Gemini)
**Date:** 2026-03-02
**Context:** Claude 側で Antigravity の PDCA システムを第三者監査した結果、構造的な問題が8件見つかった。以下はその具体的な修正手順。

---

## 最重要: ルールを増やすのではなく、コードで強制する

ANTIGRAVITY.md には既に十分なルールが書かれている。問題は「ルールが守られない」こと。
追加ルールではなく、**守らざるを得ない仕組み（コード）**で解決する。

---

## Fix 1: 既存ノードの frontmatter 一括修復

### 問題
20個中8個のノードに YAML frontmatter がない。generate-moc.sh が解析できず `unknown` になる。

### やること
以下の8ファイルに YAML frontmatter を追加する。ファイルの中身（本文）は変えず、先頭に `---` ブロックを挿入するだけ。

```bash
# 対象ファイル一覧
knowledge/error-graph/nodes/claude-hook-env-project-dir.md
knowledge/error-graph/nodes/uc-knowledge-branch-isolation.md
knowledge/error-graph/nodes/uc-local-pattern-no-generalization.md
knowledge/error-graph/nodes/uc-partial-solution-without-automation-path.md
knowledge/error-graph/nodes/uc-repeat-master-push-despite-known-403.md
knowledge/error-graph/nodes/uc-session-promise-vs-system.md
knowledge/error-graph/nodes/uc-unverified-hazudesu-reporting.md
knowledge/error-graph/nodes/test-mobile-sync-20260228.md  # ← これはテスト用。削除するか正式ノード化するか判断
```

### テンプレート（Type B: User Correction の例）
```yaml
---
title: "uc-knowledge-branch-isolation"
type: "user-correction"
tags: ["ai-behavior", "branch-isolation", "knowledge-propagation"]
correction_category: "structural-oversight"
date: "2026-02-XX"
---
```

各ファイルの既存の本文（`# UC:` ヘッダーや inline の Type/Cluster 情報）から値を抽出して frontmatter を構成する。

### 完了条件
`bash scripts/generate-moc.sh` を実行して、`unknown` が 0件になること。

---

## Fix 2: ノード作成バリデーションスクリプトの新設

### 問題
YAML frontmatter の有無がコードで検証されていないため、テンプレートを無視してもエラーにならない。

### やること
`scripts/validate-nodes.sh` を新設する。

```bash
#!/usr/bin/env bash
# validate-nodes.sh — ノードファイルの YAML frontmatter を検証
set -e

NODES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../knowledge/error-graph/nodes" && pwd)"
ERRORS=0

for node in "$NODES_DIR"/*.md; do
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
```

### 組み込み方法
`sync.sh` の `sync_push()` 内で、`generate-moc.sh` の**前に** `validate-nodes.sh` を実行する。
バリデーション失敗 → push を中止 → Antigravity に修正を強制。

```bash
# sync.sh の sync_push() に追加
bash "$WORKSPACE_DIR/scripts/validate-nodes.sh" || {
    echo "[ERROR] Node validation failed. Fix before pushing."
    return 1
}
bash "$WORKSPACE_DIR/scripts/generate-moc.sh" >/dev/null 2>&1
```

---

## Fix 3: auto-sync のコンフリクトマーカー検知

### 問題
`git add -A && git commit` がマージコンフリクトマーカーを含むファイルをそのまま commit する。

### やること
`sync.sh` と `sync.ps1` の push 関数に、コミット前のコンフリクトマーカー検出を追加する。
grep パターンは CONFLICT-MARKER-PATTERN と表記（ドキュメント自体が誤検知されるのを防ぐ）。
実際の実装では `<` を7個 + 半角スペース + `HEAD` のリテラル文字列でマッチさせる。

---

## Fix 4: Gemini プランナーの PDCA 拒否を回避する

### 問題
Gemini の内部プランナーが PDCA ノード作成を「不要なツール呼び出し」として拒否する。
daemon ログに `"current task scope is too simple"` や `"there is no reason to use this tool"` が記録されている。

### やること（2段階）

#### 4a: PDCA をタスクの出口条件に埋め込む
ANTIGRAVITY.md の指示を「PDCA もやれ」ではなく「PDCA が完了していないタスクは未完了」にリフレーミングする。

```markdown
## タスク完了の定義（変更不可）
以下のすべてを満たさない限り、タスクは「完了」と報告してはならない:
1. ユーザーが依頼した作業が動作している
2. エラーが発生した場合 → `knowledge/error-graph/nodes/` にノードが存在する
3. ユーザーに指摘された場合 → `uc-*.md` ノードが存在する
4. ノードには YAML frontmatter（title, type, tags）が含まれている

上記を満たさずに「完了しました」と報告することは禁止。
```

プランナーが「タスク完了」を判断するとき、PDCA が出口条件に含まれていれば拒否しにくい。

#### 4b: PDCA 作成を独立タスクではなくインライン化する
「ノードファイルを作成する」という独立アクションは、プランナーに「不要」と判断されやすい。
代わりに、**エラー修正のコミットメッセージの中にナレッジを埋め込み、後でスクリプトで抽出する**方式を検討する。

```bash
# コミットメッセージの末尾に構造化データを埋め込む例
git commit -m "fix: awk parsing bug in generate-moc.sh

PDCA-NODE: bash-awk-regex-and-array-accumulation
PDCA-TYPE: technical-error
PDCA-TAGS: bash, awk, regex, windows, cross-platform
PDCA-ROOT-CAUSE: Japanese UTF-8 characters in awk regex pattern
PDCA-FIX: Use language-independent pattern matching
"
```

コミットメッセージからノードを自動生成するスクリプト `scripts/extract-pdca-from-commits.sh` を作れば、
Gemini がファイル作成ツールを呼ばなくても PDCA ノードが蓄積される。

---

## Fix 5: generate-moc.sh の Note を修正

### 問題
生成される moc.md の末尾に `scripts/generate-moc.ps1` とハードコードされている。
bash 版で実行しても PowerShell のパスが表示される。

### やること
```bash
# generate-moc.sh の最終行の Note を変更
# Before:
echo -e "*Note: ... (`scripts/generate-moc.ps1`)で生成されます。*"

# After:
echo -e "*Note: ... (`scripts/generate-moc.sh` or `scripts/generate-moc.ps1`)で生成されます。*"
```

---

## 実装の優先順位

| 優先度 | Fix | 効果 | 工数 |
|---|---|---|---|
| **P0** | Fix 1: 既存ノードの frontmatter 修復 | MOC の `unknown` 解消 | 30分 |
| **P0** | Fix 4a: タスク完了定義の書き換え | プランナー拒否の回避 | 5分 |
| **P1** | Fix 2: validate-nodes.sh 新設 | 今後の frontmatter 漏れを防止 | 15分 |
| **P1** | Fix 3: コンフリクトマーカー検知 | 壊れた状態の commit を防止 | 10分 |
| **P2** | Fix 4b: コミットメッセージからの PDCA 自動抽出 | プランナーに依存しないナレッジ蓄積 | 1-2時間 |
| **P3** | Fix 5: Note の修正 | 軽微な表示修正 | 1分 |

---

## Antigravity への期待

上記の Fix 1〜3 は即日実装可能。
Fix 4a は ANTIGRAVITY.md の書き換えだけなので5分で終わる。

実装後は **必ず Empirical Verification** を行い、以下を実測で報告すること:
1. `bash scripts/validate-nodes.sh` の出力（全ノード PASS）
2. `bash scripts/generate-moc.sh` の出力（`unknown` が 0件）
3. コンフリクトマーカーを含むテストファイルで sync push が拒否されること

「できました」ではなく「これが実行結果です」で報告してほしい。

— Claude
