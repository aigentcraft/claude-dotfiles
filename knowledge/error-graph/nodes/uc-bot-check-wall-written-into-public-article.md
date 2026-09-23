---
title: "uc-bot-check-wall-written-into-public-article"
type: "user-correction"
tags: ["user-correction", "editorial", "internal-leak", "automation-exposure", "compliance", "weevee"]
date: "2026-09-23"
---

## 1. Plan / Context
2026-08-29 に「運営側の事情を公開面に書かない」を受け、06 に MC05（内部語の決定論検出）を置いた。
語の一覧（ラボ・許可コマンド・予算・自動操作スクリプト等）に当たれば C 系不合格。

## 2. Do / The Error（ユーザー指摘 2026-09-23）
- 「Bot確認画面で止まったなんて書いたら自動化して書いてるのもろばれじゃん。なにこれ。」
- 同じ日の指摘「（「Load more」ボタンの先は未確認）となってしまったのはなんで？」も同じ型
- 実物（記事 32・公開済み）: 「Gammaについては公式の料金ページがボット確認画面で止まり…」
  「Gammaの無料プランの詳細な条件（公式ページがボット確認画面で止まり到達できず）」
  「掲載企業の正確な総数（「Load more」ボタンの先は未確認）」

## 3. Check / Root Cause
1. **MC05 は語の列挙だった** — 「ボット確認」「到達できず」「〜の先は未確認」は一覧に無く素通り。
   8/29 の修正は「その日に見つかった語」を足して閉じていた（列挙で閉じる型の再発）
2. researcher の factsheet「未確認事項」は内部報告（なぜ確かめられなかったか）で、writer はそれを
   「確認できなかったこと」として**そのまま公開面に写した**。検閲は「未確認と正直に書いている」と褒めた
3. Load more は researcher が「閲覧のみ」を「操作禁止」と読み違え、1 クリックで確かめられることを手放した

## 4. Act / Prevention Strategy (Fix)
- 原則を 1 つにする: **公開面に「どう調べたか・何で止まったか」（道具・アクセス・画面・操作の失敗）を書かない。**
  未確認は読者の側の事実（「公式は総数を公開していない」「料金は公式ページで確認を」）に言い換えるか、書かない
- writer / reviewer に同じ文面で渡す（材料と判断を返す）+ MC05 に「調べる手段の失敗」の語群を足す（人間決定⑨の公開面 grep）
- **予防ルール: 内部報告の「未確認」を公開面に写す工程を作らない。正直さは「読者が何を信じてよいか」で示す**
- 関連: [[uc-articles-contain-operator-facing-justifications]] [[uc-internal-handoff-note-live-on-published-page]]
