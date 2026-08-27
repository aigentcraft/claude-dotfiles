---
title: "Reviewer Kept Sending an Article Back on a Screenshot Item the Writer Could Not Fix"
description: "weevee article 1 (n8n how-to) reached score 80 with every fact/compliance check green, but the reviewer chose send_back on Q06 alone: 'operation steps lack real screenshots' — the factsheet explicitly says screenshots were never captured (lab predates Playwright), and the writer had copied the factsheet's 'スクショ: xxx.png' mentions as HTML placeholder comments. Each round burned one of the 3 allowed rewrites toward automatic rejection. Fix: Q06 is a deduction, not a send_back reason, when the factsheet marks screenshots as unavailable; 04 strips placeholder screenshot comments; writer is told not to emit them."
type: "bug"
tags: ["reviewer", "send-back-loop", "structural-constraint", "screenshots", "checklist", "weevee"]
---

## 1. Plan / Context
検閲は F/C 系（合否）と Q 系（点数）。Q 系は reviewer が `must_fix` に入れれば send_back になる。手順記事には実測スクショを求める Q06 がある。

## 2. Do / The Error（2026-08-28 記事 1・第 3 ラウンド）
- score 80、F/C 全合格、初心者適合 Q13=7。不合格は Q06 のみ（`<!-- スクショ: docker_compose_yaml.png -->` 等のプレースホルダが画像化されていない）→ reviewer 判定で send_back
- ファクトシートは「スクショ: 未取得（Playwright 未導入）」と明記。writer には解消手段がなく、次ラウンドも同じ結果になる構造。3 回で自動破棄の寸前だった

## 3. Check / Root Cause
1. **解消不能な指摘を差し戻し理由に使えた** — チェックリストが「その項目が writer の裁量内か」を区別していなかった（Q09/Q11 には適用条件があるのに Q06 には無かった）
2. writer がファクトシートの「スクショ: xxx.png」表記を HTML コメントとして本文に写し、reviewer に「埋め込み忘れ」に見えた
3. 差し戻しループには「同じ理由で 2 回目」を検知する仕組みがない

## 4. Act / Prevention Strategy (Fix)
- checklist Q06 に適用条件を追記: ファクトシートにスクショ未取得とある場合は減点（情報図で代替なら 5〜6 点）に留め、**Q06 単独を must_fix / send_back の理由にしない**
- 04 が `<!-- スクショ: -->` プレースホルダを機械除去し、writer の出力形式指示にも「置かない」を明記
- **予防ルール: 差し戻し理由は「次のラウンドで解消可能なもの」に限る。構造的制約（ラボ未取得・案件未アサイン・公開記事なし）は各項目に適用条件として書き、減点に留める**
- 関連: [[uc-articles-too-advanced-for-beginner-readers]] [[writer-output-truncated-by-code-fence-misparse]]
