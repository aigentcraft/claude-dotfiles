---
title: "lab_guard Blocked Read-Only Utilities, Subshells, and Removal of the Lab's Own Docker Volume"
description: "First real run of weevee's Bash-enabled researcher (article 6, Ollama 2/4/8GB lab): lab_guard blocked 4 of 46 commands — `tail`, a `(cmd &)` subshell, `wait`, and `docker volume rm weevee-lab-ollama-models` (the lab's own volume). The allowlist was written before any real run and only covered launch/measure verbs; the cleanup rule treated every `docker volume rm` as destructive. Fix: allow read-only text utilities and shell control words, strip leading `(`/`{`/`&` from segments, and permit volume rm only for weevee-lab-* names. Regression tests added."
type: "bug"
tags: ["lab-guard", "allowlist", "false-block", "docker", "researcher", "weevee"]
---

## 1. Plan / Context
researcher に Bash を許可する代わりに PreToolUse フック `tools/lab_guard.py` で許可リスト + 禁止パターン（課金・クラウド・資格情報・破壊的操作）を強制する。許可リストは実走前に「使いそうな動詞」で書いた。

## 2. Do / The Error（2026-08-28 記事 6 の実測ラボ初回実走）
- 46 コマンド中 4 件をブロック: `tail -c 2000 lab.log`（ログ確認）、`(curl … &)` + `wait`（並列負荷試験）、`docker volume rm weevee-lab-ollama-models`（自分で作ったモデル共有ボリュームの片付け）
- researcher は回避策（`wc`/`cat` 経由等）で完走したが、並列負荷試験は実施できず、ボリュームは残った

## 3. Check / Root Cause
1. **許可リストが「実行の動詞」だけで「観察の動詞」を含んでいなかった** — 実測では出力を読む（tail/grep/jq）操作が半分を占める
2. 先頭語判定がサブシェル `(` やバックグラウンド `&` の記号を先頭コマンドと誤認した
3. 片付けルールが `docker volume rm` を一律禁止。「自分の weevee-lab- 資源は消してよい」原則がコンテナにしか適用されていなかった

## 4. Act / Prevention Strategy (Fix)
- ALLOWED_PREFIX に読み取り専用ユーティリティ（cat/head/tail/grep/sort/uniq/cut/tr/awk/sed/jq/xargs）とシェル制御語（wait/true/false/test/[/for/while/if/do/done/then/else/fi/export/read）を追加
- セグメント先頭の `(`/`{`/`&` を剥がし、`)`/`}` だけの断片は無視
- `docker volume rm` は `weevee-lab-` を含む場合のみ許可（prune/rmi は引き続き禁止）
- `tests/test_lab_guard.py` に誤ブロック回帰テストと課金/秘密情報の禁止テストを追加
- **予防ルール: 許可リスト型ガードは初回実走の監査ログ（blocked=true の全件）を必ずレビューし、安全な誤ブロックを許可へ移す。観察系コマンドを最初から含める**
- 関連: [[uc-articles-too-advanced-for-beginner-readers]]（同日の実走で発見）・人間決定③「researcher に Bash 許可・課金操作は一切禁止」
