---
name: claude-cli-native-migration-breaks-resident-path
title: Claude Code が npm 版からネイティブ版に切り替わり、常駐からの claude 呼び出しが全部「認識されていません」になった
cluster: shell-hook-env
type: "technical-error"
tags: ["windows", "claude-cli", "path", "subprocess", "resident", "fukugyo-hootl"]
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

## 予防ルール

- **常駐から外部 CLI を起動する時は PATH に頼らない。** 既知の置き場所を順に確かめ、見つからない時だけ PATH に任せる
- CLI の自動更新・インストーラの切り替えは、起動経路（実体の場所・拡張子・シェル経由か）を変えうる。更新日時をログで追えるようにしておく
- 「全部の呼び出しが同じ時刻から一斉に失敗」は、個々の処理ではなく起動の土台（PATH・認証・実体）を先に疑う
