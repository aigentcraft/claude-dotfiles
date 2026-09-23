---
name: not-ready-notice-blamed-persona-for-captcha
title: CAPTCHA で止まったのに「人物像の情報が足りない」と案内していた
cluster: observability
type: "runtime-error"
tags: ["user-facing-message", "misattribution", "cloudflare", "captcha", "agent", "fukugyo-hootl"]
date: 2026-09-23
severity: low
relationships:
  related_to:
    - "image-engine-refusal-and-usage-limit-reported-as-outage.md"
---

## ユーザーの指摘（原文）

「Captchaが出たということと、ペルソナに不足情報があるという回答が来ている。案件ボードの＃77」

## 1. Plan / Context

インディードの［応募内容を作る］は、エージェントが普段の Chrome で応募フォームを記入し、
承認カードを出す。進めない事情がある時は承認ボタンを出さず、案内を 1 行添える。

## 2. Do / The Error

#77 でエージェントは求人ページを開いた時点で Cloudflare の「私はロボットではありません」に当たり、
正しく止まった（突破しない）。承認カードには理由（CAPTCHA）が出ていたが、続く案内は
「**不足している情報があるため**… `persona.md` に事実を足して」だった。利用者には 2 つの別の問題に見えた。

## 3. Check / Root Cause

- 案内の文面が**理由に関わらず 1 種類**だった。書いた時に想定していた止まり方（設問に答える材料が無い）しか見ていなかった
- 止まる理由は少なくとも 3 種類ある: 関門（CAPTCHA）・人物像に無い情報・その他（募集終了など）

## 4. Act / Prevention Strategy (Fix)

`notReadyNotice(plan, jobUrl)`（純関数）で理由ごとに言い分ける。
関門 → 「普段の Chrome で求人ページを一度開いて確認を済ませてから押し直す」（リンクつき）／
人物像 → persona.md ／ その他 → 上の「進めない事情」を見るよう案内。selftest 3 件、故障注入で FAIL を確認。

### 予防ルール

1. **止まった時の案内は、止まった理由から組み立てる。** 1 種類の文面で済ませると、別の理由の時に誤った行動を指示する
2. 案内が「利用者に何かをさせる」なら、その行動が理由に合っているかを分岐ごとに検査する
