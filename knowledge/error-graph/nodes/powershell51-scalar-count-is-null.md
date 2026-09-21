---
name: powershell51-scalar-count-is-null
title: PowerShell 5.1 で CimInstance 1 件の .Count は空になる（7 では 1）
cluster: platform-syntax
type: "runtime-error"
tags: ["powershell", "windows", "version-difference", "reporting", "fukugyo-hootl"]
date: 2026-09-21
relationships:
  related_to:
    - "stop-task-leaves-either-wrapper-or-child.md"
    - "uc-handed-bash-syntax-to-a-powershell-user.md"
---

## 症状

停止スクリプトの報告が件数だけ空欄になった。

```
常駐の node を終了しました（ 個）
```

## 原因

`Where-Object` は 1 件しか通らないとき**スカラー**を返す。
`CimInstance` は `Count` というプロパティを持たないため、`$mine.Count` は `$null` になる。

**PowerShell 7 では 1 が返る。** 開発中のシェルが 7 で、実行されるのが 5.1 だと再現しない。

```
5.1.26100.9444
型            : CimInstance
スカラー .Count: []     ← $null
配列     .Count: [1]
```

## 対処

```powershell
$mine = @($watchers | Where-Object { ... })   # 必ず配列にしてから数える
```

## 汎用ルール

> **`.Count` を使うなら `@()` で包む。** 1 件と複数件で型が変わる言語では、
> 「1 件のとき」が最も踏みやすい未検査の枝になる。

> **手元のシェルと、実行されるシェルを取り違えない。**
> Windows で `powershell` は 5.1、`pwsh` は 7。スクリプトを `powershell -File` で
> 起動しているなら、検証も 5.1 で行う。7 で確かめて「直った」と言わない。
