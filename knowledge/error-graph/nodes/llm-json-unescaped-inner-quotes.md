---
title: "llm-json-unescaped-inner-quotes"
type: "error"
tags: ["llm", "json", "parsing", "python", "pullie"]
date: "2026-08-20"
---

## 症状（Symptom）

pullie x/02_listen（市場感知）が `json.decoder.JSONDecodeError: Expecting ',' delimiter` で
**2run連続クラッシュ**（05:00定時 + 08:25再開run）→ 09_notifyの介入要求がDiscordへ発報。
x-listener（sonnet）のJSON応答の文字列値の中に、引用・強調のための**エスケープなし半角二重引用符**が
含まれていた: `"summary": "…、"良いパートナーか悪いパートナーか"を見極める…"`。
内側の `"` で文字列が早期終端し、パーサは直後に `,` を期待して壊れる。

## 根本原因（Root Cause）

- 日本語文中の引用を `"…"` で書くのはLLMの自然な癖（特に投稿タイトル等を引用するsummary系フィールド）。
  同じ観測データを渡すと**再発も再現する**（2回目のrunも同じ箇所で落ちた）— 翌run自己回復に任せられない
- [[llm-json-raw-control-characters]]（2026-08-13）の `strict=False` は制御文字のみの対策で、
  構造を壊すエラーには無力
- 同一の `_extract_json` ヘルパーが**18ファイルにコピペ複製**されており、どれでも起き得た
  （8/13ノードに「共有モジュールへ一本化が本筋」と宿題として記録されていた）

## 修正（Fix）

- `workers/shared/jsonx.py` 新設 — LLM応答のJSON抽出を全ワーカーで一本化（8/13の宿題を完了）
- **JSONDecodeErrorの位置情報を使う決定論修復ループ**を追加:
  - `Expecting ',' / ':' delimiter` → 直前の `"` をエスケープして文字列を延長
    （間に構造文字 `,:{}[]"` が無い場合のみ — 別種の構造エラーは触らずraise）
  - 末尾カンマ除去 / `Extra data` は前半のみ再パース / 生 `\` 二重化 / True/False/None 置換
  - 修復不能は従来どおり例外（呼び出し側の差し戻し・通知レーンが受け止める）
- 実際に落ちた2run分の本物のペイロード（reflections.process_logから回収）で修復成功を検証後、
  本番経路で02_listenを実走し完走（new=4 update=2 consumed=60）

## 予防ルール（Prevention）

1. **LLM出力のJSONパースは必ず shared/jsonx.extract_json を使う**（新ワーカーでの再コピペ禁止）
2. パース失敗はLLM再呼び出しの前に**エラー位置駆動の決定論修復**で救う（コスト0・数ms）。
   json.loadsのエラーは位置(e.pos)と種類(e.msg)を持つ — 捨てずに修復に使う
3. LLMにJSONを書かせるスキルには「文字列値内で半角二重引用符を引用に使わない（「」を使う）」を
   明記する（x-listener SKILLに適用済み）
4. クラッシュしたLLM応答は reflections.process_log の💬発話から回収できる —
   **修復ロジックは想像でなく実際に落ちたペイロードでテストする**
