# エラーナレッジノードは停止中（2026-10-17〜）

ユーザーの判断で、エラーナレッジノード（エラーノード・UC ノード）の作成・更新・参照をいったん止めている。

- ユーザーの言葉: 「エラーナレッジノードもういらないかなと思ってて、いったん切っておきたい」
- 既存のノード（335 件）・クラスター・`moc.md` は消さずに残してある
- **このファイル自体が停止スイッチ**。`scripts/` のノード用スクリプトは、このファイルがある間は何もせずに終わる

## 止めているもの

| 場所 | 止め方 |
|---|---|
| `~/.claude/CLAUDE.md` と `claude-dotfiles/CLAUDE.md` | `fix:` コミットの出口条件・push 前の UC スキャン・UC 検出トリガー・セッション開始時の `moc.md` 読み込みを外し、「エラーナレッジノード（停止中）」の節を置いた |
| `scripts/validate-nodes`・`extract-pdca`・`generate-moc`（`.sh` / `.ps1`） | このファイルがあれば即終了。push 前フック（`.claude/hooks/pre-bash-git-push.sh`）や `sync.sh` / `sync.ps1` から呼ばれても同じ |
| `skills/skill-pdca-error-graph/SKILL.md` | `disable-model-invocation: true` で Claude が自動では使わない。本文の先頭にも停止の注記（Antigravity 向け） |
| `skills/auto-sync-rule/SKILL.md` | push 前の PDCA 振り返り（ノード作成）を外した |
| `knowledge/skills-graph/relationships.md`・`knowledge/skills-moc.md` | `skill-pdca-error-graph` を補完先として読み込まない旨を注記 |

止めていないもの:
- push 前フックのブランチ制約・コンフリクトマーカー検出・`knowledge/` の自動コミット
- Web 用の staging 同期と PAT の仕組み（エラーノードを置かなくなるだけ）
- Antigravity の `~/.gemini/antigravity/ANTIGRAVITY.md`（マシンごとのローカルファイル。Windows 機では 2026-04 以降使われていない）
- 他プロジェクトの CLAUDE.md・memory にある「詳細: error-graph `xxx`」という参照（過去の記録として残す）

## 再開するとき

claude-dotfiles 内の変更は、停止したコミットを `git revert` すればまとめて戻る（このファイルの削除も含む）。
リポジトリ外の `~/.claude/CLAUDE.md` だけは手で戻す（revert 後の `claude-dotfiles/CLAUDE.md` から同じ箇所を写せばよい）。

revert せずに手で戻す場合:
1. このファイルを削除する（スクリプトが元どおり動く）
2. 下の「止めたルールの原文」を両方の CLAUDE.md の元の位置に戻し、「エラーナレッジノード（停止中）」の節を消す
3. `skill-pdca-error-graph` の `disable-model-invocation: true` と停止の注記を消し、`auto-sync-rule` の「2. PHASE 2」を下の原文に戻す
4. `relationships.md`・`skills-moc.md` の停止の注記を消す

## 止めたルールの原文

### CLAUDE.md「Git 同期ルール」から外した 3 項目

`~/.claude/CLAUDE.md` では、1 項目目と 2 項目目の間に「push 前の DEV_LOG 検証」がある。

```markdown
- **バグ修正コミット（`fix:`）の出口条件**: コミット前に必ず以下を実施する
  1. `knowledge/error-graph/nodes/` にエラーノードを作成（症状・根本原因・修正・予防ルールを記述）
  2. 該当クラスターのサマリーを更新（なければ新クラスター作成）
  3. `knowledge/error-graph/moc.md` のインデックスに追記
  → ナレッジ蓄積なしの `fix:` コミットは不完全とみなす
- **push 前の UC スキャン（必須）**: push 前に「このセッションでユーザーに指摘された点はあったか？」を自問し、あれば UC ノードが作成済みであることを確認してから push する
- **UC 検出トリガー**: ユーザーの発言に「足りない」「まずい」「問題だ」「なぜしない」「仕組みにして」「そうじゃない」等が含まれたら、**返答の前に** UC ノード作成を開始する
```

### CLAUDE.md「共通：セッション開始時に以下を順番に読むこと」から外した 1 行（元は 2 番目）

```markdown
2. `~/claude-dotfiles/knowledge/error-graph/moc.md` — 失敗の知識・Quick Rules
```

### CLAUDE.md「Claude Code on the Web」の staging の行（元の文面）

```markdown
- エラーノード・知識ファイルは `.claude-knowledge-staging/` ディレクトリに配置して push する
```

### `skills/auto-sync-rule/SKILL.md` の「2. PHASE 2」（元の文面）

```markdown
## 2. PHASE 2: PDCA REFLECTION & POST-FLIGHT PUSH
When you have finished addressing the user's prompt (right before calling `notify_user` or finishing your task boundary), you are about to trigger the final push.
**STOP. DO NOT PUSH YET.**

### The PDCA Reflection Checkpoint (MANDATORY)
Before running the push script, you MUST explicitly ask yourself:
*"During this task, did I encounter any errors, bugs, or misunderstandings that cost me time to debug?"*
*"Did I learn a new rule about the user's preferences or environment?"*

- **If YES:** You MUST temporarily halt your completion sequence. Go to the `knowledge/error-graph/nodes/` directory, create a new PDCA markdown node documenting the fix, and link it in `knowledge/error-graph/moc.md` (as instructed in the `pdca-error-graph` skill).
- **If NO:** You may proceed directly.

### The Final Push
Only after clearing the PDCA Reflection checkpoint, you MUST push your changes to sync the hive mind.
```
