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

---

## Session 2026-10-18 #1 — 動画・モーションリールの制作ルールを追加

### ユーザーの指示・要件
- 「モーションリールを何度か作ってもらったときにハイパーフレームを使ってくれていると思ったんだけど実際はどうだった？…作ってくれたものをUIでも見せてくれるようにしてほしいんだよね。」
- 「claude-dotfiles の CLAUDE.md と me.md の変更を commit & push して」

### 実施した変更
- `CLAUDE.md`（リポジトリ版と `~/.claude/CLAUDE.md` の両方）: 「動画・モーションリールの制作ルール（全プロジェクト共通・必須）」の節を追加。HyperFrames の書式で作る／場面が多いものは章ごとのサブコンポジション／見せるときは `npx hyperframes preview --background` で Studio も開いて URL を渡す。作業状態の「完了済み」にも追記
- `knowledge/me.md`: Conversation Log の末尾に 2026-10-18 の記録を追記
- `GRAPH_RAG.md`: 現在の開発フォーカスに追記（ファイル構成の変更はなし）
- 実例の作業は `過去実績紹介＋活用導入demo` プロジェクトで行った（オープニング v2 を HyperFrames 版に移し、Studio で開けることを確認。詳細はそのプロジェクトの DEV_LOG）

### 学んだこと・重要な知見
- スキルを読み込んだだけでは、そのツールを使ったことにならない。10月のオープニングは HyperFrames のスキルを読んだうえで、自作の HTML と撮影スクリプトで書き出していた。ルールには「使う」ではなく、書式・CLI・Studio での渡し方まで具体的に書く
- 作業ツリーには自分の変更しかなかったが、`sync.sh push` は `git add -A` で全変更をまとめるため、対象のファイルを名指しして commit した

### 現在の状態
- push 済み。Mac 側は pull すればルールが入る（Mac の `~/.claude/CLAUDE.md` がリポジトリへのリンクでない場合は、同じ節を別途足す必要がある）

---

## Session 2026-10-23 #1 — yomiyasu スキルの導入

### ユーザーの指示・要件
- 「https://github.com/nanaism/yomiyasu.git をこのクロードコードに導入してください。」

### 実施した変更
- AI が書いた日本語を読みやすく直すスキル `nanaism/yomiyasu` v2.1.3 を、skill-installer の手順どおり `npx skills add nanaism/yomiyasu --skill yomiyasu --global --yes` で導入した。実体は `~/.agents/skills/yomiyasu/` で、`~/.claude/skills/yomiyasu` はジャンクション。このリポジトリには入らない
- 導入前に中身を確認した。スクリプトは外部と通信せず、起動するのは同梱の lint と diff だけで、消すのは自分が作った一時フォルダだけ。任意のフック（`yomiyasu_hook.py`）は設定を表示するだけなので、登録していない。npx skills の安全評価は Gen「Safe」、Socket「0 alerts」、Snyk「Low Risk」
- 導入後に 38 ファイルを上流の v2.1.3 とハッシュで照合し、すべて一致した。見本の文で lint、比較検査（`run`）、提出前の照合（`verify`）を `python` で実行し、動くことを確かめた
- `knowledge/skills-graph/relationships.md`: 末尾に「日本語推敲クラスター」を追加（copywriting → yomiyasu。日本語のコピーのときだけ）
- `knowledge/skills-moc.md`: 「日本語の推敲」節を追加し、copywriting の補完に yomiyasu を書いた
- `GRAPH_RAG.md`: N22（yomiyasu）と、N11・N13 からのエッジ、開発フォーカスを追記
- `CLAUDE.md`: 作業状態の「完了済み」「未解決」「環境情報」に追記

### 学んだこと・重要な知見
- この Windows の `python3` は Microsoft Store の仮のコマンドで、実行すると終了コード 49 で失敗する。yomiyasu の SKILL.md は `python3 …` で呼ぶので、Windows では `python`（3.13.5）か `py -3` で動かす
- Windows の長いパスの設定が無効（LongPathsEnabled = 0）。「フォルダなし」の会話用フォルダはパスが約 155 文字あるため、そこでの git clone や、yomiyasu の記録（`.yomiyasu/index/by-final/<64 桁>`）が 260 文字を超えて失敗した。普段のプロジェクトフォルダなら問題ない。必要なら `--state-dir` に短い場所を渡す
- `npx skills` で入れたスキルは `~/.agents/skills/` に置かれ、claude-dotfiles では同期されない。Mac では同じコマンドを一度実行する必要がある
- 導入したスキルは、Claude Code を再起動しなくても、その会話のスキル一覧に表示された

### 現在の状態
- 導入済み・動作確認済み（v2.1.3）。更新は `npx skills update yomiyasu`
- Mac への導入はまだ
