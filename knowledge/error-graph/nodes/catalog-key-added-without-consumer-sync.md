---
id: catalog-key-added-without-consumer-sync
title: カタログ拡張時に消費側キー一覧を同期し忘れ偽UI図解が量産された
type: user-correction
severity: medium
date: 2026-08-11
project: pullie (Kintone受注目的メディア運営自動化)
cluster: agent-rule-consistency
tags: [multi-agent, skill-sync, screenshot, pipeline]
---

# カタログ拡張時に消費側（writer SKILL.md）を同期し忘れ、偽UI図解が量産された

## 症状（ユーザー指摘）
「画像の余白が無駄に大きすぎる」「ステップ3の画像はkintoneのスクショが無く、余白が大きすぎる」
— 差し戻し後の自動書き直しで、記事の操作手順にAI生成の偽UIモックアップ（fig-6〜9）が使われた。

## 根本原因
1. kintone_shot.py のカタログに新キー（app_create_dialog / form_drag_mid / form_save 等）を追加したが、
   **writer SKILL.md の「使えるキー一覧」を更新しなかった**（4キーのまま）
2. writerは知らないキーを参照できず、UI操作の説明を図解指定にフォールバック
3. designerはUI画面をイラストとして描く（=偽UI・巨大余白）。生成図に余白トリム処理も無かった

## 修正
- writer SKILL.md のキー一覧をカタログ全キーと同期 + 「UI操作の画面は図解指定禁止・必ずスクショキー」を明文化
- 不足していた実画面（歯車メニュー・通知設定・フィールド設定・アプリ更新）をカタログに追加して撮影
- 05_generate_images に決定論的な余白トリム（近白色マージン検出）を追加

## 予防ルール
**プロデューサー/コンシューマー型の定義（カタログ・enum・キー一覧）を拡張したら、
参照している全エージェントのSKILL.md/skill_refsをgrepで洗い出して同期するまでを1コミットとする。**
（同型の先行事故: 2026-08-10「出典タグ禁止ルール×C06衝突」— エージェント間ルールの片側編集は必ず反対側を突き合わせる）
