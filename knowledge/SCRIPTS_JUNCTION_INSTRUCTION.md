# scripts/ Junction 化 — 実装指示書
**From:** Claude Code (Anthropic)
**To:** Antigravity (Gemini)
**Date:** 2026-03-02

---

## 目的

`scripts/` を `knowledge/` `skills/` と同様に NTFS Directory Junction で共有する。
これにより、スクリプトの手動コピー忘れ（3回連続で発生）を構造的に不可能にする。

## 完成後のアーキテクチャ

```
antigravity-dotfiles/
  knowledge/  → Junction → claude-dotfiles/knowledge/   (済)
  skills/     → Junction → claude-dotfiles/skills/       (済)
  scripts/    → Junction → claude-dotfiles/scripts/      (今回)
```

すべてのスクリプトが物理的に同一ファイルになるため、
どちらのAIが編集しても即座にもう一方に反映される。
GitHub push は claude-dotfiles 経由で全デバイスに同期。

---

## 実装手順（PowerShell を管理者権限で実行）

### Step 1: antigravity-dotfiles の scripts/ をバックアップ

```powershell
$AG = "$env:USERPROFILE\.gemini\antigravity"
$CD = "$env:USERPROFILE\claude-dotfiles"

# バックアップ
Copy-Item -Recurse -Force "$AG\scripts" "$AG\scripts.bak"
Write-Host "[backup] scripts/ -> scripts.bak"
```

### Step 2: claude-dotfiles に antigravity 固有のスクリプトがあれば統合

antigravity 側にしか存在しないスクリプトを claude-dotfiles にコピーする。
（既に両方にあるファイルは claude-dotfiles 版を正とする）

```powershell
# antigravity にしかないファイルを claude-dotfiles にコピー
Get-ChildItem "$AG\scripts\*" | ForEach-Object {
    $dest = "$CD\scripts\$($_.Name)"
    if (-not (Test-Path $dest)) {
        Copy-Item $_.FullName $dest -Force
        Write-Host "[copy] $($_.Name) -> claude-dotfiles/scripts/"
    } else {
        Write-Host "[skip] $($_.Name) already exists in claude-dotfiles"
    }
}
```

### Step 3: antigravity の scripts/ を削除して Junction 作成

```powershell
# 物理ディレクトリを削除
Remove-Item -Recurse -Force "$AG\scripts"
Write-Host "[delete] scripts/ removed"

# Junction 作成
cmd /c mklink /J "$AG\scripts" "$CD\scripts"
Write-Host "[junction] scripts/ -> claude-dotfiles/scripts/"
```

### Step 4: Junction が機能していることを検証

```powershell
# Junction の確認
cmd /c dir "$AG" | Select-String "scripts"

# 同一性テスト: 片方で作ったファイルがもう片方に見えるか
echo "junction-test" > "$CD\scripts\junction-test.txt"
$exists = Test-Path "$AG\scripts\junction-test.txt"
Remove-Item "$CD\scripts\junction-test.txt"
Write-Host "[test] Junction bidirectional: $exists"
# → True なら成功
```

### Step 5: antigravity-dotfiles の git 状態を整理

Junction 化すると git は scripts/ 内のファイルを「削除→新規追加」と認識する場合がある。

```powershell
cd $AG
git add -A
git status
# scripts/ 内のファイルが tracked のまま正常であることを確認
# ※ Junction 先のファイルは git にとっては通常のファイルに見える
```

### Step 6: バックアップ削除

すべて正常であることを確認した後：

```powershell
Remove-Item -Recurse -Force "$AG\scripts.bak"
Write-Host "[cleanup] scripts.bak removed"
```

---

## Empirical Verification（完了条件）

以下の4つの実測出力をそのまま貼ること。

```powershell
# 1. Junction が存在することの確認
cmd /c dir "$env:USERPROFILE\.gemini\antigravity" | Select-String "scripts"
# 期待: <JUNCTION> scripts [C:\Users\user\claude-dotfiles\scripts]

# 2. 同一性テスト
(Get-FileHash "$env:USERPROFILE\.gemini\antigravity\scripts\sync.sh").Hash -eq (Get-FileHash "$env:USERPROFILE\claude-dotfiles\scripts\sync.sh").Hash
# 期待: True

# 3. antigravity 側からスクリプトが実行できること
bash "$env:USERPROFILE\.gemini\antigravity\scripts\validate-nodes.sh"
# 期待: [RESULT] All nodes passed validation.

# 4. claude-dotfiles の git status（scripts/ が正常に tracked されていること）
cd "$env:USERPROFILE\claude-dotfiles"; git status --short scripts/
# 期待: 出力なし（変更なし）or 新規追加ファイルのみ
```

---

## 注意事項

- **管理者権限が必要**: `mklink /J` は管理者権限の PowerShell でないと失敗する場合がある
  （ただし Junction は通常ユーザーでも作成可能なケースが多い。失敗したら管理者で再実行）
- **scripts.bak は検証完了まで残すこと**: 万一 Junction が壊れた場合の復旧用
- **antigravity-dotfiles の .gitignore**: Junction 先のファイルは通常ファイルとして git に見えるため、
  .gitignore の変更は不要

— Claude
