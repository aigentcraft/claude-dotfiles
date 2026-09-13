# Cluster: kintone

kintone カスタマイズ（REST API・カスタム JS/CSS・全体カスタマイズ）で踏んだ落とし穴のサマリー。

## Member Nodes
- [[../nodes/kintone-calc-no-today-function.md]] — 計算フィールドに TODAY() 系関数は存在しない（GAIA_IL01）
- [[../nodes/kintone-system-js-head-execution-body-null.md]] — 全体カスタマイズ JS は `<head>` で実行され `document.body` が null
- [[../nodes/kintone-delivered-js-manual-commentout-corruption.md]] — 配信 JS がクライアントの手動コメントアウトで構文破壊
- [[../nodes/kintone-dropdown-query-nonexistent-option-error.md]] — ドロップダウンへの in クエリは選択肢に無い値でエラー（空結果ではない）
- [[../nodes/kintone-form-editor-rebuilt-old-selectors-gone.md]] — フォーム編集画面が作り直され `fm-control-*-field-gaia` が全滅。新クラスはハッシュ付きなので前方一致で持つ
- [[../nodes/writer-vocabulary-crashes-demo-app-build.md]] — 記号入りの項目名はフィールド**コード**が400。ラベルと識別子を分ける
- [[../nodes/element-present-is-not-handler-bound.md]] — プラグイン設定画面は要素が出てから config.js が走る。要素待ちでクリックすると保存が静かに効かない
- [[../nodes/matched-sample-does-not-validate-unmatched-population.md]] — 6ヶ月の完全一致は「入金済みレコード」しか検証していなかった。延滞が17〜67%漏れた

## 蒸留ルール（kintone 作業時に適用）

1. **全体カスタマイズ JS は `<head>` 実行**: DOM アクセスは `document.body` 存在チェック → なければ `DOMContentLoaded` 待ち。全画面に読み込まれるので対象画面ガード（`location.hash` 判定）を必ず入れる。
2. **配信版を信用しない**: カスタム JS が動かない時は、まず配信 URL から実ファイルを fetch して `new Function(t)` で構文検証する。行列特定は blob URL + `window.onerror`。管理者は誰でもファイルを差し替えられる（配信版 ≠ 自分の最終アップロード版）。
3. **アップロード保存後の出口条件**: 配信版を再取得して構文検証してから完了報告する。
4. **無効化はコメントアウトではなく適用範囲設定**（すべてのユーザー / 管理者だけ / 適用しない）。クライアントにもこの運用を共有する。
5. **計算フィールドの関数は公式リストのみ**: TODAY() 等の存在しない関数はデプロイ時 GAIA_IL01 で落ちる。日付演算は JS カスタマイズ側で行う。
6. **選択肢フィールドへの `in` クエリに動的値を入れない**: 選択肢に無い値が1つでもあると空結果ではなくエラー。小規模アプリは全件取得＋クライアントフィルタが最も堅牢。日付から導出した値を使う機能は「データ登録開始より前の期間」を必ずテストする。
