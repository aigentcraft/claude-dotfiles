# Cluster: 可観測性（計測・記録・監視材料）

> Layer 1 Community Summary — 関連ノードの蒸留サマリー。
> ログ・思考記録・監視材料・完走検査など「システムが自分の状態をどう残すか」を
> 実装・変更する時にロードする。
>
> このクラスターの故障は**症状が出ない**のが共通点。計測の欠落は静かで、
> 気づいた時には調べる材料が残っていない。

**対象タグ**: `observability`, `monitoring`, `logging`, `data-loss`, `silent-failure`,
`false-alarm`, `watchdog`

---

## 蒸留ルール（Distilled Rules）

### R1: 記録・計測は「失敗パス」から先に書く
成功時のログは「動いている」ことしか教えない。調査に要るのは失敗時の中身。
`if result.ok:` の中だけで記録していないか、関数の出口で確認する。
**失敗を表す戻り値が中身（events・レスポンス・中間状態）を持っているなら、
それは捨てる前提の設計ではない。**
- 詳細: [[../nodes/success-only-logging-and-overwrite-discard-history.md]]

### R2: `UPDATE ... SET col=?` を書く前に、そのキーが一意か実測する
キーが使い回されると、上書きは**エラーを出さずに履歴を消す**（成功しながら消える）。
使い回されるキーなら追記（`COALESCE(col,'') || ?`）にし、
「どの試行のものか」を見出しで判別できるようにする。
- 詳細: [[../nodes/success-only-logging-and-overwrite-discard-history.md]]

### R3: 監視材料に集計値だけを出さない — 分布を出す
`MAX()` / `COUNT()` は分布を潰す。潰れた材料を渡された監査役は、
見えない部分を推測で埋めて断定する（誤警報の発生源）。
oldest/newest・件数の内訳・母集団を添えて、分布のまま渡す。
- 詳細: [[../nodes/aggregate-material-collapses-distribution.md]]

### R4: 監視材料に「結論」を書き込まない
列の意味と仕様の説明までが材料。「＝正常」「〜だけ」と書いた時点で、
監査役は自分で見る前に結論を渡されている。判断は担当者の仕事。
- 関連: [[ai-behavior.md]] R18 / [[../nodes/uc-hardcoded-judgment-while-fixing-hardcoding.md]]

### R4b: 欠損（NULL）と観測値ゼロを、集計の時点で分ける
`COALESCE(x, 0)` を書く前に問う — その NULL は「0だった」のか「測っていない」のか。
後者を 0 にすると、**観測していない事実が最も強い否定証拠の見た目**をまとう。
集計は `SUM(値)` と `SUM(値 IS NOT NULL)` を必ず並べ、未計測は数値ではなく**状態**で出す。
「N件中M件が反応ゼロ」と書く前に、分母のうち何件が計測済みかを出すこと。
- **計画書・設計文書の数値も検証対象**。前提として引く前に自分で再現する
  （正しい設計思想が、汚染された数値を根拠に持っていることがある）
- 詳細: [[../nodes/unmeasured-counted-as-zero-fabricates-rejection-evidence.md]]

### R5: 通知役が道連れになる障害は、外側から完走を検査する
プロセスが即死する終わり方では、通知役自身も一緒に消える。
その場合**「エラー通知が来ないこと」が唯一の症状**になり、ログには何も出ない。
「開始した記録」と「完了した記録」を別々に書き、**次の実行が前回を検査する**。
- 詳細: [[../nodes/task-time-limit-kills-run-and-its-own-alarm.md]]

### R6: 自律判断へ移行する前に、失敗の記録を直す
判断させる移行では**失敗が仕事の一部**になる。思考が残らない状態で始めると、
うまくいかない時に原因を推測でしか語れず、作り直しになる。
計測 → 移行 の順を崩さない。
- 詳細: [[../nodes/success-only-logging-and-overwrite-discard-history.md]]
