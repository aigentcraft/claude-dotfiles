---
name: abstraction-left-old-name-in-user-facing-strings
title: "OS 抽象化で警告文だけ置換し、情報ログ・使い方・別コマンドに旧名が残った — Windows で「Keychain」と表示した"
cluster: producer-consumer-sync
type: "error"
tags: ["refactor", "rename", "user-facing-strings", "windows", "keychain", "grep", "fukugyo-hootl"]
date: 2026-09-19
severity: low
---

## 症状
Windows で `npm run login -- mamaworks` を実行したら、ログが
`[INFO] Keychain の資格情報で自動ログインします` と出た。Windows に Keychain は無い。
機能は正常に動作しており、**表示だけが嘘**だった。

## 根本原因
資格情報ストアを OS ごとに分離（`core/secrets/darwin-keychain.ts` / `win32-credman.ts`）した際、
`STORE_LABEL` を用意して置換したのは**警告文だけ**。次の 4 系統が旧名のまま残った。

| 残っていた場所 | 内容 |
|---|---|
| `cli/login.ts` | 自動ログイン時の情報ログ（**実行して初めて出る行**） |
| `cli/index.ts` | `npm run` の使い方説明 |
| `cli/setup-discord.ts` / `cli/watch.ts` | Discord 未登録時のエラー文 |
| `discord/channels.ts` | コメント |

grep の対象を「今いじっているモジュールとその直接の利用側」に限定していた。
文字列リテラルは import で辿れないため、**依存グラフを追う発想では見つからない**。

## なぜ検査で出なかったか
`selftest` は 26 件すべて通っていた。全 59 モジュールの import も通っていた。
**文字列は壊れない。** 型も通るし例外も出ない。実際にコマンドを走らせて人間が読むまで、
どの自動検査にも現れない種類の欠陥。今回は資格情報の登録を終えて実ログインを試した時に見えた。

## 修正
`STORE_LABEL` へ 5 ファイル分を置換（`watch.ts` は import 追加も必要だった）。

## 予防ルール
1. **名前を抽象化したら、旧名をリポジトリ全体で grep し、残存 0 を確認してからコミットする。**
   対象は `src/` 全体。import を辿る範囲ではなく、文字列として全文検索する
2. 利用者に見える語は**定数 1 箇所から供給**する（`STORE_LABEL`）。同じ語を 2 箇所に書かない
3. **表示の正しさは実行でしか確かめられない。** 移植や抽象化の後は、
   テストが全部緑でも「実際に 1 回動かして出力を読む」を出口条件に入れる
4. 関連: [[same-set-defined-in-four-places-one-silently-strips.md]]（同じ定義が複数箇所にあり、
   1 箇所だけ挙動が違った）
