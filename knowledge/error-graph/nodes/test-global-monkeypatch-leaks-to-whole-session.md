---
name: test-global-monkeypatch-leaks-to-whole-session
title: テストでモジュール属性を直書き換えすると、後続のテスト全部に漏れる
cluster: ai-behavior
type: "bug"
tags: ["pytest", "monkeypatch", "test-pollution", "weevee"]
date: 2026-09-09
severity: high
---

## 症状
新規テスト 1 本を足したら、全件テストが **99 件失敗**した。単体で走らせると全部通る。
失敗するファイルは無関係（`test_x_trends.py` など）で、原因が見えにくい。

## 根本原因
新しいテストの中で `db.emit_event` を**フィクスチャを使わず直接代入**していた:

```python
from workers.shared import db as _db
_db.emit_event = lambda c, ev, ent, eid, payload: ...   # ← セッション全体に残る
```

pytest は 1 プロセスで全テストを走らせるので、モジュール属性の代入は**後続すべてに残る**。
`monkeypatch.setattr` はテスト終了時に自動で戻すが、直接代入は戻らない。

## 修正
`monkeypatch.setattr(_db, "emit_event", …)` に変更。フィクスチャ引数に `monkeypatch` を足すだけ。

## 予防ルール
1. **テストでモジュール/クラスの属性を差し替えるときは必ず `monkeypatch.setattr`**。直接代入しない
2. 新しいテストを足して全件が大量に落ちたら、まず**そのテストの副作用**を疑う（単体で通るなら汚染）
3. 全件と単体で結果が違うときは、テスト間の共有状態（モジュール属性・環境変数・DB ファイル・カレントディレクトリ）を見る
