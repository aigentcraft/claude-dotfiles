# Cluster: パイプラインの冪等性（再利用・スキップ判定）

> Layer 1 Community Summary — 関連ノードの蒸留サマリー。
> 「成果物があれば再生成しない」「途中再開」など、冪等スキップ／再利用を実装・変更する時にロードする。

**対象タグ**: `idempotency`, `images`, `pipeline`, `caption-mismatch`, `resume`, `lock`

---

## 蒸留ルール（Distilled Rules）

### R1: 冪等スキップの条件は「成果物の同一性」で判定する
位置・連番・ファイル存在だけを再利用の根拠にしない。成果物が「何から作られたか」（見出し・種別・入力ハッシュ）をマニフェストに残し、一致した時だけ再利用する。
マニフェストが無い旧世代の成果物は再利用しない（安全側に倒す）。
- 詳細: [[../nodes/image-reuse-by-section-index-after-restructure.md]]

### R2: 構成が変わる経路（差し戻し再執筆・リライト）で再利用ロジックを必ず通す
冪等性は「入力が変わらない」前提で作られがち。差し戻し再執筆は章構成が変わる典型ケースなので、その経路で「新メタデータ + 旧成果物」の不一致が起きないかを実走で確認する。

### R3: 参照が外れた成果物は掃除する
番号がずれた旧ファイルを残すと、次回の再利用判定や重複検知・プレビュー配信を汚染する。参照集合に無いものは削除。

### R4: ロック/リースの残骸は「所有者の生存」で判定する（年齢は二次条件）
kill・クラッシュは年齢ゼロのロックを残す。pid を保存しているなら生存確認に使う。Windows で `os.kill(pid, 0)` は TerminateProcess になるため `tasklist`/psutil を使う。
- 詳細: [[../nodes/stale-pipeline-lock-after-killed-run.md]]

---

## 状況 → ルール

| 状況 | 適用するルール |
|---|---|
| 「既存ファイルがあればスキップ」を書く | R1: 同一性キー（マニフェスト）で判定 |
| 差し戻し／リライトで章構成が変わる | R2: 再利用経路を実走確認 |
| 生成物のファイル名に連番を使う | R3: 参照外の連番ファイルを掃除 |
| ロックファイル/リースの残骸判定を書く | R4: 所有 pid の生存確認を一次条件に |

## このクラスターのノード一覧

- [[../nodes/image-reuse-by-section-index-after-restructure.md]] — `images`, `idempotency`, `pipeline`, `caption-mismatch`
- [[../nodes/stale-pipeline-lock-after-killed-run.md]] — `lock`, `pipeline`, `resume`, `windows`
- [[../nodes/preview-built-published-md-instead-of-rewrite-draft.md]] — `preview`, `rewrite-lane`, `stale-artifact`（検査対象は常に今回の成果物に固定）
- [[../nodes/researcher-hard-timeout-killed-after-measurements-done.md]] — `timeout`, `retry`, `resume`（リトライには前回成果物からの再開指示を入れる）
