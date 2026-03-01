---
title: "claude-hook-env-project-dir"
type: "technical-error"
tags: ["shell-hook-env"]
correction_category: "environment-variable-fallback"
date: "2026-02-26"
---

---

## 症状

Claude Code on the web でセッション開始フックを実装したとき、
PAT リマインダー・ワークフロー自動インストールが他プロジェクトで一切動かない。

フックのログには `Current project: /home/user/claude-dotfiles` と表示され、
どのプロジェクトを開いても常に claude-dotfiles のパスになる。

---

## 根本原因

`CLAUDE_PROJECT_DIR` 環境変数が Claude Code on the web から設定されないケースがある。

```bash
# NG: CLAUDE_PROJECT_DIR が未設定だと常に DOTFILES_DIR にフォールバック
CURRENT_PROJECT="${CLAUDE_PROJECT_DIR:-$DOTFILES_DIR}"
```

フックが `~/.claude/settings.json` に登録されているグローバルフックの場合、
条件 `[ "$CURRENT_PROJECT" != "$DOTFILES_DIR" ]` が常に FALSE になり、
プロジェクト固有の処理がすべてスキップされる。

---

## 修正

フック実行時の `$PWD` はプロジェクトルートになるため、こちらをフォールバックとして使う。

```bash
# OK: $PWD はフック実行時にプロジェクトルートを指す
CURRENT_PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
```

---

## 予防ルール

> Claude Code フックで「現在のプロジェクトディレクトリ」を取得するときは
> `${CLAUDE_PROJECT_DIR:-$PWD}` を使う。`DOTFILES_DIR` へのフォールバックは禁止。

- フックのログに `CLAUDE_PROJECT_DIR` の状態を出力しておくと検証しやすい:
  ```bash
  echo "  (CLAUDE_PROJECT_DIR=${CLAUDE_PROJECT_DIR:-<not set, used PWD>})"
  ```

---

## 関連

- 修正コミット: `332d153` (claude/mobile-claude-code-support-mWvj3)
- 影響ファイル: `.claude/hooks/session-start.sh`
