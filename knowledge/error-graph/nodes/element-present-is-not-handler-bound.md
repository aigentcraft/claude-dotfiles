---
title: "element-present-is-not-handler-bound"
type: "testing"
tags: ["playwright", "e2e", "race", "kintone", "plugin", "silent-failure", "pullie"]
date: "2026-09-13"
---

## 症状

kintone プラグインの実機検証（Playwright）で、設定画面に値を入れて「保存する」を
押しているのに、**設定が保存されていなかった**。

例外は出ない。クリックは成功する。保存されないだけ。
検証は次の段階まで進み、生成物に設定値が入っていないところで初めて落ちた
（`AssertionError: 生成文書に見つかりません: '- 作成: …'`）。

```python
page.wait_for_selector("#pullie-hd-author", timeout=15_000)  # ← 通る
page.fill("#pullie-hd-author", AUTHOR)
page.wait_for_timeout(300)
page.click("#pullie-hd-save")                                 # ← 何も起きない
```

## 何が起きていたか

`wait_for_selector` が待つのは **HTML 要素が DOM にあること**だけ。
kintone のプラグイン設定画面は `config.html` を挿入したあとに `config.js` を読む。
`config.js` が `document.getElementById('...-save').onclick = ...` を実行するまで、
ボタンは**見えているがハンドラが付いていない**。

その隙間にクリックが入ると、ボタンは押されるが何も起きない。
Playwright はクリックに成功しているので、エラーにならない。

最初の推測（「固定待ちが短くて保存前に deploy している」）は**外れ**だった。
プローブで実測して分かった:

```
handler bound: True          # 1.5秒待ったあとは付いている
url after save: .../plugin/?message=CONFIG_SAVED   # 保存自体は正常
```

## 根本原因

**「要素がある」を「操作できる」の代わりに使った。**

要素の出現と、その要素を動かすスクリプトの実行は別の出来事で、順序も保証されない。
待ち時間を伸ばして直すと、遅いマシンで再発する（確率が下がるだけ）。

## 修正

固定待ちでも要素待ちでもなく、**目的の状態そのもの**を待つ:

```python
page.wait_for_function(
    "!!(document.getElementById('pullie-hd-save') || {}).onclick", timeout=15_000)
...
page.click("#pullie-hd-save")
page.wait_for_url(lambda u: "CONFIG_SAVED" in u, timeout=20_000)  # 完了も実シグナルで
```

## 予防ルール

- **クリックの前は「ハンドラが束縛されたか」、後は「相手が出す完了シグナル」を待つ**。
  `wait_for_timeout` は原則使わない（撮影直前の描画待ちのような、失敗しても無害な場面だけ）
- 静かに効かない UI 操作は、**その場では落ちず遠くで落ちる**。
  検証が「後段の生成物」で落ちたら、前段の操作が本当に効いたかをまず疑う
- 推測で直す前にプローブを1本書いて実測する（今回、推測は外れていた）

## 関連

- [[capture-success-is-not-content-correctness.md]] — 成功したように見える操作の検証
- [[deploy-wait-http-200-races-stale-build.md]] — 完了シグナルを取り違える
