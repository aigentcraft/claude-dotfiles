---
title: "kintone System-Wide Custom JS Runs in <head> (document.body is null)"
description: "kintone system-wide customize JS executes synchronously in <head> before <body> exists. MutationObserver.observe(document.body) throws, killing the whole IIFE. Wait for DOMContentLoaded."
type: "technical-error"
tags: ["kintone", "custom-js", "portal", "dom-timing", "mutation-observer"]
relationships:
  caused_by: []
  related_to: ["kintone-delivered-js-manual-commentout-corruption"]
  fixes_node: []
---

## 1. Plan / Context
kintone ポータル（トップページ）にダッシュボードを表示するため、システム管理の「JavaScript / CSSでカスタマイズ」（全体カスタマイズ）に `portal-dashboard.js` を登録した。アプリ単位のカスタマイズ（177番）では同じ描画コードが動いていた。

## 2. Do / The Error
ポータルを開いてもダッシュボードが描画されない。コンソールエラーも出ない（try-catch で握っていた）。`document.getElementById('dash-portal-root')` は常に null。

## 3. Check / Root Cause
- **アプリ単位のカスタム JS** は `<body>` 構築後に実行されるが、**システム全体カスタマイズの JS は `<head>` 内で同期実行される**。
- 実行時点で `document.body === null` のため、`new MutationObserver(...).observe(document.body, ...)` が TypeError を投げる。
- ポータルは SPA（`/k/#/portal`）なので、初回マウントを MutationObserver / hashchange に依存しており、監視が始まらない＝永久に描画されない。

## 4. Act / Prevention Strategy (Fix)

### 修正
```js
function bootPortal() {
  window.addEventListener('hashchange', function () { setTimeout(mountPortal, 300); });
  try {
    new MutationObserver(function () { mountPortal(); }).observe(document.body, { childList: true, subtree: true });
  } catch (e) {}
  mountPortal();
}
if (document.body) { bootPortal(); }
else { document.addEventListener('DOMContentLoaded', bootPortal); }
```

### 予防策
- **kintone 全体カスタマイズ JS では `document.body` / DOM 要素への即時アクセスを禁止**。必ず `document.body` の存在チェック → なければ `DOMContentLoaded` 待ち。
- アプリ単位カスタマイズからポータル用に移植する時は「実行タイミングが `<head>` に変わる」ことを移植チェックリストに入れる。
- 全アプリ画面に読み込まれるため、`location.hash.indexOf('#/portal') === 0` などのガードで対象画面以外では即 return する。
