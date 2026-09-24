---
title: "exception-split-into-sibling-escaped-existing-handlers"
type: "system-design"
tags: ["producer-consumer-sync", "exception-hierarchy", "silent-failure", "note", "pullie", "cadence"]
date: "2026-09-25"
---

## 症状

pullie の note は週2枠（木・日の朝）で1本ずつ作る。2026-09-24（木）の枠で note が作られず、
翌 09-25 の朝に「note 停止警告（5日）」が出て人間が気づいた（「noteの週次レーンが止まっている」）。

ログには生成処理の異常終了（traceback）が残っていた:

```
File ".../note_pipeline/01_compose.py", line 333, in _gen
    generate_image(prompt + WHITE, path, size=size)
File ".../shared/imagegen_client.py", line 168, in _codex_generate
    raise ImageQuotaExceeded(tail)
workers.shared.imagegen_client.ImageQuotaExceeded: ... your usage limit ...
```

処理が落ちたのは、note-writer が本文を書き、読者検品で1回書き直し、コンプラ検閲で
1回直して**合格した後**（LLM 約20分）。note の行は INSERT 済みだったが未コミットのまま
プロセスが死んだので、**合格した本文ごと消えた**。次の枠は日曜。

## 根本原因

09-19 のコミットで、画像生成の「利用上限」を通常の生成失敗から区別するために
例外クラスを新設した。そのとき**兄弟関係**で作った:

```python
class ImageQuotaExceeded(RuntimeError): ...   # 新設
class ImageGenError(RuntimeError): ...        # 既存
```

それまで利用上限は `ImageGenError` として投げられており、呼び出し元は3つとも
`except ImageGenError:` で「画像は諦めて本文だけで続ける」と書いていた。
区別が要るのは記事の画像生成（05）だけで、そこには `except ImageQuotaExceeded` を足した。
**残りの2つ（note の画像生成・撮影の注釈編集）は変更の対象として見なかった**。
兄弟クラスにしたので、この2つでは上限の例外が `except ImageGenError` を素通りする。

つまり「例外の分割」は producer 側（投げる側）の定義変更で、**既存の全ての catch が消費側**。
新しい例外を既存の型の兄弟にすると、既存の消費側の契約（「画像の失敗は ImageGenError で来る」）が
黙って破れる。型検査もテストも通り、その経路で上限に当たるまで症状が出ない。

さらに、note は週2枠でしか走らないので、1回落ちると次の枠まで3〜4日何も作られない。
パイプラインの「同じステップが2回続けて失敗したら通知」は、枠が週2だと実質鳴らない。
この日の異常終了を拾ったのは、5日後の沈黙警告だけだった。

## 修正

1. `ImageQuotaExceeded` を `ImageGenError` の**子**にした。既存の `except ImageGenError` は
   従来どおり上限も拾い、区別したい 05 は `except ImageQuotaExceeded` を先に書いてあるので
   挙動は変わらない（1行の変更で3つの呼び出し元の契約が元に戻る）。
2. note の画像生成は、上限に当たったら解除時刻を記録し（記事レーンもそれを見て止まる）、
   残りの画像は呼ばずに本文だけで進む。画像がないことは承認依頼に1行で載せ、出すかどうかは
   人間が下書きを見て決める。上限中に始まった場合は最初から画像生成を呼ばない。
3. 日次パイプラインに「前日が note 枠で、その生成が異常終了し、以後 note が無ければ翌朝やり直す」
   判定を追加。**異常終了だけ**が対象で、検品不合格や承認待ちでの見送り（正常終了）はやり直さない。
   翌朝の1日だけなので、同じ原因で落ち続けても毎日課金し続けない。
4. 失われた木曜分は、修正後にその場で生成し直した。

検証: 本番 DB のコピーで14項目（上限でも落ちない・試行は1回だけ・上限の記録・承認依頼の1行・
翌朝やり直しの判定4パターン等）を実走。

## 予防ルール

- **既存の例外を細分化するときは、新しい例外を既存の型の子にする**。兄弟にしてよいのは、
  既存の `except` 節を全部 grep して、それぞれで新しい例外をどう扱うか決めたときだけ。
- 例外クラスの新設・付け替えは定義の拡張と同じく、**`except 旧型` の全数が消費側**
  （producer-consumer-sync R1）。区別が必要な1箇所だけ直して終わりにしない。
- LLM で高い作業をした後に、副次的な処理（画像・通知など）が例外で落ちると**主成果物ごと消える**。
  副次処理の失敗は主成果物の保存を巻き込まない形で拾う。
- 固定枠（週N回）でしか走らない処理は、1回の異常終了が次の枠まで丸ごと空白になる。
  連続失敗の通知は枠の間隔では鳴らないので、**翌回のやり直し**か**枠単位の警告**を持たせる。

## 関連

- [[../clusters/producer-consumer-sync.md]] R1g
- [[published-but-never-announced-because-url-stayed-in-stdout.md]] — 同じく「成功に見える失敗」が次の工程で静かに消える形
- [[task-time-limit-kills-run-and-its-own-alarm.md]] — 異常終了が定時の通知をすり抜ける別の例
