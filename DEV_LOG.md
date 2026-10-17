# DEV_LOG.md - claude-dotfiles

> **このファイルは追記専用（append-only）です。過去のエントリを編集・削除しないでください。**
> 新しいエントリは末尾に追加してください。

---

## Session 2026-10-17 #1 — エラーナレッジノードの停止

### ユーザーの指示・要件
- 「エラーナレッジノードもういらないかなと思ってて、いったん切っておきたい」
- 消すのではなく「いったん」止める。戻せる形にしておく
- 「commit して master に取り込んで push して」

### 実施した変更
- `knowledge/error-graph/PAUSED.md` を新設。停止スイッチ兼、止めた範囲・元のルールの原文・再開手順の記録
- `scripts/validate-nodes`・`extract-pdca`・`generate-moc`（`.sh` / `.ps1` の 6 本）: PAUSED.md があれば即終了（exit 0）。push 前フック（`.claude/hooks/pre-bash-git-push.sh`）と `sync.sh` / `sync.ps1` はそのまま呼ぶが、何もしなくなる
- `CLAUDE.md`（リポジトリ版と `~/.claude/CLAUDE.md` の両方）: `fix:` コミットの出口条件・push 前の UC スキャン・UC 検出トリガー・セッション開始時の `error-graph/moc.md` 読み込みを外し、「エラーナレッジノード（2026-10-17〜 停止中）」の節を追加。Web 用 staging の行からエラーノードを外した
- `skills/skill-pdca-error-graph/SKILL.md`: `disable-model-invocation: true` と停止の注記
- `skills/auto-sync-rule/SKILL.md`: push 前の PDCA Reflection Checkpoint を外した
- `knowledge/skills-graph/relationships.md`・`knowledge/skills-moc.md`: `skill-pdca-error-graph` を補完先として読まない旨の注記
- 作業は `chore/pause-error-graph` ブランチで行い、master に取り込んで push（ユーザー指示）

### 学んだこと・重要な知見
- このリポジトリでは、どのセッションの `sync.sh push` も `git add -A` で作業ツリーの全変更をコミットする。作業途中の変更が、別セッションの「auto-sync」コミットに 2 回混ざった（01:15・09:45。ブランチに上流がなく push は失敗していた）。コミットを分け直してから取り込んだ。未コミットの状態を長く置かないこと
- push 前フックの最後の段は、`knowledge/` に未コミットの変更があると、どのプロジェクトの push でも claude-dotfiles に自動コミット・push する
- 停止前に始まったセッションは古い CLAUDE.md を読み込んだままなので、終わるまでは UC ノードを書き続ける（今回も 2 件書かれた。別コミットで保存）
- Windows の `~/.claude/CLAUDE.md` は、リポジトリの `CLAUDE.md` とハードリンクでなくなっていた（DEV_LOG ルール約 46 行分ずれている）。両方を同じように直した

### 現在の状態
- 6 本のスクリプトが停止中として exit 0 で終わることを実行して確認済み。`moc.md` は変化なし
- 既存ノード（335 件）・クラスター・`moc.md` は残してある
- 残課題: Mac 側の `~/.claude/CLAUDE.md` がリポジトリへのリンクか確認（実ファイルなら同じ修正が要る）。Antigravity を使う場合は `~/.gemini/antigravity/ANTIGRAVITY.md` のエラーノード義務も止める
