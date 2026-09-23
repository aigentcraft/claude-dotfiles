---
title: "能力の旗を 1 つ止めたら、無関係な経路まで黙って止まった"
description: "案件探索だけ止めるつもりで search=false にしたら、巡回対象の選別が search だけを見ていたため、サイトごと常駐から外れた。Discord の応募ボタンも通知メールの確認も、エラーを出さずに何もしなくなった。"
type: "technical-error"
tags: ["capability-flags", "silent-failure", "dispatch", "regression", "fukugyo-hootl"]
relationships:
  caused_by: []
  related_to: ["uc-prevention-rule-written-but-not-enforced-in-code"]
  fixes_node: []
---

## 1. Plan / Context
インディードが Cloudflare に止められたので、Playwright 版の案件探索と受信箱の巡回を止めた
（`capabilities: { search: false, inbox: false }`）。応募は別経路（Claude in Chrome）で残す（`applyMode: 'agent'`）。

## 2. Do / The Error
応募ボタンを出して push した後、通知メールの確認を足したところ、**起動しても一度も呼ばれなかった**。
調べると、常駐の巡回対象を作る `prepareSites` が

```ts
if (!adapter.capabilities.search) continue;
```

で絞っていた。インディードはサイトごと対象から外れ、

- Discord のボタン操作（`byId.get(job.site)` でチャンネルを引く）→「サイトを解決できません」で**何もしない**
- 通知メールの確認（`byId.get('indeed')` が undefined）→ **黙って飛ばされる**

どちらもエラーにならず、ログの警告 1 行か、何も出ないだけだった。

## 3. Check / Root Cause
**1 つの旗が、名前以上の意味を背負っていた。** `search` は「案件探索ができる」という意味だったが、
`prepareSites` の中では「このサイトを常駐で扱う」の代わりに使われていた。
旗を追加した当時はサイトが 1 つで、全ての能力が揃っていたので、違いが表に出なかった。

同じ日に似た形がもう 1 つあった: `repair` が応募方式の変更後もそのまま「応募の準備」を呼び、
検討中 10 件ぶん Chrome の探索を連続で起動するところだった（流す前に塞いだ）。
**旗や方式を変える時、その値を読んでいる全ての場所の意味を確かめていなかった。**

## 4. Act / Fix & Prevention
- 巡回対象は `hasAnyCapability`（search / inbox / applyMode のどれか 1 つでも動くなら対象）で決める
- 案件探索の予定だけを `isHuntable`（search）で絞る。**「扱うか」と「探索するか」を別の関数にした**
- selftest に「探索を止めても、応募があれば外さない」を追加

### 予防ルール
1. **能力の旗を変える時は、その旗を読んでいる全ての場所を grep して、それぞれが何の意味で読んでいるかを確かめる。**
   1 つの旗が 2 つの意味で読まれていたら、関数を分ける
2. **「対象から外す」処理は、外したことを必ずログに出す。** 黙って飛ばすと、壊れたことに誰も気づけない
3. 変更後の確認は「新しく足した機能が動くか」だけでなく、**「既に出したボタンが押せるか」**まで見る
