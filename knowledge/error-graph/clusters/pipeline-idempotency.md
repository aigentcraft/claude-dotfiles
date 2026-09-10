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

### R5: 記録した指摘は「誰がいつ読むか」まで辿ってから完了とする
DB に入れた ≠ 届いた。空の鍵（`run_id=''`）で入れた行は後から束ね直せず、静かに孤立する。
検出側を書いたら、受け取り側で実際に文字列が現れることをテストで固定する。
同じ差し戻しが 3 ラウンド続いたら「直せていない」ではなく「届いていない」を疑う。
- 詳細: [[../nodes/feedback-with-no-address-never-arrives.md]]

### R6: エージェントに何かをさせるなら、必要な材料が渡っているかを先に実測する
指示（SKILL.md）と材料（work dir のファイル）は別物。指示だけ足すと LLM は
もっともらしい嘘で穴を埋める（存在しない slug・存在しない記事の紹介文）。
- 詳細: [[../nodes/feedback-with-no-address-never-arrives.md]]

---

## 状況 → ルール

| 状況 | 適用するルール |
|---|---|
| 「既存ファイルがあればスキップ」を書く | R1: 同一性キー（マニフェスト）で判定 |
| 差し戻し／リライトで章構成が変わる | R2: 再利用経路を実走確認 |
| 生成物のファイル名に連番を使う | R3: 参照外の連番ファイルを掃除 |
| ロックファイル/リースの残骸判定を書く | R4: 所有 pid の生存確認を一次条件に |
| 検査結果・差し戻し理由を DB に記録する | R5: 受け取り側で現れることをテストで固定 |
| エージェントに新しい作業を指示する | R6: 材料が work dir に届いているか実測 |

## このクラスターのノード一覧

- [[../nodes/image-reuse-by-section-index-after-restructure.md]] — `images`, `idempotency`, `pipeline`, `caption-mismatch`
- [[../nodes/stale-pipeline-lock-after-killed-run.md]] — `lock`, `pipeline`, `resume`, `windows`
- [[../nodes/preview-built-published-md-instead-of-rewrite-draft.md]] — `preview`, `rewrite-lane`, `stale-artifact`（検査対象は常に今回の成果物に固定）
- [[../nodes/researcher-hard-timeout-killed-after-measurements-done.md]] — `timeout`, `retry`, `resume`（リトライには前回成果物からの再開指示を入れる）
- [[../nodes/feedback-with-no-address-never-arrives.md]] — `feedback-loop`, `sendback`, `infinite-loop`, `materials`（宛先の無い指摘は届かない・材料が無いと LLM は嘘で埋める）

### R-LOOP: ループの上限は「効くこと」を実データで確かめる
上限のコードがあることと、上限が効くことは別。特に**数え方の起点が動く**実装
（「最後の○○以降を数える」）は、その○○を別の主体が書けると上限が毎回リセットされる。
- 「新しいサイクルの開始」を表す印を、AI側の差し戻しに流用しない
- 「再試行で直る」に分類する前に、**その再実行が決定論かどうか**を見る。
  同じ入力から同じ出力が出る工程を retry に分類すると無限に投げ続ける
- **本来の上限ではない別の上限（コスト・時間・API制限）で止まったなら、
  設計した上限は効いていない**。実測: 1記事が9時間で27回書き直し・LLM 188回
- 詳細: [[../nodes/gate-rejection-recorded-as-human-sendback-reset-the-limit.md]]
