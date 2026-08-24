---
title: "kintone Delivered Custom JS Broken by Manual Comment-Out (Client-Side Edit)"
description: "A kintone custom JS file stopped parsing because someone wrapped the code in /* */ to 'disable' it, colliding with the file's own header comment. Diagnose with new Function() + blob-URL/window.onerror; never trust the delivered file to match your local source."
type: "technical-error"
tags: ["kintone", "custom-js", "syntax-error", "diagnosis", "client-edit", "block-comment"]
relationships:
  caused_by: []
  related_to: ["kintone-system-js-head-execution-body-null"]
  fixes_node: []
---

## 1. Plan / Context
kintone 全体カスタマイズの `portal-dashboard.js`（ローカルでは `node --check` パス済み）が本番で一切動かなくなった。ローカルのソースは健全なのに、配信版だけ壊れている状態。

## 2. Do / The Error
- 配信 JS を fetch して `new Function(t)` にかけると `Unexpected token '}'`。
- 原因箇所が分からない（`new Function` は行番号を返さない）。

## 3. Check / Root Cause
- **診断法1**: `new Function(t)` はパース可否の判定のみ。行列特定には **blob URL + `window.onerror`** を使う:
  ```js
  const u = URL.createObjectURL(new Blob([t], {type:'text/javascript'}));
  window.onerror = (msg, src, line, col) => { window.__err = {msg, line, col}; return true; };
  const s = document.createElement('script'); s.src = u; document.head.appendChild(s);
  ```
- **診断法2**: 行ごとの `/*` と `*/` の数の不均衡をスキャンすると、コメント構造の破壊が一目で分かる。
- **根本原因**: 配信ファイルはヘッダコメント(`/* ... */`)の直後に**単独行の `/*`**、ファイル末尾に**単独行の `*/`** が挿入されていた。誰か（クライアント管理者）が「ファイル全体をコメントアウトして無効化」しようとしたが、コード本体は生きたまま末尾に浮いた `*/` だけが構文エラーを起こす等、ヘッダコメントと干渉して全体が壊れた。
- 教訓: **配信版 ≠ ローカル版**。kintone のカスタマイズファイルは管理者なら誰でも差し替え・編集できるため、「自分が最後にアップロードした内容」だという前提は成立しない。

## 4. Act / Prevention Strategy (Fix)

### 修正
- 挿入されていた `/*` 行と末尾 `*/` を除去したクリーン版を再アップロード。
- 無効化はコメントアウトではなく **適用範囲の設定**（「システム管理者だけに適用」/「適用しない」）で行う。これが kintone の正式な無効化手段。

### 予防策
1. **配信ファイルが動かない時は、まず配信版そのものを fetch して構文検証する**（ローカルが正しくても意味がない）。
2. アップロード保存後は必ず配信版を再取得し `new Function(t)` で検証する（出口条件）。
3. クライアントに「表示を止めたい時はファイルを編集せず、適用範囲設定で切り替えるか連絡してほしい」と運用ルールを共有する。
4. アップロードするファイルではコード行内のインライン `/* */` ブロックコメントを避け `//` を使う（第三者の全体コメントアウトと干渉しにくくなる）。
