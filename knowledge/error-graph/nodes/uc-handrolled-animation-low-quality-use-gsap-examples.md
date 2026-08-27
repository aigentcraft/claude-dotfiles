---
title: "UC: Hand-Rolled CSS/rAF Animations Read as Low Quality — Use GSAP and Copy Real Demo Patterns"
description: "User on the weevee top page: 'アニメーションがレベル低いから、https://gsap.com/ を使い、実際のアニメーション例を学んで導入して。実際のアニメーション例を探してそのまま使って'. The graph used CSS keyframes (animista-style) + a hand-written rAF lerp; easing, staggering, and sequencing were generic. Lesson: for motion quality, adopt the industry tool (GSAP 3.13: core + Flip / DrawSVG / SplitText / ScrollTrigger, all free) and lift proven demo patterns (stagger from center, back/elastic eases, DrawSVG line reveal, SplitText char reveal, Flip layout transitions) instead of inventing curves."
type: "user-correction"
tags: ["user-correction", "animation", "gsap", "motion-quality", "reference-driven", "weevee"]
---

## 1. Plan / Context
トップのナレッジグラフと各セクションの出現を、CSS キーフレーム（animista 参考）+ 自前の rAF（lerp 0.11・sin 浮遊・easeOutCubic カメラ）で実装していた。機能（浮遊・ホバー・整列・ズーム・pulse）は動いていた。

## 2. Do / The Error（ユーザー指摘 2026-08-27）
- 「アニメーションがレベル低いから、gsap.com を使い、実際のアニメーション例を学んで導入して。実際のアニメーション例を探してそのまま使って」

## 3. Check / Root Cause
1. **イージングと時間構造が汎用**: 単一の cubic-bezier / lerp で「遷移が均質」。プロの動きは overshoot（back/elastic）、stagger（中心から放射）、順序（反応 → 移動 → 収束）で作られている
2. **自前実装はチューニング資産が無い**: GSAP のデモは何千回も磨かれたパラメータ（`back.out(1.7)`、`elastic.out(1, 0.5)`、`stagger: { from: 'center', amount: 0.6 }`）を持つ。それを写す方が早く、良い
3. 参照駆動の原則（[[uc-layout-without-design-reference]]）を配置には適用したが、モーションには適用していなかった

## 4. Act / Prevention Strategy (Fix)
- GSAP 3.13（全プラグイン無料）を導入し、**公式ドキュメントのデモコードをそのまま採用**:
  - 出現: `gsap.from(nodes, { scale: 0, ease: 'back.out(1.7)', stagger: { amount: 0.8, from: 'center', grid: 'auto' } })`
  - 線: `DrawSVGPlugin` で `drawSVG: '0%'` → `'100%'`（線が描かれる）
  - 見出し: `SplitText` の chars を `yPercent: 100` から stagger
  - レイアウト遷移: 位置を `gsap.to(obj, { x, y, ease: 'elastic.out(1, 0.6)', stagger })`（または Flip）
  - カメラ: `gsap.to(cam, { ..., ease: 'power3.inOut', duration: 1.1 })`
  - スクロール: `ScrollTrigger.batch('.reveal', { onEnter: batch => gsap.from(batch, { y: 40, opacity: 0, stagger: 0.1 }) })`
- **予防ルール: モーションも参照駆動。自前の easing/lerp を書く前に、GSAP 公式デモ（gsap.com/docs, gsap.com/demos, CodePen GreenSock）から同型のデモを探し、パラメータごと写す**。独自調整はその後
- 関連: [[uc-graph-focus-relayout-and-click-feedback]]・[[uc-layout-without-design-reference]]
