---
name: image-postprocess-crop-cuts-text-in-screenshots
title: 後処理の「トリム+中央クロップ」が文字を切る — 種別リストで直し漏れる
cluster: rendering-quality
type: "bug"
tags: ["rendering-quality", "image-postprocess", "screenshot", "crop", "publishing"]
date: 2026-09-07
severity: high
---

## 症状
公式ドキュメントのスクショ図で行頭の文字が左端で欠ける（「Claude」→「aude」）。
サイト上の screenshot-edit 画像 **21/21 枚すべて**が端に接触していた。公開済みを含む。

## 根本原因
後処理 `imgproc.finalize(trim=True, fit="crop")` の組み合わせ。
1. GPT Image は 1536×1024（3:2）で返す。docs のスクショは上下に白帯を持つ
2. `trim_border` が白帯を落とす → 横長になる
3. 3:2 に戻す `center_crop_aspect` が不足分を**左右から**削る = 行頭・行末の文字が消える

再現実測: 1536×1024 → 横 960px（左右 18.8% ずつ喪失）。

## 本当の原因（メタ）
2026-08-28 に同じ欠陥を hero と infographic で修正済みだった。しかし修正の適用条件を
**種別の列挙**（`kind in ("diagram","hero")` / `is_gpt_info`）で書いたため、
同じ性質を持つ screenshot-edit が漏れた。**「文字が入っている画像は切らない」という
性質ではなく、種別名で条件を書いたことが取りこぼしを生んだ。**

## 修正
- screenshot-edit も `trim=False, fit="pad"`（足りない分は紙色で足す・1 字も落とさない）
- 端接触ゲート（EDGE_MIN_MARGIN）の適用対象に追加
- `max_border_for` はスクショも情報図と同じ 32%（8% だと「切らない正しい図」が落ちる）
- 05 の `reusable()` に端接触チェック → 切れた画像は再利用されず通常走行で自然に治る
- 再生成キューが画素を実測して対象を自動検出（engine ラベルでは捕まらない欠陥）

## 予防ルール
1. **画像処理の条件は「種別名」ではなく「性質」で書く**（文字が入るか / 全面塗りか）。
   種別を増やすたびに直し漏れる。
2. 同種の欠陥を直したら、**同じ性質を持つ他の経路を全部数えてから**閉じる。
   「hero を直した」で終わらせず「文字入り画像は全部で何経路あるか」を数える。
3. ラベル（manifest の engine）ではなく**成果物の画素**を検査する。ラベルは嘘をつく。

## 関連
[[codex-image-tool-prompt-contract-multiline-and-attach-order]]
