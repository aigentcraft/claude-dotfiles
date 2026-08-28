# Cluster: プロデューサー/コンシューマー同期漏れ

> Layer 1 Community Summary — 関連ノードの蒸留サマリー。
> スキーマ・カタログ・enum・キー一覧など「定義を作る側」と「参照する側」が
> 分かれている構造を拡張する時にロードする。

**対象タグ**: `producer-consumer-sync`, `schema-sync`, `skill-sync`, `renderer`, `catalog`

---

## 蒸留ルール（Distilled Rules）

### R1: 定義の拡張は「消費側の全数同期」まで1コミット
カタログ・スキーマ・frontmatterフィールド・enum・キー一覧を拡張したら、
それを参照する**全消費側**（レンダラー・SKILL.md・skill_refs・バリデーション）を
grepで洗い出し、同一コミット内で結線または明示的に対象外と記録する。
- 消費側が2箇所以上ある定義は特に危険 — 「1箇所直して満足」が定型の事故
- 例1: kintone_shotカタログ拡張 → writer SKILL.mdキー一覧未同期 → 偽UI図解量産
  （[[../nodes/catalog-key-added-without-consumer-sync.md]]）
- 例2: heroImage追加 → /articles/ のみ結線・トップページ未結線 → 本番プレースホルダ露出
  （[[../nodes/frontmatter-field-not-wired-into-all-renderers.md]]）
- 例3: reviewer checklist が ng_phrases.md を引用 → reviewer manifest の skill_refs に未同梱 →
  LLM が「手元にないため部分照合」と自己申告して静かに劣化（rc=0・NGなし）
  （[[../nodes/checklist-references-file-not-in-skill-refs.md]]）
  → **プロンプト/checklist で `xxx.md` を引用したら、そのエージェントの manifest に同梱されているか grep で確認する**

### R2: 「表示されていない」の一次切り分けは「データは存在するか」
プレースホルダ・空欄・画像なしを検知したら、先にデータ実在を確認する。
- データあり×表示なし ＝ コード欠陥（修正レーン・high）
- データなし ＝ コンテンツ課題（企画/design助言）
誤診すると検知済み欠陥が知見DBに沈み、人間の指摘まで直らない。

### R3: 時間軸のproducer-consumer — 収集が付ける日付と集計窓の交差を検証する
データを書く側（コレクタ）と読む側（レポート・学習）が分かれている時は、
書く側のタイムスタンプが読む側の窓に**実際に入る**ことをデータで確認するまで結線完了としない。
- 「レポート直前に収集」は収集日付=当日・窓=過去で全量窓外になる定型の罠
- 周期ジョブの二重実行ガードは**暦単位**（日/ISO週/年月）で切る。「直近N日」窓は
  週途中の初回・手動実行で定時スロットと位相ズレし、次周期まるごとスキップする
  （[[../nodes/weekly-guard-day-window-phase-skip.md]]）
- `last_at`型の増分窓の後付けは、実装前に発生済みのイベントを永久に取りこぼす
  （遡及するか「過去分は捨てる」と明示記録するかを設計時に決める）
- 観測の周期は成果物の発生周期・初速の時間スケールに合わせる（週2公開に週1観測は不整合）
- 例: note KPIが週1収集×窓外日付で、不振の検知が最大2週遅れた
  （[[../nodes/note-kpi-weekly-cadence-window-blind-spot.md]]）

### R4: 消費側の窓に供給し続ける義務 — 公平キューは「巡回目的の時刻」でソートする
コンシューマが「直近N日の観測」等の鮮度窓で読む時、プロデューサの巡回ローテは
その窓を満たし続ける責務を負う。ソートキーに**別レーンの実績時刻**（例: engage時刻）を
流用すると、条件を永遠に満たさないメンバー（engage不可アカウント等）がNULL最優先で
全枠を独占し、消費側が静かに枯れる（starvation）。
- 共有予算を複数セクションが先着順で食う設計も同型 — セクション別の床/天井を機械で切る
- 「対象0件でスキップ」の正常系ゼロはrc=0で失敗監視に乗らない。ゼロ継続を活動量異常として
  拾う経路（ops-auditor）を設計時に確認する
- 例: X観測ローテがcandidate22件に独占され、いいね/リプが8/26に完全停止
  （[[../nodes/rotation-starvation-by-unengageable-accounts.md]]）

---

## クイック参照テーブル

| 状況 | 適用するルール |
|---|---|
| コンテンツコレクションのschemaにフィールド追加 | R1: getCollection消費側を全grep |
| カタログ/キー一覧/enumに項目追加 | R1: 参照SKILL.md・skill_refsを全grep |
| 検分・監査で「プレースホルダのまま」を発見 | R2: データ実在を先に確認して分類 |
| agent.md / checklist / SKILL.md で参照ファイルを引用 | R1: 引用先エージェントの manifest skill_refs を grep で照合 |
| LLM 出力に「手元にない」「参照できない」が含まれる | R1: 供給欠落として扱い manifest を修正 |
