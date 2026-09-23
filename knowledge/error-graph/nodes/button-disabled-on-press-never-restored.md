---
name: button-disabled-on-press-never-restored
title: 押した時に消したボタンを、うまくいかなかった時に戻していなかった（「押し直して」と言いながら押せない）
cluster: observability
type: "runtime-error"
tags: ["discord", "ui-state", "finally", "retry-path", "fukugyo-hootl"]
date: 2026-09-24
severity: medium
relationships:
  related_to:
    - "not-ready-notice-blamed-persona-for-captcha.md"
    - "superseded-draft-kept-its-buttons.md"
---

## ユーザーの指摘（原文）

「＃77がボット検知で止まったと通知が入っていて、ボタンを押すよう依頼が記載されているがボタンがない。ボタンを再度押す必要があるときは自動でボタンが復活するようにして」

## 1. Plan / Context

案件カードの［応募内容を作る］は、二重に押されないよう**押した時点でカードのボタンを全部消す**（`disableButtons`）。
うまくいけば承認カードがスレッドに出て、次の操作はそちらで行う。

## 2. Do / The Error

CAPTCHA で止まった時の案内は「普段の Chrome で求人ページを開いてから［応募内容を作る］を押し直してください」。
しかしカードのボタンは消えたままで、**押し直すボタンが無かった**。常駐を作業中に再起動した時も同じ（結果が届かず、ボタンも戻らない）。

## 3. Check / Root Cause

- ボタンを消す処理は「押した時」に 1 か所。戻す処理は**状態が変わった時**（syncJobPost）にしか無かった
- 承認カードを出せずに終わる経路（関門・足りない情報・例外）では状態が変わらないので、誰もボタンを戻さない
- 案内の文面（押し直して）と、画面の状態（押せない）を突き合わせる検査が無かった
- 逆向きの失敗（古い返信案にボタンが残る）は `superseded-draft-kept-its-buttons` として既に記録があった。ボタンの**消す・戻す**は対で設計する

## 4. Act / Prevention Strategy (Fix)

`startApplyDraft` を `try { draftApplication } finally { restoreJobButtons }` にした。
**取り直した最新の行で**カードを描き直すので、途中で応募済みになった案件に応募のボタンは戻らない。
selftest で「finally で描き直す」形を固定。描き直しを外すと FAIL。

### 予防ルール

1. **押した時に消した（無効にした）ボタンは、終わったら必ず戻す。** 成功だけでなく失敗・例外でも（finally）
2. 「もう一度押してください」と案内する時は、**押せるボタンがあるか**を同じ経路で保証する
3. 作業の途中で常駐を止めると finally も走らない。止める前に作業中かを確かめる
