---
name: mcp-guard-keyed-on-schema-names-bypassed-by-snake-case-alias
title: 道具の引数を見て止めるガードが、サーバーの受け付ける別の綴り（snake_case）で素通りした
cluster: observability
type: "technical-error"
tags: ["hooks", "pretooluse", "mcp", "guard", "fail-open", "google-sheets", "secrets", "royal-cloak"]
date: 2026-10-12
severity: high
relationships:
  related_to:
    - "guard-and-its-check-must-not-share-the-same-handle.md"
    - "claude-headless-permission-flags-ignored-under-bypass.md"
---

## 状況
ROYAL CLOAK の CW 自動化で、Claude Code の PreToolUse フック（CWガード）を作った。
運用管理シートの「アカウント」タブ E列（パスワード）を読ませないため、Google Sheets の `get_values` の
`spreadsheetId` と `range` を見て deny を返す。テスト 83件は全部通っていた。

## 何が起きたか
独立レビュー（security-reviewer）が「道具の説明文に `spreadsheet_id` という綴りが載っている」ことに気づいた。
実機で `get_values {"spreadsheet_id": 状態ボード, "range": "記録!A1:B1"}` を呼ぶと、**普通に読めた**。
ガードは `spreadsheetId` しか見ていないので、この綴りで運用管理シートの E列を指定されると**素通りしてパスワードを読む**。
さらに Sheets かどうかの振り分けを「`spreadsheetId` が文字列か」で行っていたので、判定そのものが走らなかった（null = 口を出さない）。

## 根本原因
- 道具の入力スキーマ（camelCase）を「サーバーが受け付ける綴りのすべて」だと思い込んだ。
  Google の API は proto の JSON 変換で **lowerCamel と元の snake_case の両方を受け付ける**のが通例
- 振り分け（どの道具か）を引数の有無で決めていた。引数の綴りが変わると、ガードの対象外に落ちる
- テストは「自分が想定した呼び方」しか作っていなかった。想定の外の呼び方は、テストが全部緑でも通る

## 修正（2026-10-12）
- Google 系の道具は、判定の前に引数名を camelCase にそろえる。2つの綴りが違う値なら ask
- 振り分けは**道具の名前の集合**で行う。対象の道具なのに必須の引数が取れなければ ask
- 抜け道ごとのテストを先に足して失敗を確認し（21件）、直したあと全部通ることと、
  直した箇所をわざと戻すとテストが落ちることを確かめた。最後にこのセッションで、
  もし止まらなくても害の無い呼び方（シート名なしの空セル）で、snake_case でも止まることを実地確認

## 予防ルール
- **引数を見て止めるガードは、サーバーが受け付ける別名までそろえてから判定する。** スキーマに無い綴りでも通ることがある。
  実在の確認は「通っても害の無い呼び方」で1回やる
- **ガードの対象は道具の名前で決める。** 引数の有無・形で振り分けると、形を変えた呼び出しが対象外（＝素通り）に落ちる
- **ガードは作った人とは別の目で、抜け道を探させる。** 自分のテストは自分の想定の中しか確かめない
- 同じレビューで見つかった型: fields マスクの抜け（拒否リスト式）、式の差し込みの別経路、内蔵ブラウザのまとめ実行、
  起動失敗で素通り（exit 2 以外の非0終了は非ブロック）。どれも「想定した形」だけを見ていたのが共通点
