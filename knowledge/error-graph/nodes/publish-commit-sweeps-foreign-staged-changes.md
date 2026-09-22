---
title: "publish-commit-sweeps-foreign-staged-changes"
type: "error"
tags: ["git", "pipeline", "publish", "security", "idempotency", "weevee"]
date: "2026-09-22"
---

## 症状（Symptom）

weevee の記事公開（`07_publish`）の自動コミット `e5f5207 post: Google AI Studioの使い方` に、
記事と無関係な **X 交流の修理コード約 900 行（25 ファイル中 13 本）** が入って main に push されていた。
前セッションがステージしたまま commit せずに終わった変更だった。

気づいたきっかけは別件: 人間が手元で commit した直後、`git status` から前セッションの変更が消えていた。
公開コミットは rc=0 で、件名は正しい記事名。**中身を開かない限り誰も気づかない**。

## 根本原因（Root Cause）

`git add` はパス個別指定で正しかった（絶対ルール 6「`git add -A` 禁止 — 秘密情報の巻き込み防止」）。
ところが直後の 2 行がインデックス全体を見ていた:

```python
staged = subprocess.run(["git", "diff", "--cached", "--quiet"]).returncode   # 全体
sh(["git", "commit", "-m", f"post: {art['title']}"])                        # パス指定なし
```

`git commit -m` は**インデックスに積まれているもの全部**を commit する。`git add` を絞っても、
その前から他人がステージしていた変更は一緒に載る。コメントには「巻き込み防止」と書いてあり、
**守っているつもりの層（add）と、実際に外へ出る層（commit）がずれていた**。

さらに差分判定も全体を見ていたため、記事に差分が無い再実行でも他人のステージを「差分あり」と誤認し、
`post: <記事名>` の件名で他人の変更だけを commit・push する経路もあった。
（この全体判定は 2026-08-11 の冪等化修理で入ったもの — [[publish-worker-not-idempotent-after-push]]）

main への push は Cloudflare Pages の自動デプロイも起動する。秘密情報や作りかけのコードが
ステージされていれば、そのまま公開リポジトリと本番に出る。

## 修正（Fix）

- add / 差分判定 / commit の 3 つを**同じパス集合**で閉じる（`commit_and_push(paths, message)` に切り出し）
  - `git diff --cached --quiet -- <paths>`（公開物だけで判定）
  - `git commit --only -m <msg> -- <paths>`（指定パスだけ commit。他人のステージはインデックスに残す）
- `tests/test_publish_commit_scope.py`: **本物の git**（一時リポジトリ + bare の origin）で push された中身を数える。
  旧コードで「公開物以外が push された: {'code.py'}」と「差分なしの再実行で commit された」の 2 件の赤を実測してから修正。
  フォルダ内の画像の追加・削除が両方とも `--only` で載ることも実測（載らないと本番 404 か残骸）
- 全数: porcelain の `git commit` は weevee 全体で **この 1 箇所だけ**。プレビュー（06b）は
  `GIT_INDEX_FILE` の一時インデックス + `commit-tree` で作業インデックスに触れないため対象外
- **参照プロジェクト（Kintone受注目的メディア運営自動化）の `07_publish.py:220-223` にも同じ形が残っている**
  （weevee はここから移植した）。別プロジェクトのため別タスクに切り出した
- push 済みの巻き込みコミットは履歴を書き換えない（共有 main の force push はしない）。中身は正しいコードで、件名だけが実態と違う

## 予防ルール（Prevention）

1. **パスを絞るなら、add だけでなく「判定」と「commit」も同じパスで絞る。**
   `git add <path>` + `git commit -m` は絞れていない。自動 commit は必ず `git commit --only -- <paths>`。
   差分判定も `git diff --cached --quiet -- <paths>`。
2. **自動で commit・push する処理は、他人のインデックスと同居している前提で書く。**
   人間・別セッション・別の定時処理が同じ作業ツリーを使う。「インデックスは空のはず」を前提にしない。
   触れたくないなら 06b のように一時インデックス（`GIT_INDEX_FILE`）を使う。
3. **守っているつもりの層と、実際に外へ出る層を一致させる。**
   コメントに「巻き込み防止」と書いた層（add）ではなく、外に出る層（commit・push）で検査する。
   テストは「push された中身」を数える — `git add` の引数を数えても意味がない。
4. **自動 commit が走る作業ツリーで、ステージしたまま作業を終えない。**
   ステージ済みの変更は次の公開で持っていかれる（修正後は持っていかれないが、残り続ける）。
   区切りでは commit するか、ステージを外してから離れる。

## 関連

- [[publish-worker-not-idempotent-after-push]] — 全体判定の `git diff --cached --quiet` が入った修理（今回の前段）
- [[verification-tool-that-cannot-fail]] — 検査は外に出る結果（push された中身）で書く
