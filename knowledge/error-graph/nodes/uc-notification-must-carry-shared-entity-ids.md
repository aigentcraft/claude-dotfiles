---
title: "UC: Approval Notifications Lacked Article IDs — Human Couldn't Map AI Reports to Discord Messages"
description: "User: 「記事29,30がどれのことなのか私には分からない。ディスコードの承認依頼時に記載して欲しい」. AIの報告・DB・ダッシュボードは記事ID（articles.id）で語るのに、Discordの承認依頼・リマインドはタイトルとURLだけでIDを載せていなかった。人間がAIの報告（『記事29・30が承認待ち』）とDiscord上のメッセージを突き合わせられない。06bの承認依頼（Bot embed+Webhook両経路）と09の放置リマインドに「記事#N」を追加。"
type: "user-correction"
tags: ["user-correction", "pullie", "notification-design", "shared-identifiers", "hitl", "approval-flow"]
---

## 1. Plan / Context
記事承認はHITLの要: 06bがDiscordへ承認依頼（タイトル・スコア・プレビューURL）を送り、
人間が返信で承認/差し戻す。AI側の報告・DB・ダッシュボード・DEV_LOGは一貫して
articles.id（記事#N）で個体を指す。

## 2. Do / The Error（ユーザー指摘 2026-09-02）
- AIがチャットで「記事29・30の公開処理を続けます」と報告した際、
  「記事29,30がどれのことなのか私には分からない。ディスコードの承認依頼時に記載して欲しい」

## 3. Check / Root Cause
1. **内部識別子（記事ID）が人間向け通知に載っていない** — 通知はタイトル+URLのみ。
   AIとDBはIDで語り、人間はタイトルで受け取る — 双方の対話に共通キーがない
2. 承認待ちが複数たまる状況（この日は4本）で初めて顕在化した — 1日1記事の平常時は
   タイトルだけで曖昧性がなかった（スケールで露呈する設計穴）

## 4. Act / Prevention Strategy (Fix)
- 06b承認依頼: embed titleを「記事の承認依頼（記事#N）」に・本文にも記事#N（Bot/Webhook両経路）
- 09放置リマインド: 各行に「記事#N」を追加
- **予防ルール**: 人間へ届く通知・依頼には、AI/DB側の**正準識別子をそのまま載せる**
  （タイトルは変わる・重複する・省略される。会話の共通キーは安定IDだけ）。
  新しい通知文面を作る時は「この通知を受けた人間がAIに問い合わせる時、何と言えば
  一意に特定できるか」を自問する
- 関連: [[uc-rewrite-approval-must-declare-itself.md]]（承認依頼の自己記述性）/
  [[uc-visualization-without-audit-purpose.md]]（人間の作業目的から可視化を設計する）
