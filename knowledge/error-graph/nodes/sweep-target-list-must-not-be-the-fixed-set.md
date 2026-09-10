---
name: sweep-target-list-must-not-be-the-fixed-set
title: 横断検査の対象を「もう直っているか」で選ぶと、直っていないものが漏れる
cluster: observability
type: "defect"
tags: ["testing", "sweep", "false-coverage", "launcher", "silent-failure", "weevee"]
date: 2026-09-11
severity: high
---

## 症状
「本体を起動していないのに成功を返す」起動役スクリプトを全数で塞ぐため、
全ファイルを対象にした検査を書いた。**38 件すべて緑**。ところが修正前のコードに戻して走らせると
**3 件しか落ちなかった**（本来 24 件落ちるべき）。

## 根本原因
検査の対象リストを、**修正済みの目印から** 作っていた。

```python
# 悪い: 「resolve_python を含むファイル」= すでに直したファイルだけが対象になる
DIRECT = [p.name for p in SCHED.glob("*.sh") if "resolve_python" in p.read_text()]
```

直っていないファイルは目印を持たないので、**パラメータ化テストのケースとして生成すらされない**。
「全数検査を書いた」という感覚だけが残り、実際の網は修正済みの範囲にしか掛かっていない。
新しいスクリプトを足したときも同じで、直し忘れたものほど検査から漏れる。

## 修正
対象は **「その役割を果たすもの全部」** から作り、例外だけを名指しで除く。

```python
# 良い: scheduler の .sh は全部が起動役。委譲するものだけ名指しで除く
DELEGATING = ["regen-images-batch.sh"]
ALL = sorted(p.name for p in SCHED.glob("*.sh") if p.name != "_lib.sh")
DIRECT = [n for n in ALL if n not in DELEGATING]
```

これで新しい起動役を足せば自動的に検査対象になり、直し忘れは赤で出る。
修正後: 旧コードで 24 件が落ちることを実測してから採用した。

## 予防ルール
1. **横断検査の対象は「性質」から導く。「対策済みの目印」から導かない。**
   目印で選ぶと、対策漏れが検査漏れと一致してしまう（最も見たいものが最も見えない）。
2. **除外はホワイトリストで名指しし、理由をコードに書く。** 「条件に合わないから対象外」は、
   条件がズレたときに黙って範囲が縮む。
3. **パラメータ化テストは、ケース数を目視する。** 全数のつもりで 13 件しか生成されていない、は起きる。
   件数が期待と違うなら対象の作り方を疑う。
4. **旧コードで赤を出す時、「何件落ちるはずか」を先に見積もる。** 落ちた件数が見積もりより
   少なければ、直したことではなく**検査の網**を疑う（今回はこれで気づいた）。

## 関連
- [[verification-tool-that-cannot-fail]] — 落ちない検査。今回は「落ちる範囲が狭すぎる検査」
- [[ps1-no-bom-lf-comment-swallows-next-line]] — この横断検査が塞いだ元の欠陥
- [[feedback-with-no-address-never-arrives]] — 「同じ性質の経路を全部数えてから閉じる」の実践例
