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

## 再発（2026-09-26・副業HOOTL）
- selftest に書く正規表現 `/\bCHROME_TOOLS\b/` を Python の通常文字列で渡したら、`\b` が**制御文字 0x08（バックスペース）**になった。
  正規表現は「0x08 を含む語」を探す形になり、**検査が常に通る**（壊しても FAIL しない）状態で書き込まれていた。
  同じ回、DEV_LOG に失敗を説明する文でも同じ 0x08 を書き込んだ。修正に使った `node -e` の置換文字列もシェルの引用で再び 0x08 に戻った
- 見つけたきっかけ: 故障注入の前に `od -c` で行を覗いた。**出力の見た目（grep の表示）では区別できない**
- 追加の予防: Python や `node -e` で編集したファイルは、コミット前に制御文字を数える
  （制御文字 0x01〜0x08・0x0B・0x0C・0x0E〜0x1F を LC_ALL=C の grep -c で数え、0 であることを確かめる）。直す時は String.fromCharCode(92) のように文字コードで組み立て、引用に頼らない
- 同じ回、長い Python ヒアドキュメントが途中で切れた（R-HEREDOC）。長い追記は Write ツールで一時ファイルに書いてから実行した
