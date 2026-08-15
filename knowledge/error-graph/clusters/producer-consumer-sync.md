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

### R2: 「表示されていない」の一次切り分けは「データは存在するか」
プレースホルダ・空欄・画像なしを検知したら、先にデータ実在を確認する。
- データあり×表示なし ＝ コード欠陥（修正レーン・high）
- データなし ＝ コンテンツ課題（企画/design助言）
誤診すると検知済み欠陥が知見DBに沈み、人間の指摘まで直らない。

---

## クイック参照テーブル

| 状況 | 適用するルール |
|---|---|
| コンテンツコレクションのschemaにフィールド追加 | R1: getCollection消費側を全grep |
| カタログ/キー一覧/enumに項目追加 | R1: 参照SKILL.md・skill_refsを全grep |
| 検分・監査で「プレースホルダのまま」を発見 | R2: データ実在を先に確認して分類 |
