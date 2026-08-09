---
title: "windows-codex-imagegen-triple-failure"
type: "error"
tags: ["windows", "codex", "imagegen", "subprocess", "acl", "npm-shim", "sandbox"]
date: "2026-08-09"
---

## 症状（Symptom）

Windowsでcodex経由の画像生成（gpt-image-2）が3種類の異なる形で連続失敗し、記事が画像なしのまま承認依頼に到達した:
1. `Error loading config.toml: unknown variant 'ultra'`（全実行が即死）
2. 修正後: exit=0だがcodexが「画像内容のプロンプトが未指定」と応答（生成されない）
3. さらに修正後: 生成はされるが親プロセスが `PermissionError` で生成物に触れない

## 根本原因（Root Cause）

1. `~/.codex/config.toml` の `model_reasoning_effort = "ultra"` がCLI 0.133の許容値外（別ツールが書いた値）
2. **npmの `codex.cmd`（batchシム）は複数行の引数を先頭行で切り落とす**。指示文の `## 画像の内容` 以降が消えていた
3. **`tempfile.TemporaryDirectory`（mkdtemp）の制限付きACLディレクトリ内では、codexサンドボックスが作ったファイルを親プロセスが読めない**。通常の `mkdir` ディレクトリなら即読める。リトライ・icacls・別プロセスmoveでも解決しない（ディレクトリ属性が原因のため）

## 修正（Fix）

- config: `ultra` → `high`
- `_resolve_codex()`: which結果が `.cmd/.bat` なら同梱の実バイナリ `codex.exe` を直接使う
- 作業ディレクトリ: mkdtempをやめ、repo内の通常mkdir + `shutil.rmtree` 自前掃除

## 予防ルール（Prevention）

1. npm製CLIに**複数行の引数**を渡す時は .cmd シム経由を禁止（実バイナリ/nodeスクリプトを直接呼ぶ）
2. サンドボックス系ツールの生成物を受け取る作業ディレクトリに mkdtemp を使わない（Windows）
3. 多段障害では「1つ直して再実行」を機械的に繰り返さず、**各修正後に最小プローブ（1件生成）で層別に検証**する — 今回パイプライン全体での再試行を2回無駄にした
