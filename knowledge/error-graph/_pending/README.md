# 未コミットの知識（2026-09-16）

`claude-dotfiles` が interactive rebase 中断（2026-03-13 / 5ファイル衝突）のため
コミットできなかったノード群の退避先。リベースを解消したら本来の場所へ戻すこと。

| ファイル | 戻す先 | 状態 |
|---|---|---|
| `claude-cli-headless-oauth-expiry.md` | `nodes/` | 新規（作業ツリーに既にある） |
| `recovery-implemented-but-not-wired.md` | `nodes/` | 新規（作業ツリーに既にある） |
| `existence-vs-completion-check.md` | `nodes/` | 新規（作業ツリーに既にある） |
| `headless-auth.md` | `clusters/` | 新規クラスター（作業ツリーに既にある） |
| `uc-partial-solution-without-automation-path.md` | `nodes/` | **既存ファイルへの追記** ← rebase --abort で消える |
| `moc.md` | `./` | **既存ファイルへの追記**（headless-auth 行） ← 同上 |

新規4件は untracked なので rebase 操作では消えないが、下2件は tracked の変更なので
`git rebase --abort` で失われる。復旧はこのフォルダから。
