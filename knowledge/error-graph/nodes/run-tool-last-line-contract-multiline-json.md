---
title: "run-tool-last-line-contract-multiline-json"
type: "error"
tags: ["pipeline", "cli-contract", "json", "logging", "weevee"]
date: "2026-08-31"
---

## 症状（Symptom）

`01_collect_signals.run_tool` は tools/ CLI の **stdout 最終行だけ**をログ/収集サマリーに使う契約。`kwcli volume` が `json.dumps(..., indent=2)` の複数行 JSON を出していたため、成功/失敗どちらも最終行が `}` になり、サマリーが `volume(})` と無意味になっていた（検知ロジックの `"written": N` 抽出も常に失敗）。

## 根本原因（Root Cause）

CLI 側が「人間向けの整形出力」と「機械向けの契約（最終行）」を区別していなかった。呼び出し側 run_tool の契約（最終行のみ）は既存 CLI（clickcli/aspcli）では守られていたが、新規 CLI 追加時にチェックする仕組みがない。

## 修正（Fix）

- `kwcli volume`: 詳細（rows）は整形 JSON で出しつつ、**最終行に 1 行サマリー JSON**（mode/targets/fetched/written/no_data）を追加。エラー時も 1 行 JSON（error + hint）
- 01 側は最終行から `"written": N` を抽出して Discord 通知の条件にする

## 予防ルール（Prevention）

1. **run_tool から呼ばれる CLI は「stdout 最終行 = 1 行の機械可読サマリー」を契約とする**（整形出力はその前に出す）。新規 CLI を 01 に配線する時に最終行を実測確認する
2. 関連: [[google-ads-api-setup-gotchas-oauth-timeout-customer-not-enabled]]
