---
name: uc-browser-ops-scripted-instead-of-claude-operated
title: 「クロードに操作させたいんだけど、なんでそうしないの？」— X の画面操作を、相談せずに決め打ちのスクリプトで組んだ
cluster: uc
type: "design-gap"
tags: ["uc", "x-twitter", "browser-automation", "agent-autonomy", "claude-in-chrome", "ask-before-architecture", "weevee"]
date: 2026-10-03
severity: medium
relationships:
  related_to:
    - "uc-x-api-spend-guard-counted-requests-not-dollars.md"
    - "uc-desk-agent-still-mechanical-one-shot.md"
---

## ユーザーの指摘（原文）

「ブラウザはクロードインクロームでaigentcraft@gmail.comのプロファイルのブラウザをちゃんと使ってる？」
「クロードに操作させたいんだけど、なんでそうしないの？」
（同日・続き）「プロファイルをweeveeのやつ作ろう、aigentcraftじゃなくて」

## 1. Plan / Context

2026-10-03、X API の課金を止めるため（人間決定⑯）、DM 以外の X 操作を画面経由に切り替えた。
既存の引用・自発リプの経路（Playwright が別の Chrome を起動し、保存した @weevee_jp の Cookie で、
決め打ちのセレクタを押す）を、そのまま投稿・いいね・フォロー・閲覧に広げた。

## 2. Do / The Error

- 「ブラウザ操作で代替」を、**誰が操作するか**を確かめずに「決め打ちのスクリプトが操作する」と読んだ
- 返答で示した選択肢 3 つ（今のまま・専用プロファイル・aigentcraft のプロファイル）は、どれもスクリプトが操作する前提で、
  **Claude が操作する案を出していなかった**
- このプロジェクトは人間決定⑭で「全役割を、道具を持って自分で動く LLM エージェントにする」と決めている

## 3. Check / Root Cause

- 既存の実装（Playwright の経路）を「このプロジェクトでの画面操作のやり方」として無検討で引き継いだ
- 速さ・無人運転・課金ゼロを優先した判断を、本人に選ばせずに確定させた（設計の分かれ道で聞いていない）

## 4. Act / Prevention Strategy (Fix)

- 2026-10-03: 理由と制約（Chrome が開いている必要・画面にタブが出る・Claude の使用量・ログイン中の X アカウント）を示し、
  Claude に操作させる形への切り替えを提案
- 同日、本人の選択「読むのも含めて全部 Claude」「送信を止めて保留」→ weevee `workers/shared/x_operator.py`
  （Claude が `claude -p --chrome` で画面を操作）と `x_claude_read.py`（先読みした画面を xmcp と同じ call_tool の口で渡す）を実装し、
  送信 7 経路（告知・速報・いいね・交流リプ・フォロー・メンション返信・引用）を接続。送信の成立は「Claude の報告」と
  「画面の証拠」の両方で決める（証拠の無い「送った」は成功にしない）。`X_SEND_HOLD=1` の間は Claude を起動しない
- 同日の追加指摘「プロファイルをweeveeのやつ作ろう、aigentcraftじゃなくて」: 拡張が人の普段のプロファイル（aigentcraft）に
  つながっていたので、そのまま使う前提で組んでいた → 操作は weevee 専用プロファイル（weevee.ai@gmail.com）に限定し、
  ブリーフで接続名「weevee」のブラウザだけを `select_browser` で選ぶ形にした（拡張の追加とログインは本人の作業）

### 予防ルール

1. **外部の画面を「誰が操作するか」は設計の分かれ道。** スクリプト / Claude（エージェント）の両案と、それぞれの代償を示して本人に選ばせる
2. 既存の実装方式を広げるときは、「この方式で良いか」を一度問い直す（引き継いだだけの方式を拡大しない）
3. 本人が決めた原則（このプロジェクトでは⑭: 役割は道具を持って自分で動く）と食い違う案は、食い違うことを明記してから出す
4. **自動操作に使うブラウザ（プロファイル）は、その事業専用のものに限る。** 人の普段のプロファイル（個人のメール・Cookie・履歴）では
   動かさない。「拡張がつながっているから」を理由に使わない。どのプロファイルで動かすかは、組む前に本人に確かめる
