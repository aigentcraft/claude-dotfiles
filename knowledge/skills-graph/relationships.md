---
title: "Skills Complement Graph"
description: "スキル間の補完関係を定義する中央グラフ。AIはスキル使用前にここを参照する。"
tags: ["skills", "graph", "complement"]
relationships:
  related_to: ["[[../skills-moc.md]]"]
---

# Skills Complement Graph

## AIへの指示（必読）

スキルを使用する際は、**必ずこのファイルを先に参照**し、補完スキルを確認すること。
補完スキルが存在する場合、以下の基準で追加読み込みと統合を行う：

| タスクの性質 | 補完スキルを読む数 |
|---|---|
| 単純・単一出力（「画像作って」「ツイート書いて」） | +1個（最も関連度が高いもの） |
| 複合・複数出力（「X投稿を完成させて」「キャンペーン作って」） | クラスター内全部 |
| ユーザーが「最高のものを」「完璧に」「全部使って」と言った | 全部 |

### 合成プロトコル
1. プライマリスキルを読む
2. このグラフで補完スキルを確認する
3. 基準に従って補完スキルを読む
4. 複数スキルのアプローチを統合してアウトプットを生成する
5. （複合タスクの場合）「X と Y を組み合わせて生成しました」と明示する

---

## 補完エッジ一覧

### X / SNS クラスター

| プライマリスキル | 補完スキル | 理由 |
|---|---|---|
| `x-viral-writing` | `x-image-prompt` | テキスト+画像でX投稿が完成する |
| `x-viral-writing` | `copywriting` | コピーライティング理論で文章の深度・説得力UP |
| `x-image-prompt` | `nanobanana` | プロンプト生成→即画像生成のフロー |
| `x-image-prompt` | `nano-banana-pro-prompts-recommend-skill` | 6000+プロンプトから最適を先に選ぶ |
| `ai-social-media-content` | `x-viral-writing` | X特化のバイラル心理学を加える |
| `ai-social-media-content` | `x-image-prompt` | 画像生成プロンプトの精度UP |

### 画像生成クラスター

| プライマリスキル | 補完スキル | 理由 |
|---|---|---|
| `nanobanana` | `nano-banana-pro-prompts-recommend-skill` | 生成前に最適プロンプトを選ぶと品質UP |
| `gpt-image-1-5` | `nano-banana-pro-prompts-recommend-skill` | モデルが違ってもプロンプト推薦は有効 |
| `nano-banana-pro-prompts-recommend-skill` | `nanobanana` | 推薦後そのまま生成まで完結できる |

### プロジェクト管理クラスター

| プライマリスキル | 補完スキル | 理由 |
|---|---|---|
| `skill-pdca-error-graph` | `skill-project-map` | エラー記録+構造把握で完全なプロジェクト認知 |
| `skill-project-map` | `skill-pdca-error-graph` | 構造変更時は過去の失敗も参照して安全に動く |

### 開発クラスター

| プライマリスキル | 補完スキル | 理由 |
|---|---|---|
| `skill-hyperbrowser-reference` | `skill-project-map` | 実装前にプロジェクト構造を把握してから参照 |
| `slack-remote-run` | `skill-project-map` | リモートコマンド実行前にプロジェクト構造を把握して安全に操作する |
| `slack-remote-run` | `auto-sync-rule` | リモート操作前に最新コードへの同期を保証する |

### システム・ガバナンスクラスター

| プライマリスキル | 補完スキル | 理由 |
|---|---|---|
| `auto-sync-rule` | `skill-pdca-error-graph` | 同期後に失敗知識を確認してから開発を進める |
| `skill-installer` | `auto-sync-rule` | 新スキルインストール後は同期ルールを即適用する |

---

## メンテナンスルール

| 条件 | アクション |
|---|---|
| 新しいスキルがインストールされた | 既存スキルとの補完関係を検討し、このファイルに追記する |
| スキルが削除された | 関連するエッジをこのファイルから削除する |
| 同一クラスターのエッジが **5件以上** になった | クラスターを分割することを検討する |

### Append-Only ルール（マルチエージェント競合防止）
このファイルは複数のAIエージェントが junction 経由で共有している。
- **既存エッジの書き換え・並べ替え禁止** — 新しいエッジは各クラスターテーブルの末尾に追加する
- **新しいクラスターは末尾に追加する** — 既存クラスターの順序を変更しない
- **削除は「スキルが削除された場合」のみ** — リファクタリング目的の並べ替えは禁止

---

*Note: エッジを追加したら [[../skills-moc.md|skills-moc.md]] のクラスター定義も更新すること*
