---
name: cmdkey-prompt-truncates-pasted-secret-to-one-char
title: "cmdkey の伏せ字プロンプトが貼り付けを 1 文字に切り詰め、「登録済み」と報告された（2 回）"
cluster: observability
type: "silent-failure"
tags: ["windows", "cmdkey", "credentials", "clipboard", "dpapi", "silent-failure", "fukugyo-hootl"]
date: 2026-09-19
severity: high
---

## 症状
Windows 資格情報マネージャーへ `cmdkey /generic:<target> /user:<account> /pass` で登録し、
プロンプトに値を**貼り付けた**ところ、保存されたのは **1 文字**だった。2 回起きた。

| 対象 | 本来の長さ | 実際に入った長さ | 発覚した経緯 |
|---|---|---|---|
| Google アプリパスワード | 16 文字 | 1 文字 | `credentials --verify` の IMAP 疎通で失敗 |
| Discord Bot トークン | 72 文字 | 1 文字 | 常駐が `invalid Authorization header` で即終了 |

**どちらも登録状況の確認では `[ OK ] 登録済み` と表示された。** 健全性判定が見ているのは
「空でないこと」だけで、長さも形も見ていない。

## 根本原因
`cmdkey` の `/pass` プロンプトはコンソールから 1 文字ずつ読む実装で、
端末の貼り付け（一度に大量の文字が流れ込む）を取りこぼす。手打ちなら入る。
`/pass:<値>` のように引数で渡す方法は、値に空白があると
`CMDKEY: コマンド ラインで重複したコマンド スイッチが見つかりました` になり使えない。

## 修正
- **長い秘密は資格情報マネージャーの画面から登録する。** 通常の入力欄なので貼り付けが効く
  （`control /name Microsoft.CredentialManager` → Windows 資格情報 → 該当項目 → 編集）
- 登録後は**形を検査する**: トークンなら長さと区切り文字の数、アプリパスワードなら 16 文字
- 可能なら**疎通まで確かめる**（このプロジェクトは `credentials -- --verify` が IMAP に実接続する）

## 予防ルール
1. **「登録済み」は長さも形も保証しない。** 空でないことしか見ていない判定を信用しない
2. **秘密を登録したら、その場で形を検査する。** 長さ・区切り文字の数を出す
   （中身は出さない）。疎通経路があるなら疎通まで
3. 50 文字を超える秘密を伏せ字プロンプトに貼り付けない。GUI か API 経由で書く
4. 関連: [[placeholder-guard-matched-only-angle-brackets.md]]（同じ日に、
   同じ「形を見ない判定が通してしまう」構造で 2 種類の事故が起きた）
