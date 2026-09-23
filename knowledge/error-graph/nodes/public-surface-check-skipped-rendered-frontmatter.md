---
title: "public-surface-check-skipped-rendered-frontmatter"
type: "bug"
tags: ["editorial", "internal-leak", "automation-exposure", "compliance", "frontmatter", "incomplete-fix", "weevee"]
date: "2026-09-23"
---

## 1. Plan / Context
同じ日の夕方、人間の指摘「Bot確認画面で止まったなんて書いたら自動化して書いてるのもろばれじゃん」を受けて、
「公開面に『どう調べたか・何で止まったか』を書かない」を 1 か所（`editorial.PUBLIC_SURFACE_CONTRACT`）に書き、
執筆・検閲に同じ文面で渡し、機械検査 MC05（`06_review.internal_vocab_hits`）に語群を足した。

## 2. Do / The Error
Discord の「録画なし（実測ラボ）」通知を追っていたら、**本番の記事上部の見出し欄**に調べ方が出ていた（weevee.net で実物を確認）:
- 記事 32（同日公開）: 環境「公式サイト閲覧のみ（**Playwrightヘッドレス・フルページ撮影**）、課金操作なし」＋ 実測日 2026-09-23
- Google AI Studio: 環境「**未ログイン**・公式ドキュメントと**Playwrightスクリーンショット確認のみ**（API実利用・Build機能は未実施）」
- ほか 3 本（「Playwrightで公式ページを確認」「実機操作は未実施」「未ログイン状態でアクセスを確認」）
どれも製品を試していないのに「実測日」が並び、試したように見えていた。執筆中の記事 34 も同じ形だった。

## 3. Check / Root Cause
1. **検査が frontmatter を最初から読み飛ばしていた** — `internal_vocab_hits` の docstring は「本文（frontmatter・コード除く）」。
   frontmatter の title / description / subject / verdict / env はレイアウトの見出し欄にそのまま出る＝公開面なのに対象外。
   夕方の修正も同じ関数に語を足しただけで、**どの文字列が公開面に出るかを数え直していなかった**
2. 執筆担当の書式は `env: "（実測環境を一行で）"` だけ。実測の無い記事では「調べ方」を書くしかない
3. 「実測ログが空の記事では measuredAt/env を省略してよい」は **Python のコメントにしか無く**、執筆担当に届いていなかった
4. 語の検査は「Playwright で自動操作」の形しか拾わず、「Playwrightヘッドレス」「Playwrightスクリーンショット」を素通り

## 4. Act / Prevention Strategy (Fix)
- `06_review.header_fields()` で見出し欄の 5 欄を取り出し、本文と同じ語の検査に加えて、`env` だけに
  「調べ方」の語（閲覧のみ・確認のみ・未ログイン・Playwright で撮影/確認・スクリーンショットで確認・実機操作は未実施 等）を当てる。
  本文には当てない（製品としての Playwright やスクショ手順は正当な題材）。07 の公開前検査は同じ関数を通るので同時に効く
- `PUBLIC_SURFACE_CONTRACT` に「見出し欄も公開面・環境には測った条件だけ・実測していない記事は実測日と環境を書かない」
- `04.FRONTMATTER_SPEC` に同じ指示を**執筆担当が読む文面として**書く（コメントから移す）
- 公開中の 5 本と記事 34 の下書きから measuredAt / env を削除（公開ファイルと `output/drafts` の控えの両方）
- 公開記事の全数検査（`test_no_other_published_article_is_flagged`）が修正前の本番データで 5 本を赤にすることを確かめてから直した
- **予防ルール: 「公開面に書かない」を検査にするときは、検査対象を『本文』ではなく『画面に出る文字列の全部』で定義する。
  テンプレートが表示する frontmatter・キャプション・alt・OG を、レイアウトのコードから数えて列挙する**
- **予防ルール: 書き手に届けたい決まりをコードのコメントに書かない**（届くのは指示文だけ）
- 関連: [[uc-bot-check-wall-written-into-public-article]] [[uc-articles-contain-operator-facing-justifications]]
  [[planner-promised-trial-the-lab-cannot-run]]
