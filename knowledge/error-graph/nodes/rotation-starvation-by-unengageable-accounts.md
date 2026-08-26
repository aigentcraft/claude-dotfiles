---
title: "観測ローテ飢餓 — 永遠に条件を満たさないメンバーがキューを独占しエンゲージが沈黙死"
type: "technical-error"
tags: ["scheduling", "starvation", "x-twitter", "silent-failure", "budget", "sqlite"]
description: "last_engaged_at昇順の巡回は、engageされ得ないcandidate(engage_ok=0)が溜まった時点でNULL最優先により観測枠を独占。交流可能アカウントの観測が途絶え、いいね/リプがrc=0のまま完全停止した（2026-08-26）。"
---

## 1. Plan / Context
pullie X課の観測（01_observe）は台帳アカウントを `ORDER BY COALESCE(last_engaged_at,'1970') ASC`
で1run 10件巡回し、交流（05_engage）は「直近2日に観測された engage_ok=1 アカウントの投稿」を
候補プールとして judge に回す設計。公平性のつもりで「engageが古い順」を採用していた。

## 2. Do / The Error
2026-08下旬、フォロワーリサーチ（08_followers）が category='candidate'（engage_ok=0・交流不可）を
22件登録した時点で発症:
- candidateは定義上engageされない → last_engaged_at が永遠にNULL → 巡回10枠を恒久独占
- engage_ok=1 の33アカウントは観測されなくなり、最終観測が8/23で途絶
- 05_engageのプール（観測2日窓）が空 → **判定前にreturn (0,0)・rc=0** → いいね/リプが8/26に完全ゼロ化
- 併発: own投稿のメトリクス更新が40件に育ち読み取り予算（朝60/夕40/夜30）を先食い
  → search観測もゼロ → scoutは同じ古いcandidate 20件を毎スロット再judge（$0.75/日の空焚き）
- 発覚は人間のDiscord報告。ログはrc=0の「likes=0 replies=0」が並ぶだけで監視に乗らなかった

## 3. Check / Root Cause
1. **飢餓（starvation）**: 「最後に処理された時刻」順の公平キューは、処理条件を永遠に満たさない
   メンバーが混入すると全枠を独占する。ソートキーは「巡回の目的（=観測の鮮度）」で選ぶべきで、
   別レーンの実績（engage時刻）を流用したのが根因
2. **共有予算の無配分**: own/account/searchが単一予算を先着順で食う設計は、どれかが成長すると
   他が黙って全滅する
3. **空振りはrc=0**: プール空は正常系として扱われ、既存の失敗監視（rc≠0の2run連続）に信号が
   届かない（[[x-api-quote-restriction-silent-lane-death]] と同型の沈黙死）

## 4. Act / Prevention Strategy (Fix)
- 巡回を「観測が古い順」+ 目的別優先枠（engage_ok=1に7/10枠、candidateに残り）へ変更
- 予算をセクション別に配分（own 35% / account 45% / search 残り）— 床と天井のみ機械で担保
- scoutはjudge済みpost_idを workflow_events 'x.scouted' で冪等ガード（新規投稿は新IDで再評価）
- **予防ルール**: ①公平キューのソートキーは巡回目的と同じ事象の時刻を使う（別レーンの実績を
  流用しない）②「対象0件でスキップ」する正常系ゼロが数日続き得るレーンは、ゼロ継続を
  ops-auditorの観点（活動量の異常減）で拾えるか設計時に確認する
