---
title: "kintone Dropdown in-Query with Non-Existent Option Throws Error (Not Empty Result)"
description: "kintone records query `年 in (\"2023\")` on a DROP_DOWN field errors with 「フィールド「年」の項目に「2023」は存在しません」 when the value is not among the field's options — it does NOT return an empty result. Dynamic date-derived query values eventually step outside the option list."
type: "technical-error"
tags: ["kintone", "rest-api", "query", "dropdown", "dynamic-range", "error-handling"]
relationships:
  caused_by: []
  related_to: ["kintone-calc-no-today-function", "kintone-system-js-head-execution-body-null"]
  fixes_node: []
---

## 1. Plan / Context
賃貸営業部ダッシュボード（app 177 / ポータル版）。月切替で過去月を選ぶと、前期（前年同期）の目標を目標マスタ（app 26/143）から `(年 in ("2023") and 月 in ("07",...))` のクエリで取得していた。「年」「月」はドロップダウンフィールドで、選択肢は目標運用開始の2024年以降しか登録されていない。

## 2. Do / The Error
2025年4月を選択すると:
```
⚠ データの取得に失敗しました: フィールド「年」の項目に「2023」は存在しません。
```
前期範囲(2023-07〜2024-04)の「2023」が選択肢に無く、**クエリが空結果ではなくエラーになる**。Promise.all 全体が reject し、目標だけでなく実績表示まで全滅した。

## 3. Check / Root Cause
- kintone の records クエリは、**選択肢系フィールド（DROP_DOWN/RADIO/CHECK_BOX等）への `in` 条件に選択肢として存在しない値が1つでもあると GAIA エラーを返す**。SQL のように「マッチ0件」とはならない。
- 基準日から動的に導出した値（年・月・前年・前期）をクエリに埋め込む設計は、いつか必ず選択肢リストの範囲外に出る。リリース時点で動いていても、過去月表示・年数経過で顕在化する時限バグになる。
- 開発時の検証が「今月・前月」など選択肢内の日付に偏っていて、選択肢範囲外に出るケース（データ登録開始より前の期間）をテストしていなかった。

## 4. Act / Prevention Strategy (Fix)

### 修正
目標マスタはレコード数が少ない（〜130件）ため、クエリでの絞り込みをやめ**全件取得→クライアント側で年月フィルタ**に変更:
```js
// Before: fetchAll(goalApp, '(年 in ("2023") and 月 in (...))', FIELDS)  ← 選択肢外の年でエラー
// After:
fetchAll(goalApp, '', FIELDS)            // '' + ' order by $id asc limit 500 offset N' は有効なクエリ
  .then(all => all.filter(r => inYm(r, yms)))  // 既存のクライアント側フィルタを流用
```

### 予防策
1. **選択肢系フィールドへの `in` クエリに動的生成値を入れない**。入れるなら (a) 事前に `/k/v1/app/form/fields` で選択肢を取得して積集合を取る、(b) クエリを try-catch して空扱いにする、(c) 小規模アプリなら全件取得＋クライアントフィルタ（最も単純・堅牢）。
2. 日付・期間から導出した値をクエリに使う機能は、**データ登録開始より前の期間を必ずテストケースに含める**（月切替UIがあるなら選べる最古の月で1回試す）。
3. 年・月をドロップダウンで持つマスタ設計自体が毎年の選択肢追加保守を要する。新規設計では数値フィールドか日付フィールドを推奨。
