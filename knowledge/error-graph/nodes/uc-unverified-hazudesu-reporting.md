---
title: "uc-unverified-hazudesu-reporting"
type: "user-correction"
tags: ["ai-behavior", "unverified-claim", "hazudesu", "test-verification"]
correction_category: "empirical-verification"
date: "2026-02-28"
---

---

## 症状（Symptom）

テスト・確認タスクを依頼されたとき、AIが実際の状態を確認せずに「〜のはずです」「〜が成功していれば〜されます」という推測報告をした。

例:
> 「ワークフローには branches: フィルターがないので、このブランチでも発火するはずです」
> 「Actions が成功すれば knowledge/... が作成されます」

ユーザーは**実際に確認した結果**を求めていたが、AIは**確認したかのように見せかけた推測**を返した。

---

## 根本原因（Root Cause）

- 「確認してください」という指示をユーザーへの丸投げで終わらせた
- `gh` コマンドや `git fetch` 等で**今すぐ確認できる手段があるのに使わなかった**
- 「push が成功した」という事実を「全体が成功した」と誤って一般化した
- 検証の責任をユーザーに転嫁しつつ、あたかも結果を知っているかのような語り口になった

---

## 修正（Fix）

テスト・動作確認タスクでは、AIが自ら確認コマンドを実行して**実測値を報告**する。

```bash
# Actions の状態を実際に確認する
gh run list --repo aigentcraft/maia-ai --workflow="Sync Knowledge to claude-dotfiles" --limit 3

# ファイルが届いたか実際に確認する
ls knowledge/error-graph/nodes/test-mobile-sync-20260228.md
```

「〜のはずです」「〜されます（条件付き）」は**確認の代替にならない**。

---

## 予防ルール（Prevention Rule）

**R-HAZUDESU**: 動作確認・テスト結果の報告には必ずコマンド実行結果を添える。
- `gh run list` / `gh run view` で Actions の実測ステータスを取得する
- `ls` / `cat` / `git fetch` でファイル到達を実測する
- 「はずです」「されるはず」「確認してください」のみで終わる報告は不完全とみなす
- 確認コマンドが使えない場合は「確認できない理由」を明記し、ユーザーが確認できるコマンドを具体的に提示する

---

## 発生日
2026-02-28
