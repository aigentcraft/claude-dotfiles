---
title: "CDP 9222がwslrelayに乗っ取られ別ブラウザに接続 — 実プロファイル無傷なのに全セッション失効と誤診"
type: "technical-error"
tags: ["wsl", "cdp", "playwright", "chrome", "port-collision", "misdiagnosis", "pullie"]
description: "Windowsの127.0.0.1:9222はWSL側プロセス（Claude Codeブラウザ等）が9222を開くとwslrelay.exeが中継する。connect_over_cdpは成功するが相手は素のサンドボックスChromium。実プロファイルは無傷なのに「BOOTHセッション失効」を2日間誤検知し、無人SSO復旧の実験まで全て偽ブラウザ上で行っていた。"
---

## 1. Plan / Context
pullie booth_browser は「1) 稼働中のCDP Chrome（9222）に接続 → 2) 無ければ実プロファイルを
persistent contextで起動」の2段構え。9222 = ユーザーの `.pullie` Chrome という前提だった。

## 2. Do / The Error
2026-08-26〜27、01_sales が「BOOTHセッション失効」を2日連続検知。調査セッションでも
CDP経由でBOOTH/pixiv/Googleすべて未ログインを確認し「Googleセッションごと完全失効・
要人間再ログイン」と結論、督促通知や支援ツールまで実装した。しかし:
- Windowsで9222をLISTENしていたのは chrome.exe ではなく **wslrelay.exe**
- WSL内でClaude Codeのブラウザ（ヘッドレスChromium）が9222を開いており、Windowsの
  127.0.0.1:9222 はそこへ中継されていた
- つまり**接続先は素のサンドボックスChromium**（クッキーゼロ）— 全部ログアウトに見えて当然
- 実プロファイルをpersistentで直接開いたら **BOOTHもGoogleも完全にログイン済み**だった
- Windows Hello承認待ち180秒×2回も偽ブラウザ上の茶番だった（ダイアログが出ないのは当然）

## 3. Check / Root Cause
1. **localhostポートはWSL環境ではWindows/Linuxの2名前空間が透過中継される**（wslrelay）。
   「9222に応答がある=目的のChrome」という同定は、ポート番号だけでプロセスの身元を
   信用しており、WSL側の同番ポートに乗っ取られる
2. /json/version の Browser名は `Chrome/144` で本物と区別不能（実測）。**User-Agentの
   OS（Linux vs Windows）だけが確実な識別子**だった
3. 誤診断の連鎖: 偽ブラウザ上の「実験結果」（全セッション失効・パスキー画面）を根拠に
   結論を重ねた。**観測装置そのものの同一性検証**を最初にしなかった

## 4. Act / Prevention Strategy (Fix)
- 修正: connect_over_cdp の前に `/json/version` の User-Agent に "Windows" を含むことを
  検証（WSL側ブラウザはLinuxを名乗る）。偽物ならpersistent（実プロファイル直接起動）へ
- **予防ルール**: ①WSL環境でlocalhostポートへ接続する設計は、相手プロセスの身元検証
  （UA/バナー/期待レスポンス）をセットで実装する — ポート番号は身元ではない
  ②「ログインしていない/データがない」系の異常を調査する時は、まず**観測経路が本物か**
  （どのブラウザ・どのDB・どのプロファイルを見ているか）を確認してから結論する
  ③ss -tlnp / Get-NetTCPConnection でポートの持ち主を見るのは1コマンド — 誤診2日より安い
