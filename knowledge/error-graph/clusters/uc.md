# Cluster: UC — 検品・自己学習・媒体目的の人間指摘系

> Layer 1 Community Summary — 関連ノードの蒸留サマリー。
> pullie等の自動運営システムで「人間に指摘されて初めて発覚した」構造欠陥のクラスター。
> 検品ゲート・可視化・エージェント学習ループの設計時にロードする。個別詳細は nodes/ を参照。

**対象タグ**: `user-correction`, `visual-inspection`, `verification`, `approval-flow`, `vision-review`

---

## 蒸留ルール（Distilled Rules）

### R1: 検品は「欠陥が発現する条件」をカバーして初めて1層と数える
層の数ではなく条件のカバレッジ。読者はスマホでも読む・最終状態を見る・白ページに合成して見る。
- 詳細: [[../nodes/uc-inspection-must-match-reader-conditions.md]]

### R2: 決定論で測れる欠陥はLLM目視の手前に決定論ゲートを置く
opacity残留・画像欠落・背景色・アルファ・外周余白はコードで測れる。LLMの目視は本体に
引っ張られ、地（キャンバス・余白）の異常をデザインと誤認する。
- 詳細: [[../nodes/image-dark-canvas-margin-passes-vision-review.md]]

### R3: グレース（欠損許容）は下流に欠損検査ゲートとペアでのみ安全
「なしで続行」した欠損を下流の誰も検査しないと、欠損のまま承認・公開まで流れる。
- 詳細: [[../nodes/uc-inspection-must-match-reader-conditions.md]]

### R4: 失敗作は消さず退避し、本人へ教訓として還流する
作り直しループだけでは癖が直らない。不合格の実物+理由を保存→定期的に教訓へ昇格→注入。
- 詳細: [[../nodes/uc-agents-must-learn-from-own-failed-work.md]]

### R5: 媒体の存在目的（受注・ポジショニング）は実行層のSKILLまで落とす
上位ドキュメントに書いただけのルールは生成物に現れない。
- 詳細: [[../nodes/uc-articles-must-carry-own-positioning.md]]

### R6: 可視化要求は「何を発見したいか（監査目的）」を先に確認する
集計サマリーは監査に無力。異常を1件ずつ辿れる粒度で設計し、可視化物も実走検証する。
- 詳細: [[../nodes/uc-visualization-without-audit-purpose.md]]

### R7: 人間への通知は判断を変える状態文脈（新規か更新か）まで運ぶ
システムだけが知る文脈を文面から省くと、正常動作が異常（重複・暴走）に見える。
新レーンが既存の人間接点（承認・通知）に合流する時は、文面がそのレーンを表現できるかまで点検する。
- 詳細: [[../nodes/uc-rewrite-approval-must-declare-itself.md]]

### R8: 方向が意味を持つデータはLLM要約器に渡す前に方向を値へ焼き込む
LLMは曖昧さを成果が大きく見える方向に解消する（自己報告の粉飾バイアス）。送り/受けの語彙は
契約で固定し、監査は「記録の実在」でなく「主張の文言」単位で一次データと突き合わせる。
- 詳細: [[../nodes/uc-activity-report-inverted-engagement-direction.md]]

### R9: 人間宛ての依頼には「その人の受信環境で開ける URL」を載せる
ローカルパスやコマンドはスマホの Discord では開けない。承認依頼＝人間が実物を見る接点なので、
プレビューデプロイ等の公開 URL を必須にし、ローカル情報は補足に留める。
「前提 X が未完了だから後回し」とした実装は、X の完了をトリガーに再評価する。
- 詳細: [[../nodes/uc-approval-request-local-path-instead-of-url.md]]

### R10: 人間が最初に見る面（デザイン・画像）を先に作り、テンプレ既定値のまま見せない
パイプラインを先に完成させても、承認者が見るのは記事の見た目と画像。ブランド資産（ロゴ）は見つけた時点で
確認して起点にし、価値提供（構造化）はナビゲーション・記事内構造・画像の役割にまで翻訳する。
画像は「装飾」でなく「読者の理解を進める情報」— 見出しごとに役割を定義し、手順は実スクショ + 加工。
- 詳細: [[../nodes/uc-site-design-direction-before-content.md]] / [[../nodes/uc-article-images-decorative-not-explanatory.md]]

### R11: ビジュアルは参照物（コード + スクショ + 実測メトリクス）を取ってから組む
トークンと機能が揃っていても、配置のリズム・大きさの対比・視線誘導は参照無しでは平均的になる。
ユーザー指定の参照サイトを curl + Playwright で取得し、余白・文字サイズ・角丸・モーションを数値で書き出してから写す。
モーションは「振幅・周期・イージング」まで数値で決める（ふよふよ = 4〜9px / 8〜18s / 位相ずらし、ホバー = scale 2.2 + バネ）。
- 詳細: [[../nodes/uc-layout-without-design-reference.md]]

### R12: グラフ UI は「全体 → 寄る → 選ぶ」の 3 段 + 実行時レイアウト + 読者の語彙の親ノード
30 を超えるノードを静的 1 スケールに収めると必ず小さく隙間だらけになる。配置は画面寸法から計算し、
選択でカメラを寄せて子を大きく見せる。親ノードは内部データの軸ではなく読者の大分類（LLM / TTS / ノーコード…）。
- 詳細: [[../nodes/uc-graph-hierarchy-zoom-and-fit.md]]

### R13: インタラクティブな図は「状態ごとのレイアウト・面の充填・枝の色・反応→遷移の順序」を仕様に含める
カメラだけの「寄る」は読めない。フォーカス専用の整列（マインドマップ）へ補間で遷移し、根ノードと全周展開で面を埋め、
色は枝単位、クリックは反応（~330ms）を先に見せてから動かす。
- 詳細: [[../nodes/uc-graph-focus-relayout-and-click-feedback.md]]

### R14: モーションも参照駆動 — GSAP 公式デモのパラメータを写す
自前の easing / lerp / CSS キーフレームは「レベルが低い」と言われる。GSAP 3.13+（全プラグイン無料）で、
SplitText / DrawSVG / stagger from center + back.out / elastic ホバー / power3.inOut カメラ / ScrollTrigger.batch を
公式ドキュメントのコード例のまま使い、独自調整はその後。
- 詳細: [[../nodes/uc-handrolled-animation-low-quality-use-gsap-examples.md]]

### R15 人に「見た目」を承認させる前に、機械が「見た目」を検査する
ファイル検査（寸法・比率・重複）だけでは HTML/CSS 層の破綻（figure 化漏れ・キャプションの重なり・cover の切り抜き）を検出できない。
承認依頼の前に実ブラウザ（Playwright PC/SP）で矩形を測るプローブを通す。画像+キャプションは Markdown 上で別ブロックにする。
- 詳細: [[../nodes/uc-article-image-cropped-caption-overlap.md]]

### R16 記事構造は読者の意思決定から逆算する（実測の深さは根拠であって主役ではない）
アフィリエイトの転換点は「決断」。初心者読者には最初の 1 画面で「得られる結果」「迷ったらこれ」、本線は最短手順 3〜5 ステップ。
深掘りは末尾に隔離。推奨は実測値+「合わない人」でのみ行い、根拠のない強調（安直な訴求）は書かない。差し戻し理由は必ず writer の入力に届いているか実装を追う。
- 詳細: [[../nodes/uc-articles-too-advanced-for-beginner-readers.md]]

### R17 モデルの限界を語る前に「自分のプロンプトが作った限界」を疑い、1 枚の実測で検証する
「GPT Image は日本語が崩れる」は自作の禁止指示（never Japanese characters / never numbers）が原因だった。ユーザーの元指示（GPT Image 2 で生成）から外れる時は、外れる根拠を実測で示す。
- 詳細: [[../nodes/uc-gpt-image-japanese-text-was-self-forbidden.md]]

### R18 「余白を減らせ」と「切るな」は同時に指示し、後処理の切り抜きは「切られて困る内容が無い」時だけ
「端まで描け」は端で切れる図を生む。1 種別（情報図）で直した余白/切れのルールは hero など全種別に横展開する。
- 詳細: [[../nodes/uc-hero-image-cropped-by-edge-to-edge-rule.md]]

### R19 画像の役割（何を伝えるか）を先に定義し、「見た人が記事との関係を説明できるか」で検収する
記事冒頭/OGP の画像は「何の記事で結論は何か」を伝える面。装飾目的の抽象図を置かない。タイトル + 結論 + 主題図。
- 詳細: [[../nodes/uc-hero-image-abstract-unrelated-to-article.md]]

### R20 内部文書を素材にする工程では「読者に無関係な語彙」を機械で検出する
factsheet の弁明（禁止・予算・ラボ制約）を記事に写すと報告書になる。正直さは「何をした/していないか」で示し、「なぜできなかったか（運営事情）」は書かない。AI 執筆の明示はサイト単位（運営者情報）で。
- 詳細: [[../nodes/uc-articles-contain-operator-facing-justifications.md]]

### R21 企画の単位は検索意図。キーワードは素材であって記事の単位ではない
KW 1 語 = 記事 1 本で企画すると、同じ意図が「動くのか」と「どう始めるのか」に割れ、読者は 2 本読むまで答えが揃わない。
束ねる基準は「意図が同じ / 読者の作業が連続 / 判断の表裏 = 1 本」「対象製品が違う = 別」（記事タイプ違い・長さは分ける理由にならない）。
競合分析は「穴（missing_topics）」と同時に「上位が揃って書いている必須要素（common_topics）」を出し、
企画・執筆・検閲の 3 段すべてに網羅性を配線する（穴だけを埋める記事を作らせない）。
- 詳細: [[../nodes/uc-plan-by-intent-not-keyword.md]]

- **X の発信の形式・本数・タイミング・文面を決めるコードを書かない**（機械が持つのは天井・ゲート・送信・ロックだけ）。新レーンを足すときは「予測（intent.predict）が付くか／週次検証の対象か／前回の結果を次の判断が読めるか」の3点を自己診断する — [[../nodes/uc-breaking-lane-tweet-format-is-strategist-judgment.md]]

- **品質劣化を人間が目で見つけたら、直すのは「見えた症状」ではなく「機械が気づけなかった理由」**。フォールバックは記録と通知に出し（グレースは隠す仕組みではない）、生成物のラベルは実経路から導出し（定数のラベルは検閲に嘘を渡す）、復旧手順が確定している外部ツールのエラーは自己修復にする（環境を変える操作には無効化スイッチ・クールダウン・1プロセス1回・排他を付ける） — [[../nodes/uc-silent-fallback-labeled-as-gpt.md]]

### R22 落ちない検査は検査ではない — 成功条件は「事実が成立していないと出現し得ないもの」で取る
「成立時に出るもの」を合図にすると、不成立時にも出ることがある（未ログイン画面にもアプリの枠は描画される・
URL がログイン前後で変わらないサイトがある・制約の無い偽スキーマでは INSERT が常に通る）。
合図は**不成立時に出るものが消えたこと**で取る。肯定と否定が同時に見えたら**否定に倒す**（未ログイン・不合格・未検証が安全側）。
検査を書いたら、条件が成立していない状態で一度走らせて**赤を出してから**採用する。
自分が書いた成功記録（ログの `LOGGED IN`・manifest のラベル）を、次の判断の証拠にしない。
DB を使うテストは本番の `schema.sql` から作る — 表の形を手で写した瞬間、制約は消える。


## このクラスターのノード一覧

- [[../nodes/uc-approval-request-local-path-instead-of-url.md]] — `user-correction`, `hitl`, `approval-flow`, `stale-assumption`
- [[../nodes/uc-site-design-direction-before-content.md]] — `user-correction`, `design`, `site-structure`, `brand`
- [[../nodes/uc-article-images-decorative-not-explanatory.md]] — `user-correction`, `images`, `content-quality`, `screenshots`
- [[../nodes/uc-layout-without-design-reference.md]] — `user-correction`, `design`, `layout`, `reference-driven`
- [[../nodes/uc-graph-hierarchy-zoom-and-fit.md]] — `user-correction`, `graph`, `layout`, `zoom`, `taxonomy`
- [[../nodes/uc-graph-focus-relayout-and-click-feedback.md]] — `user-correction`, `graph`, `mind-map`, `motion`, `color`
- [[../nodes/uc-handrolled-animation-low-quality-use-gsap-examples.md]] — `user-correction`, `animation`, `gsap`, `motion-quality`
- [[../nodes/uc-focus-labels-too-small-after-zoom.md]] — `user-correction`, `graph`, `typography`, `readability`（R13 の補足: 状態ごとの実効フォントサイズを保証）
- [[../nodes/uc-article-image-cropped-caption-overlap.md]] — `user-correction`, `images`, `captions`, `preview`（R15）
- [[../nodes/uc-articles-too-advanced-for-beginner-readers.md]] — `user-correction`, `editorial`, `audience`, `beginner`（R16）
- [[../nodes/uc-gpt-image-japanese-text-was-self-forbidden.md]] — `user-correction`, `images`, `gpt-image`, `false-premise`（R17）
- [[../nodes/uc-hero-image-cropped-by-edge-to-edge-rule.md]] — `user-correction`, `images`, `hero`, `cropping`（R18）
- [[../nodes/uc-hero-image-abstract-unrelated-to-article.md]] — `user-correction`, `images`, `hero`, `meaning`（R19）
- [[../nodes/uc-articles-contain-operator-facing-justifications.md]] — `user-correction`, `editorial`, `tone`, `internal-leak`（R20）
- [[../nodes/uc-comparison-article-without-real-measurement.md]] — `uc`, `measurement`, `policy-change`（方針変更は「実施不可」factsheet の再取得を起動する・Q03 は約束した対象の実測かを見る）
- [[../nodes/uc-ai-authorship-still-visible-in-site-chrome.md]] — `uc`, `site-chrome`, `scope-of-fix`（「X を消して」は意図として公開面全体を grep・移設しない）
- [[../nodes/uc-approval-reminder-without-clickable-preview-url.md]] — `uc`, `notification`, `discord`（行動を求める通知には開けるリンク・URL 生成は一箇所）
- [[../nodes/uc-breaking-lane-tweet-format-is-strategist-judgment.md]] — `sns`, `pdca`, `llm-free-overreach`, `weevee`（速報レーンの X 発信を固定テンプレで書いた → 「LLM不要はやめて。PDCA が回らない」→ x-strategist の速報作戦へ）
- [[../nodes/uc-internal-handoff-note-live-on-published-page.md]] — `public-tone`, `internal-leak`, `publish-gate`（公開済みページに「editor-in-chief への申し送り」が残っていた → 生成側の修正は live に遡及しない・公開直前の最終テキストに機械ゲート）
- [[../nodes/uc-x-posts-must-deliver-official-facts-with-media.md]] — `sns`, `content-quality`, `media`（「注視中」で締まる速報ツイート → 公式リソースの具体 + 画像/動画を必ず付ける。合格条件は「禁止語がない」でなく「持ち帰りが 1 つある」）
- [[../nodes/uc-plan-by-intent-not-keyword.md]] — `editorial`, `seo`, `search-intent`, `coverage`, `weevee`（R21: KW 1 語 = 記事 1 本で企画が意図ごとに割れていた → intent クラスタリング + common_topics + Q17 網羅性）
- [[../nodes/uc-silent-fallback-labeled-as-gpt.md]] — `images`, `imagegen`, `fallback`, `silent-failure`, `labeling`, `self-healing`, `weevee`（画像エンジンが 3 日間全滅していたのに manifest は「GPT Image・読み戻し照合済み」と記録 → 実経路からのラベル導出・フォールバックの可視化・外部 CLI の自動更新）
- [[../nodes/verification-tool-that-cannot-fail.md]] — `user-correction`, `verification`, `false-positive`, `test-schema`, `weevee`（R22: URL 一致で「LOGGED IN」・未ログイン画面にも出る語を「ログイン後にだけ出る語」に登録・偽スキーマが本番の CHECK/FK/NOT NULL を隠す — 同じ型が 1 時間で 3 件）
- [[../nodes/uc-gave-up-on-paid-service-without-checking.md]] — `user-correction`, `verification`, `premature-giving-up`, `cost-rule`, `weevee`（契約済みの ChatGPT Pro を「有料だから触れない」と確認せず結論 — 課金禁止は**新たな課金**の禁止であって有料サービスを使わないことではない）

- [[../nodes/uc-added-constraints-without-updating-the-goal.md]] — `goal-alignment`, `agent`, `prompt-design`, `producer-consumer-sync`, `pullie`（noteが3本続けて同じ理由で差し戻し → 私は禁止条項と差し戻し履歴を足したが、**その振る舞いを指示していた戦略文書（目的・レーン定義）を一度も読まなかった**。制約を足しても目的が古いままなら同じ場所に戻る。「順番を機械が決める」場所は判断が消えている場所）
- [[../nodes/uc-endless-whack-a-mole.md]] — `process`, `verification`, `observability`, `weevee`（「直すたびに次が出る」の根本原因 3 つ: 成功の合図が事実を含意しない／観測者が観測対象の中に住む／同じ集合を手で 4 回書く。独立診断 39 エージェントで確定。私の当初の見立て 2 点は反証された）
