---
title: "UC: Top Page Layout Built Without a Concrete Design Reference Had 'No Design Sense'"
description: "After two iterations of the weevee top page (GSAP loom hero, then a keyword graph hero), the user said 'レイアウト配置にデザインセンスがない' and pointed to a concrete reference site (keeps.homes) to imitate — code and screenshots — plus a specific motion spec (nodes float gently, enlarge on hover). Lesson: when the user cares about visual quality, obtain and study a real reference (layout grid, spacing rhythm, type scale, motion) before composing; do not invent a layout from tokens alone."
type: "user-correction"
tags: ["user-correction", "design", "layout", "reference-driven", "top-page", "weevee"]
---

## 1. Plan / Context
weevee のトップページを、ロゴ由来のトークン（色・書体）と自前の構成（ヒーロー 2 カラム・ベント・記事行・3 ステップ）で 2 回作った。動作・アニメーション・データ連動は実現していた。

## 2. Do / The Error（ユーザー指摘 2026-08-27）
- 「レイアウト配置にデザインセンスがない。https://keeps.homes のコードとスクショを参考に真似してトップページを作って」
- 「ナレッジグラフは点と線がふよふよと動きながら、マウスを乗せると大きくなるアニメーションにして」

## 3. Check / Root Cause
1. **参照物なしで構成を発明した** — ECC の design-quality ルール（「実在の参考を最低数点集める」「テンプレ既定値を出さない」）のうち、参考収集を省略した。トークンが整っていても、余白のリズム・要素の大きさの対比・視線誘導は参照無しでは平均的になる
2. **機能（データ連動・アニメーション）の完成を「デザインの完成」と錯覚した** — 実見検証は「壊れていないか」を見ており「プロの配置か」を問うていなかった
3. モーションの質感も指定がなければ汎用（scale-in・pulse）になる。ユーザーの語彙（ふよふよ・ホバーで拡大）は具体的な物理感（ゆっくりした浮遊・イージングの柔らかさ）を要求している

## 4. Act / Prevention Strategy (Fix)
- **予防ルール: ビジュアル面の実装前に、参照サイトを 1 つ以上「コード + スクリーンショット」で取得し、グリッド幅・セクション間隔・見出しサイズ比・行間・角丸・影・モーションのイージングを数値で書き出してから組む**。参照はユーザーに聞く（指定がある場合は必ずそれ）
- 参照を写す時はブランド（色・ロゴ・書体）だけ差し替え、配置とリズムは忠実に倣う（独自解釈を先にしない）
- グラフ等の装飾モーションは「浮遊（振幅 4〜8px・周期 4〜7 秒・要素ごとに位相ずらし）+ ホバー拡大（scale 1.6〜2・cubic-bezier(0.34,1.56,0.64,1)）」のような**物理感の数値**まで決めてから実装する
- 関連: [[uc-site-design-direction-before-content]]・[[uc-inspection-must-match-reader-conditions]]
