# Cluster: 決定論レンダリングの自己検証（情報図・プレビュー）

> Layer 1 Community Summary — 関連ノードの蒸留サマリー。
> HTML→PNG の情報図やレンダリング済みページなど「機械が描いた見た目」を人に見せる前の検査を設計する時にロードする。

**対象タグ**: `rendering`, `infographic`, `overflow`, `self-verification`, `images`

---

## 蒸留ルール（Distilled Rules）

### R1: 描画器は自分の出力を測る（overflow・切り抜き・重なり）
決定論描画でも「入るかどうか」は内容依存。描画後に要素の scrollWidth/Height・境界突出を数え、NG なら縮小版で描き直す。目視待ちにしない。
- 詳細: [[../nodes/infographic-text-clipped-in-narrow-cards.md]]

### R2: 文字サイズの変更は最も狭いレイアウトで確認する
最大列数・最長トークン（環境変数名・URL）を含むサンプルで描く。`overflow-wrap:anywhere` を先に付ける。

### R3: 人に見た目を承認させる前に、機械が見た目を検査する
ファイル検査（寸法・重複）は HTML/CSS 層の破綻を検出できない。実ブラウザで矩形を測る。
- 詳細: [[../nodes/uc-article-image-cropped-caption-overlap.md]]

### R4: 生成物のラベル（出所・エンジン）は実際の経路から導出する
「高品質な経路で作った」と書く文字列を定数にしない。実経路を表す変数から機械的に導出し、
不明なら**何も書かない**。ラベルは下流（検閲・人間）の判断材料なので、
**嘘のラベルは品質ゲートを迂回させる**。
- 詳細: [[../nodes/uc-silent-fallback-labeled-as-gpt.md]]

### R5: 高品質経路 → 決定論フォールバックの二段構えは、落ちたことを必ず可視化する
フォールバックが正しく働くほど、上流の全滅が「正常」に見える。
エンジン内訳（高品質 n / フォールバック m）をイベントに出し、比率が閾値を超えたら通知する。
生成器の健全性は成功率の平均でなく**「最後に成功した時刻」**で見る。
- 詳細: [[../nodes/uc-silent-fallback-labeled-as-gpt.md]] / [[observability.md]] R8

---

## 状況 → ルール

| 状況 | 適用するルール |
|---|---|
| 情報図テンプレートの文字/余白を調整する | R1 + R2 |
| 承認プレビュー・公開前ゲートを設計する | R3 |
| 画像・図の「出所」を検閲や記事に出す | R4 |
| 生成エンジンにフォールバックを付ける | R5 |

## このクラスターのノード一覧

- [[../nodes/infographic-text-clipped-in-narrow-cards.md]] — `rendering`, `infographic`, `overflow`, `self-verification`
- [[../nodes/uc-article-image-cropped-caption-overlap.md]] — `user-correction`, `images`, `captions`, `preview`
- [[../nodes/uc-silent-fallback-labeled-as-gpt.md]] — `uc`, `images`, `imagegen`, `fallback`, `silent-failure`, `labeling`, `self-healing`
