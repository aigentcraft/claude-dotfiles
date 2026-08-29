---
title: "Python-in-Heredoc Escapes Corrupted a Regex (and /tmp Was Not the Same Path for Python)"
description: "Editing a Python regex block by feeding a Python script through a Git Bash heredoc turned the '\n' inside the replacement string into real newlines, producing an unterminated string literal that was committed and pushed (tests were run but the '&& git commit' chain keyed off 'tail -1', not pytest's exit code). The follow-up repair failed once more because Git Bash '/tmp' is not Windows Python's '\tmp'. Fix: write the literal block to a repo-local file via a quoted heredoc and splice it by index; gate commits on pytest's exit status."
type: "bug"
tags: ["git-bash", "heredoc", "python", "regex", "windows-path", "commit-gate"]
---

## 1. Plan / Context
稼働中バッチが次に import するモジュール（`_lib.py`）へ正規表現ブロックを差し替える急ぎの修正。

## 2. Do / The Error（2026-08-29）
1. `python - <<'EOF'` 内で `'... r"[^\n*]" ...'` と書いた置換文字列の `\n` が実改行になり、`_lib.py` が SyntaxError のまま commit & push された
2. `pytest | tail -1 && git commit` — パイプの終了コードは `tail` のもの（0）なのでテスト失敗でもコミットが通った
3. 修復で `/tmp/x.txt` を書いて Python から読んだら `\tmp\x.txt` が存在しない（Git Bash の /tmp と Windows Python のカレントドライブ相対パスは別物）

## 3. Check / Root Cause
- Python 文字列リテラル内でのエスケープ二重化を頭で追い切れない状態で、ヒアドキュメント→Python→ファイルの 3 層エスケープをやった
- コミットの前提条件（テスト合格）がパイプラインの終了コードに反映されていなかった

## 4. Act / Prevention Strategy (Fix)
- **正規表現やバックスラッシュを含むブロックは、引用ヒアドキュメント（`<<'EOF'`）で*リテラルのまま*ファイルに書き、Python は index で挟み込むだけにする**（文字列リテラルに埋めない）
- **一時ファイルはリポジトリ内（`output/_tmp_*`）に置く** — Git Bash の `/tmp` を Windows Python に渡さない
- **`python -m pytest -q; test ${PIPESTATUS[0]} -eq 0 && git commit`** — コミットはテストの終了コードでゲートする（`| tail` の後ろに `&&` を置かない）
- 関連: [[bash-exe-wsl-vs-git-bash-detached-launch]] [[writer-internal-handoff-notes-leak]]
