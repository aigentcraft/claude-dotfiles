---
name: verification-tool-that-cannot-fail
title: 成功条件が「事実」を要求していない確認ツール — 落ちない検査は検査ではない
cluster: ai-behavior
type: "user-correction"
tags: ["user-correction", "verification", "false-positive", "test-schema", "playwright", "weevee"]
date: 2026-09-09
severity: high
---

## ユーザー指摘（原文）
「開いたけどログインされてたよ。なんでログイン出来てるのに確認依頼したの？」

## 実際に何が起きたか（同じ型の欠陥が 1 時間に 3 件）

1. **`browse.mjs login --until`**: 合図が URL の正規表現一致だった。ChatGPT はログイン後も
   `https://chatgpt.com/` のままなので、`--until 'chatgpt\.com/(\?|$|c/)'` は**着地した瞬間に一致**。
   → 人間が何もしていなくても `LOGGED IN: … セッションを保存しました。` と出て、
   **未ログインの profile を保存して成功と報告**。ログの `LOGGED IN` を信じて次に進んでいた。

2. **`session_check.py`（1 の再発を防ぐために作ったツール）**: 「ログイン後にだけ出る語」に
   `新しいチャット` `ライブラリ` を登録したが、**未ログインの着地画面にも出る**。
   肯定の目印がログイン要求の語を打ち消す実装だったため `{"ok": true}` を返した。
   数分前に自分で読んだ生テキスト（`ログイン` `無料で新規登録` を含む）と矛盾していた。

3. **テストの手書き偽スキーマ**: `CREATE TABLE domain_knowledge (id, agent, content, verified)` のように
   本番と違う表をテスト内で手書きしていた。本番の CHECK 制約・外部キー・NOT NULL が**存在しない**ため、
   編集長の影運転が本番で毎回 `CHECK constraint failed: status IN ('running','done','failed')` で
   落ちていたのに、テストは 2,502 件緑だった。

## 根本原因
**成功条件が、確かめたい事実の成立を要求していなかった。**
- URL 一致は「人間がログインした」ことを含意しない（同じ URL に留まるサイトがある）
- アプリ側の語の存在は「ログイン済み」を含意しない（未ログイン画面にもアプリの枠は出る）
- 偽スキーマの INSERT 成功は「本番で INSERT できる」を含意しない（制約が無い）

いずれも**否定側の証拠を見ていない**。「成立した証拠」だけを探し、「成立していない証拠」を無視した。

## 修正
- `browse.mjs login`: 合図を**ログイン要求の語が画面から消えたこと**に変更（URL は補助情報に降格）。
  `LOGIN_MARKERS` を `session_check.py` と同じ語に揃え、根拠を一本化
- `session_check.py`: **ログイン要求の語が勝つ**（肯定の目印で打ち消さない）。判定は未ログイン側に倒す
- `tests/conftest.py`: `real_db` フィクスチャ（本番と同じ `schema.sql` + migrations）。
  移した途端に外部キー違反 2 件・NOT NULL 違反 1 件が露出した = 偽スキーマが隠していた分

## 予防ルール
1. **検査を書いたら、条件が成立していない状態で走らせて「落ちること」を確かめる。**
   落ちない検査は検査ではない。緑を見て安心するのではなく、赤を一度出す
2. **成功の合図には、事実が成立していないと出現し得ないものを選ぶ。**
   「成立時に出るもの」ではなく「不成立時に出るもの」を消えたことで判定する方が誤りにくい
3. **否定の証拠を優先する。** 肯定と否定が同時に見えたら否定に倒す（未ログイン・不合格・未検証の側へ）
4. **DB を使うテストは本番の `schema.sql` から作る。** 表の形を手で写さない
5. **推測でユーザーに作業を依頼しない。** 10 秒で確かめられることは確かめてから依頼する
   （→ [[uc-gave-up-on-paid-service-without-checking]] と同じ根：材料が無い＝できない、の短絡）

## 関連
- [[uc-gave-up-on-paid-service-without-checking]] — 確認せず「触れない」と結論した同日の UC
- [[generated-instruction-logged-then-discarded]] — 生成物が使われたように見えて使われていない型
