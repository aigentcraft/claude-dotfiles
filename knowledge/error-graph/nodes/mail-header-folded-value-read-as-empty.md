---
name: mail-header-folded-value-read-as-empty
title: 折り返されたメールヘッダ（値が次の行にある）を 1 行ずつ読み、件名が空になった
cluster: platform-syntax
type: "error"
tags: ["mime", "rfc5322", "header-folding", "mail", "imap", "silent-failure", "fukugyo-hootl"]
date: 2026-09-26
severity: medium
relationships:
  related_to:
    - "mime-7bit-body-is-already-decoded.md"
---

## 症状

メール担当（毎時のメール巡回）を実メールで試したところ、クラウドワークスのメールだけ**件名が空**で届いた。
仕分けの LLM にも Discord の通知にも件名が渡らず、「何のメールか」が分からない形で出るところだった。
インディードの OTP のメールなど、他のメールは正しく読めていた。

## 根本原因

`core/mailbox.ts` の `headerLine` は、ヘッダを行に分けて `^Subject:\s*(.*)$` を当てていた。
クラウドワークスのメールは件名が長く、**`Subject:` の直後で改行して、値を次の行（空白始まり）に置いている**:

```
Subject:
 =?UTF-8?B?44CQ44Kv44Op44Km44OJ...?=
```

RFC 5322 では「次の行が空白で始まれば前の行の続き」（折り返し）。1 行ずつ読むと `Subject:` の行の値は空になる。
`fetchHeaders` は取得時に折り返しを畳んでいたが、**本文ごと取る `fetchMessage` の経路（メール巡回）は畳んでいなかった**。
同じ関数を 2 つの経路が使い、片方だけ前処理されていた。

## 修正

`headerLine` の中で折り返しをつないでから読む（`headers.replace(/\r?\n[ \t]+/g, ' ')`）。
呼び出し側の前処理に頼らない。selftest に「値が 2 行目にある件名」と「1 行の件名（OTP）」の両方を固定し、
つなぐ処理を外すと FAIL することを確認した。

## 予防ルール

1. **ヘッダを読む関数は、折り返しを自分でつなぐ。** 呼び出し側の前処理に頼ると、経路が増えた時に片方だけ壊れる
2. メールの検査は「短い 1 行の件名」だけでなく、**長い件名（折り返し・複数の符号化語）**も入れる。短いものしか試さないと通る
3. 空の件名は「件名の無いメール」ではなく「読めていない」可能性が高い。実メールで試した時に空欄があれば疑う
