---
title: "kintone計算フィールドにTODAY/NOW関数は存在しない（GAIA_IL01でアプリ構築ごと失敗）"
type: "technical-error"
tags: ["kintone", "api", "calc-field", "GAIA_IL01", "pullie"]
description: "writerがデモアプリDSLに「経過日数(計算:TODAY-受注日)」を指定→フィールド追加APIがGAIA_IL01で400→アプリ構築失敗→その記事のkintoneスクショが全滅した。"
---

## 1. Plan / Context
pullieの記事用デモアプリ自動構築（kintone_demo_app）は、writerが書いたフィールドDSLの
`計算:式` をそのまま kintone の CALC フィールド expression に渡していた。

## 2. Do / The Error
記事#18（顧客管理）でwriterが「経過日数(計算:TODAY-受注日)」を指定。
`POST /k/v1/preview/app/form/fields.json` が
`400 GAIA_IL01: フィールド「経過日数」の計算式が正しくありません。(TODAY関数は使用できません。)`
→ アプリ構築が失敗し、そのアプリを使う record_list / record_form 等のスクショが全滅
（グレース継続で記事は公開されたが、1枚は未処理マーカーのまま残った）。

## 3. Check / Root Cause
kintoneの計算フィールドには **TODAY / NOW / FROM_TODAY 等の「現在時刻」系関数が存在しない**
（使えるのはフィールド参照の四則・SUM・IF・ROUND・DATE_FORMAT等。「今日からの経過日数」は
標準機能では計算不可でJSカスタマイズ領域）。LLMはスプレッドシート感覚でTODAY()を書きがちで、
構築側に式のバリデーションが無かったため1フィールドの非対応がアプリ全体を道連れにした。

## 4. Act / Prevention Strategy (Fix)
**Fix:** `_parse_field()` で式に TODAY/NOW/FROM_TODAY/DATE_ADD を検知したら **CALCでなく
NUMBER（桁区切り）へ機械降格**（ラベル維持・サンプル値はLLM生成側が埋める — 1式のために
撮影レーンを死なせない）。writer SKILLにも「計算式にTODAY系は書けない・使える式は四則+
SUM/IF/ROUND程度」を明記。

**Prevention:**
1. LLMが書いた式・クエリ・設定値を外部APIへ渡す境界では、**非対応が既知のパターンを
   機械検知して「失敗」でなく「降格」に倒す**（全体を道連れにしない部分縮退）
2. kintoneの計算式パワーはスプレッドシートより大幅に狭い前提で設計する（TODAY不可が代表例）
