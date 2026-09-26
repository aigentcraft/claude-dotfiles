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
- **同一性には「どう作られたか（経路・品質）」も含める**（2026-09-25）: 代用品（フォールバック）を「揃っている」と数えると、
  待機・作り直しの仕組みがあっても代用品がそのまま出る。再試行するキューには順番を回す仕組み（直近の試行を後ろへ）を付ける
  — [[../nodes/resumed-article-reused-fallback-images.md]]
- **グレース（止めずに続行）で「完了」の記録を書かない / 関門は原因ではなく結果で書く**（2026-09-26）:
  図の担当の企画失敗を「描き終えた」と記録し、画像 0 枚・簡易版のまま承認依頼が 4 本出た。「上限なら待つ」という原因側の
  条件は別の原因を通す — 公開の手前で**成果物そのもの**（本文の参照 + manifest の経路）を数える
  — [[../nodes/uc-approval-requested-with-non-gpt-images.md]]

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
| 生成物を作り直す道具を書く | R8: 公開中のものが変わったかを本番で数える |

## このクラスターのノード一覧

- [[../nodes/image-reuse-by-section-index-after-restructure.md]] — `images`, `idempotency`, `pipeline`, `caption-mismatch`
- [[../nodes/stale-pipeline-lock-after-killed-run.md]] — `lock`, `pipeline`, `resume`, `windows`
- [[../nodes/preview-built-published-md-instead-of-rewrite-draft.md]] — `preview`, `rewrite-lane`, `stale-artifact`（検査対象は常に今回の成果物に固定）
- [[../nodes/researcher-hard-timeout-killed-after-measurements-done.md]] — `timeout`, `retry`, `resume`（リトライには前回成果物からの再開指示を入れる）
- [[../nodes/feedback-with-no-address-never-arrives.md]] — `feedback-loop`, `sendback`, `infinite-loop`, `materials`（宛先の無い指摘は届かない・材料が無いと LLM は嘘で埋める）
- [[../nodes/resumed-article-reused-fallback-images.md]] — `reuse`, `fallback`, `queue-starvation`（代用品を「揃っている」と数えない・キューの順番を回す）
- [[../nodes/regenerated-images-never-reached-live-site.md]] — `deploy`, `silent-failure`, `image-generation`, `usage-limit`（作り直しても本番に出ない・本番を数える）
- [[../nodes/uc-approval-requested-with-non-gpt-images.md]] — `uc`, `fallback`, `grace`, `human-in-the-loop`（グレースで完了を書かない・関門は結果で書く・押す場所へのリンク）

### R7: 冪等判定と commit は「自分が出すパス」だけで閉じる — インデックス全体を見ない
「差分があれば commit」の差分判定と `git commit -m` がインデックス全体を見ると、
**その作業ツリーで他人がステージしていた変更**を自分の件名で commit・push する。
`git add` をパス個別指定にしても防げない（commit 側が全部載せる）。
- 例: weevee の記事公開が、前セッションのステージ済み修理 約 900 行を `post: <記事名>` で main に push した
  （[[../nodes/publish-commit-sweeps-foreign-staged-changes.md]]）。全体判定は R の冪等化修理
  （[[../nodes/publish-worker-not-idempotent-after-push.md]]）で入ったもの — **冪等化が巻き込みの経路を開いた**
- 例2（2026-09-23 判明）: 移植元の pullie でも 2026-08-19 に `da92463 post: …` が手動セッションの 12 ファイルを
  巻き込んでいた。当時は「競合（タイミング）」と診断して**人間側が気をつける**で閉じ、公開側を直さなかった
  → 移植先で同じ事故が再発した。**巻き込みは「気をつける」で閉じず、外に出る層の範囲を直す**
- 自動 commit は `git diff --cached --quiet -- <paths>` + `git commit --only -m <msg> -- <paths>`
- **`--only` に渡すのは差分のあるパスだけ**（パスごとに判定する）。git が一度も見ていないパス
  （全部掃除された新規の空フォルダ）を渡すと pathspec エラーで公開ごと落ちる — 旧コードの `commit -m` は落ちなかった
- 作業インデックスに一切触れたくないなら `GIT_INDEX_FILE` の一時インデックス + `commit-tree`
- テストは本物の git で「push された中身」を数える（一時リポジトリ + bare origin）


### R8: 修理の経路は「公開の経路」まで通して完了とする — 手元の成果物・記録は証拠にならない
作り直しの道具が書き換えるのが下書きと作業フォルダだけなら、**公開中のものは何度直しても変わらない**。
記録（manifest・ログ）は「直した」と言い、本番だけが古いまま — 誰も気づかない。
- 例: weevee の画像の作り直しキューは、公開中の記事の図を GPT で描き直しても commit・push せず、
  「端で切れた図」の直し（9/21〜22）も週上限中に簡易版で公開された 4 本（9/23〜24）も本番に出ていなかった
  （[[../nodes/regenerated-images-never-reached-live-site.md]]）
- 反映の段は「変わった部分だけ」「書き直し中の下書きを混ぜない判定つき」で持つ（見出し・本文の一致）
- 成果チェックは **本番（HEAD の記録 / 配信 URL）** を数える。手元の記録を数えると同じ食い違いを見落とす
- 作り直しの順番は「いま読者に見えているもの」を先に

### R-LOOP: ループの上限は「効くこと」を実データで確かめる
上限のコードがあることと、上限が効くことは別。特に**数え方の起点が動く**実装
（「最後の○○以降を数える」）は、その○○を別の主体が書けると上限が毎回リセットされる。
- 「新しいサイクルの開始」を表す印を、AI側の差し戻しに流用しない
- 「再試行で直る」に分類する前に、**その再実行が決定論かどうか**を見る。
  同じ入力から同じ出力が出る工程を retry に分類すると無限に投げ続ける
- **本来の上限ではない別の上限（コスト・時間・API制限）で止まったなら、
  設計した上限は効いていない**。実測: 1記事が9時間で27回書き直し・LLM 188回
- 詳細: [[../nodes/gate-rejection-recorded-as-human-sendback-reset-the-limit.md]]


### R-UNFIXABLE: 「書き直しで直るか」を判定に持たないループは終わらない
再実行の判断材料が合否だけだと、**原理的に直らない不合格**でも回り続ける。
- 検閲役は毎ラウンド「構造的制約であり差し戻しでは解消しない」と書いていたが、
  その講評は人間が読む文章としてしか保存されず、制御に使われていなかった
  （[[../nodes/reviewer-says-unfixable-but-loop-keeps-retrying.md]]）
- 同じ考え方は撮影失敗で一度適用済み（決定論的に同じ結果になるものを再試行対象から外す）。
  **検閲の講評へ広げていなかった**
- 併発する型: 「この断定を消せ」という指示だけ渡すと、事実を持たない書き手は
  **別の未確認の断定で穴を埋める**（指摘箇所が毎回入れ替わる）
