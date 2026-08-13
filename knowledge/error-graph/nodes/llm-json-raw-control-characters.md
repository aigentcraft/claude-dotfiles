---
title: "llm-json-raw-control-characters"
type: "error"
tags: ["llm", "json", "parsing", "python", "pullie"]
date: "2026-08-13"
---

## 症状（Symptom）

pullie 記事#9の画像生成が `json.decoder.JSONDecodeError: Invalid control character` でクラッシュ。
designer（LLM）のJSON応答の文字列値の中に**エスケープされていない生の改行**が含まれていた。

## 根本原因（Root Cause）

- LLMはJSON文字列値の中に生の改行・タブを平気で出力する（複数行のプロンプト文を値に入れる時に頻発）
- Pythonの `json.loads` はデフォルト（strict=True）で文字列内の制御文字を拒否する
- 同じ脆弱なパースパターンが**10ファイルにコピペ複製**されており、どれでも起き得た

## 修正（Fix）

- 全10箇所の `json.loads(...)` に `strict=False` を付与（文字列内の制御文字を許容）
- 生改行入りJSONの再現テストで確認

## 予防ルール（Prevention）

- **LLM出力をjson.loadsする時は常に strict=False**（コードレビュー観点に追加）
- 同一ヘルパーの10箇所コピペは今回の修正コストそのもの — LLM出力パースは共有モジュールに
  一本化するのが本筋（pullieでは今後の宿題として記録）
