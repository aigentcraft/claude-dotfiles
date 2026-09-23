---
name: stop-script-killed-every-playwright-browser
title: 常駐の停止スクリプトが、PC 上の Playwright のブラウザを全部終了させていた
cluster: observability
type: "runtime-error"
tags: ["windows", "powershell", "process-tree", "playwright", "orphan", "kill-scope", "fukugyo-hootl"]
date: 2026-09-23
severity: medium
relationships:
  related_to:
    - "stop-task-leaves-either-wrapper-or-child.md"
---

## 1. Plan / Context

`uninstall-agent.ps1` は常駐（タスク → run-watch.ps1 → node）を止めた後、
取り残されたブラウザを掃除していた。判定は「実行ファイルのパスに `ms-playwright` を含む chrome」。
利用者が普段使う Chrome を巻き込まないための絞り込みだった。

## 2. Do / The Error

同じ作業ツリーで 2 つのセッションが並行していた。片方が常駐を再起動した瞬間、
もう片方の selftest が落ちた。

```
[14:18:05] [FAIL] page.waitForTimeout: Page crashed
取り残された Playwright のブラウザを終了します（8 個）
```

8 個は常駐のものではなく、selftest の使い捨てブラウザだった。
常駐中に許されている `npm run login -- indeed`（プロファイルが別）や doctor のブラウザも同じく巻き込まれる。

## 3. Check / Root Cause

- **「普段の Chrome ではない」と「常駐のもの」は別の集合。** 絞ったのは前者だけで、
  同じ PC で Playwright を使う他の処理（selftest・doctor・有人ログイン・他プロジェクト）が全部入っていた
- 2 日前に R-STOP として「終わらせる判定は狭く」を書き、node と起動スクリプトは**プロジェクトで絞った**。
  **ブラウザの掃除だけ、その規則が適用されずに残っていた**（規則を書いた範囲と直した範囲がずれた）
- 実測（2026-09-23）: Playwright のブラウザ本体は起動した node の**直接の子**、補助プロセスは本体の子。
  どれも `--user-data-dir` を持つ（引用符つきとなしが混在）。node を殺すとブラウザは自分で終わる（pipe が切れる）ので、
  「取り残し」は普段は起きず、起きるのは例外的な時だけ

## 4. Act / Prevention Strategy (Fix)

`scripts/windows/agent-browsers.ps1` の `Select-AgentBrowsers`（純関数）で選ぶ:

1. **常駐の子孫**にいる Playwright のブラウザ（親子関係は**止める前に**控える。親を消すと辿れない）
2. **親を失った** Playwright のブラウザのうち、プロファイルが `<プロジェクト>\.sessions\` の**下**のもの（前方一致）

とその子孫だけ。PID の使い回しに備え、子より後に生まれた「親」は親とみなさない。
控えた PID は起動時刻まで一致した時だけ同じプロセスとして終わらせる。残したものは数だけ報告する。

- selftest が偽のプロセス一覧（常駐・selftest・有人ログイン・隣のフォルダ・普段の Chrome・使い回しの PID）で確かめる
- 故障注入: 旧判定に戻す → FAIL（11 個選ぶ）／使い回しの判定を外す → FAIL（800 を選ぶ）
- 実物: 探りのブラウザで「常駐とみなせば 9 個・みなさなければ 0 個」、
  孤児にしたブラウザで「探りのプロジェクトなら 11 個・本物のプロジェクトなら 0 個」

### 予防ルール

1. **終わらせる対象は「自分が起動したもの」で定義する。** 「〜ではないもの」の除外で定義すると、同じ種類の他人が入る
2. **親子関係で選ぶなら、親を消す前に控える。** 後からでは辿れない
3. 規則を書いたら、**同じ種類の処理を全部**その規則で見直す（node は直したがブラウザは直さなかった）
