---
title: "status-says-ready-but-the-page-was-never-served"
type: "system-design"
tags: ["observability", "human-in-the-loop", "notification", "build-flakiness", "astro", "pullie"]
date: "2026-09-20"
---

## 症状

人間からの報告 — 「記事の承認待ちがメッセに来てるけど**リンク先が404**」。

DBを見ると記事は `status='review'`（承認待ち）で正常。スコアも 82 点で合格。
画像も 5 枚すべて生成済み。なのにプレビューのURLは 404 を返す。

## 何が起きていたか

承認用プレビューを配信する工程が、その日の 03:41 に**一度だけ**落ちていた:

```
RuntimeError: npm run build failed
    at async reloadContentConfigObserver (astro/dist/content/utils.js:498)
    at async runEvents               (astro/dist/content/types-generator.js:249)
```

この工程は下書きを content 配下へ一時コピー → ビルド → コピーを消す、という形で動く。
Astro のコンテンツ型生成がそのファイルイベントを拾って落ちる競合とみられる
（同じコマンドを手で流すと通る＝一過性）。

決定的なのは、そのあと**誰も作り直さなかった**こと:

1. 配信工程が落ちる → 記事は `review` のまま
2. 日次オーケストレータは「review になったら配信する」を**そのrunの中でしか**やらない。
   翌日は新しい記事に取りかかるので、落ちた記事は永久に配信されない
3. 督促は「review ならページがある」**前提でURLを組み立てていた**
   → 人間には**踏めないリンクだけ**が毎日届く

つまり、**状態（review）と事実（配信されている）を同一視していた**。

## 根本原因

- 一過性の失敗に再試行が無い（1回落ちたらそれっきり）
- **落ちたあとの回復経路が無い**。前に進む道だけがあり、戻って直す道が無かった
- 通知が「DBの状態」から文面を組んでいた。外の世界を見ていない

## 修正（2026-09-20）

1. ビルドを共通モジュールへ集約し、**1回だけ再試行**する。
   再試行したことは grace に残す（握りつぶしと区別する）
2. 日次runに「**承認待ちなのにページが出ていない記事を作り直す**」手当てを新設。
   判定は状態ではなく **実際に200が返るか**（1runで最大2本・Pagesのビルド待ちがあるため）
3. 督促は**送る前にURLの生存を確かめる**。出ていなければリンクを出さず、その事実を書く

## 予防ルール

- **状態は事実ではない。** 「公開した」「配信した」を意味する状態を根拠に外向きの
  文面を作るときは、**その瞬間に外から確かめる**
- 前に進むだけのパイプラインには、**落ちたものを拾い直す掃除係**を必ず1つ置く。
  「次のrunが気づく」は、次のrunが別の仕事を始めるなら成立しない
- 一過性で落ちる外部ツールには再試行を入れてよい。ただし**回数と最初のエラーを必ず残す**

## 関連

- [[reminder-covers-only-the-entity-it-was-written-for]] — 督促が対象を取りこぼす形
- [[published-but-never-announced-because-url-stayed-in-stdout]] — 成果が次工程に届かない形
- [[uc-mechanical-notifications-lack-situation]] — 通知が状況を伝えない形
