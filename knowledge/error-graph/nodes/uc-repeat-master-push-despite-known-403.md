---
title: "uc-repeat-master-push-despite-known-403"
type: "user-correction"
tags: ["git", "permissions", "repeat-error"]
correction_category: "instruction-enforcement"
date: "2026-02-28"
---

## 症状
- セッション内で「masterへのpushは403になる」ことがすでに判明していた
- それにもかかわらず、次のコミット時に `git push -u origin master` を実行した
- 403で失敗した後にようやくclaude/ブランチへpushした

## 根本原因
**ナレッジの「知っている」と「適用する」が分離していた**

- システム指示に「CRITICAL: branch must start with 'claude/'」と明記されていた
- 同セッション内で1度目の失敗があった
- しかしpush実行前にこの制約を「チェックリストとして確認する」行動が発生しなかった
- 「push = git push origin master」という習慣的パターンが制約より優先された

## 修正
- エラー後に `git push -u origin master:claude/mobile-claude-code-support-mWvj3` で解決

## 予防ルール（push前チェックリスト）

> **push実行前に必ず自問する**:
> 1. このリポジトリに「push先ブランチの制約」はあるか？
>    - システム指示に `claude/` ブランチ指定がある場合 → masterへのpushは禁止
>    - 同セッション内でpush失敗があった場合 → 同じコマンドを再実行しない
> 2. 前回失敗したコマンドと同じコマンドを打とうとしていないか？

## 再発防止の仕組み化
- **Quick Rulesに昇格候補**: git push前のブランチ制約チェック
- セッション内で一度でも「403 push失敗」が発生したら、以降のpushはすべてclaude/ブランチへ
