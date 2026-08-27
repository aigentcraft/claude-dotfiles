---
title: "Checklist Cites a Reference File the Agent Manifest Never Loads"
description: "The reviewer checklist item Q08 says 'per ng_phrases.md', but ng_phrases.md was only listed in the writer's manifest skill_refs — the reviewer never received it and self-reported 'file not at hand, partial check'. Any file a prompt cites must be wired into that agent's manifest; grep citations against manifests."
type: "technical-error"
tags: ["producer-consumer-sync", "skill-sync", "agent-manifest", "llm-pipeline", "weevee"]
---

## 1. Plan / Context
weevee のエージェントは `manifest.yaml` の `skill_refs` に列挙したファイルだけをプロンプトに同梱する（`agent_defs.compose_prompt`）。
reviewer の checklist.md Q08 は「AI臭フレーズがない（ng_phrases.md 準拠）」と定義。

## 2. Do / The Error
- `ng_phrases.md` は writer / sns-manager の manifest にはあるが **reviewer の manifest には無かった**
- reviewer は Q08 を「ng_phrases.md が手元にないため全件照合は不可。典型的なフレーズのみ確認」と**自己申告付きで部分判定**し、スコア 8 で通した
- quality_checks のコメントを読まなければ気づかない静かな劣化（rc=0・NGでもない）

## 3. Check / Root Cause
1. **参照ファイルの「引用側（checklist）」と「同梱側（manifest）」が別ファイルで、追加時に片方しか更新されなかった** — producer-consumer 同期漏れの定型（[[../clusters/producer-consumer-sync.md]] R1）
2. 同じファイルを複数エージェントが必要とする時、manifest は各エージェントごとに独立しているため「writer に入れた＝全員に入った」と錯覚した
3. LLM は欠落を補完して「それらしく」判定するので、欠落がエラーとして表面化しない

## 4. Act / Prevention Strategy (Fix)
- reviewer manifest の skill_refs に `agents/writer/skill_refs/ng_phrases.md` を追加（相対パスは共有可）
- **予防ルール: プロンプト・checklist・agent.md 内で `xxx.md` を引用したら、そのエージェントの manifest に同梱されているかを grep で確認する**
  - 検査コマンド例: `grep -rhoE "[a-z_]+\.md" agents/*/skill_refs agents/*/agent.md | sort -u` と各 manifest の skill_refs を突き合わせる
- **予防ルール: LLM の出力に「手元にない」「参照できない」「不明のため」が含まれたら供給欠落として扱う** — quality_checks / execution_logs へのそのフレーズ検知を ops-auditor に持たせる候補
- 関連: [[llm-reviewer-false-ng-on-template-layer-items]]（同じ reviewer の判定基準不備）
