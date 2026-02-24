---
name: x-image-prompt
description: X(Twitter)投稿・スレッド用のアイキャッチ画像プロンプトを生成する。「ツイート用の画像を作って」「投稿の画像プロンプトを生成して」「Xのアイキャッチ」「OGP画像」などと言われたら使用。Nano Banana Pro（Gemini Image）対応のプロンプトを出力する。
---

# X Image Prompt Generator

X（Twitter）投稿用のアイキャッチ画像を Nano Banana Pro で生成するための最適化プロンプトを作成する。

---

## ワークフロー

```
ツイート本文 → 感情トリガー分析 → ビジュアルコンセプト決定 → Nano Banana Pro プロンプト生成 → 画像生成
```

### Step 1: ツイート内容の分析

ツイートのテキストから以下を抽出する：
- **主題**: 何について書いているか
- **感情トリガー**: 共感？驚き？恐れ？好奇心？
- **ターゲット属性**: 誰向けの投稿か
- **メタファー/比喩**: 使われているアナロジーがあるか

### Step 2: ビジュアルコンセプトの決定

感情トリガーに基づいてビジュアルスタイルを選択：

| 感情トリガー | ビジュアルスタイル | 色彩 |
|-------------|-------------------|------|
| 共感・あるある | 日常シーンのイラスト、柔らかい色調 | 暖色系、パステル |
| 驚き・衝撃 | コントラストの強い構図、ダイナミック | 補色配色、ビビッド |
| 恐れ・危機感 | ダークトーン、崩壊・断絶のモチーフ | 暗色系、赤アクセント |
| 好奇心・知識欲 | 図解風、ミニマル、情報密度 | ブルー系、クリーン |
| 達成・解決 | 明るい光、上昇、完成のモチーフ | ゴールド、グリーン |

### Step 3: プロンプト構成要素

Nano Banana Pro に最適化されたプロンプトは以下の要素で構成する：

```
[主題のビジュアル表現], [スタイル指定], [構図], [色彩/雰囲気], [品質指定]
```

#### 各要素の詳細

**主題のビジュアル表現（最重要）**
- ツイートの比喩やメタファーを視覚化する
- 抽象概念は具体的オブジェクトに変換する
- 例:「AIに記憶がない」→「金魚が泳ぐモニターの前に座る開発者」

**スタイル指定**
- `digital illustration` - テック系・モダン
- `flat design infographic` - 情報整理系
- `cinematic photography` - ドラマチック・ストーリー系
- `isometric 3D render` - システム・アーキテクチャ系
- `manga style` - 日本語圏・エモーショナル
- `minimalist vector art` - クリーン・プロフェッショナル

**構図（X最適化）**
- `centered composition` - OGPプレビューで切れない
- `rule of thirds` - 視線誘導
- `negative space on left/right` - テキストオーバーレイ用余白
- `bold text overlay area` - タイトル入れ用

**品質指定**
- `high detail, sharp focus, professional quality`
- `4K resolution, clean lines, vibrant colors`
- `studio lighting, polished finish`

---

## X（Twitter）画像仕様

| 用途 | アスペクト比 | 推奨サイズ | Nano Banana `--ratio` |
|------|-------------|-----------|---------------------|
| 単独画像ツイート | 16:9 | 1200x675 | `16:9` |
| OGPプレビュー | 1.91:1 | 1200x628 | `16:9`（近似） |
| 正方形画像 | 1:1 | 1080x1080 | `1:1` |
| スレッド内画像 | 4:3 | 1200x900 | `4:3` |

**デフォルトは `16:9`**。フィードで最も面積を取り、スクロール停止率が高い。

---

## スクロール停止を引き起こす画像の原則

### 1. CONTRAST PRINCIPLE（コントラスト原則）
フィードは白/グレー基調。**彩度の高い色**か**真っ暗な背景**が目を引く。

### 2. FACE PRINCIPLE（顔原則）
人間の脳は顔を0.1秒で検出する。キャラクターやアバターの顔を入れると停止率が上がる。

### 3. TEXT-IMAGE MISMATCH（テキスト画像ギャップ）
画像が「答え」を持っていて、テキストが「問い」を持つ構成。
両方を見ないと意味がわからない→エンゲージメントが上がる。

### 4. PATTERN BREAK（パターン中断）
フィードの中で「異質」に見える画像。写真の中にイラスト、テキストの中にグラフ、など。

---

## プロンプトテンプレート

### テック系・開発者向け
```
A developer sitting in front of dual monitors in a dimly lit room,
one screen showing clean code, the other showing chaotic error messages,
digital illustration style, moody blue and orange lighting,
centered composition with negative space at top for text overlay,
high detail, 4K quality, professional tech aesthetic
```

### 比較・Before/After
```
Split screen composition: left side dark and chaotic, right side bright and organized,
representing transformation from manual to automated workflow,
flat design infographic style, high contrast color scheme,
clean vector lines, 16:9 aspect ratio, professional quality
```

### 概念図・システム図
```
Isometric 3D render of interconnected glowing nodes forming a network,
data flowing between a laptop, cloud server, and mobile phone,
minimal background, soft gradient from dark blue to black,
neon accent colors (cyan and magenta), futuristic tech aesthetic,
high detail, sharp edges, professional quality
```

### エモーショナル・共感系
```
A tired robot sitting alone at a desk surrounded by sticky notes,
each note has a different instruction, warm yellow desk lamp glow,
manga-inspired illustration style, soft shadows, empathetic mood,
16:9 cinematic composition, pastel color palette with warm tones
```

---

## 画像生成コマンド

### Nano Banana Pro（推奨）
```bash
python3 ~/.agents/skills/nanobanana/scripts/generate.py "YOUR_PROMPT_HERE" --ratio 16:9 --size 2K -o tweet_image.png
```

### GPT Image 1.5（代替）
```bash
uv run ~/.claude/skills/gpt-image-1-5/scripts/generate_image.py --prompt "YOUR_PROMPT_HERE" --size 1536x1024 --quality high --filename tweet_image.png
```

---

## 出力フォーマット

プロンプト生成時は以下の形式で出力する：

```
📸 画像コンセプト: [1行の説明]
🎨 スタイル: [使用するスタイル]
📐 アスペクト比: 16:9

🖼️ プロンプト:
[Nano Banana Pro 用の完全なプロンプト（英語）]

🔧 生成コマンド:
python3 ~/.agents/skills/nanobanana/scripts/generate.py "[プロンプト]" --ratio 16:9 --size 2K -o image.png
```

---

## 関連スキル

- **x-viral-writing**: ツイート本文の執筆（このスキルと組み合わせて使用）
- **nano-banana-pro-prompts-recommend-skill**: 6000+プロンプトからの推薦検索
- **nanobanana**: Nano Banana Pro 画像生成スクリプト
- **gpt-image-1-5**: GPT Image 1.5 画像生成スクリプト
- **copywriting**: コピーライティング全般
