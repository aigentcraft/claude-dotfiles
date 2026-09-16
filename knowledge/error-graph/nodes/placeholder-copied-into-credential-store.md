---
title: "案内文のプレースホルダがそのまま資格情報として登録された"
description: "`-a \"<メールアドレス>\"` を山括弧ごと貼り付け、対話プロンプトにはパスワードではなくアドレスを入力してしまった。さらに検査側が非ASCIIのaccountを読めず『未登録』と誤報告し、破損に気づけなかった。"
type: "technical-error"
tags: ["keychain", "secrets", "developer-experience", "silent-failure", "cli-guidance"]
relationships:
  caused_by: []
  related_to: ["swallowed-error-logged-as-success", "existence-vs-completion-check"]
  fixes_node: []
---

## 1. Plan / Context
秘密を macOS Keychain にだけ置く設計。**登録は利用者自身が行い、コードは読むだけ**。
そのため CLI は登録コマンドを案内として表示する。

```
security add-generic-password -s "fukugyo-hootl:indeed" -a "<メールアドレス>" -U -w
```

## 2. Do / The Error
利用者から「アドレスって書いてあるからアドレス入れたけど、パスワードって入れなくていいのかな」。

実際に登録された内容:

```
"acct"<blob>=0x3C496E64656564E381AE...3E  "<Indeedのメールアドレス>"   ← 山括弧ごと
secret                                    21 文字                      ← パスワードではなくアドレス
```

**account も secret も両方間違っていた。**

## 3. Check / Root Cause

**① 案内文が 2 つの情報を落としていた**

- `<メールアドレス>` が置換対象であることを書いていない
- `-w` の対話プロンプトは `password data for new item:` としか出ない。
  英語で、しかもコマンドの見た目からは何の欄か分からない。
  直前に「メールアドレス」と書いてあれば、そこにアドレスを入れるのが自然な読み。

**② 検査側が破損を検出できなかった**

```ts
// 「項目が在るか」しか見ていない
export function hasCredential(siteId: string): boolean {
  return readAccount(siteId) !== null;
}
```

**③ さらに悪いことに、パーサが非 ASCII を読めなかった**

`security` の出力は値によって 2 形態になる。

```
ASCII のみ : "acct"<blob>="alice@example.com"
非 ASCII   : "acct"<blob>=0x3C49...3E  "<Indeed\343\201\256...>"
```

引用符形式しか見ない正規表現だったため、日本語入りの account が **null** になり
「未登録」と報告された。**壊れた登録が「無い」ことにされた。**

これが最も危険だった。「未登録」の案内どおり登録し直すと、`-U` は
「同じ service かつ同じ account」しか更新しないので**別項目が追加され**、
同じ service の項目が 2 つできて `find-generic-password -s` の戻り値が曖昧になる。

## 4. Act / Fix & Prevention

1. **案内に、置換と対話プロンプトの中身を明記する**

```
※ 山括弧 <> の部分は実際の値に置き換えてください（山括弧も消します）
※ 実行すると `password data for new item:` と聞かれます。
   そこに入力するのは サイトのパスワード です（確認のため 2 回入力します）。
※ 入力しても画面には何も表示されません（伏せ字ではなく無表示）。
```

2. **「在るか」ではなく「使えるか」を検査する**

```ts
type CredentialHealth = 'ok' | 'missing' | 'placeholder' | 'empty-secret';
if (/^<.*>$/.test(account.trim())) return 'placeholder';   // 案内文の貼り付け
if (readCredential(siteId) === null) return 'empty-secret'; // 秘密が空
```

3. **訂正手順に「先に削除」を含める。** 更新コマンドが更新にならない条件を書く。

### 予防ルール

- **利用者に貼り付けさせるコマンドは、貼り付けただけで動く状態で出すか、
  置換が必要な箇所を明示する。** プレースホルダは必ずそのまま貼られると考える。
- **対話入力を伴うコマンドを案内する時は、プロンプトに何を入れるかまで書く。**
  プロンプトの文言は自分たちで制御できない。
- **外部コマンドの出力をパースする時は、値によって形式が変わらないか確かめる。**
  ASCII だけで試すと非 ASCII 形式を取りこぼす。取りこぼしが「無い」に化けると、
  破損データが正常系の案内に流れ込む。
