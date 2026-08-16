---
id: instant-approval-path-skips-sns-fanout
title: 即時承認経路が07止まりでX告知が生成されず、公開3記事分のツイートが3日間沈黙した
type: bug
severity: high
date: 2026-08-16
project: pullie (Kintone受注目的メディア運営自動化)
cluster: producer-consumer-sync
tags: [pullie, sns, pipeline-wiring, dual-path, approval-flow, x-twitter]
---

# 同じ結果に至る経路が2本あると、後段の結線は片方だけ張られて壊れる

## 症状（ユーザー指摘）
「ツイートが13日で止まってるけど」— @pullie_jp の投稿が2026-08-13 06:21を最後に停止。
記事#9/#10/#11は公開されたのに article_link 告知ツイートが1本も生成されていなかった。

## 根本原因
記事公開に至る経路が2本あり、X告知生成（08_sns_post --article-id N）の結線が片方にしかなかった:
- **経路A（日次run）**: run_pipeline 手順2「承認済み回収公開」= 07_publish → 08_sns_post ✅
- **経路B（即時承認）**: apply_approvals がDiscord返信を検知 → その場で 07_publish のみ ❌

経路Bで公開されると status が published になるため、翌朝の経路Aは「approved の記事なし」で
no-op — **08は永遠に呼ばれない**。ユーザーがDiscordで即承認するようになるほど（=運用が
理想形に近づくほど）X告知が確実に脱落する構造だった。
複合要因: 週次Tipsのキュー（3本）も8/13に尽きており、article_link脱落と合わさって完全沈黙。

## 修正（2026-08-16・実弾検証済み）
- apply_approvals.publish() の07成功後に 08_sns_post --article-id を best-effort で結線
  （08は生成済みスキップの冪等ガードあり・失敗しても公開は成立、後続runが回収）
- バックフィル: #11は2本生成→1本C08ブロック・1本即時投稿（検閲ゲート健全を同時確認）、
  #9/#10は生成のみ（--post-id 999999 で flush回避）→ バックログ1本/runの既定ペースで排出

## 予防ルール（一般化）
- **後段処理の結線は「トリガー箇所」でなく「状態遷移」に着目して張る**。published への遷移が
  2箇所から起きるなら、両方に同じ後段が要る（理想は遷移点を1関数に集約）。
- 新しい即時実行経路（イベント駆動）を追加する時は、置き換える定期実行経路の**後続ステップ
  一覧を書き出して全て移植したか照合する**。[[frontmatter-field-not-wired-into-all-renderers.md]]
  （複数レンダラーの片側更新）と同族の「二重経路の片側結線」パターン。
- 沈黙系の障害は誰も通知しない（エラーが出ないから）。「最後に投稿してからN時間」のような
  **無活動ウォッチドッグ**が監視の別レイヤーとして必要（今回は人間が気づいた）。
