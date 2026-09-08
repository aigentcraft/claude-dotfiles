---
name: single-source-migration-broke-the-legacy-reader
title: 定義を一本化した途端、旧経路の読み手が落ちて安全ゲートが全部 blocked になった
cluster: producer-consumer-sync
type: "bug"
tags: ["migration", "single-source", "legacy-path", "fail-safe", "weevee"]
date: 2026-09-08
severity: high
---

## 症状
エージェント定義を「薄いラッパー + スキル」に移行し、`manifest.yaml` から `files`（agent.md / SKILL.md の在処）を削除した。
移行した役（reviewer）を**旧経路で呼ぶ別の場所**（`sns_gate.review_posts` — X 投稿の法令ゲート）が
`AgentDefError: エージェント定義ファイルがありません` で落ち、**その run の投稿が全部 blocked** になった。

## 根本原因
移行計画には「`agents/<役>/agent.md` は最後まで削除しない（旧経路が壊れる）」と書いていたのに、
**`manifest.files` を消すことが実質的に同じ**だと気づかなかった。旧経路の読み手は
ファイルの実在ではなく **manifest の指し先**に依存していた。

## 良かった点
ゲートは**安全側に倒れた**（例外 → 合格ではなく blocked）。fail-closed だったので投稿は出ていない。
fail-open だったら未検閲の投稿が送信されていた。

## 修正
`compose_prompt` / `model_for` を「manifest に files が無く、薄い定義があるなら
`.claude/agents/<役>.md`（本文）+ `.claude/skills/<役>-toolkit/SKILL.md` + refs から組み立てる」に。
定義の一本化と旧経路の生存を両立させる。

## 予防ルール
1. **移行で「消してよいのはどれか」を、ファイル単位ではなく『読み手が何を見ているか』で判断する。**
   実在するファイルを残しても、指し先を消せば読み手は落ちる
2. 移行の前に **その定義を読む全経路を列挙する**（grep で呼び出し元を数える）。1 か所でも旧経路が残るなら、
   旧経路が新しい置き場から読めるようにしてから消す
3. 安全ゲートは fail-closed に保つ。今回それが唯一の救いだった

## 関連
[[duplicate-skill-dirs-manifest-points-at-stale-copy]] / [[catalog-key-added-without-consumer-sync]]
