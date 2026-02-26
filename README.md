# claude-dotfiles

**布団の中から本番バグを直す**ための、Claude Code 設定一式。

複数マシン間の設定同期 ＋ スマホ・ブラウザでの Claude Code Web セッション対応。

---

## できること

| 機能 | 説明 |
|---|---|
| **マルチマシン同期** | Windows / Mac / Linux で同じ設定・スキル・知識ベースを共有 |
| **Webセッション自動設定** | スマホブラウザから開くと、ルール・スキル・知識が自動ロード |
| **スキル管理** | カスタムスキルをリポジトリで管理・同期 |
| **知識ベース** | エラーグラフ（PDCA ナレッジ）をセッションをまたいで蓄積 |

---

## 仕組み

```
スマホ (claude.ai)
  └─ GitHub リポジトリを開く
       └─ SessionStart フック自動実行
            └─ settings.json / CLAUDE.md / skills / knowledge を ~/.claude/ に適用
                 └─ すぐに開発できる状態になる
```

ローカルマシンでは `sync.sh` が設定を双方向に同期する。

---

## セットアップ

### 新しいマシンで初回のみ

```bash
git clone https://github.com/aigentcraft/claude-dotfiles.git ~/claude-dotfiles
bash ~/claude-dotfiles/scripts/bootstrap.sh
```

### 手動同期

```bash
bash ~/claude-dotfiles/scripts/sync.sh pull   # 最新を取得して ~/.claude/ に適用
bash ~/claude-dotfiles/scripts/sync.sh push   # ローカルの変更を GitHub に送信
```

### 自動同期（30秒ごと）

```bash
bash ~/claude-dotfiles/scripts/sync.sh watch
```

---

## スマホから使う

1. このリポジトリを fork する
2. `CLAUDE.md` に自分のルールを書く（モデル設定、コーディングルール等）
3. `claude.ai` のブラウザでそのリポジトリを開く
4. スマホで指示を打つだけ

> セッション開始時に `.claude/hooks/session-start.sh` が自動実行され、
> 設定・スキル・知識がすべて適用された状態でスタートする。

---

## リポジトリ構成

```
claude-dotfiles/
├── .claude/
│   ├── hooks/
│   │   └── session-start.sh   # Webセッション開始時に自動実行
│   └── settings.json          # フック登録
├── settings.json              # Claude Code 設定（モデル・effort等）
├── CLAUDE.md                  # グローバルルール（AIへの指示）
├── skills/                    # カスタムスキル集
│   ├── x-viral-writing/
│   ├── skill-pdca-error-graph/
│   └── ...（14スキル）
├── knowledge/
│   └── error-graph/           # 蓄積された知識ベース（PDCA）
└── scripts/
    ├── bootstrap.sh           # 新マシンの初回セットアップ
    ├── setup.sh               # シンボリックリンク作成
    └── sync.sh                # 双方向同期スクリプト
```

---

## fork して使う場合のカスタマイズ

**最低限これだけ変えれば動く：**

1. `CLAUDE.md` — 自分のプロジェクトルール・開発スタイルを書く
2. `settings.json` — 使いたいモデルや effort レベルを変更
3. `skills/` — 不要なスキルを消して、自分のスキルを追加

---

## SessionStart フックについて

`.claude/hooks/session-start.sh` は `CLAUDE_CODE_REMOTE=true`（Webセッション）のときだけ実行される。ローカル環境には影響しない。

```bash
# ブラウザ（Web）セッションのときだけ実行
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi
# → settings.json / CLAUDE.md / skills / knowledge を ~/.claude/ にコピー
```

---

## ライセンス

MIT
