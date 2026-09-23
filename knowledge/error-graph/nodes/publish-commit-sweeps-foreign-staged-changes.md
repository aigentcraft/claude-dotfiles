---
title: "publish-commit-sweeps-foreign-staged-changes"
type: "error"
tags: ["git", "pipeline", "publish", "security", "idempotency", "weevee", "pullie"]
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

## 参照プロジェクトでも起きていた（2026-09-23 追記・Kintone受注目的メディア運営自動化 / pullie）

weevee の移植元である pullie の記事公開にも同じ形が残っていた（weevee は欠陥ごと移植していた）。

### 実は 1 か月前に一度起きていた — 診断が「競合」で止まっていた

- 全 32 本の `post:` コミットを走査すると、**`da92463 post: kintone開発は内製か外注か？…`（2026-08-19）**に
  記事と無関係な 12 ファイル（手動セッションのフォントサイズ変更一式 + CLAUDE.md + DEV_LOG.md）が載って main に push されていた。
  巻き込みはこの 1 件だけ
- 当時の記録は「手動セッションの git 操作はパイプラインの公開処理と**競合しうる**」。予防策は
  「git 操作の前に承認待ちと lock を確認し、ステージから push まで間を置かない」＝**人間側が気をつける**で閉じており、
  **公開コミットの範囲が原因だとは診断されなかった**。1 か月後、移植先の weevee で同じ事故が再発した

### 修正 — weevee の `commit_and_push` を移植し、1 点だけ変えた

- add / 差分判定 / commit を同じパス集合で閉じる（weevee と同じ）
- **変更点: 差分判定をパスごとに行い、差分のあるパスだけを `--only` に渡す**。
  `git commit --only -- <path>` は **git が一度も見ていないパス**を渡すと
  `error: pathspec '…' did not match any file(s) known to git` で落ちる。新規記事の画像が全部未参照として掃除され、
  空の未追跡フォルダだけが残るとこの状態になる。旧コードの `git commit -m` はこれで落ちなかったので、
  **そのまま移植すると公開そのものが止まる経路を新しく作る**
- 実測: テスト 5 本（weevee の 4 本 + 空フォルダ 1 本）。旧コードで 2 件赤
  （`公開物以外が push された: {'code.py'}` / 差分なしの再実行で commit して `True`）→
  **weevee そのままの移植で空フォルダの 1 件が赤**（上の pathspec エラー）→ パスごとの判定で 5/5 緑。
  独立レビューの提案で「本文は同じ・画像だけ差し替え」を足して 6/6・全体 209 件緑（レビュー指摘なし）
- 本番の形でも確認: 日本語を含むリポジトリパス + このリポジトリの pre-commit フック（秘密ファイル・パターン検査）を有効にし、
  他人のステージとしてダミーの `.env` を積んだ状態で、公開物 2 本だけが push され `.env` はステージされたまま残った。
  `--only` でも pre-commit フックは commit 対象（git が作る一時インデックス）を検査する —
  `.env` そのものを `--only` で commit しようとするとフックが拒否することも実測
- 全数: porcelain の `git commit` は pullie 全体で **公開処理の 1 箇所だけ**。プレビュー（06b）は `GIT_INDEX_FILE` の
  一時インデックス + `commit-tree` で対象外。`git add -A` / `git add .` は 0 件
- ~~weevee 側にも空フォルダの潜在経路が残っている~~ → **2026-09-23 weevee でも修正**（同じくパスごとの判定。`test_an_empty_image_folder_does_not_stop_the_publish` で旧コードの pathspec エラーを再現してから）

### 予防ルール（追記）

5. **`--only -- <paths>` に渡すのは「差分のあるパス」だけ。** git が知らないパス（空の未追跡フォルダ等）を渡すと
   pathspec エラーで処理ごと落ちる。パスを絞る修正は、旧コードが黙って通していた入力で落ちないかを確かめる
6. **巻き込み事故を「人間が気をつける」で閉じない。** 外に出る層（自動 commit）の範囲を直さない限り、
   気をつける主体が変わる（別セッション・別プロジェクト・移植先）たびに再発する。
   事故の記録に「競合」「タイミング」と書く前に、**どの層が他人の物まで外に出したか**を特定する
