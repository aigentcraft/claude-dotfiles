---
name: info-request-asked-in-other-channel-ignored-thread-reply
title: 返信案に要る情報を別のチャンネルで聞き、本人がスレッドに書いた返事を無視していた
cluster: observability
type: "runtime-error"
tags: ["human-in-the-loop", "discord", "thread", "hootl", "notification", "fukugyo-hootl"]
date: 2026-09-26
severity: medium
relationships:
  related_to:
    - "uc-asked-user-to-edit-local-file-from-phone.md"
    - "arrival-notice-hardwired-to-first-site-channel.md"
---

## ユーザーの指摘（原文）

「indeedのユニタスのところで知らない情報があるとかいって文面案作ってくれてない。何が知りたいのかわからないし、メッセージ送っても返信がない。」

## 1. Plan / Context

企業の連絡を「やること」に分解し、返信に本人しか知らない情報（年齢・PC 環境・稼働時間など）が要る時は
返信案を保留する。情報は #📌対応事項 のカード（1 件 1 カード・完了ボタン＋入力欄）で受け取り、
そろったら返信案を作る。

## 2. Do / The Error

ユニタスのスレッドに出たのは「あなたしか知らない情報が要ります。**対応事項チャンネルのカードで**入力してください」だけ。
**何を聞いているかはスレッドに書かれていなかった**（4 問は別チャンネルのカードにしか無い）。
本人がスレッドに「何が必要？」と書いたが、`onThreadMessage` はログに残すだけで返事をしなかった。

## 3. Check / Root Cause

- 質問を出す場所（対応事項チャンネル）と、本人が見ている場所（その会話のスレッド）が別だった
- スレッドへの返信を**受け取る口が無かった**（人物像の質問には前日に作ったが、情報待ちには無かった）
- 前日の UC（`uc-asked-user-to-edit-local-file-from-phone`）で「Discord の返信で完結させる」と決めたのに、
  **同じ形の別の経路（返信案の情報待ち）を見直していなかった**

## 4. Act / Prevention Strategy (Fix)

`core/info-request.ts`（純関数）と `watch.handleInfoReply`:
- 保留した時、スレッドに質問を具体的に並べ、メンションを付ける（「このスレッドに返信して」）
- スレッドへの本人の返信から質問ごとに答えを取り出し（persona-request の `extractFacts`）、対応事項に記録
- 足りなければ残りを聞き直す（「何が必要？」には質問を並べて返す）。全部そろったら分解した順に完了させ、
  返信のタスクが開いたところで返信案を作る。本人以外の返信は受け付けない
- 補修用コマンド（backfill-tasks / redo-tasks）の案内も同じ形にそろえた
- selftest 7 件。故障注入（「そろうまで完了させない」を外す・本人確認を外す）で FAIL を確認

### 予防ルール

1. **人に聞く時は、本人が見ている場所で聞き、そこで受け取る。** 別の場所へ行かせる案内は、何を聞くかを書いても不親切
2. 「人に頼む」経路を 1 つ直したら、**同じ形の経路を全部洗う**（人物像・情報待ち・フォームの★要確認…）
3. スレッドへの返信をログに残すだけにしない。受け取れない時も「今は受け付けていない」と返す
