---
title: "published-but-never-announced-because-url-stayed-in-stdout"
type: "system-design"
tags: ["producer-consumer-sync", "silent-failure", "handoff", "booth", "pullie", "release"]
date: "2026-09-13"
---

## 症状

2026-09-12 に製品 #16「集計最新化チェッカー」を BOOTH に出品し、
`product_ideas.status` を `listed` にした。セッションは「発売完了」と報告した。

翌日に実測すると、この製品は **X で一度も告知されていなかった**。
記事企画も 0 件。エラーは 1 件も出ていない。通知も鳴っていない。

```
#16 集計最新化: 告知ポスト=0件 / 記事企画=0件
#11 表記ゆれ  : 告知ポスト=1件 / 記事企画=1件
```

## 何が起きていたか

告知は**自動の仕組みが既にある**。`product_pipeline/02_promote.py` が日次で
1 製品ずつ X 告知を積む。その入口条件がこれ:

```sql
SELECT ... FROM product_ideas
WHERE status='listed' AND booth_url IS NOT NULL ...
```

一方、出品ランナー `products/_publish_from_md.py` は出品後に URL を
**標準出力に print するだけ**だった。docstring にもこう書いてあった:

> 出品後にURLを表示 — **DB更新は呼び出し側で**

つまり「印刷された値を、人（またはAI）が見て、DB に書き写す」手順が挟まっていた。
#11〜#13 のときは書き写された。#16 のときは**静かに抜けた**。
`booth_url` が NULL のままなので `pick_target` はこの製品を一度も選ばず、
**出品はされたが、売る動きが一切起きない状態**が丸一日続いた。

## 根本原因

**次の工程が読む場所に書かず、人間が読む場所（stdout）に出した。**

出品ツールは URL を「表示すべき結果」として扱い、
告知ワーカーは URL を「入力条件」として扱っていた。
その間を埋めていたのは、どこにも書かれていないコピー作業だった。

手順書に書けば守られる、というのは制御ではない
（[[uc-hardcoded-judgment-while-fixing-hardcoding.md]] と同じ形で、
「推奨は制御ではない」— [[catalog-key-added-without-consumer-sync.md]]）。

さらに悪いのは **失敗が無症状**なこと。出品は成功し、status も `listed` になり、
ダッシュボードにも「発売済み」と出る。欠けているのは
「起きるはずだった別のこと」であって、壊れた何かではない。
壊れていないものは通知できない。

## 修正

1. `_publish_from_md.py` に `--idea-id N` を追加し、**出品と同じ実行の中で**
   `status='listed'` と `booth_url` を書く（`record_listed()`）
2. `--idea-id` が無い場合は最後に警告を出す
   — 「booth_url がNULLのままだと 02_promote がこの製品を告知しません」
3. #16 の `booth_url` を遡って補填（告知ドリップが拾えるようになった）

## 予防ルール

- **次の工程が読む場所に書くまでが1つの作業**。値を print して終わりにしない。
  print は人間への報告であって、機械への受け渡しではない
- 「完了の定義」を散文で複数項目に分けたら、**どれが機械で、どれが人の手順か**を
  その場で分ける。人の手順として残したものは必ず抜ける前提で、警告を出す口を作る
- 発売のように**失敗が無症状な連鎖**は、下流の入口条件（WHERE 句）を
  上流のツールが満たすところまで持たせる

## 関連

- [[enumeration-guards-never-close-use-structural-rules.md]] — 列挙で守ろうとすると閉じない
- [[catalog-key-added-without-consumer-sync.md]] — 生産側と消費側の同期漏れ
- [[generated-instruction-logged-then-discarded.md]] — 作ったのに受け手に届かない
