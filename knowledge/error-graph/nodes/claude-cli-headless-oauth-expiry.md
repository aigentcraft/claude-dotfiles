---
title: "claude CLI: 認証系の環境変数は参照されない。auth status も有効性を保証しない"
description: "無人実行の claude -p が 401 になる。auth status は loggedIn: true を返し、CLAUDE_CODE_OAUTH_TOKEN も ANTHROPIC_API_KEY も参照されない。CLI 自身の保存資格情報の失効で先に落ちているため、復旧は claude auth login。"
type: "technical-error"
tags: ["claude-code", "cli", "auth", "headless", "automation", "diagnosis-method"]
relationships:
  caused_by: []
  related_to: ["ai-instruction-enforcement"]
  fixes_node: []
---

## 1. Plan / Context
副業HOOTL で、副業サイトの新着メッセージへの返信案を**無人で**生成させるため、
Node のサブプロセスから `claude -p` を呼ぶ設計にした（API キーを持たず、
既存の Claude Code サブスクリプションをそのまま使うため）。

## 2. Do / The Error
```
Failed to authenticate. API Error: 401 OAuth access token has expired. Re-authenticate to continue.
```
一方、認証状態の確認コマンドは正常を返す:
```
$ claude auth status
{ "loggedIn": true, "authMethod": "claude.ai", "subscriptionType": "max", ... }
```

## 3. Check / Root Cause

### 誤診の経緯（重要）
最初は「`claude setup-token` の長期トークンを `CLAUDE_CODE_OAUTH_TOKEN` で渡せば通る」と
判断した。トークンを Keychain に登録して env で注入したが、変化なし。
次に「トークンが 49 文字と短いのでコピー時に切れた」と推測した。**これも誤り。**

### 切り分けを決めた実験
**意図的に無効な値**を環境変数に入れ、エラー文言が変化するかを見た:

| 条件 | 結果 |
|---|---|
| A. `CLAUDE_CODE_OAUTH_TOKEN` に無効値 | 401・文言が B と完全一致 |
| B. 環境変数なし | 401 |
| C. `ANTHROPIC_API_KEY` に無効値 | 401・文言が B と完全一致 |

**無効な値を渡してもエラーが変わらない = その環境変数は読まれていない。**

真因は、**CLI が自身の保存資格情報の失効で先に失敗しており、環境変数まで到達していない**こと。
401 はこちらが渡したトークンの話ではなく、CLI 自身の資格情報の話だった。

## 4. Act / Prevention Strategy (Fix)

### 復旧手順
```bash
claude auth login      # 対話再認証（CLI 自身の資格情報を更新する）
```

### 予防ルール

1. **「環境変数が読まれているか」は、意図的に無効な値を入れて確かめる。**
   正しい値を入れて失敗しても「値が悪い」のか「読まれていない」のか区別できない。
   **無効値でエラーが変化しなければ、その入力経路は使われていない。**
   これは env / 設定ファイル / CLI 引数すべてに使える一般的な切り分け手法。
2. **`status` 系コマンドを可否判定に使わない。** 資格情報の「有無」しか見ていないことが多い。
   実際に 1 回叩いた結果で判定する（`--verify` のような疎通確認を実装する）。
3. **「登録済み」と「使える」を UI 上で区別する。** Keychain に入っただけで OK と表示すると、
   使えない状態を見逃す。疎通確認の結果を別の状態として表示する。
4. **推測で対処手順を案内しない。** 「トークンが切れているはず」と長さから推測して
   再取得を依頼したが、実際は長さの問題ではなく、利用者の手間を無駄にした。
   切り分け実験を先に行ってから案内する。
