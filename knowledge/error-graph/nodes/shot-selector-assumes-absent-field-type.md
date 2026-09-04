---
title: "Screenshot Selector Assumed a Field Type the App Lacked — Grace Swallow Made Every Retry Fail"
description: "pullie 05_generate_images の field_settings 撮影が、単一行テキスト固定のCSSセレクタにホバーする実装だったため、その型を1つも持たないデモアプリ（シフト表=日付/選択/ユーザー/計算/複数行のみ）で Page.hover が10秒Timeout。失敗はグレースで握り潰され `<!-- スクショ: ... -->` が本文に残り、reviewerがQ05/Q09で必ずfail。しかも差し戻し先はwriterで原因の05は直せず、3ラウンド空回りして記事破棄。2026-09-02〜04に3記事連続破棄・review.passed 40時間停止。9/2に潰した fs-demands-uncapturable-screens-deadlock の**別ドアからの再発**。"
type: "technical-error"
tags: ["producer-consumer-sync", "pullie", "selector-brittleness", "graceful-degradation", "blame-routing", "screenshot-catalog", "pipeline-stall", "playwright"]
---

## 1. Plan / Context
2026-09-01に `fs-demands-uncapturable-screens-deadlock`（FSが撮影不能画面を指定 →
Q05/Q09で構造的に合格不能 → 5記事破棄）を、カタログへの5キー追加と3者契約の同期で解決した。
撮影レーンは「カタログキー → 固定CSSセレクタ列 → Playwrightで実撮 → 失敗はコメント残置で
グレース継続」という決定論。writerは記事題材に合わせたデモアプリをフィールドDSLで指定し、
kintone_demo_app が実際にアプリを構築してから撮る。

## 2. Do / The Error（発覚 2026-09-04・人間がDiscordのops-auditor所見を持ち込んで調査指示）
- ops-auditor high: 「review.passed が 2026-09-02 14:40 を最後に約40時間停止・2日連続で新規記事ゼロ」
- 記事#31(9/2)・#32(9/3)・#33(9/4) が3日連続 rejected（破棄率32%）
- #33 のログ: `スクショ失敗（グレース継続）: field_settings: Page.hover: Timeout 10000ms exceeded.
  waiting for locator(".fm-control-single_line_text-field-gaia")` が **同一runで3回**（3ラウンド分）
- reviewer は3ラウンドとも Q05/Q09 で
  「`<!-- スクショ: field_settings | シフト表 | ... -->` がHTMLコメントのまま残存し、
  読者にはこの節のフィールド設計が一切表示されない」と fail
- 差し戻し指示の宛先は毎回 **writer**。writerは本文を書き直すだけで、撮影は直せない

## 3. Check / Root Cause
1. **セレクタが「特定のフィールド型の存在」を暗黙の前提にしていた** —
   `field_settings` は単一行テキスト固定でホバー。記事#33の「シフト表」アプリのDSLは
   日付・選択・ユーザー・計算・複数行のみで、単一行テキストが**1つも無い**。
   実測（probe）: app130 の `-field-gaia` 系は label/date/single_select/user_select/calc/
   multiple_line_text の6種。単一行テキストを持つ app133/124 では従来どおり成功していたため、
   セレクタは「壊れていない」ように見え続けた（題材依存の間欠故障）
2. **グレースが失敗を握り潰し、下流が事情を知らない** — 失敗時にマーカーを本文に残す設計。
   HTMLコメントは公開時にレンダリングされないので、reviewerから見れば「節が丸ごと欠落した記事」。
   reviewerには「05が撮影に失敗した」という情報が**一切渡っていなかった**
3. **差し戻し先が誤っていた（blame routing の不在）** — 原因工程(05)と差し戻し先(writer)がズレ、
   直せない担当が3ラウンド消費して破棄に到達する。再試行が救済でなく罰として機能する
4. 9/1の対策は「カタログにキーを足す（供給を増やす）」だったが、今回は
   **キーはあるのに、そのキーの前提条件が題材によって満たされない**。
   個別の故障モードを列挙して塞ぐ方式の限界が出た形（列挙は想定済みの故障しか捕まえない）

## 4. Act / Prevention Strategy (Fix)
実装（2026-09-04・docs/12 Phase 0。**旧実装は削除でなく降格・保存**）:
- **候補セレクタ機構 `pick`**: カタログが `{"FIELD": [候補1, 候補2, ...]}` を持つと、
  セレクタ中の `{FIELD}` を「実在する最初の候補」に置換。旧セレクタは**候補の先頭に保存**
  （説明に最も向くため優先度は変えない）→ 無ければ実測済みの総称セレクタ
  `[class*="fm-control-"][class*="-field-gaia"]:not(.fm-control-label-field-gaia)` に落ちる。
  候補が1つも無ければ `ShotUnavailable`（構造的に撮影不能）を送出し、一時的失敗と区別する
- **`grace_events` テーブル新設**: 握り潰していた失敗を構造化して記録。
  `structural` フラグ / 失敗理由 / **本文から除去した原文（復元用）** / 代替表現を保存
- **reviewerへの申し送り**: 06_review が直近24hの grace_events をプロンプトに注入し、
  「素材欠落は05側の事象でwriterへ差し戻しても直らない」「structural な項目はテキスト代替で
  手順が再現できていればQ05/Q09合格」と明記
- **プレースホルダー掃除 `sweep_placeholders`**: 05の最後に、残ったマーカーを読者に意味のある
  テキストへ落とす（スクショDSL→Markdownのフィールド表 / 図解→削除）。原文は grace_events へ退避。
  安全弁 `PLACEHOLDER_SWEEP=0` で旧挙動へ即復帰
- 検証: 今朝3回失敗した `field_settings`×app130 の実撮影が成功（85秒・歯車メニュー展開を目視）。
  記事#33実ドラフトの掃除で残存HTMLコメント0件・フィールド表9行を生成

**予防ルール（横展開可能な一般形）**
1. **UI操作のセレクタは「その要素が常に存在する」ことを暗黙の前提にしない。**
   題材・データによって構成が変わる画面では、必ず候補列 + 総称セレクタ + 明示的な
   「構造的に不能」シグナルの3段で書く（推測登録禁止＝候補はプローブで実測してから追加）
2. **グレース（縮退継続）は「失敗を無かったことにする」ことではない。**
   縮退したら ①構造化して記録し ②下流のゲートへ申し送り ③本文/成果物には
   読者に意味のある代替を必ず残す。黙って穴を空けると、下流が別の担当を罰する
3. **再試行ループを作るときは「その担当が直せるのか」を必ず検査する。**
   原因工程と差し戻し先がズレたループは、救済ではなく破棄への近道になる
4. 同じ死に方が別の入口から再発したら、入口（セレクタ・キー）を塞ぐ前に
   **経路（グレース→沈黙→誤ルーティング）を塞ぐ**

## 5. Related
- [[nodes/fs-demands-uncapturable-screens-deadlock.md]] — 同じ死に方の前回（供給不足が原因）。
  今回は供給はあるが前提条件が題材依存で満たされないパターン
- [[nodes/frontmatter-field-not-wired-into-all-renderers.md]] — 片側更新事故の系列
- docs/12_ai-org-transition-plan.md — 本件を契機とした「決定論→エージェント」移行計画
