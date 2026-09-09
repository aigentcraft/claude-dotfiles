---
name: ps1-no-bom-lf-comment-swallows-next-line
title: BOM 無し UTF-8 + LF の .ps1 は日本語コメントが次の行を飲み込む — 定時タスクが rc=0 で 7 日間何もしなかった
cluster: platform-syntax
type: "silent-failure"
tags: ["powershell", "encoding", "cp932", "windows", "task-scheduler", "silent-failure", "weevee", "bom"]
date: 2026-09-09
severity: critical
---

## ユーザー指摘（原文）
「Xだけど、引用rt も、引用したツイートを参考にしたツイートもできてないけどなんで？」

## 症状
`weevee-engage`（X 交流サイクル・08:30 / 18:30 / 21:30）が 2026-09-02 の登録以降**毎回「成功」**して
いたのに、引用レーン（07_amplify）は 1 度も回っていなかった。

- Task Scheduler: `LastTaskResult = 0`
- ログ `logs/x-engage-YYYYMMDD.log`: ヘッダと `== engage cycle exit: rc=` が**同一秒**で並ぶだけ
  （本来は 10〜20 分かかる）。python の出力は 1 行も無い
- DB: `x.engage_cycle` イベントは 7 日間で 1 件だけ（それも別経路からの起動）

## 根本原因
`scheduler/run-engage.ps1` が **UTF-8 BOM 無し + LF のみ**で保存されていた。
PowerShell 5.1 は BOM の無い `.ps1` を **cp932** として読む。日本語コメント末尾の
`）` = `EF BC 89` の `89` は cp932 の lead byte で、.NET の DBCS デコーダは
**lead byte を見たら次の 1 バイトを必ず trail byte として消費する**。次の 1 バイトが LF なので
**改行が食われる**。

```
# python3はストアスタブのためpython.exeを使う（docs/03 §7）   ← 末尾 89 が LF を食う
python "$RepoRoot\workers\x_pipeline\run_engage_cycle.py" @args 2>&1 |
```

この 2 行が 1 行のコメントに融合し、**python が一度も起動しない**。
起動していないので `$LASTEXITCODE` は `$null` のまま → `exit $rc` = `exit $null` = **0**。
「起動しなかった」と「正常終了した」が区別できず、定時タスクは緑のままだった。

実測（`[Text.Encoding]::GetEncoding(932)` で読んだ行数）:

| ファイル | UTF-8 行数 | cp932 行数 | python 行がコメント内 |
|---|---|---|---|
| run-engage.ps1 | 25 | 22 | **はい** |
| run-pipeline.ps1 | 32 | 28 | **はい** |
| run-create.ps1 | 26 | 22 | **はい** |
| gsc-sitemap-check.ps1 | 16 | 14 | いいえ（偶然助かった） |

`weevee-articles` / `weevee-regen-images` が動いていたのは、**python.exe を直接 Exec していて
.ps1 を経由しないから**。ラッパー経由のタスクだけが死んでいた。

### CRLF なら事故らない理由
lead byte が食うのは CR（`0D`）で、LF（`0A`）が残るため行が終わる。だから同じ内容でも
CRLF 保存なら動く。**しかし本筋は BOM**（cp932 として読まれること自体を止める）。

### Python の cp932 コーデックでは再現しない
Python の `bytes.decode("cp932", errors="replace")` は不正な組を 1 バイトずつ置換するので
**改行を食わない**（実測: 同じファイルが Python 25 行 / PowerShell 22 行）。
Python で書いた検査は緑になる。.NET 側の規則を明示的に写す必要がある。

## 修正
1. 非 ASCII を含む `.ps1` 全 4 本に **UTF-8 BOM** を付与し、CRLF に正規化（二重の歯止め）
2. `.gitattributes` に `*.ps1 text eol=crlf`
3. `tests/test_ps1_encoding.py`: BOM 必須 + 「cp932 で読んだとき改行が消えない」を機械検査。
   .NET の lead-byte 規則を写した `_decode_cp932_dotnet()` を持ち、**事故当時のバイト列で
   赤が出ることを自己検査**する
4. 全ラッパーに**起動確認ゲート**を追加 —
   `if ($null -eq $LASTEXITCODE) { … exit 97 }`。python が 1 度も走らなかったら専用コード 97 で落ち、
   Task Scheduler の LastTaskResult が非ゼロになる
5. `run_engage_cycle.run_step`: 失敗した子プロセスの stderr 末尾を `execution_logs.detail` に残す
   （それまでは「失敗（続行）」の 1 行だけで、なぜ落ちたか永久に不明だった）

## 予防ルール
1. **Windows の `.ps1` は必ず UTF-8 BOM で保存する。**
   日本語コメントが 1 行あるだけで、直後のコードが実行されなくなる
2. **「起動しなかった」を「成功」と同じ終了コードで返すラッパーを作らない。**
   ネイティブコマンドを呼ぶラッパーは `$LASTEXITCODE -eq $null` を専用の失敗として扱う
3. **定時タスクは rc だけでなく「所要時間」と「出力の有無」を見る。**
   開始と終了が同一秒・出力ゼロは、成功ではなく起動失敗の兆候
   （→ [[verification-tool-that-cannot-fail]] と同じ根：成功条件が事実の成立を要求していない）
4. **同じ環境依存の検査を Python の標準コーデックで代用しない。**
   デコーダの実装差で再現しないことがある（cp932 の不正組の扱いが .NET と Python で違う）
5. ラッパー経由に変えた瞬間から、直接 Exec で動いていた保証は消える。
   **タスクの Action を .ps1 に変えたら、1 度は手で起動して出力が出ることを確認する**

## 関連
- [[verification-tool-that-cannot-fail]] — 成功条件が事実の成立を要求していない同型（同日）
- [[generated-instruction-logged-then-discarded]] — 生成物が使われたように見えて使われていない型
- [[uc-pipeline-is-conveyor-not-agent-org]] — 「機械が回っているように見えて回っていない」の系譜
