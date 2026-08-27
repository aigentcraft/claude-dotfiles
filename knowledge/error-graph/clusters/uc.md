# Cluster: UC — 検品・自己学習・媒体目的の人間指摘系

> Layer 1 Community Summary — 関連ノードの蒸留サマリー。
> pullie等の自動運営システムで「人間に指摘されて初めて発覚した」構造欠陥のクラスター。
> 検品ゲート・可視化・エージェント学習ループの設計時にロードする。個別詳細は nodes/ を参照。

**対象タグ**: `user-correction`, `visual-inspection`, `verification`, `approval-flow`, `vision-review`

---

## 蒸留ルール（Distilled Rules）

### R1: 検品は「欠陥が発現する条件」をカバーして初めて1層と数える
層の数ではなく条件のカバレッジ。読者はスマホでも読む・最終状態を見る・白ページに合成して見る。
- 詳細: [[../nodes/uc-inspection-must-match-reader-conditions.md]]

### R2: 決定論で測れる欠陥はLLM目視の手前に決定論ゲートを置く
opacity残留・画像欠落・背景色・アルファ・外周余白はコードで測れる。LLMの目視は本体に
引っ張られ、地（キャンバス・余白）の異常をデザインと誤認する。
- 詳細: [[../nodes/image-dark-canvas-margin-passes-vision-review.md]]

### R3: グレース（欠損許容）は下流に欠損検査ゲートとペアでのみ安全
「なしで続行」した欠損を下流の誰も検査しないと、欠損のまま承認・公開まで流れる。
- 詳細: [[../nodes/uc-inspection-must-match-reader-conditions.md]]

### R4: 失敗作は消さず退避し、本人へ教訓として還流する
作り直しループだけでは癖が直らない。不合格の実物+理由を保存→定期的に教訓へ昇格→注入。
- 詳細: [[../nodes/uc-agents-must-learn-from-own-failed-work.md]]

### R5: 媒体の存在目的（受注・ポジショニング）は実行層のSKILLまで落とす
上位ドキュメントに書いただけのルールは生成物に現れない。
- 詳細: [[../nodes/uc-articles-must-carry-own-positioning.md]]

### R6: 可視化要求は「何を発見したいか（監査目的）」を先に確認する
集計サマリーは監査に無力。異常を1件ずつ辿れる粒度で設計し、可視化物も実走検証する。
- 詳細: [[../nodes/uc-visualization-without-audit-purpose.md]]

### R7: 人間への通知は判断を変える状態文脈（新規か更新か）まで運ぶ
システムだけが知る文脈を文面から省くと、正常動作が異常（重複・暴走）に見える。
新レーンが既存の人間接点（承認・通知）に合流する時は、文面がそのレーンを表現できるかまで点検する。
- 詳細: [[../nodes/uc-rewrite-approval-must-declare-itself.md]]

### R8: 方向が意味を持つデータはLLM要約器に渡す前に方向を値へ焼き込む
LLMは曖昧さを成果が大きく見える方向に解消する（自己報告の粉飾バイアス）。送り/受けの語彙は
契約で固定し、監査は「記録の実在」でなく「主張の文言」単位で一次データと突き合わせる。
- 詳細: [[../nodes/uc-activity-report-inverted-engagement-direction.md]]

### R9: 人間宛ての依頼には「その人の受信環境で開ける URL」を載せる
ローカルパスやコマンドはスマホの Discord では開けない。承認依頼＝人間が実物を見る接点なので、
プレビューデプロイ等の公開 URL を必須にし、ローカル情報は補足に留める。
「前提 X が未完了だから後回し」とした実装は、X の完了をトリガーに再評価する。
- 詳細: [[../nodes/uc-approval-request-local-path-instead-of-url.md]]

## このクラスターのノード一覧

- [[../nodes/uc-approval-request-local-path-instead-of-url.md]] — `user-correction`, `hitl`, `approval-flow`, `stale-assumption`
