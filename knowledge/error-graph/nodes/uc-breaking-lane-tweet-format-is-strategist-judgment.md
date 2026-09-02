---
title: "uc-breaking-lane-tweet-format-is-strategist-judgment"
type: "uc"
tags: ["uc", "sns", "x-twitter", "pdca", "llm-free-overreach", "weevee", "breaking-lane"]
date: "2026-09-02"
---

## 症状（Symptom）

速報レーン（新モデル/新サービス発表 → 即日記事 + X 発信）を実装する際、X 側の速報ツイートを
`tools/breaking.py --announce` として **機械側に固定テンプレで** 書いた（1 本・URL なし・「実測中・本日公開予定」で締める・
kind=tips・pattern='速報' 固定）。ツール名にも「LLM-Free オーケストレータ」と付けた。

ユーザー: **「LLM不要はやめて。どんなふうにツイートするのが伸びるのかPDCAが回らない。」**

## 根本原因（Root Cause）

- 「速攻で出す」を「機械が決めて機械が出す」と短絡した。docs/09 の設計原則（**形式・本数・タイミングは判断業務であり
  定数の仕事ではない** / 予測 → 実測のカリブレーション / 機械が持つのは天井とゲートと送信だけ）を、
  新レーンを足す瞬間に忘れた
- 固定テンプレの投稿には「狙い・型・予測」が無い（あっても固定値）ので x-analyst の週次検証に学びが積まれない —
  つまり **速報という最も反応の差が出る局面で PDCA が回らない**
- 「決定論的処理は LLM-Free」（絶対ルール5）の適用範囲を誤読した。送信・ゲート・上限・ロックは決定論だが、
  「どう発信するか」は決定論ではない

## 修正（Fix）

- `tools/breaking.py` から固定テンプレの announce を撤去。X 側は **`workers/x_pipeline/03b_breaking.py`（LLM）** に移す:
  x-strategist が **速報作戦**（引用/単発/スレッド/自前動画・本数・タイミング now/after_article・各投稿の狙い・型・**予測**・
  逸脱枠）を過去の速報成績と制約（引用はブラウザ経路の有無・URL 付き投稿の単価）を見て決める → sns-manager が本文 →
  二層ゲート → 送信（now は即時・after_article は記事公開時）。intent（aim/pattern/predict/format/timing）を全投稿に付け、
  既存の 05_report（x-analyst）の予測カリブレーション・型別成績の対象にする
- 作戦の散文と JSON を workflow_events `x.breaking_plan` に残し、次の速報で strategist が「前回の速報作戦と結果」を読む

## 予防ルール（Prevention）

1. **X の発信の「形式・本数・タイミング・文面」を決めるコードを書かない**。機械が持つのは天井（日次上限）・ゲート（C系二層）・
   送信・ロックだけ。新レーンでも例外にしない
2. 新しい投稿経路を足すときの自己診断: 「この投稿に **予測（intent.predict）** が付くか」「週次の x-analyst 検証の対象になるか」
   「前回の結果を次の判断が読めるか」— 3 つのどれかが No なら設計をやり直す
3. 「速攻」は **判断の速さ**（発表を検知したらその場で strategist を呼ぶ）で実現する。判断の省略で実現しない
4. 関連: [[uc-x-engagement-should-self-drive]]（機械処理の割合が多すぎる・配分は判断業務 — 参照 2026-08-23 の同型 UC）
