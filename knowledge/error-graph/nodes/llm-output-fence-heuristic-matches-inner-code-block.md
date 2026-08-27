---
title: "LLM出力のフェンス剥がしヒューリスティックが本文中のコードブロックを誤検出し確定クラッシュ"
type: "technical-error"
tags: ["llm", "output-parsing", "regex", "markdown", "pullie", "deterministic-crash"]
description: "「```フェンスがあれば中身が本文」という抽出規則が、記事本文中の最初のコードブロック（URL1行）にマッチしfrontmatter無しエラー。コードブロック入り記事で初めて発症する潜伏地雷で、同一入力の再試行が全て同一クラッシュ→2run連続失敗の🚨介入要求が発火した。"
---

## 1. Plan / Context
pullie 04_write_article は writer 出力（SLUG行 + frontmatter付きMarkdown）を
`parse_slug_markdown` で抽出する。LLMが全文を ```markdown フェンスで包んで返すことが
あるため、「フェンスがあれば中身を本文とみなす」ヒューリスティックを置いていた:
`re.search(r"```(?:markdown|md)?\s*\n(.*?)```", rest, DOTALL)` — 非貪欲・出現位置不問。

## 2. Do / The Error
2026-08-26〜27、記事#23（kintone×Excel連携）で2run連続クラッシュ→🚨介入要求:
- writer出力は完全に正常（SLUG+frontmatter+本文7,000字級）だが、本文中に
  RESTエンドポイントの素の ``` コードブロックを含んでいた
- 出力全体は外側フェンスで包まれていなかったため、`$`アンカー付きの第1正規表現は不成立、
  フォールバックの第2正規表現が**本文中の最初のコードブロック**（URL1行）にマッチ
- md = URL1行 → `md.find("---") == -1` → ValueError「frontmatter(---)が見つかりません」
- 同一企画の再執筆でも本文にコードブロックが入る限り再現 → リトライ全滅の確定クラッシュ

## 3. Check / Root Cause
1. **「包むフェンス」と「本文中のフェンス」を区別しない抽出規則**。ラッパー判定に
   「中身が期待構造（frontmatter）を含むか」の検証がなく、マッチ＝ラッパーと即断した
2. 22記事を通過してきた実績が安全を意味しなかった — コードブロックを含む記事という
   入力条件が初めて揃った時に発症する**潜伏地雷**（ヒューリスティックは反例入力が
   来るまで正しく見える）
3. 過去に同族の事故あり: `llm-json-extract-object-regex-breaks-arrays`（抽出正規表現が
   構造の一部だけ食い破る）— 「LLM出力から構造を切り出す正規表現」は同じ失敗系列

## 4. Act / Prevention Strategy (Fix)
- 修正: フェンス中身に `---`（frontmatter）が無ければラッパーではないと判定し
  全文へフォールバック — `md = fence.group(1) if fence and "---" in fence.group(1) else rest`
- **予防ルール**: ①LLM出力から構造を切り出すヒューリスティックは、切り出した結果が
  **期待構造の必須マーカーを含むかで検証**してから採用し、含まなければ広い候補へ
  フォールバックする ②「中身に何が書かれるか分からない自由文」を対象にする正規表現は、
  対象自身が区切り記号（``` や --- や JSON括弧）を含むケースを必ずテストに入れる
