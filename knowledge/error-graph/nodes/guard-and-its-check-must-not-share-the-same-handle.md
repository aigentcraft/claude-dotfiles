---
name: guard-and-its-check-must-not-share-the-same-handle
title: 隠すのと確かめるのに同じセレクタを使うと、UI が変わった日から検査は永久に緑になる
cluster: observability
type: "principle"
tags: ["privacy", "masking", "verification", "selector-drift", "fail-open", "weevee"]
date: 2026-09-14
severity: high
---

## 状況
ラボのブラウザで録画する画面に、個人アカウントのサイドバー（会話履歴の題名）が写り込む経路があった。
CSS で `display:none` にして隠す方針を採った。

## 危ない書き方
隠したセレクタと**同じセレクタ**で「もう見えていないこと」を確かめる。

```js
mask.forEach(sel => hide(sel));
const leaked = mask.some(sel => visible(sel));   // ← 常に false
```

サイトが DOM を変えてセレクタが当たらなくなった日から、
- 隠す側: 何も隠さない（**写り込む**）
- 確かめる側: 何も見つからない（**合格**）

となり、**壊れた瞬間に検査が永久に緑になる**。壊れたことを知る手段が無い。

## 正しい書き方
確かめる側は、**隠す側が使っていない手がかり**で数える。

| | 手がかり |
|---|---|
| 隠す | `#stage-slideover-sidebar` / `#history`（サイトの内部 id） |
| 確かめる | `a[href^="/c/"]`（**URL の形** = 会話ページへのリンク） |

id が変わっても URL の形は変わらない。実測: マスクのセレクタを外すと、立会い検査は
「会話履歴へのリンク 28 件」を検出した。

## 予防ルール
- **守る仕掛けと、それが効いているかを見る仕掛けは、別の前提に立たせる**。
  同じ前提に立つと、前提が崩れた時に両方が同時に黙る
- 検査を書いたら、**守る側だけを壊して赤を一度出す**（検査ごと壊すのでは意味がない）
- 記録は件数だけにする。何が見えたかの中身を持ち出すと、
  写り込みを防ぐ仕組みが個人情報をログに運ぶ

## 関連
- [[verification-tool-that-cannot-fail]] — 成功条件が、確かめたい事実の成立を要求していない型
- [[documented-but-never-implemented]] — 説明と実装がずれても誰も気づかない型
