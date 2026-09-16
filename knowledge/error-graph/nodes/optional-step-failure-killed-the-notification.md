---
title: "おまけの処理を先に呼んだせいで、本体の通知ごと消えた"
description: "新着メッセージの通知より先に返信案の生成（LLM）を呼んでいたため、CLI のトークン失効だけで企業からの連絡が丸ごと通知されなかった。例外は捕捉・記録されていたので、外からは「処理済み」に見えた。"
type: "technical-error"
tags: ["error-handling", "ordering", "notification", "llm", "silent-failure", "hootl"]
relationships:
  caused_by: []
  related_to: ["swallowed-error-logged-as-success", "stale-selector-reported-success-as-failure"]
  fixes_node: []
---

## 1. Plan / Context
企業から新着メッセージが届いたら、Discord に通知し、あわせて返信案を出す。
1 件の失敗で巡回全体を止めないよう、各件を try/catch で囲んであった。

## 2. Do / The Error
利用者からの指摘: 「企業からのメッセージが複数届いているけど Discord には通知が来てない」。

ログを見ると、検知はしていた。

```
[18:00:21] [INFO] 新着: [scout] レジル株式会社
[18:00:26] [FAIL] レジル株式会社 の処理に失敗: claude CLI の認証が通りませんでした。
```

**企業から連絡が来た事実そのものが、どこにも残らなかった。**

## 3. Check / Root Cause

```ts
const draft = await generateDraft({ thread });          // ← LLM。失効で例外
const discordThreadId = await bridge.notifyArrival(thread);  // ← 到達しない
```

呼ぶ順序が逆だった。**通知は本体、返信案はおまけ**なのに、おまけを先に呼んでいた。

try/catch は機能しており、巡回は止まらず、ログにも残った。
つまり「エラー処理はしてある」状態だったが、**利用者から見れば情報が消えた**だけだった。
巡回は次の周期も同じ場所で落ちるので、トークンを直すまで永久に通知されない。

さらに、失敗時は記録（ThreadRecord）も作られないため、
「通知に失敗したまま放置されている件がある」ことすら一覧に出てこなかった。

## 4. Act / Fix & Prevention

順序を入れ替え、生成の失敗は**劣化**として扱うようにした。

```ts
const discordThreadId = await notify(thread);   // まず知らせる
try {
  draft = await generateDraft({ thread });
  await postDraft(discordThreadId, draft);
} catch (error) {
  await postNotice(discordThreadId,
    '⚠️ 返信案を生成できませんでした。**メッセージは届いています**（上を参照）。');
}
upsertRecord(newRecord(thread, draft ? 'awaiting_approval' : 'failed', { discordThreadId, draft }));
```

実地検証: 溜まっていた 11 件が、返信案の生成に失敗したまま**全件通知された**。

### 予防ルール

1. **必須と付加価値を分け、必須を先に完了させる。**
   「人間に知らせる」は必須。「気の利いた下書きを添える」は付加価値。
   付加価値の失敗が必須を巻き添えにする順序で書かない。
2. **外部依存（LLM・API・CLI）は必ず落ちると考えて、その外側に必須処理を置く。**
3. **例外を捕捉して次へ進む設計は、「利用者にとって何が失われたか」を別に考える。**
   プロセスが止まらないことと、情報が届くことは別の要件。
4. **失敗しても記録を残す。** 記録が無いと「取りこぼしがある」ことが観測できない。

## 5. 続き — 劣化させたら、そこから戻る道も作る

修正後にもう 1 つ穴が残っていた。失敗時に記録を `failed` で残すようにしたことで、
**新着判定が「記録あり・指紋同じ」と見て二度と処理しなくなった**。

```ts
if (record.fingerprint === thread.fingerprint) return false;   // 永久にスキップ
```

結果、「通知は届いたが返信案は永久に作られない」状態で 11 件が固定された。
トークンを直しても自動では回復しない。

再試行は**新着経路に戻してはいけない**。戻すと通知をやり直して Discord スレッドが二重にできる。
「通知済みだが生成だけ失敗した件」を拾い、**同じスレッドへ生成結果だけ追加する**専用経路を足した。

実地検証: トークン復旧後、11 件すべての返信案が既存スレッドへ投稿され、
状態が `failed` から `awaiting_approval` へ戻った。

**教訓: 劣化（graceful degradation）は新しい中間状態を作る。
その状態から正常へ戻る経路を、劣化を実装したその場で一緒に作ること。**
「落ちないようにした」だけでは、落ちた先に留まり続ける。
