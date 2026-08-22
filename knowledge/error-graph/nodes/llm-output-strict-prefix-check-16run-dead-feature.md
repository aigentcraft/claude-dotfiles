---
title: "publisher内部リンク挿入が初公開以来16連敗 — 厳格プレフィックス検査+恒久グレースで機能が死んだまま"
type: "technical-error"
tags: ["llm", "output-parsing", "grace-degradation", "silent-failure", "link-validation", "pullie"]
description: "haikuの出力が毎回フェンス包み+末尾概要+捏造リンク付きで「---開始」検査に全落ち。グレース（リンクなし公開）が19日間発動し続け、内部リンク機能は一度も動いていなかった。"
---

## 1. Plan / Context
pullieの07_publish: 公開直前にpublisher(haiku)が記事へ内部リンクを挿入する。出力検証は
`if not final_md.startswith("---")` の1条件のみで、失敗時は「リンクなしで公開続行」のグレース。

## 2. Do / The Error
2026-08-23の全体監査で発覚: このグレースwarnが**初公開(8/4)から16回=全公開で発動**していた。
haikuは毎回 ①コードフェンスで全文を包む ②末尾に「リンク挿入の概要」を付ける ③**実在しない
記事slugへのリンクを捏造する**（例: /articles/kintone-banso-shien-guide/）— ①で検査に落ち、
機能は一度も成功しないまま19日間「正常」に運転していた。皮肉にも棄却が③の404リンク公開を防いでいた。

## 3. Check / Root Cause
1. **LLM出力の現実（前置き・フェンス・後書き）に対して検査が厳格すぎ、修復を試みない** —
   startswith一発棄却は「惜しい出力」を全部捨てる
2. **恒久グレースの無検知**: warnはrc=0のため失敗監視に乗らず、発動率の集計も無いため
   「たまの劣化」と「機能死」を誰も区別できなかった（[[x-api-quote-restriction-silent-lane-death]]と同族）
3. 仮に検査を通っても**リンク実在検証が無く**、捏造slugがそのまま公開される設計だった

## 4. Act / Prevention Strategy (Fix)
**Fix:** `salvage_publisher_output()`（純関数・単体テスト5ケース）:
最初の`---`行から採用 → フェンス数が奇数なら最後のフェンス以降を切除 → 末尾の「リンク挿入の
概要」段落を切除 → frontmatter形状+本文量(元の90%以上)検証 → **/articles/リンクは実在slug
照合で捏造をアンカー解除** → 採用時は追加リンクをinfoログ。プロンプトにも「1文字目から---」
「一覧にないslug発明禁止」を明記。

**Prevention:**
1. **LLM出力の検査は「棄却」でなく「決定論サルベージ→検証→ダメなら棄却」の順に組む** —
   よくある崩れ方（フェンス・前置き・後書き）は機械で直せる
2. **グレース分岐には発動率の可視化をペアで**: 100%発動しているグレースは機能死。
   監査時は「warnの初出日と累計」を必ず見る（`SELECT MIN(created_at), COUNT(*)`）
3. **LLMが生成する参照（リンク・パス・ID）は必ず実在集合と照合してから公開物に載せる**
   （writerの画像パス捏造対策 sanitize_asset_refs と同じ原則の横展開）
