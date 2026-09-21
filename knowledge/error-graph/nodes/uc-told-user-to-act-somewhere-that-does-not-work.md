---
name: uc-told-user-to-act-somewhere-that-does-not-work
title: 「スレッドで返信してください」— リンクも無く、そのスレッドに書いても届かなかった
cluster: uc
type: "user-correction"
tags: ["user-correction", "ux", "affordance", "dead-end", "notification", "fukugyo-hootl"]
date: 2026-09-21
severity: high
relationships:
  related_to:
    - "uc-error-message-names-the-symptom-not-the-cause.md"
    - "uc-approval-asked-in-the-wrong-place.md"
    - "uc-approval-request-local-path-instead-of-url.md"
---

## ユーザー指摘（原文）

> スレッドで返信してください、というけど、スレッドへのリンクが無くて不親切なんだよね

## 1. Plan / Context

求人 URL を持たないスカウト案件は応募できない。案件カードにその理由を 1 行で出し、
「スレッドで返信してください」と代替行動を案内していた。

直前のセッションで、この文面は 4 行 → 1 行に削ったばかりだった
（[[uc-error-message-names-the-symptom-not-the-cause.md]] §5）。
**短くしたが、行き先は書かないままだった。**

## 2. Do / The Error

指摘を受けて実装を追ったところ、問題は 2 段構えだった。

**① リンクが無い** — 「スレッド」がどれを指すのか、どこを開けばよいのかが書いていない。

**② そもそも、そのスレッドに書いても企業には届かない**（より深刻）

```ts
// cli/watch.ts  onThreadMessage
// まずは受け取れていることを可視化するだけ。
log.info('スレッド発言を受信: ' + userName + ' — ' + text …);
```

Discord のスレッドに書かれた自由文は**ログに出るだけ**で、送信経路が無い。
つまり私は、**動かない場所を行き先として案内していた**。

## 3. Check / Root Cause

- **自分が書いた文言の宛先を、一度も辿らなかった。**
  「スレッドで返信」は自然な日本語なので、読み返しても違和感が無い。
  実装を辿って初めて「そこには送信経路が無い」と分かる
- 文面を短くする作業に集中し、**短くする対象が正しいかを問い直さなかった**。
  4 行を 1 行にする編集では、行き先の妥当性は検査されない
- 返信先の URL は**取れていた**（`ThreadRecord.clientId` → `scout_mail?client_id=N`）。
  情報が無かったのではなく、**使っていなかった**

## 4. Act / Prevention Strategy (Fix)

- `core/contact.ts` を追加。企業名（正規化一致）から**実際に話せる場所の URL** を引く
- **直接開けるかどうかを区別する**（`ContactLink.direct`）。
  企業 ID が取れれば その会話だけを開く URL、取れなければ一覧まで。
  **「返信する」と書いて 41 件の一覧に着地させるのは、リンクが無いのと同じ不親切**
- 表示側（`discord/jobs.ts`）は解決済みの値だけを受け取る純関数のまま。
  解決は `buildJobMessage` の 1 箇所
- `selftest` に 4 件追加（リンクになる / 一覧の時は言い方を変える /
  解決できない時もどこで返信するかは書く / 1 行に収まる）

実測:

```
job#106 → [ママワークスで返信する](https://mamaworks.jp/scout_mail?client_id=6152)
job#53  → [ママワークスのスカウト一覧を開く](https://mamaworks.jp/scout_mail)
```

## 汎用ルール

> **代替行動を案内する文言は、その行き先が実際に機能するかを確かめてから書く。**
> 「〜で返信してください」「〜から操作してください」と書いた瞬間に、
> **その経路の実装を辿る**。辿らずに書いた案内は、丁寧なだけの行き止まりになる。

> **場所を指したら、そこへのリンクを必ず添える。**
> 人間に「どこだろう」と探させた時点で不親切。
> 直接開けない時は**開けないと書く**（着地点を偽らない）。

> **文面を短くする作業は、文面が正しいかを検査しない。**
> 推敲と検証は別の作業。短くする前に、まず宛先を辿る。
