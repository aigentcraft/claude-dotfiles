---
name: bulk-migration-regex-ate-the-adjacent-block
title: 一括移設の正規表現が隣のブロックまで食い、9 役の DB 契約が消えた
cluster: producer-consumer-sync
type: "bug"
tags: ["migration", "regex", "bulk-edit", "single-source", "weevee"]
date: 2026-09-09
severity: high
---

## 症状
9 役の manifest.yaml を一括で縮退（`files:` ブロックを削除）したところ、**`db:`（DB 契約）まで一緒に消えた**。
絶対ルール 2（エージェント間は DB 経由）の単一ソースが 9 役ぶん欠落した状態でコミット直前まで進んだ。

## 根本原因
```python
re.sub(r"(?ms)^files:\n(?:^[ \t]+.*\n)*", "", t)
```
`files:` の次から**インデント行が続く限り**削る。YAML では
```yaml
files:
  agent: …
db:
  reads: [...]     ← これもインデント行
```
`db:` 自体は列 0 で止まるが、その配下の `  reads:` `  writes:` が続きの行として消え、
結果として db ブロックが壊れた（列 0 の行で止める想定が甘かった）。

## 検出できた理由
**テストが `manifest["db"]` を読んでいた**（`test_offer_scout.py::test_agent_definition_validates`）。
全件テストを流していなければ、DB 契約が消えたまま push していた。

## 修正
1. `git show HEAD:<path>` から db ブロックを復元（9 役）
2. `agent_defs.validate_thin` に **db.reads / db.writes の存在検査**を追加（縮退の副作用で契約を落とさない）

## 予防ルール
1. **構造化ファイル（YAML/JSON）を正規表現で一括編集しない。** パーサで読んで、キーを消して、書き戻す
2. どうしても正規表現でやるなら、**削除後に「残っているべきキー」を機械で検査する**（今回 validate に足した）
3. 一括移設のあとは必ず全件テスト。単体テストだけでは「隣が消えた」に気づけない

## 関連
[[single-source-migration-broke-the-legacy-reader]] / [[duplicate-skill-dirs-manifest-points-at-stale-copy]]
