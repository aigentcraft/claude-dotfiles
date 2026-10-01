---
title: "claude CLI: CLAUDE_CODE_OAUTH_TOKEN は保存済みログインより優先される。折り返しコピーの空白で全滅する"
description: "常駐の claude -p が 401。保存済みログインが壊れ（期限 0・リフレッシュ無し）、再ログインで直した直後に長期トークンを登録したら再び 401。CLI は env のトークンを優先し、そのトークンにターミナルの折り返しで空白が 1 つ入っていた。9/15 の『env は読まれない』は旧版の結論。"
type: "technical-error"
tags: ["claude-code", "cli", "auth", "headless", "credentials", "clipboard", "windows", "fukugyo-hootl"]
relationships:
  caused_by: []
  related_to: ["claude-cli-headless-oauth-expiry", "cmdkey-prompt-truncates-pasted-secret-to-one-char"]
  fixes_node: ["claude-cli-headless-oauth-expiry"]
---

## 1. Plan / Context
副業HOOTL の常駐（Windows・タスクスケジューラ）は、返信案の生成や LINE の巡回で
`claude -p` をサブプロセスで呼ぶ。`core/claude.ts` は資格情報マネージャーに
`fukugyo-hootl:claude`（長期トークン）があれば `CLAUDE_CODE_OAUTH_TOKEN` に入れて渡す。
9/15 の実測で「CLI はこの env を読まない」と結論しており、注入は「将来のための残置」扱いだった。

## 2. Do / The Error
2026-10-01 14:01 から常駐の claude 呼び出しが全部失敗（40 回）:
```
claude CLI の認証が通りませんでした。
```
- `claude auth status` → `loggedIn: false`
- `~/.claude/.credentials.json` は 13:20 に上書きされ、`expiresAt` が 0・`refreshToken` 無し
  （誰が書いたかは未特定。デスクトップアプリ側の可能性）

`claude auth login` で復旧 → 続けて `claude setup-token` の長期トークンを登録 → **再び 401**。

## 3. Check / Root Cause
二つの事実が重なった。

1. **今の CLI（2.1.258）は env のトークンを保存済みログインより優先する。**
   正しいログインがある状態で、壊れたトークンを env に入れると 401。
   空の `CLAUDE_CONFIG_DIR` ＋正しいトークンだけなら `authMethod: oauth_token` で通る。
   9/15（Mac・旧版）の「無効値でもエラーが変わらない＝読まれていない」は、当時の版の結論だった。
2. **登録されたトークンに空白が 1 つ入っていた**（108 字 → 72 字目に空白で 109 字）。
   ターミナルパネルの折り返し位置でコピーすると、改行が空白として貼り付けられる。
   コードは `stored.secret` をそのまま渡していた。

→ 「長期トークンを登録した瞬間に、生きているログインまで巻き込んで全滅する」状態だった。

## 4. Act / Prevention Strategy (Fix)

### 修正
- `core/claude.ts` に `normalizeClaudeToken()`（空白・改行を全部除く。トークンは空白を含まない）
- 認証エラーの文面を、長期トークンの有無で案内を分けるように（トークンがあればトークンを疑う）
- selftest に「折り返しで入った空白を除く」検査
- 確認: `node src/cli/index.ts credentials --verify` → `登録済み・疎通OK`
  （`npm run credentials -- --verify` は npm が `--verify` を食うので効かない）

### 予防ルール
1. **「読まれない」という実測結論には版数を付ける。** CLI の挙動は版で変わる。
   コメント・ドキュメントに「（実測 日付・版）」を残し、前提にしている箇所は再測定してから頼る
2. **コピーした秘密は、使う側で空白を除いてから渡す。** トークン・アプリパスワード・API キーは
   空白を含まない。利用者の貼り付け手順に頼らず、コードで正規化する（Gmail アプリパスワードと同じ扱い）
3. **秘密の登録直後は「長さ」と「空白の有無・位置」を値を出さずに確かめる。**
   さらに、空の設定ディレクトリでその秘密だけを使って実際に 1 回叩く（他の経路で通ってしまうのを除く）
4. **優先順位のある認証経路は、両方が同時にある状態でも試す。** 単独で通ることと、
   併存時にどちらが使われるかは別の問題
