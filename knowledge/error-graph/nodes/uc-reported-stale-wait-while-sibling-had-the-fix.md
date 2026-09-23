---
name: uc-reported-stale-wait-while-sibling-had-the-fix
title: 「審査待ち」と報告したが、隣のプロジェクトとナレッジに答えが 9 日前からあった
cluster: uc
type: "user-correction"
tags: ["ai-behavior", "external-dependency", "waiting", "cross-project", "knowledge-transfer", "google-ads", "pullie"]
date: 2026-09-23
severity: high
---

## ユーザーの指摘
> 「weeveeの方だと、検索ボリュームの取得が申請ではなく別経路になってたと見つけてくれて実際に取得できているよ」
（2026-09-21・pullie のセッション）

## 何が起きていたか
pullie（kintone 受注メディア）で「キーワード調査の流れは本当に動いているのか」と聞かれ、実測して報告した。
検索ボリュームについては **「Google Ads の審査待ち」** と書いた（CLAUDE.md にもそう書いてあった）。

実際は:
- Google Ads API のアクセスレベルは **Cloud コンソールの Cloud プロジェクト単位**で管理する制度に変わっていた。
  pullie が 8/15 に旧 API センターで出した申請は**永久に処理されない**状態だった
- エラーコードは途中で `DEVELOPER_TOKEN_NOT_APPROVED` → **`CLOUD_PROJECT_NOT_APPROVED_FOR_PRODUCTION`** に変わっていた。
  ログには毎週残っていたのに、取得ツールの案内文が「Basic 承認待ちの可能性」の**固定文**だったので誰も読まなかった
- **同じ罠を weevee（隣のプロジェクト・同じユーザー）が 9/14 に踏んで数分で抜けていた。**
  共有ナレッジ [[stale-external-approval-never-reverified]] に「外部の待ちは再確認の日と場所を書く」
  「同一エラー 3 日連続は調査の合図」とまで書いてあった
- pullie は 403 を **37 日連続**で踏んだ。報告の時点で答えは 9 日前から手元（同じマシン・同じナレッジ）にあった

## 根本原因
1. **状態を報告する前に、既存の記録（CLAUDE.md）をそのまま信じた。** 「審査待ち」は 8/15 に書かれた記述で、
   報告時点でエラーコードを読み直していなかった（ログを開けば 1 行で違うと分かった）
2. **ナレッジの参照が「エラーが起きたとき」だけで、「状態を報告するとき」に無かった。** 同じ依存先
   （Google Ads API）について共有ナレッジを検索していれば、weevee のノードが出てきた
3. **同じユーザーの隣のプロジェクトを参照先として持っていなかった。** weevee は pullie の設計を移植して
   始まり、その後 pullie より先に進んだ部分（キーワード調査の 4 段階・Keyword Planner の開通）がある。
   逆方向（weevee → pullie）の横展開の経路が無かった

## 直したこと（2026-09-23）
- Cloud コンソールで pullie のプロジェクトの現在値を実見（**テスト**）。キーワードプランナーは**ベーシック必須**
  （エクスプローラでは Planning 系が制限対象）と公式ドキュメントで確認。申請は pullie.automate の 2 段階認証が
  前提（Google Cloud は 8/20 から MFA 必須）で、人間の作業が 1 つ残る
- 取得ツールの案内文を**エラーコードで出し分け**に変更（`CLOUD_PROJECT_NOT_APPROVED_FOR_PRODUCTION` なら申請先 URL と
  必要レベルを出す）。固定文の案内は、状況が変わった瞬間に嘘になる
- weevee で実働しているキーワード調査の 4 段階を pullie に移植（docs/13）

## 予防ルール
1. **外部依存の状態を「待ち」と報告する前に、今日のエラーコードを読む。** 記録（CLAUDE.md 等）の「待ち」は
   書かれた日の事実であって、今日の事実ではない
2. **状態を報告する前に、同じ依存先で共有ナレッジを検索する**（`grep -rl <依存先名> ~/claude-dotfiles/knowledge/`）。
   エラー時だけでなく「動いているか」と聞かれたときも
3. **同じユーザーの隣のプロジェクトは参照先。** 「動いていない」と報告する機能があれば、隣のプロジェクトに
   同じ機能が動いていないかを見てから報告する（weevee ⇄ pullie は相互に移植元）
4. **エラーメッセージの案内文を固定文にしない。** 理由コードで出し分けるか、コードそのものを表示する

## 関連
- [[stale-external-approval-never-reverified]] — 同じ罠の初出（weevee・9/14）。今回はその再発
- [[uc-declared-missing-path-without-checking-detector-timing]] — 確認せずに「無い」と言い切る型
