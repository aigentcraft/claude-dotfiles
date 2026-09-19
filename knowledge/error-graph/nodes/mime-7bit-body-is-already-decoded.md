---
name: mime-7bit-body-is-already-decoded
title: "7bit のメール本文を再びバイト列として扱い、復号済みの日本語を壊した"
cluster: platform-syntax
type: "error"
tags: ["mime", "encoding", "iso-2022-jp", "utf-8", "mail", "imap", "fukugyo-hootl"]
date: 2026-09-19
severity: medium
---

## 症状
メールの本文を取り出す処理で、HTML だけのメール（`Content-Transfer-Encoding: 7bit`、
`charset=utf-8`）の日本語が文字化けした。base64 と quoted-printable は正しく読めていた。

## 根本原因
本文の取得は `curl` の出力を `encoding: 'utf8'` で受けており、**この時点で既に文字列**になっている。
そこへ `Buffer.from(body, 'binary')`（latin1 相当）を掛けると、多バイト文字の下位バイトだけが
残って壊れる。base64 / quoted-printable は中身が ASCII の表現なので往復しても無事だった。

一方で **ISO-2022-JP は 7 ビットの範囲しか使わない**ため、UTF-8 として文字列化しても
コードポイントが一致し、`binary` で戻すと元のバイト列が復元できる。だから
「7bit は全部バイト列に戻す」でも ISO-2022-JP だけは動いてしまい、**片方だけ壊れた**。

## 修正
```ts
const alreadyText = encoding !== 'base64' && encoding !== 'quoted-printable';
const utf8ish = charset === 'utf-8' || charset === 'utf8' || charset === 'us-ascii';
if (alreadyText && utf8ish) return body;   // 復号済み。触らない
```

## 予防ルール
1. **「どの層で文字列になったか」を意識する。** 子プロセスの出力を文字列で受けた時点で
   復号は済んでいる。そこから先でバイト列に戻す処理は二重復号になりうる
2. 符号化の検査は**複数の組み合わせ**で行う（base64×UTF-8 / base64×ISO-2022-JP /
   quoted-printable / 7bit×UTF-8）。1 つ通っただけでは通ったことにならない
3. この欠陥は selftest の追加で見つかった。**実行するまで出ない種類**なので、
   符号化を扱うコードには必ず検査を書く
