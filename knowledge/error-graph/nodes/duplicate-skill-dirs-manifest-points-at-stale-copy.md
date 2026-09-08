---
name: duplicate-skill-dirs-manifest-points-at-stale-copy
title: SKILL.md の二重配置 — manifest が古い方を指し、本番の researcher が古い手順で動いていた
cluster: producer-consumer-sync
type: "bug"
tags: ["skills", "manifest", "duplicate-source", "stale-config", "weevee"]
date: 2026-09-08
severity: high
---

## 症状
`agents/<role>/manifest.yaml` の `files.skill` が 10 役で旧置き場 `skills/<role>-toolkit/SKILL.md` を指し、
`.claude/skills/<role>-toolkit/SKILL.md`（本日更新した方）と二重になっていた。9 役は同一内容だったが
**researcher は差分あり**（旧: 録画の節なし・「外部サービスへのサインアップは行わない」）。
`03_research.py` → `compose_prompt` → **本番の researcher は今日、古い SKILL を読んでいた**。
CLAUDE.md には 8/27 から「二重配置。片方だけ直す事故を防ぐため一本化する」と書いてあった。

## 根本原因
「書込制限のため skills/ に置いた」セッション（`agents/writer/manifest.yaml:2` の NOTE）の残骸を、
一本化のタスクを未解決欄に書いただけで放置した。**書き手（SKILL を編集する側）は `.claude/skills/` を直し、
読み手（manifest → compose_prompt）は `skills/` を読む**という producer/consumer の分裂。

## 修正
manifest 16 本を `.claude/skills/` に統一・`skills/` を git rm・`agent_defs.validate` 全 16 役 OK。

## 予防ルール
1. **同じ内容のファイルを 2 か所に置かない。** 一時的に置いたら、その場で片方を消すか、消すタスクを次の commit に入れる
2. 設定の「読み手」がどのパスを読むかを、書き手側の文書（CLAUDE.md の置き場説明）だけでなく **validate で機械検査**する
   （今回: validate は「ファイルが存在するか」しか見ておらず、「正の置き場か」を見ていなかった）
3. 二重の疑いがある時は `diff` を取る。「同じはず」は事実ではない

## 関連
[[catalog-key-added-without-consumer-sync]]
