# Claude Code をスマホで諦めた人へ──フック1つで、毎回の説明が不要になった

Mobile IDE を試した人なら、わかると思う。

補完が効かない。ターミナルがない。Git 操作が壊滅的。「スマホでコード書くのは無理」という結論に、だいたい3週間くらいで辿り着く。

自分もそうだった。

でも間違っていたのは結論じゃなくて、**前提**だった。

---

## 「コードを書く」じゃなく「コードを書かせる」

Claude Code には Web モードがある。

`claude.ai` のブラウザから GitHub リポジトリを開くと、AI がファイルを読み、コードを書き、コミットして push まで完結させる。スマホで指示を打つだけでいい。

Mobile IDE で詰まっていた3週間が、発想ひとつで消えた。

---

## ただし、毎回コンテキストがリセットされる

ここで止まる人が多いと思う。

ブラウザから新しいセッションを開くたびに、AI の記憶がゼロになる。「npm install は `--legacy-peer-deps` を付けて」「コミット前に CLAUDE.md を更新して」——毎回同じ説明をする羽目になる。

5回繰り返したところで、仕組みで解決することにした。

---

## SessionStart フックで解決する

Claude Code の `.claude/hooks/session-start.sh` に、以下を書く。

```bash
#!/bin/bash
# ブラウザ（Web）セッションのときだけ実行
if [ "$CLAUDE_CODE_REMOTE" != "true" ]; then
  exit 0
fi

# プロジェクトルールを自動適用
cp "$CLAUDE_PROJECT_DIR/.claude/settings.json" ~/.claude/settings.json
cat "$CLAUDE_PROJECT_DIR/CLAUDE.md"
```

`settings.json` の hooks セクションに登録する。

```json
{
  "hooks": {
    "SessionStart": [
      {
        "command": "bash .claude/hooks/session-start.sh"
      }
    ]
  }
}
```

これだけ。

次からブラウザでセッションを開くたびに、AI がプロジェクトルールを自動で把握する。同じ説明をする必要がなくなる。

---

## 実際の使い方

1. このリポジトリ（[claude-dotfiles](https://github.com/aigentcraft/claude-dotfiles)）を fork する
2. `claude.ai` のブラウザでリポジトリを開く
3. セッションが始まったら、あとはスマホで指示を打つだけ

深夜に本番バグを見つけても、PC まで歩かなくていい。

---

## まだ完全じゃない

複数プロジェクトを並行して触るとき、knowledge の管理がどこかで複雑になる気がしている。Claude Code 自体の進化速度によっては、このフックが半年後に不要になる可能性もある。

ただ、布団の中から本番のバグを直した夜が 2 回あった。

それだけで、作った意味はあった。
