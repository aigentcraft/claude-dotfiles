---
name: kyujinbox-arrival-duplicated-threads-fullwidth-company
title: 全角の社名を別人扱いし、着信のたびに新スレッドを立てて同じ会社のスレッドが 3 本並んだ
cluster: observability
type: "runtime-error"
tags: ["discord", "thread", "dedup", "unicode", "nfkc", "company-name", "fukugyo-hootl"]
date: 2026-10-01
severity: medium
relationships:
  related_to:
    - "arrival-notice-hardwired-to-first-site-channel.md"
---

## ユーザーの指摘（原文）

「wanderwallのスレッドが複数になっている」

## 1. Plan / Context

企業からの着信は、追跡中の案件（応募済みなど）があればその案件スレッドへ集約し、無ければ #やり取り に通知する。
同じ相手かどうかは `core/company.ts` の `sameCompany`（正規化一致）で決める。

## 2. Do / The Error

Wonder Wall に応募済み（案件 #255）なのに、求人ボックスのメッセージが届くたびに #やり取り に
`[メッセージ] Ｗｏｎｄｅｒ Ｗａｌｌ株式会社` という新しいスレッドが立ち、3 本並んだ。

## 3. Check / Root Cause

1. **社名の全角・半角を揃えていなかった。** 求人ボックスの受信 API は社名を全角英字で返し、求人一覧は半角だった。
   `normalizeCompany` は法人格と空白を落とすだけで、「ｗｏｎｄｅｒｗａｌｌ」と「wonderwall」は別物 → #255 が見つからない
2. **案件が無い時、着信のたびに新スレッドを立てていた。** 同じ会話（thread.key）の既存スレッドを再利用しない作りだった
3. 調査でも同じ罠を踏んだ: 半角の `/onder/` で検索して全角のスレッドを見落とし、最初は「1 本しかない」と判断しかけた

## 4. Act / Prevention Strategy (Fix)

- `normalizeCompany` の先頭で `.normalize('NFKC')`（同じ文字の互換形だけを揃えるので、別の名前は束ねない）
- `handleArrival`: 案件が無い時は、同じ会話の既存スレッドが生きていればそこへ追記。消えていれば新規
- selftest 3 件（全角半角の同一視・別名を束ねない・既存スレッドへの追記）。故障注入で FAIL を確認

### 予防ルール

1. **外部から来る名前は、比べる前に NFKC で揃える。** サイトごとに全角・半角・半角カナの癖が違う
2. 「新しく作る」処理は、**同じ鍵の既存物を先に探す**（スレッド・投稿・記録）。無い時だけ作る
3. 自分の調査の検索も NFKC で揃える（全角を見落として「重複は無い」と誤判断しかけた）
