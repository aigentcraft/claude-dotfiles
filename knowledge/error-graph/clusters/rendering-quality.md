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

---

## 状況 → ルール

| 状況 | 適用するルール |
|---|---|
| 情報図テンプレートの文字/余白を調整する | R1 + R2 |
| 承認プレビュー・公開前ゲートを設計する | R3 |

## このクラスターのノード一覧

- [[../nodes/infographic-text-clipped-in-narrow-cards.md]] — `rendering`, `infographic`, `overflow`, `self-verification`
- [[../nodes/uc-article-image-cropped-caption-overlap.md]] — `user-correction`, `images`, `captions`, `preview`
