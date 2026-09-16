---
title: "「存在するか」で弾いて「処理済みか」を見ていなかった"
description: "予算上限で処理を繰り越した項目が、次回実行で『既知』として存在チェックに弾かれ、永久に処理されなくなった。存在と完了は別の概念。"
type: "technical-error"
tags: ["idempotency", "batch-processing", "state-design", "cost-control"]
relationships:
  caused_by: []
  related_to: ["recovery-implemented-but-not-wired"]
  fixes_node: []
---

## 1. Plan / Context
LLM 判定にコストがかかるため、1 回の実行で判定する件数に上限を設けた。
上限を超えた分は「次回の実行で処理する」つもりで、レコードだけ作って判定を保留した
（`state = screening`, `verdict = NULL`）。

## 2. Do / The Error
次回実行の結果:
```
発見          60 件
既知（再判定なし） 60 件   ← 全部スキップされた
LLM 判定        0 件
```
繰り越したはずの 42 件が 1 件も処理されなかった。

## 3. Check / Root Cause

```ts
// 欠陥のあったコード
if (jobExists(item.jobKey)) { alreadyKnown += 1; continue; }
```

`jobExists()` は **DB に行があるか**しか見ていない。
繰り越した項目は「行はあるが判定はまだ」の状態なので、存在チェックに引っかかる。

**「存在する」と「処理が終わっている」を同一視したのが原因。**
上限で打ち切る設計を入れた時点で、この 2 つは必ず分岐する。

さらに悪いのは**失敗が静かなこと**。「既知 60 件」はエラーに見えず、
正常動作の報告として表示される。実行するほど「何もしない」状態が続く。

## 4. Act / Prevention Strategy (Fix)

```ts
/** 「判定済みか」を返す。「DB に存在するか」ではない */
export function isJobScreened(jobKey: string): boolean {
  const row = db().prepare('SELECT verdict FROM jobs WHERE job_key = ?').get(jobKey);
  return row?.verdict != null;   // 完了を示す列で判定する
}
```

### 予防ルール

1. **冪等性の判定は「完了を示す列」で行う。** 主キーの存在で弾かない。
   `verdict IS NOT NULL` / `completed_at IS NOT NULL` のように、
   **処理が終わったことを示すフィールド**を必ず用意して、それで判定する。
2. **処理を打ち切る仕組み（上限・タイムアウト・バッチ分割）を入れたら、
   「打ち切られた分が次回どう拾われるか」を同時に設計する。**
   打ち切りだけ実装して再開経路を作らないのは未完成。
3. **スキップ件数が全件と一致したら異常を疑う。**
   「既知 60 件 / 処理 0 件」は正常に見えて何も進んでいない。
   全件スキップは警告として出す価値がある。
4. **保留状態にはそれと分かる名前を付ける。** `screening`（判定中）のように
   「まだ終わっていない」ことが読める状態名にすると、存在チェックの誤りに気づきやすい。
