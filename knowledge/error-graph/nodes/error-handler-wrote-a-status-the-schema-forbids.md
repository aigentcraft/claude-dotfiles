---
title: "error-handler-wrote-a-status-the-schema-forbids"
type: "system-design"
tags: ["observability", "error-handling", "notification-storm", "db-constraint", "silent-failure", "pullie"]
date: "2026-09-11"
---

## ユーザーの指摘

「**ずっと上限通知がディスコードに届き続けててうざい。**」

## 症状

日次コスト上限の通知が **約15分おきに約38通** Discordへ届いた。

## 何が起きていたか

通知役 `09_notify` の構造はこうなっている:

1. ブロック1: コスト上限で止まっていたら Discord へ1通
2. ブロック2: 2run連続で失敗したステップを分析（haiku）して「介入要求」を送る
3. ブロック3以降: 承認待ちリマインド・X沈黙・note沈黙…

ブロック2の分析は失敗を握るつもりで `try/except` が書いてあった:

```python
    run_id = db.start_reflection(con, "ops-analyst")
    try:
        res = claude_client.run_agent(...)      # ← コスト上限で例外
        ...
    except Exception as e:
        db.finish_reflection(con, run_id, status="error", ...)   # ← ここで落ちる
```

`reflections.status` には `CHECK (status IN ('running','done','failed'))` があり、
**`"error"` は許可されていない**。つまり:

- 例外は握れている
- **握った直後、記録しようとした側が `IntegrityError` で落ちる**
- その例外は `except` の外なので上位へ抜け、**09_notify がプロセスごと死ぬ**

死ぬのはブロック2なので、**ブロック1（コスト上限通知）だけは毎回送られる**。
そしてブロック3以降（承認リマインド・沈黙監視）は**一度も実行されない**。

さらにこの日は別の不具合でパイプラインが15分おきに再起動されており、
**再起動のたびに「1通送って死ぬ」を繰り返した**。

実測の痕跡: `09_notify` 完走17回に対し**途中死38回**、
`reflections` に `running` のまま残った孤児 **273件**（うち241件がその日）。

## 根本原因

**エラーハンドラ自身が、スキーマの許さない値を書いていた。**
`status="error"` は自然な語だが、スキーマの語彙は `failed` だった。
そして**この行はエラー時にしか実行されない**ため、正常系のテストでは永久に露見しない。

同じ書き方が**9箇所**にあった（note/product/visual/weekly_pdca/review/notify）。
つまり「失敗したときだけ壊れるコード」がパイプライン全体に散っていた。

## 修正

- `db.finish_reflection` が**未知のstatusを `failed` に丸める**（元の語は what_done に退避）。
  列挙で塞がず構造で塞ぐ — 次に誰かが別の語を渡しても事故にならない
- 呼び出し側9箇所も `failed` へ統一
- コスト上限通知に**1日1回の重複抑止**を追加（上限は日次なので伝える事実も1日1つ。
  リード督促・X沈黙・note沈黙には既に同型のガードがあり、ここだけ無かった）

## 予防ルール

- **エラーハンドラの中の書き込みは、正常系のテストでは絶対に通らない。**
  `except` 節に DB 書き込み・API 呼び出しがあるなら、**わざと例外を起こして1度実行する**
- **文字列でスキーマの語彙を指定する箇所は、スキーマ側の定数と突き合わせる。**
  `status="error"` と `CHECK IN (…)` が別々に書かれていたら、いつかずれる
- **共通関数の入口で丸める。** 呼び出し側を全部直しても、次に増える呼び出し側は直っていない
- **「同じ通知が繰り返し来る」は、通知の重複抑止が無いだけとは限らない。**
  「1通送って死ぬ」を繰り返している可能性を先に潰す — 完走回数と途中死回数を数えれば分かる
- 関連: [[observability.md]] R5（通知役が道連れになる障害）/
  [[enumeration-guards-never-close-use-structural-rules.md]] /
  [[verification-tool-that-cannot-fail.md]]
