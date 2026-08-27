# GSAP アニメーション基礎 — 100 種ギャラリーの蓄積（参照: codequest.work）

> 出典: https://codequest.work/generator/gsap-animation-gallery/ （GSAPアニメーション サンプル集 100種｜ScrollTriggerもコピペで動く）
> 取得日: 2026-08-27 / GSAP 3.13 想定。**有料プラグインを使わず標準機能だけで再現**している点が学びの核（SplitText 相当は素の JS で文字分割、DrawSVG 相当は stroke-dasharray/dashoffset、MorphSVG 相当は polygon 頂点補間）。
> 用途: モーション実装の前に、目的の演出をこの一覧から探して「パラメータごと」写す（error-graph uc クラスター R14: モーションも参照駆動）。gsap.com 公式デモと併用。

## 使い方の原則（ページの解説から）
- 基本は `to` / `from` / `fromTo`。`from()` は「今の見た目」をゴールにして指定状態から動かす
- 複数の動きは `gsap.timeline()` で繋ぐ（ラベル・入れ子・再生制御・速度変更・シーク）
- スクロール連動は `ScrollTrigger`（`scrub` / `pin` / `snap` / `batch` / `toggleClass` / `markers`）。ページ全体をスクロール対象とする通常の書き方でそのまま使える
- 読み込むのは `gsap.min.js` と、必要な場合のみ `ScrollTrigger.min.js` / `Draggable.min.js`
- 弾む印象 = `back.out(1.7)`（行き過ぎて戻る）、滑らかな減速 = `power3.out`、往復 = `yoyo: true, repeat: -1`、等速ループ = `ease: "none"`

## 早見表: 目的 → サンプル key（このギャラリーで探す時の索引）
| やりたいこと | key |
|---|---|
| 要素をふわっと出す / 弾んで出す / ぼかしから | `fade-up` / `fade-scale`（back.out(1.7)）/ `blur-in` |
| 複数要素を順番に出す（リスト・格子・端から）/ ランダムに散らばる | `stagger-list` / `stagger-grid` / `stagger-edges` / `random-scatter` |
| 動きの質を比べる / キーフレーム / 往復 | `ease-compare` / `keyframes` / `repeat-yoyo` |
| 一連の動きを繋ぐ・制御する | `tl-sequence` / `tl-labels` / `tl-nested` / `tl-control` / `tl-timescale` / `tl-seek` / `tl-callbacks` |
| ヒーローの登場演出 / ホバーで小さな連鎖 | `tl-hero` / `tl-hover` |
| 無限に流す（マーキー）/ ループ | `tl-marquee` / `tx-marquee` / `sa-marquee-dir` / `tl-loop` |
| スクロールで出現 / 1 回だけ / 段階出現 / クラス付与 | `st-fade` / `st-once` / `st-stagger` / `st-classes` / `st-toggle` |
| スクロール進捗に連動（scrub）/ プログレス / パララックス / 奥行き | `st-scrub` / `st-progress` / `sa-progress-circle` / `st-parallax` / `st-depth` |
| スクロールで固定して見せる / スナップ / ヘッダー変化 / セクション色 | `sa-pin-text` / `st-snap` / `st-header` / `sa-section-color` |
| 縦スクロールで横に流す / カードが重なる / 扇状 / コマ送り / 突き抜けズーム | `sa-horizontal` / `sa-stack-cards` / `sa-card-fan` / `sa-frames` / `sa-zoom-through` |
| 読了ハイライト / 目次連動 / 分割して開く | `sa-text-highlight` / `sa-toc` / `sa-split-open` |
| 文字を 1 文字ずつ / 単語ごと / 行マスク / タイプライター / シャッフル / グリッチ | `tx-chars` / `tx-words` / `tx-mask-lines` / `tx-typewriter` / `tx-scramble` / `tx-glitch` |
| 数値カウントアップ / 通貨表示 / 単語ローテーション / 波打つ文字 | `tx-counter` / `sa-counter` / `tx-currency` / `tx-rotate-words` / `tx-wave` |
| SVG の線を描く / チェック / 矢印 / 署名 / 波 / 進捗リング | `svg-draw` / `svg-check` / `svg-arrow` / `svg-signature` / `svg-wave` / `svg-progress` |
| 図形の変形 / ブロブ / 棒グラフ / 折れ線 / 経路に沿う点 | `svg-morph` / `svg-blob` / `svg-bar` / `svg-line-chart` / `svg-dot-path` |
| 磁石ボタン / カーソル追従 / チルト / ドラッグ / リップル / シェイク | `ix-magnetic` / `ix-cursor` / `ix-tilt` / `ix-drag` / `ix-ripple` / `ix-shake` |
| アコーディオン / メニュー / モーダル / 画像比較 / コピー完了 | `ix-accordion` / `ix-menu` / `ix-modal` / `ix-compare` / `ix-copy` |
| 3D フリップ / クリップで現す / 斜め・回転で入る / 弧を描いて移動 | `flip-3d` / `clip-reveal` / `skew-in` / `rotate-in` / `arc-move` |

## カテゴリ一覧（100 種）

### 基本トゥイーン（16種）

| key | 名前 | 要点（最初の GSAP 呼び出し） |
|---|---|---|
| `fade-up` | フェードアップ | `gsap.from(".box", { y: 64, opacity: 0, duration: 0.9, ease: "power3.out", });` |
| `fade-scale` | フェード＋拡大 | `gsap.from(".box", { scale: 0.6, opacity: 0, duration: 0.8, ease: "back.out(1.7)", });` |
| `slide-in` | 左右からスライドイン | `gsap.from(".row-l", { x: -120, opacity: 0, duration: 0.8, ease: "power3.out" });` |
| `stagger-grid` | スタガー（中央から順に） | `gsap.from(".sq", { scale: 0, opacity: 0, duration: 0.5, ease: "back.out(1.7)", stagger: { each: …` |
| `stagger-list` | リストを順に表示 | `gsap.from(".li-list li", { x: -28, opacity: 0, duration: 0.5, ease: "power2.out", stagger: 0.09,…` |
| `ease-compare` | イージング比較（4種） | `gsap.fromTo(".ball", { x: 0 }, { x: 240, duration: 1.4, ease: "power2.out" } );` |
| `rotate-in` | 回転しながら登場 | `gsap.from(".rot", { rotation: -180, scale: 0.2, opacity: 0, duration: 1, ease: "power4.out", });` |
| `flip-3d` | 3Dフリップ | `gsap.from(".flip-el", { rotationY: 90, opacity: 0, duration: 1, ease: "power3.out", transformOri…` |
| `repeat-yoyo` | 往復し続ける（repeat / yoyo） | `gsap.to(".yo-dot", { y: -26, duration: 0.45, ease: "power1.inOut", repeat: -1, yoyo: true, stagg…` |
| `keyframes` | キーフレーム（多段の動き） | `gsap.to(".kf", { keyframes: [ { x: -70, duration: 0.5 }, { y: -46, rotation: 180, duration: 0.5 …` |
| `blur-in` | ぼかしから鮮明になる | `gsap.from(".bl", { filter: "blur(14px)", opacity: 0, scale: 1.15, duration: 1, ease: "power2.out…` |
| `skew-in` | 傾きながらスライドイン | `gsap.from(".sk-row", { x: -90, skewX: 22, opacity: 0, duration: 0.7, ease: "power3.out", stagger…` |
| `random-scatter` | ランダムに散らばって整列 | `gsap.from(".rs-cell", { x: () => gsap.utils.random(-140, 140), y: () => gsap.utils.random(-90, 9…` |
| `clip-reveal` | クリップで開く | `gsap.from(".cr", { clipPath: "inset(0 100% 0 0)", duration: 1, ease: "power3.inOut", });` |
| `arc-move` | 弧を描いて移動 | `gsap.fromTo(".am-ball", { x: 0 }, { x: 280, duration: 1.4, ease: "none" });` |
| `stagger-edges` | 端から中央へ集まる | `gsap.from(".se-bar", { scaleY: 0, opacity: 0, transformOrigin: "center center", duration: 0.6, e…` |

### タイムライン（12種）

| key | 名前 | 要点（最初の GSAP 呼び出し） |
|---|---|---|
| `tl-sequence` | 順次再生（重ねて繋ぐ） | `gsap.timeline({ defaults: { ease: "power3.out", duration: 0.6 } });` |
| `tl-labels` | ラベルで位置を揃える | `gsap.timeline({ defaults: { duration: 0.6, ease: "power2.out" } });` |
| `tl-hero` | ヒーローの登場演出 | `gsap.timeline({ defaults: { ease: "power3.out" } }) .from(".hero-tag", { y: -16, opacity: 0, dur…` |
| `tl-loop` | ループするタイムライン | `gsap.timeline({ repeat: -1 }) .to(".lp-track", { rotation: 360, duration: 3, ease: "none", trans…` |
| `tl-control` | 再生・一時停止・逆再生 | `gsap.timeline({ paused: true, defaults: { duration: 0.7 } }) .to(".ctl-box", { x: 70, rotation: …` |
| `tl-nested` | タイムラインの入れ子 | `gsap.timeline().from(sel + " span", { scale: 0, opacity: 0, duration: 0.5, ease: "back.out(2)", …` |
| `tl-timescale` | 速度を変える（timeScale） | `gsap.timeline({ repeat: -1 }) .fromTo(".ts-fill", { scaleX: 0 }, { scaleX: 1, duration: 2, ease:…` |
| `tl-hover` | ホバー用タイムライン | `gsap.timeline({ paused: true, defaults: { duration: 0.35, ease: "power2.out" } }) .to(".hv-img",…` |
| `tl-callbacks` | コールバックで状態を拾う | `gsap.timeline({ onStart: () => console.log("開始"), onComplete: () => console.log("完了"), onUpdate(…` |
| `tl-seek` | シークバーで頭出し | `gsap.timeline({ paused: true }) .to(".sk2-box", { x: 70, rotation: 180, duration: 1, ease: "none…` |
| `tl-marquee` | 途切れないループ（マーキー） | `gsap.to(".mq-track", { x: -set.offsetWidth, duration: 8, ease: "none", repeat: -1, });` |
| `tl-repeat-delay` | 間を置いて繰り返す | `gsap.timeline({ repeat: -1, repeatDelay: 1.1 }) .to(".rd-dot", { scale: 1.25, duration: 0.3, yoy…` |

### ScrollTrigger（20種）

| key | 名前 | 要点（最初の GSAP 呼び出し） |
|---|---|---|
| `st-fade` | スクロールでフェードイン | `gsap.registerPlugin(ScrollTrigger);` |
| `st-stagger` | 画面に入ったら順に表示 | `gsap.registerPlugin(ScrollTrigger);` |
| `st-once` | 1回だけ再生する（once） | `gsap.registerPlugin(ScrollTrigger);` |
| `st-toggle` | 出入りで再生と巻き戻し | `gsap.registerPlugin(ScrollTrigger);` |
| `st-scrub` | スクロール量に固定（scrub） | `gsap.registerPlugin(ScrollTrigger);` |
| `st-progress` | 読了プログレスバー | `gsap.registerPlugin(ScrollTrigger);` |
| `st-batch` | まとめて管理（batch） | `gsap.registerPlugin(ScrollTrigger);` |
| `st-header` | 追従ヘッダーの出し入れ | `gsap.registerPlugin(ScrollTrigger);` |
| `st-markers` | 位置をデバッグする（markers） | `gsap.registerPlugin(ScrollTrigger);` |
| `st-classes` | クラスを付け外しする | `gsap.registerPlugin(ScrollTrigger);` |
| `st-snap` | セクションに吸い付く（snap） | `gsap.registerPlugin(ScrollTrigger);` |
| `st-parallax` | パララックス（背景だけ遅らせる） | `gsap.registerPlugin(ScrollTrigger);` |
| `st-mask` | マスクで下から現れる | `gsap.registerPlugin(ScrollTrigger);` |
| `st-zoom` | 画像がゆっくりズーム | `gsap.registerPlugin(ScrollTrigger);` |
| `st-line-grow` | 区切り線が伸びる | `gsap.registerPlugin(ScrollTrigger);` |
| `st-rotate-in` | 回転しながら入ってくる | `gsap.registerPlugin(ScrollTrigger);` |
| `st-blur-focus` | ぼけて入りピントが合う | `gsap.registerPlugin(ScrollTrigger);` |
| `st-clip` | クリップで下から開く | `gsap.registerPlugin(ScrollTrigger);` |
| `st-alternate` | 左右交互に入ってくる | `gsap.registerPlugin(ScrollTrigger);` |
| `st-depth` | 多層パララックス（3層） | `gsap.registerPlugin(ScrollTrigger);` |

### スクロール演出（16種）

| key | 名前 | 要点（最初の GSAP 呼び出し） |
|---|---|---|
| `sa-horizontal` | 横スクロール（縦で横に流す） | `gsap.registerPlugin(ScrollTrigger);` |
| `sa-pin-text` | 固定しながらテキスト切替 | `gsap.registerPlugin(ScrollTrigger);` |
| `sa-counter` | スクロールで数字が伸びる | `gsap.registerPlugin(ScrollTrigger);` |
| `sa-frames` | コマ送り（画像シーケンス） | `gsap.registerPlugin(ScrollTrigger);` |
| `sa-split-open` | 左右に開くカーテン | `gsap.registerPlugin(ScrollTrigger);` |
| `sa-timeline-scrub` | タイムライン全体をscrubに繋ぐ | `gsap.registerPlugin(ScrollTrigger);` |
| `sa-card-fan` | カードが扇状に開く | `gsap.registerPlugin(ScrollTrigger);` |
| `sa-zoom-through` | 中央を突き抜けるズーム | `gsap.registerPlugin(ScrollTrigger);` |
| `sa-section-color` | 背景色がセクションで変わる | `gsap.registerPlugin(ScrollTrigger);` |
| `sa-stack-cards` | カードが重なって積み上がる | `gsap.registerPlugin(ScrollTrigger);` |
| `sa-text-highlight` | 読み進めた行がハイライト | `gsap.registerPlugin(ScrollTrigger);` |
| `sa-grid-collapse` | グリッドが1枚に収束 | `gsap.registerPlugin(ScrollTrigger);` |
| `sa-marquee-dir` | スクロール方向で流れが変わる | `gsap.registerPlugin(ScrollTrigger);` |
| `sa-progress-circle` | 円形の読了インジケーター | `gsap.registerPlugin(ScrollTrigger);` |
| `sa-columns` | 列ごとに時間差で立ち上がる | `gsap.registerPlugin(ScrollTrigger);` |
| `sa-toc` | 目次が現在地に追従 | `gsap.registerPlugin(ScrollTrigger);` |

### テキスト・数値（14種）

| key | 名前 | 要点（最初の GSAP 呼び出し） |
|---|---|---|
| `tx-chars` | 1文字ずつ立ち上がる | `gsap.from(el.querySelectorAll("span"), { y: 40, opacity: 0, rotateX: -90, duration: 0.7, ease: "…` |
| `tx-words` | 単語ずつフェードイン | `gsap.from(el.querySelectorAll("span"), { y: 24, opacity: 0, filter: "blur(6px)", duration: 0.7, …` |
| `tx-typewriter` | タイプライター | `gsap.to(el, { x: 100 });` |
| `tx-wave` | 波打つ文字 | `gsap.to(".wv span", { y: -16, duration: 0.5, ease: "sine.inOut", repeat: -1, yoyo: true, stagger…` |
| `tx-mask-lines` | 行マスクでせり上がる | `gsap.from(".ml-mask span", { yPercent: 115, duration: 0.9, ease: "power4.out", stagger: 0.12, })…` |
| `tx-scramble` | 文字がシャッフルして揃う | `gsap.to(state, { n: full.length, duration: 1.8, ease: "power1.inOut", onUpdate: () => { const fi…` |
| `tx-counter` | 数字カウントアップ | `gsap.to(obj, { v: 128400, duration: 2, ease: "power2.out", onUpdate: () => { el.textContent = Ma…` |
| `tx-gradient` | グラデーションが流れる見出し | `gsap.to(".gr", { backgroundPosition: "-200% 0", duration: 2.4, ease: "none", repeat: -1, });` |
| `tx-blur-chars` | 1文字ずつぼけて現れる | `gsap.from(el.querySelectorAll("span"), { filter: "blur(12px)", opacity: 0, scale: 1.4, duration:…` |
| `tx-rotate-words` | 単語が入れ替わり続ける | `gsap.set(words, { yPercent: 110 });` |
| `tx-outline-fill` | 輪郭文字が塗りつぶされる | `gsap.fromTo(".of-fill", { clipPath: "inset(100% 0 0 0)" }, { clipPath: "inset(0% 0 0 0)", durati…` |
| `tx-currency` | 金額のカウントアップ | `gsap.to(obj, { v: 4820000, duration: 2.2, ease: "power3.out", onUpdate: () => { el.textContent =…` |
| `tx-marquee` | 見出しの無限マーキー | `gsap.to(".tm-track", { x: -set.offsetWidth, duration: 7, ease: "none", repeat: -1 });` |
| `tx-glitch` | グリッチする文字 | `gsap.to(sel, { x: () => gsap.utils.random(-5, 5) * sign, y: () => gsap.utils.random(-3, 3), dura…` |

### SVG・図形（11種）

| key | 名前 | 要点（最初の GSAP 呼び出し） |
|---|---|---|
| `svg-draw` | 線が描かれるSVG | `gsap.fromTo(path, { strokeDasharray: len, strokeDashoffset: len }, { strokeDashoffset: 0, durati…` |
| `svg-check` | チェックマークが描かれる | `gsap.timeline() .fromTo(".ck-ring", { ...ringFrom, rotation: -90, transformOrigin: "center" }, {…` |
| `svg-progress` | 円グラフ（ドーナツ） | `gsap.set(circle, { strokeDasharray: len, strokeDashoffset: len });` |
| `svg-morph` | 図形が変形する | `gsap.timeline({ repeat: -1, yoyo: true, defaults: { duration: 1.1, ease: "power2.inOut" } }) .to…` |
| `svg-wave` | 波が流れ続ける | `gsap.to(".wv2-back", { x: -200, duration: 4, ease: "none", repeat: -1 });` |
| `svg-arrow` | 矢印が繰り返し描かれる | `gsap.set(el, { strokeDasharray: len, strokeDashoffset: len });` |
| `svg-blob` | ブロブが有機的に変形 | `gsap.timeline({ repeat: -1, yoyo: true, defaults: { duration: 2, ease: "sine.inOut" } }) .to(".b…` |
| `svg-bar` | 棒グラフが伸びる | `gsap.from(".bg2-bar", { scaleY: 0, duration: 0.9, ease: "power3.out", stagger: 0.1 });` |
| `svg-line-chart` | 折れ線グラフと点 | `gsap.timeline() .fromTo(path, { strokeDasharray: len, strokeDashoffset: len }, { strokeDashoffse…` |
| `svg-signature` | 手書き署名風 | `gsap.fromTo(path, { strokeDasharray: len, strokeDashoffset: len }, { strokeDashoffset: 0, durati…` |
| `svg-dot-path` | 点がパス上を進む | `gsap.to(state, { d: len, duration: 2.6, ease: "power1.inOut", repeat: -1, yoyo: true, onUpdate: …` |

### インタラクション（11種）

| key | 名前 | 要点（最初の GSAP 呼び出し） |
|---|---|---|
| `ix-magnetic` | マグネットボタン（追従） | `gsap.quickTo(btn, "x", { duration: 0.5, ease: "power3" });` |
| `ix-cursor` | カスタムカーソル追従 | `gsap.quickTo(".cu-dot", "x", { duration: 0.12, ease: "power2" });` |
| `ix-tilt` | 傾くカード（3Dチルト） | `gsap.quickTo(card, "rotationX", { duration: 0.5, ease: "power3" });` |
| `ix-ripple` | クリックで波紋 | `gsap.to(wave, { scale: 26, opacity: 0, duration: 0.7, ease: "power2.out", onComplete: () => wave…` |
| `ix-drag` | ドラッグで動かす（Draggable） | `gsap.registerPlugin(Draggable);` |
| `ix-accordion` | アコーディオン開閉 | `gsap.to(body, { height: open ? "auto" : 0, duration: 0.4, ease: "power2.inOut" });` |
| `ix-modal` | モーダルの出入り | `gsap.timeline({ paused: true }) .set(overlay, { visibility: "visible" }) .to(overlay, { opacity:…` |
| `ix-menu` | メニューが順に開く | `gsap.timeline({ paused: true }) .to(".mn-panel", { clipPath: "inset(0 0 0% 0)", duration: 0.45, …` |
| `ix-compare` | 画像比較スライダー | `gsap.registerPlugin(Draggable);` |
| `ix-shake` | エラー時のシェイク | `gsap.fromTo(input, { x: 0 }, { x: 10, duration: 0.07, repeat: 5, yoyo: true, clearProps: "x" });` |
| `ix-copy` | コピー完了のフィードバック | `gsap.set(".cy-done", { yPercent: 100 });` |

## サンプルコード（script 部分・原文のコメント付き）

### 基本トゥイーン

#### `fade-up` — フェードアップ
```js
// from() は「今の見た目」をゴールにして、指定した状態から動かす
gsap.from(".box", {
  y: 64,        // 64px下から
  opacity: 0,   // 透明から
  duration: 0.9,
  ease: "power3.out",
});
```

#### `fade-scale` — フェード＋拡大
```js
gsap.from(".box", {
  scale: 0.6,
  opacity: 0,
  duration: 0.8,
  ease: "back.out(1.7)",   // 行き過ぎて戻る＝弾む印象になる
});
```

#### `slide-in` — 左右からスライドイン
```js
gsap.from(".row-l", { x: -120, opacity: 0, duration: 0.8, ease: "power3.out" });
gsap.from(".row-r", { x: 120,  opacity: 0, duration: 0.8, ease: "power3.out", delay: 0.15 });
```

#### `stagger-grid` — スタガー（中央から順に）
```js
gsap.from(".sq", {
  scale: 0, opacity: 0, duration: 0.5, ease: "back.out(1.7)",
  // grid を渡すと「中央から波紋状に」など2次元の順番が指定できる
  stagger: { each: 0.06, from: "center", grid: [3, 3] },
});
```

#### `stagger-list` — リストを順に表示
```js
// stagger に数値を渡すだけで「1件あたり◯秒ずらす」になる
gsap.from(".li-list li", {
  x: -28, opacity: 0, duration: 0.5, ease: "power2.out",
  stagger: 0.09,
});
```

#### `ease-compare` — イージング比較（4種）
```js
// fromTo() は開始値と終了値の両方を明示する書き方
gsap.fromTo(".ball",
  { x: 0 },
  { x: 240, duration: 1.4, ease: "power2.out" }
);
// 主な ease: power1〜4.out / back.out(2) / elastic.out(1, 0.4) / bounce.out / none
```

#### `rotate-in` — 回転しながら登場
```js
gsap.from(".rot", {
  rotation: -180,   // 度数で指定（CSSのdeg不要）
  scale: 0.2,
  opacity: 0,
  duration: 1,
  ease: "power4.out",
});
```

#### `flip-3d` — 3Dフリップ
```js
gsap.from(".flip-el", {
  rotationY: 90,
  opacity: 0,
  duration: 1,
  ease: "power3.out",
  transformOrigin: "left center",   // 左端を軸にして開く
});
```

#### `repeat-yoyo` — 往復し続ける（repeat / yoyo）
```js
// ローディングインジケーターなどに使える無限往復
gsap.to(".yo-dot", {
  y: -26,
  duration: 0.45,
  ease: "power1.inOut",
  repeat: -1,      // -1 で無限ループ
  yoyo: true,      // 折り返して戻る
  stagger: 0.12,
});
```

#### `keyframes` — キーフレーム（多段の動き）
```js
// 1つのトゥイーンで多段の動きを書ける。timelineを組むまでもない時に便利
gsap.to(".kf", {
  keyframes: [
    { x: -70, duration: 0.5 },
    { y: -46, rotation: 180, duration: 0.5 },
    { x: 70, duration: 0.5 },
    { y: 0, rotation: 360, duration: 0.5 },
    { x: 0, duration: 0.5 },
  ],
  ease: "power2.inOut",
});
```

#### `blur-in` — ぼかしから鮮明になる
```js
// filter も文字列のまま渡せる。ぼかしは重いので対象は小さく絞る
gsap.from(".bl", {
  filter: "blur(14px)",
  opacity: 0,
  scale: 1.15,
  duration: 1,
  ease: "power2.out",
});
```

#### `skew-in` — 傾きながらスライドイン
```js
// skewX を初期値だけに入れると「勢いで歪んで、止まると直る」ように見える
gsap.from(".sk-row", {
  x: -90,
  skewX: 22,
  opacity: 0,
  duration: 0.7,
  ease: "power3.out",
  stagger: 0.1,
});
```

#### `random-scatter` — ランダムに散らばって整列
```js
// 値を関数で渡すと要素ごとに評価される＝1件ずつ違う乱数を割り当てられる
gsap.from(".rs-cell", {
  x: () => gsap.utils.random(-140, 140),
  y: () => gsap.utils.random(-90, 90),
  rotation: () => gsap.utils.random(-180, 180),
  opacity: 0,
  duration: 1,
  ease: "power3.out",
  stagger: 0.03,
});
```

#### `clip-reveal` — クリップで開く
```js
// clip-path も補間できる。inset の4辺は「上 右 下 左」の順
gsap.from(".cr", {
  clipPath: "inset(0 100% 0 0)",   // 右側を100%削った＝幅ゼロの状態から
  duration: 1,
  ease: "power3.inOut",
});
```

#### `arc-move` — 弧を描いて移動
```js
// 横は等速、縦だけ上がって落ちる。2本重ねるだけで放物線になる
gsap.fromTo(".am-ball", { x: 0 }, { x: 280, duration: 1.4, ease: "none" });

gsap.fromTo(".am-ball",
  { y: 0 },
  { y: -96, duration: 0.7, ease: "power2.out", yoyo: true, repeat: 1 }
);
```

#### `stagger-edges` — 端から中央へ集まる
```js
gsap.from(".se-bar", {
  scaleY: 0, opacity: 0, transformOrigin: "center center",
  duration: 0.6, ease: "back.out(2)",
  // from には "start" "center" "end" "edges" "random" が指定できる
  stagger: { each: 0.07, from: "edges" },
});
```

### タイムライン

#### `tl-sequence` — 順次再生（重ねて繋ぐ）
```js
// timeline は「順番に並べる箱」。第3引数の位置指定で重ね方を調整する
const tl = gsap.timeline({ defaults: { ease: "power3.out", duration: 0.6 } });

tl.from(".tl-thumb", { scaleY: 0, transformOrigin: "top center" })
  .from(".tl-title", { y: 20, opacity: 0 }, "-=0.3")    // 0.3秒前倒しで重ねる
  .from(".tl-text",  { y: 20, opacity: 0 }, "-=0.45")
  .from(".tl-btn",   { scale: 0.6, opacity: 0, ease: "back.out(2)" }, "-=0.3");
```

#### `tl-labels` — ラベルで位置を揃える
```js
const tl = gsap.timeline({ defaults: { duration: 0.6, ease: "power2.out" } });

tl.from(".lb-a", { x: -60, opacity: 0 })
  .addLabel("together")                          // この時点に名前を付ける
  .from(".lb-b", { x: -60, opacity: 0 }, "together")  // ラベル位置から開始
  .from(".lb-c", { x: 60,  opacity: 0 }, "together"); // Bと完全に同時

// 位置指定の書き方: "together" / "together+=0.2" / "<"(直前と同時) / ">"(直前の直後)
```

#### `tl-hero` — ヒーローの登場演出
```js
// "<" は「直前のトゥイーンと同じ時刻」。"<0.15" で0.15秒だけ遅らせて重ねる
gsap.timeline({ defaults: { ease: "power3.out" } })
  .from(".hero-tag", { y: -16, opacity: 0, duration: 0.5 })
  .from(".hero-h",   { y: 28,  opacity: 0, duration: 0.7 }, "<0.15")
  .from(".hero-p",   { y: 20,  opacity: 0, duration: 0.7 }, "<0.15")
  .from(".hero-cta", { scale: 0.7, opacity: 0, duration: 0.6, ease: "back.out(2)" }, "<0.2");
```

#### `tl-loop` — ループするタイムライン
```js
// timeline 側に repeat: -1 を書けば、中身をまとめて無限ループできる
gsap.timeline({ repeat: -1 })
  .to(".lp-track", { rotation: 360, duration: 3, ease: "none", transformOrigin: "center center" })
  .to(".lp-dot", { scale: 1.6, duration: 0.75, yoyo: true, repeat: 3 }, 0); // 0 = 先頭から同時
```

#### `tl-control` — 再生・一時停止・逆再生
```js
// paused: true で作っておき、あとから好きなタイミングで操作する
const tl = gsap.timeline({ paused: true, defaults: { duration: 0.7 } })
  .to(".ctl-box", { x: 70, rotation: 180 })
  .to(".ctl-box", { x: -70, borderRadius: "50%" })
  .to(".ctl-box", { x: 0, rotation: 360, borderRadius: "16px" });

// tl.play() / tl.pause() / tl.reverse() / tl.restart() / tl.seek(1.2)
document.querySelectorAll("[data-act]").forEach((btn) => {
  btn.addEventListener("click", () => tl[btn.dataset.act]());
});
```

#### `tl-nested` — タイムラインの入れ子
```js
// 部品ごとに timeline を関数で作り、親 timeline に add() で組み込む
const makeGroup = (sel) =>
  gsap.timeline().from(sel + " span", {
    scale: 0, opacity: 0, duration: 0.5, ease: "back.out(2)", stagger: 0.1,
  });

gsap.timeline()
  .add(makeGroup(".ns-g1"))
  .add(makeGroup(".ns-g2"), "-=0.2");   // 前のグループに少し重ねる
```

#### `tl-timescale` — 速度を変える（timeScale）
```js
const tl = gsap.timeline({ repeat: -1 })
  .fromTo(".ts-fill", { scaleX: 0 }, { scaleX: 1, duration: 2, ease: "none" });

// timeScale は再生中でも即座に効く。1が等速、0.5で半分、2で倍速
tl.timeScale(2.5);

// gsap.globalTimeline.timeScale(0.2) にすればページ全体をスローにできる（デバッグ用）
```

#### `tl-hover` — ホバー用タイムライン
```js
// ホバーのたびに新しいトゥイーンを作らず、1本を play/reverse で使い回すのがコツ
const card = document.querySelector(".hv-card");

const tl = gsap.timeline({ paused: true, defaults: { duration: 0.35, ease: "power2.out" } })
  .to(".hv-img", { scale: 1.12 }, 0)
  .to(".hv-d", { opacity: 1, y: -2 }, 0)
  .to(card, { y: -6, boxShadow: "0 12px 28px rgba(15,23,42,0.16)" }, 0);

card.addEventListener("pointerenter", () => tl.play());
card.addEventListener("pointerleave", () => tl.reverse());
```

#### `tl-callbacks` — コールバックで状態を拾う
```js
// コールバック内の this はそのタイムライン自身を指す（アロー関数だと this が変わるので注意）
gsap.timeline({
  onStart: () => console.log("開始"),
  onComplete: () => console.log("完了"),
  onUpdate() {
    console.log(Math.round(this.progress() * 100) + "%");
  },
})
  .to(".cb-box", { x: 80, rotation: 180, duration: 1 })
  .to(".cb-box", { x: 0, rotation: 360, duration: 1 });
```

#### `tl-seek` — シークバーで頭出し
```js
const tl = gsap.timeline({ paused: true })
  .to(".sk2-box", { x: 70, rotation: 180, duration: 1, ease: "none" })
  .to(".sk2-box", { x: -70, scale: 0.6, duration: 1, ease: "none" });

// progress() は 0〜1。引数なしで呼ぶと現在位置の取得になる
document.querySelector(".sk2-range").addEventListener("input", (e) => {
  tl.progress(e.target.value / 100);
});
```

#### `tl-marquee` — 途切れないループ（マーキー）
```js
// 同じ内容を2つ並べ、1セット分ちょうど動かして戻す＝継ぎ目が見えない
const set = document.querySelector(".mq-set");

gsap.to(".mq-track", {
  x: -set.offsetWidth,
  duration: 8,
  ease: "none",
  repeat: -1,
});
```

#### `tl-repeat-delay` — 間を置いて繰り返す
```js
// repeatDelay を入れると「繰り返しの間に一拍置く」＝しつこさが消える
gsap.timeline({ repeat: -1, repeatDelay: 1.1 })
  .to(".rd-dot", { scale: 1.25, duration: 0.3, yoyo: true, repeat: 1 })
  .fromTo(".rd-ring",
    { scale: 0.5, opacity: 0.9 },
    { scale: 1.35, opacity: 0, duration: 0.9, ease: "power2.out" },
    0
  );
```

### ScrollTrigger

#### `st-fade` — スクロールでフェードイン
```js
gsap.registerPlugin(ScrollTrigger);

gsap.utils.toArray(".st-item").forEach((item) => {
  gsap.from(item, {
    y: 44, opacity: 0, ease: "none",
    scrollTrigger: {
      trigger: item,
      // scrub でスクロール位置に直結させると、スクロールを止めた分だけ途中で止まる
      start: "top bottom",   // 要素の上端が画面下端に来たら開始
      end: "top 55%",        // 上端が画面の55%位置まで来たら完了
      scrub: true,
    },
  });
});
```

#### `st-stagger` — 画面に入ったら順に表示
```js
gsap.registerPlugin(ScrollTrigger);

// トリガーは「まとまり」に1つだけ置き、中身は stagger でずらす
gsap.from(".sg-cell", {
  y: 34, opacity: 0, ease: "none",
  // scrub と併用するとき、stagger は秒数ではなくスクロール範囲の配分として効く
  stagger: 0.5,
  scrollTrigger: { trigger: ".sg-grid", start: "top bottom", end: "top 40%", scrub: true },
});
```

#### `st-once` — 1回だけ再生する（once）
```js
gsap.registerPlugin(ScrollTrigger);

gsap.from(".on-box", {
  scale: 0.7, opacity: 0, duration: 0.8, ease: "back.out(1.6)",
  scrollTrigger: {
    trigger: ".on-box",
    start: "top 85%",
    once: true,   // 一度再生したらトリガーを破棄する（登場演出はこれが基本）
  },
});
```

#### `st-toggle` — 出入りで再生と巻き戻し
```js
gsap.registerPlugin(ScrollTrigger);

gsap.from(".tg-box", {
  x: -80, opacity: 0, duration: 0.7, ease: "power3.out",
  scrollTrigger: {
    trigger: ".tg-box",
    start: "top 85%",
    end: "bottom 20%",
    // 順に onEnter / onLeave / onEnterBack / onLeaveBack の挙動を指定する
    // 指定できる値: play, pause, resume, reverse, restart, reset, complete, none
    toggleActions: "play reverse play reverse",
  },
});
```

#### `st-scrub` — スクロール量に固定（scrub）
```js
gsap.registerPlugin(ScrollTrigger);

// scrub を付けると「再生」ではなく「スクロール位置＝再生位置」になる
gsap.to(".sc-box", {
  rotation: 360, scale: 1.5, borderRadius: "50%",
  ease: "none",            // scrub では none にしないと二重に緩急がつく
  scrollTrigger: {
    trigger: ".sc-inner",
    start: "top top",
    end: "bottom bottom",
    scrub: true,           // 数値(例: 0.5)にすると少し遅れて追従して滑らかになる
  },
});
```

#### `st-progress` — 読了プログレスバー
```js
gsap.registerPlugin(ScrollTrigger);

// width ではなく scaleX を動かすとレイアウト計算が走らず滑らかに動く
gsap.to(".pg-bar", {
  scaleX: 1, ease: "none",
  scrollTrigger: { trigger: ".pg-body", start: "top top", end: "bottom bottom", scrub: true },
});
```

#### `st-batch` — まとめて管理（batch）
```js
gsap.registerPlugin(ScrollTrigger);

// 要素数が多いとき、1件ずつトリガーを作らず「同時に入ってきた分をまとめて」動かす
gsap.set(".bt-cell", { opacity: 0, y: 30 });

ScrollTrigger.batch(".bt-cell", {
  start: "top 90%",
  onEnter: (batch) =>
    gsap.to(batch, { opacity: 1, y: 0, duration: 0.6, ease: "power2.out", stagger: 0.1, overwrite: true }),
  // onLeaveBack: (batch) => gsap.to(batch, { opacity: 0, y: 30, overwrite: true }),
});
```

#### `st-header` — 追従ヘッダーの出し入れ
```js
gsap.registerPlugin(ScrollTrigger);

ScrollTrigger.create({
  start: "top top",
  end: "max",
  onUpdate: (self) => {
    // self.direction は下スクロールで 1、上スクロールで -1
    gsap.to(".hd-bar", {
      yPercent: self.direction === 1 && self.scroll() > 40 ? -100 : 0,
      duration: 0.3, ease: "power2.out", overwrite: true,
    });
  },
});
```

#### `st-markers` — 位置をデバッグする（markers）
```js
gsap.registerPlugin(ScrollTrigger);

gsap.from(".mr-box", {
  opacity: 0, y: 40, ease: "none",
  scrollTrigger: {
    trigger: ".mr-box",
    start: "top 80%",
    end: "top 40%",
    scrub: true,
    markers: true,   // 開発中だけ true にして start/end の位置を目視で確認する
  },
});
```

#### `st-classes` — クラスを付け外しする
```js
gsap.registerPlugin(ScrollTrigger);

// アニメーションをGSAPで書かず、CSSのtransitionに任せたい時はこれが一番手軽
ScrollTrigger.create({
  trigger: ".tc-box",
  start: "top 80%",
  end: "bottom 30%",
  toggleClass: { targets: ".tc-box", className: "is-active" },
});
```

#### `st-snap` — セクションに吸い付く（snap）
```js
gsap.registerPlugin(ScrollTrigger);

ScrollTrigger.create({
  trigger: ".sn-inner",
  start: "top top",
  end: "bottom bottom",
  // snapTo は「進捗のどの間隔で止めるか」。3セクションなら 1/2（区切りは2つ）
  snap: { snapTo: 1 / 2, duration: 0.4, ease: "power2.inOut" },
});
```

#### `st-parallax` — パララックス（背景だけ遅らせる）
```js
gsap.registerPlugin(ScrollTrigger);

gsap.fromTo(".px-bg",
  { yPercent: -18 },
  {
    yPercent: 18,
    ease: "none",
    scrollTrigger: {
      trigger: ".px-hero",
      // 画面に入った瞬間から出ていくまでを丸ごと使うと、動く距離が確保できる
      start: "top bottom",
      end: "bottom top",
      scrub: true,
    },
  }
);
```

#### `st-mask` — マスクで下から現れる
```js
gsap.registerPlugin(ScrollTrigger);

gsap.from(".mk-line", {
  yPercent: 110, ease: "none",
  scrollTrigger: { trigger: ".mk-mask", start: "top bottom", end: "top 55%", scrub: true },
});
```

#### `st-zoom` — 画像がゆっくりズーム
```js
gsap.registerPlugin(ScrollTrigger);

gsap.fromTo(".zm-img",
  { scale: 1.6 },        // 拡大側から等倍へ戻すと「引いていく」印象になる
  {
    scale: 1, ease: "none",
    scrollTrigger: {
      trigger: ".zm-frame",
      // 画面に入った瞬間から出ていくまでを丸ごと使うと、動く距離が確保できる
      start: "top bottom",
      end: "bottom top",
      scrub: true,
    },
  }
);
```

#### `st-line-grow` — 区切り線が伸びる
```js
gsap.registerPlugin(ScrollTrigger);

gsap.utils.toArray(".lg-block").forEach((block) => {
  gsap.to(block.querySelector(".lg-line"), {
    scaleX: 1, ease: "none",
    scrollTrigger: { trigger: block, start: "top bottom", end: "top 50%", scrub: true },
  });
});
```

#### `st-rotate-in` — 回転しながら入ってくる
```js
gsap.registerPlugin(ScrollTrigger);

gsap.utils.toArray(".ri-card").forEach((card) => {
  gsap.from(card, {
    rotation: -10, y: 50, opacity: 0,
    // 軸を左下に置くと「めくれ上がる」ような入り方になる
    transformOrigin: "left bottom",
    ease: "none",
    scrollTrigger: { trigger: card, start: "top bottom", end: "top 55%", scrub: true },
  });
});
```

#### `st-blur-focus` — ぼけて入りピントが合う
```js
gsap.registerPlugin(ScrollTrigger);

gsap.utils.toArray(".bf-item").forEach((item) => {
  gsap.from(item, {
    filter: "blur(10px)", opacity: 0, scale: 1.08,
    ease: "none",
    scrollTrigger: { trigger: item, start: "top bottom", end: "top 55%", scrub: true },
  });
});
```

#### `st-clip` — クリップで下から開く
```js
gsap.registerPlugin(ScrollTrigger);

gsap.utils.toArray(".cl-item").forEach((item) => {
  gsap.from(item, {
    // inset の4辺は「上 右 下 左」。上を100%削ると下から開く
    clipPath: "inset(100% 0 0 0)",
    ease: "none",
    scrollTrigger: { trigger: item, start: "top bottom", end: "top 50%", scrub: true },
  });
});
```

#### `st-alternate` — 左右交互に入ってくる
```js
gsap.registerPlugin(ScrollTrigger);

gsap.utils.toArray(".al-row").forEach((row, i) => {
  gsap.from(row.querySelector(".al-item"), {
    // 添字の偶奇で向きを変えるだけ。CSS側の並びと揃えるのを忘れずに
    x: i % 2 === 0 ? -80 : 80,
    opacity: 0, ease: "none",
    scrollTrigger: { trigger: row, start: "top bottom", end: "top 55%", scrub: true },
  });
});
```

#### `st-depth` — 多層パララックス（3層）
```js
gsap.registerPlugin(ScrollTrigger);

const st = { trigger: ".dp-scene", start: "top bottom", end: "bottom top", scrub: true };

// 手前ほど大きく動かすと奥行きが出る。同じ設定オブジェクトを使い回せる
gsap.fromTo(".dp-back",  { y: 26 }, { y: -26, ease: "none", scrollTrigger: st });
gsap.fromTo(".dp-mid",   { y: 46 }, { y: -46, ease: "none", scrollTrigger: st });
gsap.fromTo(".dp-front", { y: 72 }, { y: -72, ease: "none", scrollTrigger: st });
```

### スクロール演出

#### `sa-horizontal` — 横スクロール（縦で横に流す）
```js
gsap.registerPlugin(ScrollTrigger);

// position:sticky で固定しておけば pin なしでも横スクロールが作れる
gsap.to(".hz-track", {
  xPercent: -66.6666,      // パネル3枚なら -66.6666（= -100 × (枚数-1) / 枚数）
  ease: "none",
  scrollTrigger: { trigger: ".hz-sec", start: "top top", end: "bottom bottom", scrub: 0.5 },
});
```

#### `sa-pin-text` — 固定しながらテキスト切替
```js
gsap.registerPlugin(ScrollTrigger);

const words = gsap.utils.toArray(".pt-word");
gsap.set(words, { opacity: 0, y: 30 });
gsap.set(words[0], { opacity: 1, y: 0 });

const tl = gsap.timeline({
  scrollTrigger: { trigger: ".pt-sec", start: "top top", end: "bottom bottom", scrub: true },
});

words.forEach((word, i) => {
  if (i === 0) return;
  tl.to(words[i - 1], { opacity: 0, y: -30, duration: 1 })
    .to(word, { opacity: 1, y: 0, duration: 1 }, "<");
});
```

#### `sa-counter` — スクロールで数字が伸びる
```js
gsap.registerPlugin(ScrollTrigger);

const el = document.querySelector(".cs-num");
const obj = { v: 0 };   // ただの箱をトゥイーンして、その値を表示に反映する

gsap.to(obj, {
  v: 100, ease: "none",
  onUpdate: () => { el.textContent = Math.round(obj.v); },
  scrollTrigger: { trigger: ".cs-sec", start: "top top", end: "bottom bottom", scrub: true },
});
```

#### `sa-frames` — コマ送り（画像シーケンス）
```js
gsap.registerPlugin(ScrollTrigger);

// Apple公式サイト風の「スクロールでコマ送り」。連番画像の添字をトゥイーンする
const frames = gsap.utils.toArray(".fr-frame");
const state = { i: 0 };

gsap.to(state, {
  i: frames.length - 1,
  ease: "none",
  snap: { i: 1 },          // 整数にスナップしてコマ落ちを防ぐ
  onUpdate: () => {
    frames.forEach((f, idx) => gsap.set(f, { opacity: idx === state.i ? 1 : 0 }));
  },
  scrollTrigger: { trigger: ".fr-sec", start: "top top", end: "bottom bottom", scrub: true },
});
```

#### `sa-split-open` — 左右に開くカーテン
```js
gsap.registerPlugin(ScrollTrigger);

const st = { trigger: ".so-sec", start: "top top", end: "bottom bottom", scrub: true };

gsap.to(".so-l", { xPercent: -100, ease: "none", scrollTrigger: st });
gsap.to(".so-r", { xPercent: 100,  ease: "none", scrollTrigger: st });
```

#### `sa-timeline-scrub` — タイムライン全体をscrubに繋ぐ
```js
gsap.registerPlugin(ScrollTrigger);

// timeline 自体に scrollTrigger を渡すと、複数段の動きを1本のスクロールに割り当てられる
gsap.timeline({
  scrollTrigger: { trigger: ".tsc-sec", start: "top top", end: "bottom bottom", scrub: 0.6 },
  defaults: { ease: "none", duration: 1 },   // scrub では duration が「配分の比率」になる
})
  .from(".tsc-1", { y: -80, rotation: -90, opacity: 0 })
  .from(".tsc-2", { scale: 0, opacity: 0 })
  .from(".tsc-3", { y: 80, rotation: 90, opacity: 0 });
```

#### `sa-card-fan` — カードが扇状に開く
```js
gsap.registerPlugin(ScrollTrigger);

const st = { trigger: ".cf-sec", start: "top top", end: "bottom bottom", scrub: 0.5 };

gsap.to(".cf-1", { x: -96, rotation: -18, ease: "none", scrollTrigger: st });
gsap.to(".cf-3", { x: 96,  rotation: 18,  ease: "none", scrollTrigger: st });
```

#### `sa-zoom-through` — 中央を突き抜けるズーム
```js
gsap.registerPlugin(ScrollTrigger);

// 画面の対角線を覆いきる倍率まで拡げる（46px の円なら 9倍で約414px）
gsap.fromTo(".zt-hole",
  { scale: 0.2 },
  {
    scale: 9, ease: "none",
    scrollTrigger: { trigger: ".zt-sec", start: "top top", end: "bottom bottom", scrub: 0.4 },
  }
);
```

#### `sa-section-color` — 背景色がセクションで変わる
```js
gsap.registerPlugin(ScrollTrigger);

gsap.utils.toArray(".bc-sec").forEach((sec) => {
  ScrollTrigger.create({
    trigger: sec,
    start: "top 60%",
    end: "bottom 60%",
    // onToggle は範囲に入った時と出た時の両方で呼ばれる。isActive で入った時だけ拾う
    onToggle: (self) => {
      if (!self.isActive) return;
      gsap.to("body", { backgroundColor: sec.dataset.bg, duration: 0.5, ease: "power2.out" });
    },
  });
});
```

#### `sa-stack-cards` — カードが重なって積み上がる
```js
gsap.registerPlugin(ScrollTrigger);

const cards = gsap.utils.toArray(".sk-card");

cards.forEach((card, i) => {
  if (i === cards.length - 1) return;
  gsap.to(card, {
    scale: 0.9, opacity: 0.6, ease: "none",
    // 「次のカード」の位置を基準にして、今のカードを奥へ下げる
    scrollTrigger: { trigger: cards[i + 1], start: "top 60%", end: "top 16%", scrub: true },
  });
});
```

#### `sa-text-highlight` — 読み進めた行がハイライト
```js
gsap.registerPlugin(ScrollTrigger);

const tl = gsap.timeline({
  scrollTrigger: { trigger: ".th-sec", start: "top top", end: "bottom bottom", scrub: true },
});

// 行数ぶん to() を並べれば、スクロール量が自動で等分される
gsap.utils.toArray(".th-line").forEach((line) => {
  tl.to(line, { color: "#0f172a", duration: 1, ease: "none" });
});
```

#### `sa-grid-collapse` — グリッドが1枚に収束
```js
gsap.registerPlugin(ScrollTrigger);

const cells = gsap.utils.toArray(".gc-cell");
const center = cells[4].getBoundingClientRect();   // 中央のセルを集合点にする

gsap.to(cells, {
  // 関数で渡すと (index, element) を受け取れる＝要素ごとに移動量を計算できる
  x: (i, el) => center.left - el.getBoundingClientRect().left,
  y: (i, el) => center.top - el.getBoundingClientRect().top,
  ease: "none",
  scrollTrigger: { trigger: ".gc-sec", start: "top top", end: "bottom bottom", scrub: 0.5 },
});
```

#### `sa-marquee-dir` — スクロール方向で流れが変わる
```js
gsap.registerPlugin(ScrollTrigger);

const set = document.querySelector(".md2-set");
const loop = gsap.to(".md2-track", { x: -set.offsetWidth, duration: 8, ease: "none", repeat: -1 });

ScrollTrigger.create({
  start: "top top",
  end: "max",
  onUpdate: (self) => {
    // 下スクロールで正方向、上スクロールで逆方向に流す
    gsap.to(loop, { timeScale: self.direction === 1 ? 1 : -1, duration: 0.3, overwrite: true });
  },
});
```

#### `sa-progress-circle` — 円形の読了インジケーター
```js
gsap.registerPlugin(ScrollTrigger);

const circle = document.querySelector(".pc2-val");
const len = circle.getTotalLength();
gsap.set(circle, { strokeDasharray: len, strokeDashoffset: len });

gsap.to(circle, {
  strokeDashoffset: 0, ease: "none",
  scrollTrigger: { trigger: ".pc2-body", start: "top top", end: "bottom bottom", scrub: true },
});
```

#### `sa-columns` — 列ごとに時間差で立ち上がる
```js
gsap.registerPlugin(ScrollTrigger);

gsap.from(".co-bar", {
  scaleY: 0, duration: 0.8, ease: "power3.out", stagger: 0.08,
  scrollTrigger: { trigger: ".co-chart", start: "top 85%" },
});
```

#### `sa-toc` — 目次が現在地に追従
```js
gsap.registerPlugin(ScrollTrigger);

const items = gsap.utils.toArray(".toc-item");
const setCurrent = (i) => items.forEach((el, idx) => el.classList.toggle("is-current", idx === i));

gsap.utils.toArray(".toc-sec").forEach((sec, i) => {
  ScrollTrigger.create({
    trigger: sec,
    // 画面の中央付近を判定線にすると、現在地の切り替わりが自然に見える
    start: "top 45%",
    end: "bottom 45%",
    onToggle: (self) => self.isActive && setCurrent(i),
  });
});
```

### テキスト・数値

#### `tx-chars` — 1文字ずつ立ち上がる
```js
// 1文字ずつ span に分解する（有料プラグイン SplitText なしでOK）
const el = document.querySelector(".tx");
el.innerHTML = [...el.textContent]
  .map((c) => \`<span>\${c === " " ? "&nbsp;" : c}</span>\`)
  .join("");

gsap.from(el.querySelectorAll("span"), {
  y: 40, opacity: 0, rotateX: -90,
  duration: 0.7, ease: "back.out(1.7)",
  stagger: 0.05,
});
```

#### `tx-words` — 単語ずつフェードイン
```js
const el = document.querySelector(".wd");
// 単語単位なら分解が軽く、日本語でも読みやすさを保てる
el.innerHTML = el.textContent.split(" ").map((w) => \`<span>\${w}</span>\`).join("");

gsap.from(el.querySelectorAll("span"), {
  y: 24, opacity: 0, filter: "blur(6px)",
  duration: 0.7, ease: "power2.out", stagger: 0.12,
});
```

#### `tx-typewriter` — タイプライター
```js
const out = document.querySelector(".tw-out");
const full = "gsap.to(el, { x: 100 });";
const state = { n: 0 };

gsap.to(state, {
  n: full.length,
  duration: 2.2,
  ease: "none",
  snap: { n: 1 },     // 文字数は整数でないと1文字が半分だけ出る
  onUpdate: () => { out.textContent = full.slice(0, state.n); },
});

// カーソルの点滅は steps(1) で「パッと切り替わる」動きにする
gsap.to(".tw-caret", { opacity: 0, duration: 0.5, repeat: -1, yoyo: true, ease: "steps(1)" });
```

#### `tx-wave` — 波打つ文字
```js
gsap.to(".wv span", {
  y: -16,
  duration: 0.5,
  ease: "sine.inOut",
  repeat: -1,
  yoyo: true,
  stagger: { each: 0.07, repeat: -1, yoyo: true },   // stagger 側にも repeat を書くと波が途切れない
});
```

#### `tx-mask-lines` — 行マスクでせり上がる
```js
gsap.from(".ml-mask span", {
  yPercent: 115,      // 100より少し大きくすると下端が見切れない
  duration: 0.9, ease: "power4.out", stagger: 0.12,
});
```

#### `tx-scramble` — 文字がシャッフルして揃う
```js
// 有料の ScrambleTextPlugin と同等の表現を、確定した文字数をトゥイーンして作る
const el = document.querySelector(".sb");
const full = el.textContent;
const pool = "ABCDEFGHIJKLMNOPQRSTUVWXYZ#$%&";
const state = { n: 0 };

gsap.to(state, {
  n: full.length,
  duration: 1.8,
  ease: "power1.inOut",
  onUpdate: () => {
    const fixed = Math.floor(state.n);
    const noise = [...full.slice(fixed)]
      .map(() => pool[Math.floor(Math.random() * pool.length)]).join("");
    el.textContent = full.slice(0, fixed) + noise;
  },
  onComplete: () => { el.textContent = full; },
});
```

#### `tx-counter` — 数字カウントアップ
```js
const el = document.querySelector(".ct-num");
const obj = { v: 0 };   // ただの箱をトゥイーンして、その値を表示に反映する

gsap.to(obj, {
  v: 128400,
  duration: 2,
  ease: "power2.out",
  onUpdate: () => { el.textContent = Math.round(obj.v).toLocaleString(); },
});
```

#### `tx-gradient` — グラデーションが流れる見出し
```js
// 文字に切り抜いた背景の位置をずらすことで、色が流れて見える
gsap.to(".gr", {
  backgroundPosition: "-200% 0",
  duration: 2.4, ease: "none", repeat: -1,
});
```

#### `tx-blur-chars` — 1文字ずつぼけて現れる
```js
const el = document.querySelector(".bc2");
el.innerHTML = [...el.textContent].map((c) => \`<span>\${c}</span>\`).join("");

gsap.from(el.querySelectorAll("span"), {
  filter: "blur(12px)", opacity: 0, scale: 1.4,
  duration: 0.8, ease: "power2.out", stagger: 0.07,
});
```

#### `tx-rotate-words` — 単語が入れ替わり続ける
```js
const words = gsap.utils.toArray(".rw-word");
gsap.set(words, { yPercent: 110 });
gsap.set(words[0], { yPercent: 0 });

const tl = gsap.timeline({ repeat: -1 });

words.forEach((word, i) => {
  const next = words[(i + 1) % words.length];   // 最後は先頭に戻す
  tl.to(word, { yPercent: -110, duration: 0.5, ease: "power2.in", delay: 1 })
    .fromTo(next, { yPercent: 110 }, { yPercent: 0, duration: 0.5, ease: "power2.out" }, "<");
});
```

#### `tx-outline-fill` — 輪郭文字が塗りつぶされる
```js
gsap.fromTo(".of-fill",
  { clipPath: "inset(100% 0 0 0)" },
  { clipPath: "inset(0% 0 0 0)", duration: 1.4, ease: "power2.inOut", repeat: -1, repeatDelay: 0.8, yoyo: true }
);
```

#### `tx-currency` — 金額のカウントアップ
```js
// 桁区切りや通貨記号は Intl.NumberFormat に任せると、ロケール違いにも耐える
const el = document.querySelector(".cu2-num");
const fmt = new Intl.NumberFormat("ja-JP", { style: "currency", currency: "JPY", maximumFractionDigits: 0 });
const obj = { v: 0 };

gsap.to(obj, {
  v: 4820000,
  duration: 2.2,
  ease: "power3.out",
  onUpdate: () => { el.textContent = fmt.format(Math.round(obj.v)); },
});
```

#### `tx-marquee` — 見出しの無限マーキー
```js
// 同じ内容を2つ並べ、1セット分ちょうど動かして戻す＝継ぎ目が見えない
const set = document.querySelector(".tm-set");
gsap.to(".tm-track", { x: -set.offsetWidth, duration: 7, ease: "none", repeat: -1 });
```

#### `tx-glitch` — グリッチする文字
```js
const jolt = (sel, sign) => gsap.to(sel, {
  x: () => gsap.utils.random(-5, 5) * sign,
  y: () => gsap.utils.random(-3, 3),
  duration: 0.09,
  ease: "steps(1)",
  repeat: -1,
  repeatRefresh: true,   // 繰り返しのたびに関数を再評価する＝毎回違う乱数になる
});

jolt(".gl-r", 1);
jolt(".gl-b", -1);
```

### SVG・図形

#### `svg-draw` — 線が描かれるSVG
```js
// 有料の DrawSVGPlugin を使わず、dasharray / dashoffset で同じ表現ができる
const path = document.querySelector(".dr-line");
const len = path.getTotalLength();

gsap.fromTo(path,
  { strokeDasharray: len, strokeDashoffset: len },  // 破線1本分を線の外に逃がして「消えた」状態にする
  { strokeDashoffset: 0, duration: 1.4, ease: "power2.inOut" }
);
```

#### `svg-check` — チェックマークが描かれる
```js
// 送信完了・保存完了のフィードバックに使えるチェックマーク
const draw = (el) => {
  const len = el.getTotalLength();
  return [{ strokeDasharray: len, strokeDashoffset: len }, { strokeDashoffset: 0 }];
};

const [ringFrom, ringTo] = draw(document.querySelector(".ck-ring"));
const [markFrom, markTo] = draw(document.querySelector(".ck-mark"));

gsap.timeline()
  .fromTo(".ck-ring", { ...ringFrom, rotation: -90, transformOrigin: "center" },
                      { ...ringTo, duration: 0.8, ease: "power2.inOut" })
  .fromTo(".ck-mark", markFrom, { ...markTo, duration: 0.45, ease: "power2.out" }, "-=0.15");
```

#### `svg-progress` — 円グラフ（ドーナツ）
```js
const circle = document.querySelector(".cp-val");
const len = circle.getTotalLength();
const state = { p: 0 };

gsap.set(circle, { strokeDasharray: len, strokeDashoffset: len });

gsap.to(state, {
  p: 0.72,                 // 72%
  duration: 1.6, ease: "power2.out",
  onUpdate: () => gsap.set(circle, { strokeDashoffset: len * (1 - state.p) }),
});
```

#### `svg-morph` — 図形が変形する
```js
// 有料の MorphSVGPlugin なしでも、頂点の数が同じ polygon 同士なら attr で補間できる
gsap.timeline({ repeat: -1, yoyo: true, defaults: { duration: 1.1, ease: "power2.inOut" } })
  .to(".mp-shape", { attr: { points: "60,10 105,35 105,85 60,110 15,85 15,35" }, fill: "#ec4899" })
  .to(".mp-shape", { attr: { points: "60,20 100,60 60,100 20,60 60,20 20,60" }, fill: "#0f172a" });
```

#### `svg-wave` — 波が流れ続ける
```js
// 同じ波形を横に2つ並べて幅2倍（400）のパスにしておき、
// 1周期ぶん（この例では200）ちょうど動かすと、継ぎ目なく無限ループする
gsap.to(".wv2-back",  { x: -200, duration: 4,   ease: "none", repeat: -1 });
gsap.to(".wv2-front", { x: -200, duration: 2.6, ease: "none", repeat: -1 });  // 速度差で奥行きが出る
```

#### `svg-arrow` — 矢印が繰り返し描かれる
```js
// 線と矢じりを別パスにしておくと、描かれる順番を制御できる
const draw = (sel) => {
  const el = document.querySelector(sel);
  const len = el.getTotalLength();
  gsap.set(el, { strokeDasharray: len, strokeDashoffset: len });
};
draw(".ar-line");
draw(".ar-head");

gsap.timeline({ repeat: -1, repeatDelay: 0.7 })
  .to(".ar-line", { strokeDashoffset: 0, duration: 0.7, ease: "power2.out" })
  .to(".ar-head", { strokeDashoffset: 0, duration: 0.35, ease: "power2.out" }, "-=0.15");
```

#### `svg-blob` — ブロブが有機的に変形
```js
// path の d も、コマンドの並びが同じなら attr で補間できる（C の数と順序を揃えるのがコツ）
gsap.timeline({ repeat: -1, yoyo: true, defaults: { duration: 2, ease: "sine.inOut" } })
  .to(".bb-shape", {
    attr: { d: "M100,20 C150,34 180,64 172,108 C164,152 128,182 92,176 C56,170 24,136 30,94 C36,52 50,6 100,20 Z" },
    fill: "#ec4899",
  });
```

#### `svg-bar` — 棒グラフが伸びる
```js
gsap.from(".bg2-bar", { scaleY: 0, duration: 0.9, ease: "power3.out", stagger: 0.1 });
```

#### `svg-line-chart` — 折れ線グラフと点
```js
const path = document.querySelector(".lc-line");
const len = path.getTotalLength();

// 線を描き始めた少し後から点を出すと、線に沿って現れるように見える
gsap.timeline()
  .fromTo(path,
    { strokeDasharray: len, strokeDashoffset: len },
    { strokeDashoffset: 0, duration: 1.3, ease: "power2.inOut" })
  .from(".lc-dot", { scale: 0, duration: 0.4, ease: "back.out(3)", stagger: 0.12 }, 0.2);
```

#### `svg-signature` — 手書き署名風
```js
// 1本の連続したパスにしておくと、ペンで書いたように順番どおり描かれる
const path = document.querySelector(".sg2-p");
const len = path.getTotalLength();

gsap.fromTo(path,
  { strokeDasharray: len, strokeDashoffset: len },
  { strokeDashoffset: 0, duration: 2.2, ease: "power1.inOut", repeat: -1, repeatDelay: 1 }
);
```

#### `svg-dot-path` — 点がパス上を進む
```js
// MotionPathPlugin を使わずとも、getPointAtLength で座標を拾えばパス上を動かせる
const track = document.querySelector(".dp2-track");
const dot = document.querySelector(".dp2-dot");
const len = track.getTotalLength();
const state = { d: 0 };

gsap.to(state, {
  d: len,
  duration: 2.6, ease: "power1.inOut", repeat: -1, yoyo: true,
  onUpdate: () => {
    const p = track.getPointAtLength(state.d);
    gsap.set(dot, { attr: { cx: p.x, cy: p.y } });
  },
});
```

### インタラクション

#### `ix-magnetic` — マグネットボタン（追従）
```js
const btn = document.querySelector(".mg-btn");
const area = document.querySelector(".mg-area");

// quickTo は毎フレーム呼んでも軽い、追従アニメ専用のショートカット
const xTo = gsap.quickTo(btn, "x", { duration: 0.5, ease: "power3" });
const yTo = gsap.quickTo(btn, "y", { duration: 0.5, ease: "power3" });

area.addEventListener("pointermove", (e) => {
  const r = btn.getBoundingClientRect();
  xTo((e.clientX - (r.left + r.width / 2)) * 0.4);   // 0.4 = 引っ張られる強さ
  yTo((e.clientY - (r.top + r.height / 2)) * 0.4);
});
area.addEventListener("pointerleave", () => { xTo(0); yTo(0); });
```

#### `ix-cursor` — カスタムカーソル追従
```js
// 追従速度に差をつけると、リングが遅れて付いてくる質感が出る
const dotX  = gsap.quickTo(".cu-dot", "x",  { duration: 0.12, ease: "power2" });
const dotY  = gsap.quickTo(".cu-dot", "y",  { duration: 0.12, ease: "power2" });
const ringX = gsap.quickTo(".cu-ring", "x", { duration: 0.55, ease: "power3" });
const ringY = gsap.quickTo(".cu-ring", "y", { duration: 0.55, ease: "power3" });

window.addEventListener("pointermove", (e) => {
  dotX(e.clientX);  dotY(e.clientY);
  ringX(e.clientX); ringY(e.clientY);
});
```

#### `ix-tilt` — 傾くカード（3Dチルト）
```js
const scene = document.querySelector(".tl-scene");
const card = document.querySelector(".tl-card3");

const rx = gsap.quickTo(card, "rotationX", { duration: 0.5, ease: "power3" });
const ry = gsap.quickTo(card, "rotationY", { duration: 0.5, ease: "power3" });

scene.addEventListener("pointermove", (e) => {
  const r = card.getBoundingClientRect();
  // カード中心からのズレを -1〜1 に正規化して、最大34度まで傾ける
  rx(((e.clientY - (r.top + r.height / 2)) / r.height) * -34);
  ry(((e.clientX - (r.left + r.width / 2)) / r.width) * 34);
});
scene.addEventListener("pointerleave", () => { rx(0); ry(0); });
```

#### `ix-ripple` — クリックで波紋
```js
const btn = document.querySelector(".rp-btn");

btn.addEventListener("click", (e) => {
  const r = btn.getBoundingClientRect();
  const wave = document.createElement("span");
  wave.className = "rp-wave";
  wave.style.left = (e.clientX - r.left) + "px";   // クリックした位置から広がる
  wave.style.top  = (e.clientY - r.top) + "px";
  btn.appendChild(wave);

  // 使い終わった要素は onComplete で必ず削除する（放置するとDOMが増え続ける）
  gsap.to(wave, { scale: 26, opacity: 0, duration: 0.7, ease: "power2.out",
                  onComplete: () => wave.remove() });
});
```

#### `ix-drag` — ドラッグで動かす（Draggable）
```js
gsap.registerPlugin(Draggable);

Draggable.create(".dg-item", {
  type: "x,y",
  bounds: ".dg-area",          // 親からはみ出さないように制限する
  onPress()   { gsap.to(this.target, { scale: 1.1, duration: 0.2 }); },
  onRelease() { gsap.to(this.target, { scale: 1, duration: 0.3, ease: "back.out(2)" }); },
});
```

#### `ix-accordion` — アコーディオン開閉
```js
document.querySelectorAll(".ac-item").forEach((item) => {
  const body = item.querySelector(".ac-body");
  let open = false;

  item.querySelector(".ac-head").addEventListener("click", () => {
    open = !open;
    // GSAPは height: "auto" を扱える（実寸を測ってから数値でアニメーションしてくれる）
    gsap.to(body, { height: open ? "auto" : 0, duration: 0.4, ease: "power2.inOut" });
    gsap.to(item.querySelector(".ac-mark"), { rotation: open ? 135 : 0, duration: 0.4 });
  });
});
```

#### `ix-modal` — モーダルの出入り
```js
const overlay = document.querySelector(".md-overlay");

// 開閉で2本作らず、1本を play / reverse する。visibility は set() で先に切り替える
const tl = gsap.timeline({ paused: true })
  .set(overlay, { visibility: "visible" })
  .to(overlay, { opacity: 1, duration: 0.25, ease: "power2.out" })
  .from(".md-panel", { y: 24, scale: 0.94, duration: 0.35, ease: "back.out(1.5)" }, "<");

document.querySelector(".md-open").addEventListener("click", () => tl.play());
document.querySelector(".md-close").addEventListener("click", () => tl.reverse());
overlay.addEventListener("click", (e) => { if (e.target === overlay) tl.reverse(); });
```

#### `ix-menu` — メニューが順に開く
```js
const tl = gsap.timeline({ paused: true })
  .to(".mn-panel", { clipPath: "inset(0 0 0% 0)", duration: 0.45, ease: "power3.inOut" })
  // 面が開ききる少し前から項目を出すと、待たされる感じが消える
  .from(".mn-item", { x: -24, opacity: 0, duration: 0.35, stagger: 0.07 }, "-=0.15");

let open = false;
document.querySelector(".mn-btn").addEventListener("click", () => {
  open = !open;
  open ? tl.play() : tl.reverse();
});
```

#### `ix-compare` — 画像比較スライダー
```js
gsap.registerPlugin(Draggable);

const area = document.querySelector(".cp2-area");
const handle = document.querySelector(".cp2-handle");

const applyClip = () => {
  // ハンドルの x は中心を0とした相対値。0〜1の比率に直して clip-path に渡す
  const ratio = (gsap.getProperty(handle, "x") + area.offsetWidth / 2) / area.offsetWidth;
  gsap.set(".cp2-before", { clipPath: \`inset(0 \${(1 - ratio) * 100}% 0 0)\` });
};

Draggable.create(handle, { type: "x", bounds: area, onDrag: applyClip });
```

#### `ix-shake` — エラー時のシェイク
```js
const form = document.querySelector(".sh-form");
const input = document.querySelector(".sh-input");

form.addEventListener("submit", (e) => {
  e.preventDefault();
  if (input.value.trim()) return;

  // repeat + yoyo の短いトゥイーンでシェイクになる。
  // clearProps でインラインの transform を消しておくと、後続のCSSと衝突しない
  gsap.fromTo(input, { x: 0 },
    { x: 10, duration: 0.07, repeat: 5, yoyo: true, clearProps: "x" });
});
```

#### `ix-copy` — コピー完了のフィードバック
```js
gsap.set(".cy-done", { yPercent: 100 });

const tl = gsap.timeline({ paused: true })
  .to(".cy-label", { yPercent: -100, duration: 0.3, ease: "power2.in" })
  .to(".cy-done", { yPercent: 0, duration: 0.3, ease: "power2.out" }, "<")
  // 空のトゥイーンは「何もしない間」を作るための定番の書き方
  .to({}, { duration: 1.2 })
  .to(".cy-done", { yPercent: 100, duration: 0.3, ease: "power2.in" })
  .to(".cy-label", { yPercent: 0, duration: 0.3, ease: "power2.out" }, "<");

document.querySelector(".cy-btn").addEventListener("click", async () => {
  await navigator.clipboard.writeText("コピーしたい文字列");
  tl.restart();
});
```
