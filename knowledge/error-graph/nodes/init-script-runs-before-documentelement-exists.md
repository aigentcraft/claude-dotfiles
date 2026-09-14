---
name: init-script-runs-before-documentelement-exists
title: 初期化スクリプトは空の document で走る — その場で observe() すると監視が一度も付かない
cluster: observability
type: "defect"
tags: ["playwright", "addInitScript", "mutationobserver", "dom", "silent-skip", "weevee"]
date: 2026-09-14
severity: medium
---

## 症状
ページに常時かける CSS マスクを、消されても入れ直すよう `MutationObserver` で見張る実装にした。
マスク自体は入る。しかし**消すと入り直さない**（実測: 消して 1.5 秒後もマスク無し）。

## 根本原因
`BrowserContext.addInitScript` は**ページのどのスクリプトよりも前**に走る。その時点では
`document.documentElement` がまだ `null` のことがある。

```js
try {
  new MutationObserver(ensure).observe(document.documentElement, {...});
} catch { /* 後で入る、と思っていた */ }
```

`observe(null)` は例外を投げ、`catch` が握りつぶす。**以後ずっと監視なし**。
`DOMContentLoaded` で CSS を入れる経路は別にあったので、マスクは入る = 一見動いて見えた。

## 修正
監視の登録を「documentElement が生えてから」に遅らせ、登録できたかを状態で持つ。

```js
let armed = false;
const arm = () => { if (armed || !document.documentElement) return;
                    new MutationObserver(ensure).observe(document.documentElement, {...}); armed = true; };
const tick = () => { ensure(); arm(); };
tick();
document.addEventListener('readystatechange', tick);
document.addEventListener('DOMContentLoaded', tick);
if (!armed) { const iv = setInterval(() => { tick(); if (armed) clearInterval(iv); }, 100);
              setTimeout(() => clearInterval(iv), 30000); }
```

## 予防ルール
- `addInitScript` の中で DOM を前提にしない。**DOM が要るものは「生えてから」に遅らせ、
  遅らせたものは登録できたかを状態で持つ**
- `catch {}` で握りつぶした先に「以後ずっと無効」があるなら、それは握りつぶしてはいけない
- 自己修復を名乗る仕組みは、**壊してみて直ることを実測する**まで名乗らない

## 関連
- [[guard-and-its-check-must-not-share-the-same-handle]] — 同じ仕事で見つけた、検査側の同型
