---
name: uc-approval-draft-hidden-in-question-preview
title: 「文面が見えていない」— 承認してほしい送信文を、選択肢のプレビュー欄にだけ入れていた
cluster: uc
type: "user-correction"
tags: ["uc", "approval-flow", "ask-user-question", "preview", "ui", "royal-cloak"]
date: 2026-10-13
severity: low
relationships:
  related_to:
    - "uc-approval-asked-in-the-wrong-place.md"
    - "uc-approved-in-chat-then-asked-again-by-guard.md"
---

## ユーザーの指摘（原文）
「文面が見えていない」
（2026-10-13・ROYAL CLOAK。事務スタッフへの Slack の文面の承認を、AskUserQuestion の選択肢の preview 欄に入れて聞いた）

## 根本原因
- preview 欄は「選択肢にカーソルを合わせると出る」もので、オーナーの画面（デスクトップアプリ・スマホのリモート操作）では見えないことがある
- 承認の判断に要る中身（送る文面）を、見えるかどうか確かめていない場所にだけ置いた

## 修正
- 文面を返答の本文に全文出し、「この文面で送ってよいですか？」と本文で聞き直した。オーナーは「送って」と答えた

## 予防ルール
- **承認してほしい中身（送る文面・書き込む値）は、返答の本文に全文出す。** 選択肢の preview・折りたたみ・添付だけに置かない
- 選択式の質問は、本文に中身を出したうえで「送る／直す」を選ばせる補助として使う
