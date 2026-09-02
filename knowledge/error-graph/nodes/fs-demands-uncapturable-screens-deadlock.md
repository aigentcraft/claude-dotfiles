---
title: "FS Demands Uncapturable Screens — Three-Agent Contract Deadlock Stalled Publishing 64h"
description: "pullie記事パイプラインで、researcherのFS「図解・SS指定」が撮影システム（kintone_shot CATALOG 13キー）と無契約に実画面スクショを指定 → writerはカタログ外画面を要求できず概念イラストで代替（偽UI禁止ルール準拠）→ reviewerはQ05/Q09でFS指定スクショの欠落を【重大】fail → どう改稿しても合格不可能。2026-08-29〜09-01に5記事連続破棄・review.passed 64時間ゼロ（ops-auditor high検知・Discord報告で人間が調査指示）。FSテンプレの例文自体がカタログ外画面（プロセス管理設定）を教えていた。"
type: "technical-error"
tags: ["producer-consumer-sync", "pullie", "multi-agent", "contract", "screenshot-catalog", "deadlock", "pipeline-stall"]
---

## 1. Plan / Context
pullie記事パイプラインは researcher（FS作成・SS指定）→ writer（執筆・スクショマーカー）→
05_generate_images（kintone_shot CATALOG のキーだけPlaywright実撮）→ reviewer（Q05: 各操作
ステップに実画面スクショ / Q09: 手順=実画面・各H2最低1枚）の分業。過去の事故対策で
「UI画面を図解で描くの禁止（偽UIモックアップ 2026-08-11）」「カタログ外はスクショなし文章のみ」
が writer に入っていた。

## 2. Do / The Error（発覚 2026-09-01 人間「Discordにエラー報告が来ている」）
- Discord報告の正体は ops-auditor の high 所見「review.passed が約64時間ゼロ＝公開チェーン停滞」
- 8/29以降の5記事（CSV取込×2・条件書式・Excel連携・表記ゆれ）+ 日報リライト2回が全て
  Q05/Q09「FS指定の実画面スクショが概念イラストで代替/欠落」で3〜4ラウンド消費→破棄
- FSが指定していたのは CSVインポートのマッピングUI・文字コード選択・更新キー・プロセス管理・
  リマインダー条件通知・自社プラグインUI・n8n/Zapier画面 — **全部カタログ13キーの外**
- researcherテンプレの例文自体が `[SS: プロセス管理の設定画面]`（カタログ外）だった

## 3. Check / Root Cause
1. **生産者（FS）が消費者（撮影システム）の能力と無契約** — SS指定は自由記述で、撮影可能性の
   検証がどこにも無い。指定が満たせない時に緩める役もいない
2. **各エージェントは自ルールに忠実** — writer は偽UI禁止に従い正しく図解/文章化、reviewer は
   FS指定を正として正しくfail。**局所最適の総和がグローバルデッドロック**
3. 顕在化が遅れた理由: 8/28以前はカタログ内画面で足りる記事（アプリ作成系）が中心。製品13SKU化で
   製品連動・手順系トピック（CSV/プラグイン）に入った途端に発火
4. 類似既知エラー `llm-dsl-single-line-flattening-breaks-parser` / catalog同期漏れ（2026-08-11）の
   上位版: 今回はキー一覧の同期漏れでなく**契約自体の不存在**

## 4. Act / Prevention Strategy (Fix)
- **供給を増やす（本命）**: kintone_shot CATALOG に5キー追加（app_process / app_reminder /
  app_customize / csv_import_upload / csv_import_mapping — 全てPlaywrightプローブ実測後に登録。
  trigger=timer や /k/admin/app/js 等の推測URLは実際に外れた）+ 製品課devtestアプリ再利用の
  capture_product（plugin_config / plugin_applied_list — BOOTH検証用に既に存在した実画面資産を
  記事レーンへ配線）。CSVマッピングは対象アプリの実フィールド・実レコードからCSVを決定論生成して
  実投入（プレビューはShift-JIS既定 — CP932で書かないと文字化けする実測知見）
- **生産側に契約を注入**: researcher factsheet_template に「SS指定の契約」節（指定可キー一覧+
  撮影不可リスト=外部ツールUI/モバイル/AI管理画面はSS指定禁止・図解指定にする）
- **検閲側の執行基準を実能力に接地**: reviewer checklist に「Q05/Q09で実画面必須として裁くのは
  撮影可能な画面のみ。撮影不可画面は文章+概念図解の代替を減点しない（UI風モックアップは従来
  どおりfail）」を明記
- **予防ルール（横展開可能な一般形）**:
  1. 多段エージェント分業では、**上流の「指定」は下流の「実行能力」との明示的契約に載せる**
     （自由記述の指示は能力表(カタログ)への参照を必須にする）
  2. 検閲者の合格条件は「理想」でなく「システムの実行可能集合」に接地する — さもないと
     再試行ループが罰にしかならない
  3. テンプレの例文は契約内の実例にする（例文はエージェントが最も模倣する仕様）
  4. 同型停滞が2回連続で自動再試行で解消しない時は、ラウンド消費でなく**契約の矛盾**を疑う
     （ops-auditorの「3回連続報告・改稿ループでは解消していない可能性が高い」が正しかった）
- 関連: [[uc-real-but-unrelated-screenshots.md]]（本物だが無関係な画面）/
  [[uc-tutorial-images-must-cover-every-step.md]]（手順=実画面の原則の由来）/
  [[llm-dsl-single-line-flattening-breaks-parser.md]]（カタログ消費側同期）
