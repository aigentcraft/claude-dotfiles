---
title: "uc-x-posts-must-deliver-official-facts-with-media"
type: "uc"
tags: ["uc", "sns", "x-twitter", "content-quality", "media", "weevee", "breaking-lane"]
date: "2026-09-02"
---

## 症状（Symptom）

Fable 5.1 の速報ツイート 3 本（スレッド・数字1枚・考察）が、いずれも「weevee で注視中」「整理した」で締まる薄い投稿だった。
ユーザー: **「注視中なんてツイートだれの利益にもならんな。公式リソースを確認して分かりやすくまとめないと。画像や動画付きでね。」**

## 根本原因（Root Cause）

- sns-manager の契約が「140 字・URL なし・weevee を含める・断定しない」など **禁止側** に寄っていて、「読者が持ち帰る具体（公式の数字・手順・判断軸）を必ず 1 つ渡す」という **価値側の契約** が弱かった。断定を避けた結果が「注視中」
- 速報作戦（03b）が公式一次ソース（docs / 料金ページ）を sns-manager に渡していなかった（渡していたのはファクトシート抜粋のみ・URL なし）
- 投稿にメディア（図・動画）を付ける経路が無かった。記事側には情報図（GPT Image・日本語文字・読み戻し照合）の仕組みがあるのに X 側に流用していなかった。テキストだけの速報は TL で止まらない
- 機械ゲートは C 系（違法・伏せ字）しか見ておらず、「中身が無い」投稿を止めなかった

## 修正（Fix）

1. **価値契約**（sns-manager SKILL / x-strategist 速報作戦）: すべての投稿は「公式リソースから確認した事実（数字・仕様・手順）を分かりやすく」+「読者の判断軸」で締める。「注視中 / 近日公開 / 整理していきます / 確認していきます / 続報」で締める投稿は禁止
2. **機械ゲート**: `sns_gate.filler_hits` — 上記の締め語を含む単独投稿は不合格（C 系と同じ層 1）
3. **メディア添付**: 03b で strategist が投稿ごとに `image_brief`（見出し + 行）を出し、記事の情報図と同じ経路（GPT Image・日本語・読み戻し照合）で PNG を生成 → `sns_posts.media_path` → `x_media.upload_media` で添付。記事連動投稿（article_link / after_article）は記事の hero を添付
4. 公式一次ソース（factsheets.sources の URL）を sns-manager のプロンプトに渡す

## 予防ルール（Prevention）

1. **投稿の合格条件は「禁止語がない」ではなく「持ち帰りが 1 つある」**。締めの一文が読者の行動・判断に繋がらない投稿は出さない
2. 新しい発信経路を作るときは、メディア（図・動画）の添付経路を最初から含める（テキストのみは暫定でも出さない）
3. 関連: [[uc-breaking-lane-tweet-format-is-strategist-judgment]] [[feedback-images-must-explain]]
