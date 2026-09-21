---
name: uc-x-zero-impressions-engage-pool-starved-12-days
title: UC「Xが全くインプレッションついてないね」— 交流プールが12日間空で、届く経路が死んでいた
cluster: uc
type: "user-correction"
tags: ["user-correction", "x-twitter", "starvation", "silent-failure", "distribution", "join-empty", "weevee"]
date: 2026-09-21
severity: high
---

## 1. Plan / Context
weevee の X 運用は「引用リプライを主力・1サイクル 引用2+Tips1」という設計で
2026-09-02 に開始した（人間決定⑪）。以後 19 日間、投稿・メディア添付・価値契約ゲート・
NG ワード検査など**投稿の中身**を繰り返し改善してきた。

## 2. Do / The Error
人間の指摘「Xが全くインプレッションついてないね」。実測:
- posted 56 本 / 合計インプレッション **70**（平均 1.25）。`organic_metrics` と
  `public_metrics` が一致 → **計測は正しい。本当に 1〜4 imp**
- `users/me`: **followers_count = 0**（19 日・62 投稿・received likes 0）
- kind 別平均: tips 2.36 / article_link 1.43 / **quote 0.35**（主力レーンが最下位）
- `x/run_engage_cycle` は毎サイクル「いいね0 リプ0 引用0 フォロー0」。
  最後の実いいね/フォローは **2026-09-09**（12 日間ゼロ）

## 3. Check / Root Cause
**① 交流プールの JOIN が 12 日間ずっと 0 件だった。**
`05_engage.engage_cluster` の候補プールは
`x_observations o JOIN x_accounts a ON a.handle=o.author_handle
 WHERE a.engage_ok=1 AND o.collected_at >= datetime('now','-2 days')`。
交流可(engage_ok=1)は 6 アカウントだけで、その**最終観測は 4 件が 2026-09-02**、
残り 2 件が 09-04 / 09-09。2 日窓に 1 件も入らない → プールは常に空。

**② 空にした犯人は「公式アカウント固定枠」。**
`01_observe._accounts_rotation` は official 7 件（engage_ok=0）を**無条件で先頭**に置く。
読み取り予算は夕枠 10 / 朝枠 25 reads。`observe_own_posts` が最低 8 reads を先に取り、
残りを official 7 件 × 5 posts が食い尽くす。`ENGAGE_OK_SLOTS=6` の優先枠には**一度も到達しない**。
コメントには「engage_ok=0 が巡回を独占する starvation の対策」と書いてあり、
**その対策が逆向きの starvation を作っていた**。

**③ 0 件のとき理由が記録されない。**
`items` が空だと `return 0, 0` が `db.log(...候補N件を判定)` の**手前**にある。
外から見えるのは「いいね0 リプ0」だけで、「候補が0件だった」も「なぜ0件か」も残らない。
rc=0・Task Scheduler は緑。12 日間、誰も気づけなかった。

**④ 設計そのものの誤り: 0 フォロワーで「引用」を主力にした。**
引用は**自分のTLに立つ新規ポスト**なので、フォロワー 0 では到達先が無い。
他人の観客を借りられるのは**返信（相手のスレッドに入る）**の方。
実データもそれを示している（quote 0.35 < tips 2.36）。
中身の改善（価値契約・メディア添付・NG語ゲート）は**配信がゼロの上では効果が測れない**。

## 4. Act / Prevention
- **R1: JOIN で候補を作るレーンは「0 件」を必ず記録する。**
  早期 return は log の**後**に置く。「0 件でした」と「左右どちらが欠けたか」
  （観測が古い / 台帳が空）を分けて書く。件数 0 は正常ではなく**調査対象**。
- **R2: 固定枠を足すときは、押し出される側に床を与える。**
  「A を必ず見る」を実装したら、同じ commit で「B が N 日観測されていなければ
  A より先に見る」も入れる。優先枠は予算が届かなければ存在しないのと同じ。
- **R3: 到達がゼロのうちは、中身の改善を成果として数えない。**
  フォロワー 0 の期間にやることは配信経路の獲得（返信で他人の観客に入る・
  フォローされる導線）であって、投稿文の推敲ではない。
- **R4: 外形の KPI を1つ、系の外から毎朝数える。**
  followers_count と「直近7日のインプレッション合計」は `daily_invariants` の
  赤条件に入れる。0 が続くこと自体をインシデントにする。

## 5. 修理と実走（2026-09-21）
窓・対象・空の理由を `workers/shared/x_engage.py` に単一ソース化し、生産側（01_observe）と
消費側（05_engage）が同じ定義を読むようにした。実走で確かめた 3 つ:
- 交流プール **0 → 10 件**（12 日ぶり）
- 開拓の候補源 **0 → 20 件**（`trend:` を候補源に入れた）
- 交流サイクル **いいね 2・返信 1・台帳追加 5**（交流可 6 → 11 アカウント）。
  返信は実際に X に載った

**直す途中で同じ型を 2 回自分でやった**（どちらも初回実走が無ければ気づけなかった）:
1. フォロワー数のために `getUsersMe` へ `user.fields` を足したら xmcp の出力スキーマ検証に
   弾かれ、`observe skipped` で**観測レーン全体が止まった**。到達の計測は「あると良いもの」で
   観測の前提ではない → OAuth1 直叩きに分離し、失敗しても観測は続ける形に
2. `kpi_snapshots` の UNIQUE 制約で、同じ日の 2 回目の記録が例外になり**また観測が止まった**
   → UPSERT + 関数全体を握る
→ **R5: 付加的な計測を、必須処理の成功経路に混ぜない。**

もう 1 つ、初回実走でしか出なかった欠陥: `_accounts_rotation` に床を入れても、
`observe_accounts` が **listener の当日計画を先頭に置く**ため床が上書きされていた
（計画の先頭は公式 7 件）。床は計画順にも勝たせた。
→ **R6: 優先順位を足す時は、その並びを後段で上書きする箇所を全部 grep する。**

関連: [[x-api-quote-restriction-silent-lane-death]]（同じ「レーンの沈黙死」）/
[[uc-explained-by-filename-not-by-role]] / [[sweep-target-list-must-not-be-the-fixed-set]]
