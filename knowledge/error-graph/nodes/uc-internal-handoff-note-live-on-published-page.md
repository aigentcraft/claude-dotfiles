---
title: "uc-internal-handoff-note-live-on-published-page"
type: "uc"
tags: ["uc", "public-tone", "internal-leak", "publish-gate", "weevee", "writer"]
date: "2026-09-02"
---

## 症状（Symptom）

公開中の記事 https://weevee.net/ja/blog/claude-code-vps-remote-control-docker-lab/ の末尾（「セキュリティ面で気をつけること」節の最後）に
「editor-in-chief への申し送り:」という **内向きの段落** が載っていた。

ユーザー: **「一番最後に editor-in-chief への申し送り:とかいう内向きの情報が入っている。あり得ない。」**

## 根本原因（Root Cause）

- writer は「編集長への申し送り」を本文末尾に書く癖がある（既知 — 2026-08-29 に `_lib.strip_internal_notes` を 04/05/07 に入れた:
  [[writer-internal-handoff-notes-leak]]）。**しかしその修正は「これから生成・公開する原稿」にしか効かず、
  8/28 に公開済みだった記事（live の `site/src/content/blog/*.md`）は掃除されないまま残っていた**
- 公開面の機械検査（06 の MC05 内部語）も 8/29 以降の検閲にしか走らない。**「既に公開されているページ」を走査する検査が存在しなかった**
- 記事は後にリライトレーンで status=review に戻っていたが、live のページは旧版のまま（承認待ちの新版は未公開）— DB の状態と公開面の状態がずれる期間に、誰も公開面を見ていない

## 修正（Fix）

1. live コンテンツ全件を機械 grep（`申し送り` / `editor-in-chief` / `内部メモ` 等の内部語 + AI 伏せ語）→ 該当行を除去して main へ push（即時デプロイ）
2. **公開面ゲート**を 07_publish の最終段に追加: 公開直前の markdown（内部リンク LLM の出力後）に `machine_compliance_checks`（MC01-06）と
   `strip_internal_notes` を再適用し、C 系不合格なら公開を中止する（敵対的レビューの HIGH「07 の LLM 書き換え後に再検査が無い」と同根）
3. **公開済みページの定期監査**: 01_collect_signals（日次）で `site/src/content/blog/**` を内部語・AI 伏せ語で grep し、ヒットしたら ops 🚨 + 自動除去 PR（機械的に行を落とすだけ）

## 予防ルール（Prevention）

1. **生成側の修正は「既に出ているもの」を直さない**。検閲・伏せ字・除去のルールを足したら、必ず live 全件に遡及適用する（grep 1 本で済む）
2. 公開面の状態は DB の status ではなく **実際の公開ファイル** で検査する。公開ゲートは公開直前の最終テキストに掛ける
3. LLM が触った後のテキストは、人間が見ない経路では必ず機械で再検査する（[[uc-breaking-lane-tweet-format-is-strategist-judgment]] と同じ「機械が持つのはゲート」原則）
4. 関連: [[writer-internal-handoff-notes-leak]] [[uc-public-tone-no-operator-report]]
