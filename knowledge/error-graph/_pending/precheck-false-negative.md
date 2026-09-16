---
title: "事前の権限チェックがキャッシュ未構築で誤検知し、不要な再設定を促した"
description: "ログイン直後はメンバーキャッシュが空で権限を読めず、権限があるのに『権限なし』と判定。事前チェックより、実際に操作してエラーで判断する方が確実。"
type: "technical-error"
tags: ["discord", "api", "precheck", "false-negative", "cache"]
relationships:
  caused_by: []
  related_to: ["existence-vs-completion-check"]
  fixes_node: []
---

## 1. Plan / Context
Discord Bot がチャンネルを作る前に、`Manage Channels` 権限があるかを事前確認し、
無ければ再招待 URL を案内する設計にした。

```ts
const me = guild.members.me ?? (await guild.members.fetchMe().catch(() => null));
return me?.permissions.has(PermissionFlagsBits.ManageChannels) ?? false;
```

## 2. Do / The Error
権限は確かに付与済みで、**同じコードベースの常駐プロセスはチャンネルの改名に成功していた**
のに、セットアップコマンドだけが失敗した。

```
[FAIL] Bot に「チャンネルの管理」権限がありません。
  → 再招待 URL を案内（実際には不要）
```

## 3. Check / Root Cause
ログイン直後は**メンバーキャッシュが空**で `guild.members.me` が `null`。
フォールバックの `fetchMe()` も `.catch(() => null)` で握りつぶしていたため、
取得失敗と「権限なし」が区別できず `false` に落ちた。

常駐側が成功していたのは、**事前チェックを通らず実操作を直接行っていた**から。

**事前チェックが本処理より脆い**という逆転が起きていた。しかも失敗の向きが悪く、
**偽陰性（権限があるのに無いと言う）**なので、利用者に不要な再設定を強いる。

## 4. Act / Prevention Strategy (Fix)

事前チェックを廃止し、実際に操作してエラーコードで判断する。

```ts
export function isMissingPermissions(error: unknown): boolean {
  const code = (error as { code?: number | string })?.code;
  if (code === 50013 || code === '50013') return true;   // Discord: Missing Permissions
  const message = error instanceof Error ? error.message : String(error);
  return /Missing Permissions|Missing Access/i.test(message);
}

try {
  map = await ensureChannels(...);
} catch (error) {
  if (!isMissingPermissions(error)) throw error;
  // ここで初めて再招待を案内する
}
```

### 予防ルール

1. **事前チェックより実行結果で判断する。** 「できるか確かめてから実行」は、
   確かめる経路が本処理と別だと、そちらが先に壊れる。実行して返ってきた
   エラーで分岐する方が経路が 1 本になり確実。
2. **判定の失敗と「否」を区別する。** `.catch(() => null)` で握りつぶすと
   「取得できなかった」が「無い」に化ける。区別できない場合は、
   **偽陽性より偽陰性の害が大きい方へ倒さない**（ここでは「不明なら実行してみる」）。
3. **同じことをする経路が 2 つあるなら、片方が壊れていないか疑う。**
   常駐は成功しコマンドは失敗した時点で、差分は「事前チェックの有無」だけだった。
