---
title: "xmcp-venv-python-exe-lookup-windows"
type: "error"
tags: ["windows", "venv", "path-exists", "xmcp", "subprocess", "weevee"]
date: "2026-09-02"
---

## 症状（Symptom）

weevee の `XActions()`（`mcp_http.ensure_xmcp`）が Windows で常に
`McpHttpError: xmcp が未セットアップです: C:\Users\user\xmcp\.venv\Scripts\python がありません` を投げる。
`~/xmcp/.venv` は存在し、`Scripts/python.exe` もある。

## 根本原因（Root Cause）

- 起動コードが `xdir / ".venv" / "Scripts" / "python"` を組み立てて `Path.exists()` で検査していた
- Windows の venv 実行ファイルは `python.exe`。`Path.exists()` は PATHEXT の補完をしないので拡張子なしは False
- 参照プロジェクト（pullie）は同じコードだが xmcp がポート 8000 で常駐しており `_port_open` の早期 return で
  この分岐に到達しない → バグが潜伏したまま移植された

## 修正（Fix）

```python
py = (xdir / ".venv" / "Scripts" / "python.exe") if sys.platform == "win32" \
    else (xdir / ".venv" / "bin" / "python")
```

修正後 `XActions()` が xmcp を 8010 で起動し `verify_identity` が `@weevee_jp` で通過（終了後ポート解放も確認）。

## 予防ルール（Prevention）

1. **Windows で実行ファイルを `Path.exists()` するときは `.exe` を付ける**（`shutil.which` か明示パス）
2. **移植したコードの「未起動なら起動する」分岐は、常駐サービスを止めた状態で 1 回実走して確認する**
   （早期 return の裏にある経路は本番で初めて踏む）
3. 関連: [[windows-python3-store-stub-silent-hook-failure]] [[windows-subprocess-cp932-decode-crash]]
