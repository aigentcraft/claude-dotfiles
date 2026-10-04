---
name: claude-cli-native-migration-breaks-resident-path
title: Claude Code が npm 版からネイティブ版に切り替わり、常駐からの claude 呼び出しが全部「認識されていません」になった
cluster: shell-hook-env
type: "technical-error"
tags: ["windows", "claude-cli", "path", "subprocess", "resident", "fukugyo-hootl", "weevee", "pullie", "cross-project-sweep"]
date: 2026-10-04
severity: high
relationships:
  related_to:
    - "windows-claude-cli-subprocess-needs-cmd-and-gitbash.md"
    - "claude-cli-env-token-overrides-login-wrapped-copy.md"
---

## 1. Plan / Context

fukugyo-hootl の常駐（タスクスケジューラで起動した node）は、返信案・メールの仕分け・LINE の読み取り・常駐の Claude Code を
すべて `spawn('claude', …, { shell: true })`（Windows は cmd.exe 経由）で起動していた。実体は npm のグローバル `claude.cmd`。

## 2. Do / The Error

2026-10-04 11:45 に `~/.local/bin/claude.exe`（ネイティブ版）が置かれ、同時に `%APPDATA%\npm\node_modules\@anthropic-ai\` が空になった
（npm 版からネイティブ版への切り替え）。12:02 以降、常駐からの呼び出しが毎回
`claude CLI が終了コード 1 で失敗しました: 'claude' は、内部コマンドまたは外部コマンド…として認識されていません` になった。

- LINE の巡回・メールの仕分け・スカウトの判定・返信案がすべて失敗
- メールは仕分けできないまま「担当が結論を出せなかった」扱いで **13 通が素通しで Discord に通知**された
- ログの stderr は cmd.exe の CP932 が UTF-8 として読まれて文字化けし、原因が読みにくかった

## 3. Check / Root Cause

- ネイティブ版の置き場所 `~/.local/bin` は、**前日から動いている常駐の PATH に入っていない**（環境変数は起動時に固定される。
  この PC ではデスクトップアプリのシェルの PATH にも無かった）
- 起動を PATH 任せにしていたので、実体が引っ越した瞬間に全経路が止まった。CLI の自動更新は利用者の操作なしに起きる

## 4. Act / Prevention Strategy (Fix)

- `src/core/claude-bin.ts` の `claudeCommand()`: Windows では `%USERPROFILE%\.local\bin\claude.exe` → `%APPDATA%\npm\claude.cmd` の順に
  実在を確かめ、どちらも無ければ従来どおり PATH の `claude`。空白入りのパスは cmd.exe 向けに引用符で囲む。macOS は変えない
- 起動する 3 か所（`core/claude.ts`・`agent/runner.ts`・`agent/resident.ts`）をすべてこれに揃えた。selftest が 3 か所の起動を検査する
- 確認: `node --experimental-strip-types src/cli/index.ts credentials --verify` が新しい経路（PATH に claude が無い端末）で疎通 OK
- 常駐に反映するには再起動が要る（動いている node は古いコードのまま）

## 5. 同じ日の再発 — weevee（アフィリエイトエージェント）で 7 時間止まった

- weevee の `workers/shared/claude_client.run_agent` も `shutil.which("claude") or "claude"` で起動していた。12:05 から
  19:00 頃まで、**記事・X・実測ラボの全担当（企画・公開・編集長・取材・図・X の各担当）の起動 217 回が**
  「claude コマンドが見つかりません（PATHを確認）」で落ちた（14:00 / 18:00 の記事生産・18:30 の交流サイクルが空振り）
- **誰にも知らせが届かず**、X の画面操作担当の立ち会いテスト（いいね 1 件）が「0 件」で終わったことから気づいた
- Windows のユーザーの PATH（`HKCU\Environment`）に入っているのは `%APPDATA%\npm` だけで、`~/.local/bin` は無かった
- 修正: `claude_client.resolve_claude_bin()`（`CLAUDE_BIN` → PATH → `~/.local/bin/claude.exe` → `%APPDATA%\npm\claude.cmd`）に
  起動 3 か所（`run_agent`・`imagegen.read_text_claude`・`tools/modelbench.py`）をそろえ、見つからない時は ops に JST の 1 日 1 回
  「🚨 Claude を起動できない（全担当が停止）」（`ops.claude_cli_missing`）。`tests/test_claude_bin.py`（元の探し方に戻すと 3 件が赤）
- **このノードは同じ日の朝に別プロジェクト（fukugyo-hootl）で書かれていたのに、同じ PC の weevee には当てはめられなかった**

## 6. 同じ日の 3 件目 — pullie（Kintone受注目的メディア運営自動化）

- pullie の `workers/shared/claude_client.run_agent` も `shutil.which("claude") or "claude"` だった。12:00 の日次処理の記事企画の補充（3 回）と、
  18:30 の交流サイクルの観測（API に代わりに回った）・交流判定（3 回 → いいね 0・返信 0）が「claude コマンドが見つかりません」で落ちた
- 気づいたきっかけは weevee と同じく、X の画面操作担当の立ち会いテスト（いいね 1 件・18:57）が同じエラーで落ちたこと。
  3 つのプロジェクトとも、**定時処理の失敗からは誰も気づいていない**
- 届いた知らせは「X の観測を API で代わりに行った」（理由欄にエラー文が載っていただけ）と、**Claude が起動すらしていないのに出た
  「Chrome のタブが残っているかもしれない」の誤報**だけ。全担当が止まっていることは伝わらなかった
- 修正: `_find_claude()`（`CLAUDE_BIN` → PATH → `~/.local/bin/claude.exe` → `%APPDATA%\npm\claude.cmd`）。再試行のたびに探し直し、
  それでも見つからなければ ops に JST の 1 日 1 回（`ops.claude_cli_missing`）。タブの知らせは、道具を 1 度も使っていない実行では出さない。
  独立レビューの指摘で、①送れなかった知らせを「今日は知らせた」と記録しない（枠を先に取り、送れなければ返す）②自動更新の差し替えの
  一瞬に当たっただけでは知らせない（再試行の後にまだ無い時だけ）③既存の潜在バグ（git-bash の env と二重に渡る型エラー）も直した。
  `tests/test_claude_bin.py` は、わざと入れた誤り 6 種類（UTC の日付で数える・送れなくても枠を返さない・PATH を CLAUDE_BIN より先に
  見る・探し直さない・実体が戻っていても知らせる・env を二重に渡す）をすべて捕まえる
- 洗い出し: タスクスケジューラの一覧（`schtasks /query /fo CSV /v` の「実行するタスク」）から、この PC で Claude を定時起動しているのは
  fukugyo-hootl・weevee・pullie の 3 つ（Fleet-Scout の定時処理は Codex）。3 つとも対処済み

## 予防ルール

- **洗い出しは最初に見つけた時に、手順どおりにやる**: ①タスクスケジューラの一覧から定時起動しているプロジェクトを列挙する
  ②各プロジェクトで CLI を起動している箇所（`which("claude")` / `spawn('claude'` など）を検索する。最初の発見（fukugyo-hootl）の時点で
  洗っていれば、weevee と pullie の停止（合わせて約 14 時間ぶん）は防げた。「全プロジェクトを洗う」と書くだけでは実行されない
- 後始末の知らせ（タブ・一時ファイルが残っているかも）は、その資源を作った可能性がある時だけ出す。起動すらしていない時に出すと誤報になり、
  本当に残った時の知らせの信用を下げる
- 「1 日 1 回だけ知らせる」の記録は、送れた時だけ残す。送る前に記録すると、送信の一時的な失敗 1 回でその日の残りが無音になる
  （全担当が止まる種類の知らせは他に経路が無いので、これが起きると知らせの目的が丸ごと崩れる）

- **PC 全体の変化（CLI の入れ替え・PATH・認証）が根の障害は、その PC で同じ CLI を起動している全プロジェクトを洗う。**
  見つけたプロジェクトだけ直して閉じない（このノードは書かれた日のうちに別プロジェクトで 7 時間の停止を出した）
- 全担当が止まる種類の失敗（起動できない・認証切れ）は、起動の口で人に知らせる（失敗の記録だけでは誰も気づかない）
- **常駐から外部 CLI を起動する時は PATH に頼らない。** 既知の置き場所を順に確かめ、見つからない時だけ PATH に任せる
- CLI の自動更新・インストーラの切り替えは、起動経路（実体の場所・拡張子・シェル経由か）を変えうる。更新日時をログで追えるようにしておく
- 「全部の呼び出しが同じ時刻から一斉に失敗」は、個々の処理ではなく起動の土台（PATH・認証・実体）を先に疑う
