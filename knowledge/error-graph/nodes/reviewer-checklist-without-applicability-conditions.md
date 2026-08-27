---
title: "Reviewer Checklist Items Without Applicability Conditions Penalize Articles They Don't Apply To"
description: "weevee's reviewer scored Q09 (affiliate CTA present) and Q06 (step-by-step screenshots) as failures on a comparison article that had no assigned offer — in Phase 0 no ASP contract exists, so CTA absence is the correct state. Two unconditional items pushed score to 65 (<70 floor) and the article was discarded. Every checklist item needs 'applies when …' so N/A cases aren't scored as defects."
type: "technical-error"
tags: ["ai-behavior", "llm-pipeline", "reviewer", "checklist", "scoring", "weevee"]
---

## 1. Plan / Context
weevee の 06_review は checklist.md（F/C/Q 系・重み付き）で採点し、score < 70 で破棄。Phase 0 は ASP 未契約のため offers が空 → 02b は「提携済み案件なし — 集客記事として続行」で offer をアサインしない。

## 2. Do / The Error
- 記事2（Ollama×VPS メモリ比較）が **Q09「CTA `{{affil:}}` が記事タイプ別ルール通り」= 1点**（「収益記事としての体をなしていない」）、**Q06「手順の再現性とスクショ」= 1〜2点**（比較記事に操作ステップは無い）で減点され、score 65 → 破棄
- reviewer 自身が「offer 未アサインが原因である可能性もあるが」と書きつつ減点した — 判定基準に例外が無いので LLM は減点側に倒す
- 差し戻し2ラウンド分の writer/reviewer 呼び出し（約30分・サブスク枠）が無駄になった。残り企画も同条件なので放置すると破棄が連鎖する

## 3. Check / Root Cause
1. **チェック項目が「何を満たすか」だけで、「どの記事タイプ・どの状態に適用するか」を持っていない** — Q09 は案件アサイン済み記事、Q06 は手順記事にしか意味が無い
2. Phase 0 特有の状態（案件ゼロ）を checklist 設計時に想定していなかった — 参照プロジェクト（案件常時あり）からの移植で前提が変わったのに基準を見直さなかった
3. [[llm-reviewer-false-ng-on-template-layer-items]] と同型: 基準に「充足される層」が無い → 今回は「適用条件」が無い

## 4. Act / Prevention Strategy (Fix)
- Q06 に「手順記事以外（比較・解説・選び方）は対象外＝減点しない」、Q09 に「案件未アサイン記事は CTA 無しが正＝対象外。逆に未アサインで `{{affil:}}` があれば NG」を明記
- **予防ルール: LLM 採点基準の各項目には「適用条件」と「対象外の場合の扱い（満点/除外）」を必ず併記する**。無条件の項目は該当しない対象に減点され、score 床の破棄が連鎖する
- **予防ルール: 参照プロジェクトから採点基準を移植したら、移植先で成立しない前提（案件あり・実測環境あり等）を列挙して例外を書く**
- 未解決（人間決定待ち）: Q03「実測ログが核」は researcher が WebSearch/WebFetch のみで実操作できない現状では構造的に満たせない。基準を緩めるのではなく、実測環境（Bash/Docker）を与えるか企画を絞るかの設計判断が必要
