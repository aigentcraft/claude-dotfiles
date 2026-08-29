---
title: "UC: Comparison Article Shipped to Approval Without the Measurement That Was Its Whole Point"
description: "weevee article 13 (Notta / Rimo / tl;dv transcription comparison) reached the approval queue with a good plan but no real comparison: the researcher ran when sign-ups were still forbidden (factsheet 2026-08-28 19:45, human decision allowing free sign-ups came 2026-08-29 morning), substituted a local faster-whisper run, and the reviewer accepted 'local ASR CER' as the article's core (Q03 pass). User: '企画は良いが実測ができていない'. Root cause: a policy change did not trigger re-research of articles whose factsheet was blocked by the old policy, and Q03 does not check that the measurement matches the article's promise."
type: "uc"
tags: ["uc", "measurement", "research-lab", "policy-change", "reviewer-gap", "weevee"]
---

## 1. Plan / Context
文字起こし比較記事の企画は「同一の日本語音声を Notta / Rimo / tl;dv に投入して誤字・話者分離を数える」。研究時点ではサインアップ禁止だったため researcher は実施不可と明記し、ローカル faster-whisper の CER を代替データとした。

## 2. Do / The Error（2026-08-29 ユーザー指摘）
- 記事 13 が score 83・preview verified で承認キューに載った
- 「企画は良いが実測ができていない」— タイトルが約束する比較（3 サービスの実投入）が存在しない

## 3. Check / Root Cause
1. **方針変更（人間決定⑧ 無料サインアップ可）が既存ファクトシートの再取得を起動しなかった** — 旧方針で「実施不可」になった記事（9/13/10）はそのまま執筆・検閲へ流れた
2. reviewer Q03 は「一次データが核か」を見るが、**その一次データが記事の約束（タイトル・企画の芯）と同じ対象か**を見ない。代替実測（ローカル ASR）で合格した
3. 承認依頼の文面に「企画で約束した実測が実施されたか」の一行が無く、人間が気づくまで分からない

## 4. Act / Prevention Strategy (Fix)
- 方針変更でラボの許可範囲が広がったら、**「構造的制約により実施不可」と書かれた factsheet を機械的に列挙して 03 を再実行**する（`factsheets.content LIKE '%実施不可%'`）
- reviewer checklist Q03 に「タイトル/企画の芯が約束する対象そのものを実測しているか。代替対象の実測は Q03 を満たさない（未実施として F04 の開示対象）」を追記
- 承認依頼（06b の Discord 文面）に「企画の実測対象: 実施 / 代替 / 未実施」を機械表示する
- 関連: [[writer-internal-handoff-notes-leak]] [[reviewer-structural-q06-loop-auto-discard]]
