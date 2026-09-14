---
name: documented-but-never-implemented
title: 説明書に書いたことが実装されていない — 「仕様」として 11 日間引き継がれた自動解決
cluster: observability
type: "defect"
tags: ["docstring", "unimplemented", "silent-skip", "naming-drift", "discord", "weevee"]
date: 2026-09-14
severity: high
---

## 症状
Discord の承認レーン（記事の承認依頼に返信すると状態が変わる仕組み）が、作った日から一度も
動いていなかった。実査すると:
- Bot はサーバーに参加済み（8/26 から）
- メッセージ本文も読める（Message Content Intent 有効）
- 承認の読み取りを走らせても毎回 `{"seen": 0, ...}` で何もしない

人間には「Bot をサーバーに招待してください」と 3 週間言い続けていた（招待は済んでいた）。

## 根本原因（2 つが重なっていた）

### 1. 説明書に書いたことが実装されていない
`10_approvals` の説明:
> DISCORD_APPROVALS_CHANNEL_ID（**未設定なら DISCORD_APPROVALS_WEBHOOK_URL から自動解決**）

実装:
```python
def approvals_channel_id() -> str | None:
    c = (os.environ.get("DISCORD_APPROVALS_CHANNEL_ID") or "").strip()
    return c or None          # ← 自動解決は存在しない
```
環境変数は未設定だったので常に `None` を返し、呼び出し側は「未設定ならグレーススキップ」の
設計どおり静かに何もしていなかった。**書いた本人（私）が翌日以降それを「仕様」として読み、
11 日間そのまま引き継いだ。**

### 2. 同じものに 2 つの名前があり、片方だけ設定されていた
- 送信側が探す名前: `DISCORD_WEBHOOK_URL_APPROVALS`
- 読み取り側が探す名前: `DISCORD_APPROVALS_WEBHOOK_URL`（単語の順序違い）

`.env` にあったのは後者だけ。送信側は見つけられず汎用（`DISCORD_WEBHOOK_URL` = #ops）に
フォールバックし、**承認依頼は #ops に届き、読み取りは #approvals を見ていた**。
仮に 1 を直しても、この食い違いで返信は取り込まれなかった。

## 修正
- 自動解決を実装（Discord の Webhook は token 付き URL を叩けば `channel_id` を返す・認証不要）
- `notify` が名前の揺れを吸収（`("DISCORD_WEBHOOK_URL_APPROVALS", "DISCORD_APPROVALS_WEBHOOK_URL")` の順に探す）
- 説明書を実態に合わせ、「いつまで未実装だったか」を残した
- tests 7 件（修正前で赤 — 関数の signature 変更で ERROR になることも含めて確認）

## 予防ルール
1. **グレーススキップする経路は「なぜスキップしたか」を必ず残す。** 「未設定なので何もしない」を
   無言で通すと、設定漏れと実装漏れの区別がつかない。せめて 1 日 1 回 warn を出す
2. **説明書に条件分岐を書いたら、その分岐のテストを同時に書く。** 書いた条件が実在するかは
   テストでしか担保できない（docstring は実行されない）
3. **同じものに 2 つの名前を許さない。** 別名が要るなら、探索順をコードの 1 か所に持つ。
   環境変数は「設定漏れ」と「名前違い」が同じ見た目（空）になるので、特に危険
4. **「人間待ち」と書いた項目は、人間に催促する前に自分で実査する。**
   3 週間「招待してください」と言い続けた先に、自分の実装漏れがあった

## 関連
- [[stale-external-approval-never-reverified]] — 同じ日に見つけた「待ちのまま再確認しない」型
- [[feedback-with-no-address-never-arrives]] — 記録した ≠ 届いた。今回は「書いた ≠ 動く」
- [[uc-endless-whack-a-mole]] — 「同じ集合を複数箇所に手書きし、片方だけ直す」
