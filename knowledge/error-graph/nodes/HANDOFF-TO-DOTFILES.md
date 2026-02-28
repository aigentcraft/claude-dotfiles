# claude-dotfiles セッションへの引き継ぎプロンプト

このファイルの内容をすべて実行してください。

---

## 背景: 何が起きたか

Maia-ai プロジェクトの開発セッション中、スマホの Claude Code on the web から作業していた。開発中にハマったエラー（Supabase v2 の型が `never` に解決される問題、AI SDK v6 のプロパティ名変更）を PDCA エラーナレッジグラフに記録しようとした。

しかし、**Claude Code on the web はサンドボックス環境で動いており、セッション起動時に指定された1つのリポジトリ（今回は aigentcraft/Maia-ai）にしか git push できない**ことが判明した。

つまり:
- `~/claude-dotfiles` ディレクトリはクラウドコンテナ上に存在しない
- `sync.sh pull/push` は実行不可能
- claude-dotfiles リポジトリへの直接 push も git proxy が `repository not authorized` で拒否
- `gh` CLI も未インストール、GitHub トークンもない

**結果**: どのプロジェクトで作業していても、スマホ（web）からはナレッジの蓄積が一切できない状態だった。

## 解決策: GitHub Actions による自動同期

各プロジェクトリポジトリに GitHub Actions ワークフローを配置する。Claude Code が `.claude-knowledge-staging/` ディレクトリにナレッジファイルを置いて push すると、GitHub Actions が自動で claude-dotfiles に同期し、staging ディレクトリを削除する。

この仕組みなら:
- スマホ（web）からでも動く（push 先はそのプロジェクトリポジトリだけでOK）
- ローカルマシンからも動く（push すれば Actions が走る）
- 従来の sync.sh と共存できる

---

## やること

### 1. ワークフローテンプレートを `templates/sync-knowledge-to-dotfiles.yml` として保存

```yaml
name: Sync Knowledge to claude-dotfiles
on:
  push:
    paths:
      - '.claude-knowledge-staging/**'
env:
  DOTFILES_REPO: aigentcraft/claude-dotfiles
  DOTFILES_BRANCH: master
  KNOWLEDGE_STAGING_DIR: .claude-knowledge-staging
jobs:
  sync-knowledge:
    runs-on: ubuntu-latest
    if: "!contains(github.event.head_commit.message, '[knowledge-sync]')"
    steps:
      - name: Checkout source repo
        uses: actions/checkout@v4
        with:
          path: source-repo
      - name: Check for staging files
        id: check
        run: |
          STAGING_DIR="source-repo/${{ env.KNOWLEDGE_STAGING_DIR }}"
          if [ ! -d "$STAGING_DIR" ] || [ -z "$(ls -A "$STAGING_DIR" 2>/dev/null)" ]; then
            echo "has_files=false" >> "$GITHUB_OUTPUT"
          else
            echo "has_files=true" >> "$GITHUB_OUTPUT"
          fi
      - name: Checkout claude-dotfiles
        if: steps.check.outputs.has_files == 'true'
        uses: actions/checkout@v4
        with:
          repository: ${{ env.DOTFILES_REPO }}
          ref: ${{ env.DOTFILES_BRANCH }}
          token: ${{ secrets.CLAUDE_DOTFILES_PAT }}
          path: claude-dotfiles
      - name: Sync knowledge files
        if: steps.check.outputs.has_files == 'true'
        run: |
          STAGING="source-repo/${{ env.KNOWLEDGE_STAGING_DIR }}"
          DOTFILES="claude-dotfiles"
          for f in "$STAGING"/*.md; do
            [ -f "$f" ] || continue
            filename=$(basename "$f")
            if [ "$filename" = "moc-updated.md" ]; then
              cp "$f" "$DOTFILES/knowledge/error-graph/moc.md"
            elif [[ "$filename" != moc-* ]] && [[ "$filename" != README* ]] && [[ "$filename" != HANDOFF-* ]]; then
              mkdir -p "$DOTFILES/knowledge/error-graph/nodes"
              cp "$f" "$DOTFILES/knowledge/error-graph/nodes/$filename"
            fi
          done
          for f in "$STAGING"/*.json; do
            [ -f "$f" ] || continue
            cp "$f" "$DOTFILES/knowledge/error-graph/$(basename "$f")"
          done
          for d in "$STAGING"/*/; do
            [ -d "$d" ] || continue
            dirname=$(basename "$d")
            mkdir -p "$DOTFILES/knowledge/$dirname"
            cp -Rf "$d"* "$DOTFILES/knowledge/$dirname/" 2>/dev/null
          done
      - name: Commit and push to claude-dotfiles
        if: steps.check.outputs.has_files == 'true'
        run: |
          cd claude-dotfiles
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          if [ -n "$(git status --porcelain)" ]; then
            git add -A
            git commit -m "knowledge-sync from ${{ github.repository }} [knowledge-sync]"
            for i in 1 2 3 4; do
              git push && break
              [ $i -lt 4 ] && sleep $((2 ** i))
            done
          fi
      - name: Clean up staging in source repo
        if: steps.check.outputs.has_files == 'true'
        run: |
          cd source-repo
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          rm -rf "${{ env.KNOWLEDGE_STAGING_DIR }}"
          if [ -n "$(git status --porcelain)" ]; then
            git add -A
            git commit -m "chore: clean up knowledge staging [knowledge-sync]"
            git push
          fi
```

### 2. グローバル CLAUDE.md の「知識ベース自動同期（必須）」セクションを以下に書き換え

```markdown
## 知識ベース自動同期（必須）

### 環境の判別と同期方法
- **ローカルマシン（Windows/Mac）**: 従来通り `bash ~/claude-dotfiles/scripts/sync.sh pull/push` を使用
- **Claude Code on the web（スマホ等）**: sync.sh は動作しない（サンドボックス環境で、セッション起動時のリポジトリにしか push できないため）
  - 代わりに `.claude-knowledge-staging/` にファイルを配置して push する
  - GitHub Actions が自動で claude-dotfiles に同期し、staging を削除する

### エラーナレッジの記録手順（全環境共通）
1. エラー解決・ハマりポイントを見つけたら、PDCAノードを作成:
   - `.claude-knowledge-staging/<node-name>.md`（YAML frontmatter + PDCA形式）
2. MOCを更新する場合:
   - `.claude-knowledge-staging/moc-updated.md` として最新版を配置
3. commit & push すれば自動同期される

### 新しいプロジェクトでの初回セットアップ（必須）
- プロジェクトに `.github/workflows/sync-knowledge-to-dotfiles.yml` が存在しない場合:
  - ローカル: `~/claude-dotfiles/templates/sync-knowledge-to-dotfiles.yml` を `.github/workflows/` にコピー
  - web: テンプレートの内容を知っているので直接作成すること

### GitHub Actions の前提条件
- aigentcraft org（または個人アカウント）に `CLAUDE_DOTFILES_PAT` シークレットが必要
- PAT (classic) の scope: `repo`
- 設定: GitHub > Settings > Secrets and variables > Actions > Organization secrets
```

### 3. 今回 Maia-ai セッションで作成済みのエラーノード2つを反映

Maia-ai リポジトリの `.claude-knowledge-staging/` に以下のファイルがある。内容を確認して claude-dotfiles の `knowledge/error-graph/nodes/` に反映すること:

- `supabase-v2-types-resolve-never.md` - Supabase v2 で手動定義した Database 型が Insert/Update 時に `never` に解決される問題
- `ai-sdk-v6-renamed-properties.md` - AI SDK v6 で maxTokens → maxOutputTokens にリネームされた問題

MOC（`knowledge/error-graph/moc.md`）にも以下のカテゴリとエントリを追加:

```markdown
### Database & ORM
- [[nodes/supabase-v2-types-resolve-never.md]] - Supabase v2 TypeScript types resolve to `never` for ungenerated schemas

### SDK & Framework Migration
- [[nodes/ai-sdk-v6-renamed-properties.md]] - AI SDK v6 renamed properties (maxTokens → maxOutputTokens)
```

### 4. commit & push

すべての変更を commit して push する。
