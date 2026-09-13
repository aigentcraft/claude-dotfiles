---
title: "kintone-form-editor-rebuilt-old-selectors-gone"
type: "external-change"
tags: ["kintone", "playwright", "selector", "screenshot", "external-breakage", "pullie"]
date: "2026-09-13"
---

## 症状（未修正・現状把握のみ）

フォーム設定画面のスクショ（フィールド設定パネル）が撮れない。

```
ShotUnavailable: field_settings: FIELD の候補セレクタが1つも存在しない
  ['.fm-control-single_line_text-field-gaia',
   '[class*="fm-control-"][class*="-field-gaia"]', ...]
```

**過去に撮影が成功していたアプリでも 0 件**だったので、こちらの変更や待ち時間の問題ではない。

## 何が起きていたか

kintone がフォーム編集画面を作り直している。旧 UI の
`fm-control-*-field-gaia` 系クラスは**1つも残っていない**。
実測した新しいクラス（CSSモジュールのハッシュ付き）:

| 役割 | 新クラス（前方一致で使う） | 個数（8項目・2見出しのアプリ） |
|---|---|---|
| 行 | `_appForm-row_…` | 5 |
| 行＋見出しを含む枠 | `_appForm-field-container_…` | 10 |
| **1項目ごとの枠** | `_fieldPresenterContainer_…` | **8（＝項目数と一致）** |
| 項目ラベル | `_appForm-fieldLabel_…` | 8 |
| 歯車（設定） | `_appForm-field-menu-icon_…` | 10 |

ハッシュ接尾辞（`_1w1xp_1` 等）は kintone のデプロイで変わるため、
**完全一致で書いてはいけない**。`[class*="appForm-..."]` の前方一致で持つこと。

## まだ分かっていないこと

歯車を押しても設定パネルが開かない。歯車は**行の単位**に出ており、
1項目ごとの枠（`fieldPresenterContainer`）の中にも親にも見つからなかった。
実際の操作列（どの要素にホバーし、どれを押すと設定パネルが出るか）は未特定。

## なぜ今まで気づかなかったか

**手前の故障がこの故障を隠していた。** デモアプリの構築が
`未知の型` と `CB_VA01` で落ちていたため、撮影処理にそもそも到達していなかった
（[[writer-vocabulary-crashes-demo-app-build.md]]）。構築を直した瞬間に表に出た。

「Q05/Q09 が慢性的に落ちる」の原因を撮影カタログの作り込み不足だと診断していたが、
**少なくとも一部は外部UIの変更**だった。

## 予防ルール

- 外部SaaSの画面に依存する撮影は、**セレクタが全滅したことを型として検知**する
  （`ShotUnavailable` は既にある。これを「記事の失敗」ではなく
  「外部変更の疑い」として集計する経路がまだ無い）
- 故障が重なっているときは、**手前を直すと奥が出てくる**前提で計画する。
  1つ直して「解決」と報告しない
- ハッシュ付きクラス名は前方一致で持つ。完全一致は次のデプロイで壊れる
