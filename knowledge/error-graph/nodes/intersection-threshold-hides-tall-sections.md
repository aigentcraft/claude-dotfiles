---
id: intersection-threshold-hides-tall-sections
title: IntersectionObserverの割合thresholdが背の高いセクションで発火不能になり巨大な空白を生んだ
type: technical-error
severity: high
date: 2026-08-15
project: pullie (Kintone受注目的メディア運営自動化)
cluster: web-frontend
tags: [web-frontend, intersection-observer, reveal-animation, mobile, viewport, pullie]
---

# threshold:0.12 の出現アニメが「高さ6938pxのセクション」で永遠に発火せず、読者には巨大な空白になった

## 症状（ユーザー報告 2026-08-15）
承認依頼された記事プレビューに「ものすごい長い空白の部分がある」。
実測: モバイル幅(375×667)で「7つの基準」H2セクション（高さ6938px）が
読了スクロール後も opacity:0 のまま＝**約7000pxの空白**。
デスクトップ(1280×900)では全要素表示される＝**モバイル幅でのみ発現**。

## 根本原因
1. 記事本文をH2区切りでラップし `IntersectionObserver({threshold: 0.12})` で出現させる設計。
   **thresholdは「要素の何割が見えたか」の割合指定** — 必要可視量 = 0.12×要素高。
   要素高がビューポート高の約8.3倍（=1/0.12）を超えると必要可視量がビューポートを
   物理的に超え、**数学的に発火不能**（6938px×0.12=832px > 667px）。
2. コードは「単一ラッパーだと長文で発火しない」問題を認識しH2分割で対策済み**だった**が、
   H3を7つ含むH2セクション（この記事は「基準1〜7」が1つのH2配下）で再発。
   **分割は高さの上限を保証しない** — 割合thresholdの前提（要素高≪ビューポート）は
   コンテンツ次第でいつでも破れる。
3. モバイルは同幅あたりの文章高が伸びるため、デスクトップで安全な高さでも
   モバイルだけ閾値超えになる（デスクトップのみの検証では原理的に見つからない）。

## 修正
- `{threshold: 0.12}` → `{threshold: 0}`（1pxでも入ったら表示）。
  任意高さのコンテンツに割合thresholdを使わない。

## 予防ルール
1. **IntersectionObserverの割合threshold（>0）は高さが有界な要素にだけ使う**。
   記事本文・リスト等の「コンテンツ次第で伸びる」要素には threshold:0
   （+必要なら rootMargin の固定px）を使う。可視条件を割合で書いた時点で
   「高さが1/threshold×viewportを超えたら消える」爆弾が埋まる。
2. **「表示されるはず」はビューポート2種（PC/モバイル幅）×実スクロールで計測してから言う**。
   デスクトップ1条件の目視・撮影はモバイル限定の発火不能を検出できない。
   pullieでは webshot.probe_reader_view()（決定論プローブ）として承認ゲートに常設化。
3. 出現アニメは「JS無効・未発火＝コンテンツが読めない」設計にしない
   （最終手段のCSSフォールバックか、確実に発火する条件だけで使う）。
関連: [[uc-inspection-must-match-reader-conditions.md]]
