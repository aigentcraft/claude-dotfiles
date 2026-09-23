---
name: placeholder-example-domain-executed-verbatim
title: "例示用の taro@example.com がそのまま資格情報に登録された — 「明らかに架空なら置き換えてもらえる」は成り立たなかった"
cluster: observability
type: "silent-failure"
tags: ["credentials", "placeholder", "guard", "cli-guidance", "human-in-the-loop", "fukugyo-hootl"]
date: 2026-09-23
severity: medium
---

## 症状
求人ボックスの資格情報登録を `cmdkey /generic:fukugyo-hootl:kyujinbox /user:taro@example.com /pass` と案内したところ、
**そのまま実行された**。`npm run credentials` は `[ OK ] 登録済み` と報告し、
自動ログインで初めて「メールアドレスとパスワードが一致しません」が出た。

## 根本原因
1. [[placeholder-guard-matched-only-angle-brackets]] の予防ルール 1
   「例文は `taro@example.com` のように明らかに架空の値にする」が、**それ自体で再発を招いた**。
   丸ごと実行できるコマンドを渡すと、人は置き換えずに実行する。架空かどうかは関係なかった
2. プレースホルダ検出が山括弧しか見ておらず、例示ドメインを素通しした（前回「見送った修正」のまま）

## 修正
- `isPlaceholderAccount()`（純関数）を追加し、山括弧に加えて **RFC 2606 の例示ドメイン**
  （example.com/.net/.org・`.example`・`.test`・`.invalid`）を `placeholder` として弾く。
  実在アカウントになりえないため、稼働機の既存データを落とす心配が無い（前回見送った理由を回避）
- selftest に陽性・陰性対照を追加（実在しうる値 `gmail.com` / `myexample.com` / チャンネル ID を誤検知しない）
- 表示文言を「例（<…> や example.com）のまま」に

## 予防ルール
1. **置き換えが必要な値を含むコマンドは「そのまま実行できる完成形」で渡さない。**
   置き換える箇所を文章で名指しし、例示値は検出器が必ず弾く形（example.com 等）に限る
2. 例示値を決めたら、**その値が検出器に弾かれることを selftest で固定する**。
   例示値と検出器は対で設計する
3. 登録直後に「形の検査」だけでなく実ログインまで通して確かめる（今回は実ログインで発覚）
