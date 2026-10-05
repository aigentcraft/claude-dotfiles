---
name: agent-input-drops-attachments-silently
title: Discord の画像を受け口で捨てていて、秘書（常駐の Claude Code）が「画像は見られません」と答えた
cluster: ai-behavior
type: "design-gap"
tags: ["ai-behavior", "agent", "input-pipeline", "discord", "multimodal", "silent-drop", "fukugyo-hootl"]
date: 2026-10-05
severity: medium
relationships:
  related_to:
    - "uc-secretary-relays-without-verifying-or-acting.md"
    - "uc-desk-agent-still-mechanical-one-shot.md"
---

## ユーザーの指摘（原文）

「ディスコードから秘書に画像送ったら見れないって言われたんだけど」

## 1. Plan / Context

副業HOOTL の常駐の Claude Code（agent/resident.ts）は、Discord の書き込みを `claude -p --input-format stream-json` の標準入力に流す。
送る中身の型（`UserContent`）は最初から画像のブロックを持てる形で、モデル自身も画像を読める。

## 2. Do / The Error

- #🗂秘書（スレッドではないチャンネル）は `message.content` だけを渡し、添付を見ていなかった。文字の無い投稿は受け手に届きもしない
- 案件のスレッドは画像を拾っていたが、全部「LINE と紐づけて」の意味に取り、常駐には文字だけを渡していた
- 秘書は画像が貼られたことすら知らず、「画像は見られません」と答えるしかなかった

## 3. Check / Root Cause

- **受け口（bot.ts）で落とした情報は、その先の誰も取り戻せない。** 型もモデルも画像に対応していたのに、入口の 1 行で消えていた
- 「画像 = LINE の紐づけ」と 1 つの用途に決め打ちしていた。後から「なんでも頼める秘書」を足した時に、入口の決め打ちを見直していなかった
- 捨てたことを誰にも知らせていなかった（ログにも、エージェントにも）

## 4. Act / Prevention Strategy (Fix)

- bot.ts で画像の URL を先に集め、秘書の机にも渡す（画像だけの投稿も受ける）
- `agent/resident-images.ts`: 小さい画像は画像のまま渡す（base64）。大きい画像・形式外・枚数超過は作業場に保存し、パスを渡して Read で開かせる。取れなかった画像は理由を本文に書き添える
- 種類と縦横は**中身から**確かめる。画像のまま渡したものは会話の記録に残り、`--resume` のたびに送り直されるため、API に断られる画像を入れるとそのスレッドが以後ずっと失敗しうる
- 案件のスレッドは「画像だけ」なら LINE の紐づけ、「文字つき」なら常駐に見せる
- 実物で確認: stream-json に画像を流すと haiku が画像の文字と色を正しく答えた。保存したファイルを Read で開く経路も、常駐と同じ権限設定で通った

### 予防ルール

1. **エージェントに入力を渡す受け口では、捨てるものを明示的に決める。** 文字以外（画像・ファイル・返信先）を黙って落とさない。落とすなら「落とした」とエージェントに書き添える
2. **入口で用途を決め打ちしたら、受け手が汎用のエージェントに変わった時に見直す。**「画像 = この用途」は、何でも頼める相手の前では誤り
3. **会話の記録に残る入力は、送る前に中身で検証する。** 一度 API に断られる物を入れると、再開のたびに失敗する
