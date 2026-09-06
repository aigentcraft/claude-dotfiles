---
title: "uc-silent-fallback-labeled-as-gpt"
type: "uc"
tags: ["uc", "images", "imagegen", "codex", "fallback", "silent-failure", "labeling", "self-healing", "observability", "weevee"]
date: "2026-09-07"
---

## 症状（Symptom）

ユーザー **「記事の各見出しに挿入する画像がめっちゃレベルが下がってる。本当に GPT イメージ 2 で作ったやつなのかな。」**（2026-09-07）

実データで確認したところ **人間の見立てが正しかった**:

- `logs/imagegen.jsonl`: 総数 691 / 成功 550 / 失敗 141。**最後の成功は 2026-09-04 01:45**、以降 **103 件連続失敗**（直近 40 件は全滅）
- 失敗理由は一貫して同一。`rc=1 ... The '<model>' model requires a newer version of Codex. Please upgrade to the latest app or CLI and try again.`
  （`ERROR: {"type":"error","status":400,"error":{"type":"invalid_request_error", ...}}` 付き・初出 2026-09-07 01:46・80 件）
  — Codex CLI 0.150.1 がサーバ側の新モデル世代に追いつかず 400 で弾かれていた
- その間に作った記事 16〜19 の情報図は **全部 HTML フォールバック**（`tools/diagram_render.py`・1600×1067 固定。実ファイルで確認）
- **にもかかわらず `manifest.json` の出所欄には「本文の文字・数値をそのまま転記した情報図（GPT Image・読み戻し照合済み）」と書かれていた**
  （16 の画像ディレクトリ中 15 に同じラベル）
- **GPT が全滅しても記録上は正常に見える状態**だった。人間が画像を見て気づかなければそのまま公開されていた

## 根本原因（Root Cause）

1. **ラベルが実経路を見ていない** — `workers/daily_pipeline/05_generate_images.py` の `plan_source()` は
   `kind == "infographic"` なら**無条件で**「GPT Image・読み戻し照合済み」を返す。実際の経路は同じ処理が
   `plan["_source"]`（`"gpt"` / `"html"`）に持っているのに参照していない。ラベルは実測ではなく
   「設計上そうなっているはず」を書いた**文字列定数**だった（[[uc-unverified-hazudesu-reporting]]）
   - しかもこの出所欄は `06_review.image_sources()` が **reviewer に渡す検閲材料**。もともと機械描画の画像を
     「証跡の捏造」と誤判定させないために足した欄で（[[reviewer-flagged-machine-rendered-log-image-as-fabricated]]）、
     **品質ゲートに嘘を渡す穴**に化けていた
2. **フォールバックが記録にも通知にも上がらない** — `plan["_source"]='html'` はプロセス内の dict にしか残らず、
   manifest にも `workflow_events` にも Discord にも出ない。グレース（画像が出れば公開を止めない）が正しく働くほど
   **全滅が正常に見える**（[[success-only-logging-and-overwrite-discard-history]] / [[grace-skip-needs-escalation-for-human-only-recovery]]）
3. **外部 CLI のバージョン要求は予告なく来る** — `codex` は npm 配布で、サーバ側のモデル世代が上がると旧 CLI が 400 で弾かれる。
   これは一過性障害ではなく**復旧手順が 1 コマンドで確定している恒久障害**（`npm install -g @openai/codex`）なのに、
   自己修復の対象になっておらず 3 日間・103 回同じ失敗を繰り返した
   （[[uc-notification-instead-of-self-healing]] / [[windows-codex-imagegen-triple-failure]]）
4. **監視がステップの成否しか見ていない** — 05 は画像が 1 枚でも出れば「成功」。エンジン内訳（GPT n / HTML m）という
   **質の指標**も、「最後に成功したのはいつか」という時刻の指標も誰も数えていなかった。
   失敗率 20%（141/691）という平均値には「3 日前から全滅」が現れない

## 修正（Fix）

- **A. 検出と自己修復**（`workers/shared/imagegen.py`）: `needs_upgrade(stderr)` 純関数でバージョン要求エラーを判定
  （実ログの文言をテストで固定・大小文字と JSON 断片混じりに耐える）→ `codex_version()` / `upgrade_codex()` が
  `npm install -g @openai/codex` を timeout つきで実行 → **同じ生成を 1 回だけ再試行**。
  枷は 4 つ: `IMAGEGEN_AUTO_UPGRADE=0` で無効化 / `logs/imagegen_upgrade.json` + `IMAGEGEN_UPGRADE_COOLDOWN_MIN`（既定 60 分）の
  クールダウン / `_upgraded_once` で 1 プロセス 1 回 / `logs/imagegen.lock` と同じ O_EXCL 方式の別ロックで同時実行抑止。
  全経路を `logs/imagegen.jsonl` に `upgrade_attempted` / `upgraded_to` / `retried` で記録
- **B. ラベルの正直化**（`05_generate_images.py`）: `plan_source()` を `plan["_source"]` から導出（`gpt` → GPT Image /
  `html` → HTML レンダラ / 不明 → **経路を書かない**）。manifest `sections[n].engine`（`"gpt"｜"html"`）を機械可読で保存し、
  既存 manifest の誤ラベルを実態へ移行
- **C. フォールバックの可視化**（05 + `09_notify.py`）: 記事ごとに `workflow_events` `image.engine_mix`（gpt/html/失敗の件数）を発行 →
  フォールバック率が `IMAGE_FALLBACK_WARN_RATIO`（既定 0.5）超で Discord ops に通知（24h 抑止・全件フォールバックは `level='warn'`）。
  日次サマリーに「情報図: GPT n枚 / HTML m枚」を 1 行
- **D. 復旧**: `npm install -g @openai/codex` で 0.150.1 → 0.153.4 に更新し、日本語入りの図が生成できることを実走で確認。
  記事 16〜19 の情報図は `bash scheduler/regen-images-batch.sh 16 17 18 19` → `bash scheduler/preview-batch.sh 16 17 18 19` で作り直す
- 設計書: `docs/03_system-architecture.md` §6.1「画像エンジンの自己修復」

## 予防ルール（Prevention）

1. **フォールバックは必ず記録と通知に出す** — 代替経路に落ちたことは、結果を成功として扱う場合でも
   `workflow_events` とログに残し、比率が閾値を超えたら通知する。**「動いているように見える degraded 状態」を作らない**。
   グレースは「止めない」ための仕組みであって「隠す」ための仕組みではない
2. **生成物のラベルは実際の経路から導出する** — 「どう作ったか」を書く文字列を定数にしない。
   経路を表す変数（`_source` / `engine`）から機械的に導出し、経路が不明なら**何も書かない**。
   ラベルは下流（検閲・人間）の判断材料なので、嘘のラベルは品質ゲートを迂回させる
3. **外部ツールのバージョン要求は自己修復の対象にする** — 復旧手順が 1 コマンドで確定しているエラーは、
   通知ではなく自動実行にする。ただし環境を変える操作（`npm install -g` 等）には
   **①無効化スイッチ ②クールダウン ③1 プロセス 1 回 ④同時実行の排他**を必ず付ける
4. **監視は「最後に成功した時刻」を見る** — 成否カウントの平均は全滅を隠す。
   生成・送信・収集など外部依存の経路には last-success 監視を置く
5. **人間が目で気づいた品質劣化は、必ず「なぜ機械が気づけなかったか」まで遡る** — 見えた症状（画像の質）を直すだけでは、
   同じ盲点が別のレーンで再発する（[[uc-partial-solution-without-automation-path]]）

関連: [[uc-gpt-image-japanese-text-was-self-forbidden]] / [[uc-article-images-decorative-not-explanatory]] /
[[infographic-text-clipped-in-narrow-cards]] / [[uc-visual-inspection-of-rendered-reality]]
