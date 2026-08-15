---
id: utc-timestamps-render-as-last-night
title: UTC保存タイムスタンプの素通し表示で「朝5時のrun」が「昨晩」に見えた
type: technical-error
severity: medium
date: 2026-08-15
project: pullie (Kintone受注目的メディア運営自動化)
cluster: sqlite
tags: [sqlite, timezone, utc, dashboard, jst, pullie]
---

# SQLiteのUTCタイムスタンプを素通し表示し、朝5時runのダッシュボードが「昨晩のまま」に見えた

## 症状（ユーザー報告 2026-08-15）
「ダッシュボードが、5時に始動して更新されているはずなのに昨晩の状態のままになっている」
— 実際には5時runは正常完走し、docs/dashboard.html も 06:07 に再生成**されていた**。

## 根本原因
1. SQLiteの `DEFAULT CURRENT_TIMESTAMP` は **UTC**。gen_dashboard は created_at を
   無変換で表示・日付グルーピング（`t.slice(0,10)`）していたため、
   05:00〜06:07 JST のrunの活動が全部「**2026-08-14 の 20:00〜21:07**」＝昨晩として
   表示された。データは今朝の分まで入っているのに、見た目が完全に「昨晩のまま」。
2. run_pipeline 側には同じ轍の教訓が**既にあった**
   （1記事/日ガード: 「created_at はUTC保存。JSTの『今日』で比較しないと別日扱いになる」
   というコメント付きコード）。可視化側に横展開されていなかった
   （Quick Rule 9「パターン実装後の横展開チェック」の不履行事例）。
3. 副因: 再生成がrun末尾のみ（始動〜完了の約1時間は本当に前日状態）+
   生成時刻の表示が小さく、見る側が「古い」と「古く見える」を判別できなかった。

## 修正
- `to_jst()` を表示層の入り口に一元適用（calls / artifacts / orphans / execution_logs
  すべて変換してから埋め込み。日付グルーピング・「今日」判定も自動的にJST化）
- ヘッダーに「生成 YYYY-MM-DD HH:MM JST（◯分前）」チップ+20時間超で更新停止警告
- run_pipeline の**各ステップ後**に再生成（05:00始動直後から画面に反映）
- Playwright実測: 朝runの試行が「2026-08-15（今日）05:17〜」として表示されることを確認

## 予防ルール
1. **DBのタイムスタンプはUTCが既定と仮定し、表示・日付グルーピング・「今日」判定の
   直前で必ずタイムゾーン変換を一元適用する**（表示箇所ごとに個別変換しない —
   1箇所でも素通しが残ると「その画面だけ9時間ズレる」）。画面には基準TZを明記する。
2. **TZ起因のバグを1箇所で直したら、同じDBを読む他の消費側（可視化・通知・ガード）を
   grepで横展開する**。run_pipelineのJST比較コメントが既にあった＝検索可能だった。
3. 鮮度は可視化物に自己申告させる（生成時刻・経過・更新契機）。
   関連: [[uc-visualization-without-audit-purpose.md]] 続報2 /
   同型の横展開漏れ: [[frontmatter-field-not-wired-into-all-renderers.md]]
