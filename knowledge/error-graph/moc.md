# Error Knowledge Graph: MOC (Global Index) — Layer 2

**AIへの指示**: アクション実行前・エラー発生時・ユーザー指摘時に以下を順番に行う。
1. [[relationships.md]] を読み、今の**アクション種別**に対応するフラグをトラバーサルする
2. 該当フラグを適用してからアクションを実行する
3. Quick Rules は頻出パターンのショートカット（relationships.md の補完）

*Related MOC*: [[../skills-moc.md|Skills Knowledge Graph (MOC)]]

---

## Quick Rules（最重要ルール — 毎回適用）

> クラスターから昇格した、最も頻繁に必要なルール

1. **ファイル作成・変更前**: `PROJECT_MAP.md` を読んで重複・依存関係を確認する
2. **後処理の強制設計**: 重要な後処理（ドキュメント・記録）は「完了の出口条件」にする。"後でやる"は機能しない
3. **外部APIの `await`**: 必ずタイムアウトで包む（`Promise.race` 等）。タイムアウトなし `await` は禁止
4. **設計提案の具体化**: 「誰が・いつ・何をトリガーに・何を書くか」まで具体化する。抽象ラベル（「重要な知見」等）禁止
5. **バグ修正コミットの出口条件**: バグ修正コミットを作る前に必ずエラーノード（`nodes/` + クラスター更新 + MOC 追記）を作成する。コミットメッセージに `fix:` が含まれる場合は必須
6. **セッション宣言は無効**: 「次回からやります」は何も変えない。宣言したい内容は **今すぐ** CLAUDE.md か error-graph に書いてコミットする
7. **UC検出トリガー（即時反応）**: ユーザーの発言に以下のパターンが含まれたら、返答より先に UC ノード作成を開始する
   - 「〜は足りない」「〜では足りない」「〜が抜けている」「〜はまずい」「〜は問題だ」
   - 「なぜ〜しない」「〜すべきだ」「〜してくれないと」
   - 「仕組みにして」「ルールにして」「構造にして」「埋め込んで」
   - 「そうじゃない」「違う」「ちがう」「それは違います」
   → UCノード（`uc-*.md`）を nodes/ に作り、クラスターと MOC を更新してからコミット
8. **コミット前 UC スキャン**: push 前に「このセッションでユーザー指摘はあったか？」を必ず自問する。あれば UC ノードが作成済みか確認する
   ※ git push のブランチ制約は `pre-bash-git-push.sh` フックが自動強制 — ルールではなくコードで解決済み
9. **パターン実装後の横展開チェック**: 新しい構造・ファイル・パターンを「ある場所に」実装したら必ず自問する
   > 「これは局所要件か、この種の構造すべてに必要な汎用要件か？」
   > 同種の構造が他にあれば、同じパターンを即座に展開する（例: relationships.md → 全グラフ構造）
10. **R-HAZUDESU（実測報告の義務）**: テスト・動作確認タスクでは「〜のはずです」「〜されます」で終わらず、必ずコマンド実行結果（`gh run list` / `ls` / `git show` 等）を添えて実測値を報告する。確認コマンドが使えない場合は「確認できない理由」を明記する

---

## Clusters（Layer 1 — トピック別コミュニティサマリー）

| クラスター | 内容 | ノード数 | ロード条件 |
|---|---|---|---|
| [[clusters/ai-behavior.md]] | AI行動パターン・システム設計・知識グラフ設計 | 10 | AI設計・スケール・ナレッジシステム系タスク |
| [[clusters/api-network.md]] | API/ネットワーク・非同期・タイムアウト・プラットフォーム規制 | 3 | 外部API・ネットワークリクエストを書く時 |
| [[clusters/platform-syntax.md]] | PowerShell/Windows固有の構文エラー | 1 | PowerShell・Windowsスクリプト作業時 |
| [[clusters/copywriting-psychology.md]] | コピーライティング心理学・間接的動機づけ設計 | 1 | 記事・LP・SNS投稿のコピーを書く時 |
| `database-orm` | Database/ORM の型・スキーマ・クエリエラー | 1 | Supabase・Prisma・ORM を使う時 |
| `sdk-migration` | SDK バージョンアップグレード時のブレーキングチェンジ | 1 | ライブラリをアップグレードする時 |
| [[clusters/shell-hook-env.md]] | Claude Code フック・シェル環境変数の落とし穴 | 1 | Claude Code フック・session-start.sh・シェルスクリプトを書く時 |
| [[clusters/producer-consumer-sync.md]] | 定義（スキーマ/カタログ/キー一覧）拡張時の消費側同期漏れ | 2 | スキーマ・カタログ・enum・frontmatterフィールドを拡張する時 |
| [[clusters/kintone.md]] | kintone カスタマイズ（REST API・カスタムJS/CSS・全体カスタマイズ）の落とし穴 | 4 | kintone アプリ構築・カスタマイズ作業時 |

---

## スケールメンテナンスルール

このシステムが機能し続けるために以下を守る:

| 条件 | アクション |
|---|---|
| 同クラスターに **3件以上** ノードが追加された | クラスターサマリーを更新し蒸留ルールを追加する |
| クラスターの蒸留ルールが **5件以上** になった | 上位ルールを Quick Rules セクションへ昇格する |
| Quick Rules が **10件以上** になった | SKILL.md（Procedural Memory）へ昇格し MOC から削除する |
| 既存クラスターに収まらない新ノード | 新クラスターを `clusters/` に作成し、この表に追加する |

---

## All Nodes Index (nodes/)

> Complete index below. Use clusters for structured entry.

### [Type A] Technical Errors
- [[nodes/ai-context-blindness-at-scale.md]] — `ai-behavior` cluster (`scaling`, `system-design`, `architecture`)
- [[nodes/ai-instruction-enforcement.md]] — `ai-behavior` cluster (`prompt-engineering`, `system-design`)
- [[nodes/ai-sdk-v6-renamed-properties.md]] — `ai-sdk` cluster (`vercel-ai`, `typescript`, `api-migration`)
- [[nodes/api-rate-limit-exceeded.md]] — `api` cluster (`network`, `rate-limit`)
- [[nodes/bash-awk-regex-and-array-accumulation.md]] — `bash` cluster (`awk`, `regex`, `arrays`, `windows`, `git-bash`, `cross-platform`)
- [[nodes/cdp-port-9222-hijacked-by-wsl-relay-wrong-browser.md]] — `wsl` cluster (`cdp`, `playwright`, `chrome`, `port-collision`, `misdiagnosis`, `pullie`)
- [[nodes/checklist-references-file-not-in-skill-refs.md]] — `producer-consumer-sync` cluster (`skill-sync`, `agent-manifest`, `llm-pipeline`, `weevee`)
- [[nodes/claude-headless-chunk-timeout-truncation.md]] — `claude-headless` cluster (`llm-pipeline`, `timeout`, `streaming`, `weevee`)
- [[nodes/claude-headless-permission-flags-ignored-under-bypass.md]] — `claude-headless` cluster (`permissions`, `hooks`, `sandbox`, `windows`, `weevee`)
- [[nodes/claude-hook-env-project-dir.md]] — `shell-hook-env` cluster
- [[nodes/cloudflare-github-app-single-account-binding.md]] — `cloudflare-pages` cluster (`github-app`, `git-integration`, `infrastructure`, `multi-account`)
- [[nodes/codex-image-tool-prompt-contract-multiline-and-attach-order.md]] — `codex` cluster (`imagegen`, `cli-contract`, `silent-failure`, `weevee`)
- [[nodes/copywriting-indirect-motivation.md]] — `copywriting` cluster (`psychology`, `content-writing`, `behavioral`, `self-determination`)
- [[nodes/deploy-wait-http-200-races-stale-build.md]] — `cloudflare` cluster (`pages`, `deploy`, `race-condition`, `verification`, `pullie`)
- [[nodes/discard-path-topic-requeue-leak.md]] — `pipeline` cluster (`state-machine`, `cleanup`, `sqlite`)
- [[nodes/frontmatter-field-not-wired-into-all-renderers.md]] — `producer-consumer-sync` cluster (`astro`, `schema-sync`, `renderer`, `visual-inspector`, `pullie`)
- [[nodes/grace-skip-needs-escalation-for-human-only-recovery.md]] — `monitoring` cluster (`silent-failure`, `grace-degradation`, `hitl`, `session-expiry`, `pullie`)
- [[nodes/gsc-final-lag-outruns-lookback-window.md]] — `pullie` cluster (`gsc`, `data-collection`, `lookback-window`, `upsert`, `silent-failure`)
- [[nodes/image-dark-canvas-margin-passes-vision-review.md]] — `pullie` cluster (`image-generation`, `gpt-image`, `vision-review`, `alpha-channel`, `deterministic-gate`)
- [[nodes/image-reuse-by-section-index-after-restructure.md]] — `images` cluster (`idempotency`, `pipeline`, `caption-mismatch`, `weevee`)
- [[nodes/infographic-text-clipped-in-narrow-cards.md]] — `images` cluster (`rendering`, `infographic`, `overflow`, `self-verification`, `weevee`)
- [[nodes/instant-approval-path-skips-sns-fanout.md]] — `pullie` cluster (`sns`, `pipeline-wiring`, `dual-path`, `approval-flow`, `x-twitter`)
- [[nodes/intersection-threshold-hides-tall-sections.md]] — `web-frontend` cluster (`intersection-observer`, `reveal-animation`, `mobile`, `viewport`, `pullie`)
- [[nodes/kintone-calc-no-today-function.md]] — `kintone` cluster (`api`, `calc-field`, `GAIA_IL01`, `pullie`)
- [[nodes/kintone-delivered-js-manual-commentout-corruption.md]] — `kintone` cluster (`custom-js`, `syntax-error`, `diagnosis`, `client-edit`, `block-comment`)
- [[nodes/kintone-dropdown-query-nonexistent-option-error.md]] — `kintone` cluster (`rest-api`, `query`, `dropdown`, `dynamic-range`, `error-handling`)
- [[nodes/kintone-system-js-head-execution-body-null.md]] — `kintone` cluster (`custom-js`, `portal`, `dom-timing`, `mutation-observer`)
- [[nodes/lab-guard-blocked-readonly-utils-and-own-volume.md]] — `lab-guard` cluster (`allowlist`, `false-block`, `docker`, `researcher`, `weevee`)
- [[nodes/llm-dsl-single-line-flattening-breaks-parser.md]] — `llm` cluster (`dsl`, `parsing`, `format-variance`, `deterministic-crash`, `pullie`)
- [[nodes/llm-json-extract-object-regex-breaks-arrays.md]] — `llm` cluster (`json`, `regex`, `parsing`)
- [[nodes/llm-json-raw-control-characters.md]] — `llm` cluster (`json`, `parsing`, `python`, `pullie`)
- [[nodes/llm-json-unescaped-inner-quotes.md]] — `llm` cluster (`json`, `parsing`, `python`, `pullie`)
- [[nodes/llm-output-fence-heuristic-matches-inner-code-block.md]] — `llm` cluster (`output-parsing`, `regex`, `markdown`, `pullie`, `deterministic-crash`)
- [[nodes/llm-output-strict-prefix-check-16run-dead-feature.md]] — `llm` cluster (`output-parsing`, `grace-degradation`, `silent-failure`, `link-validation`, `pullie`)
- [[nodes/llm-reviewer-false-ng-on-template-layer-items.md]] — `ai-behavior` cluster (`llm-pipeline`, `reviewer`, `checklist`, `audit-log`, `weevee`)
- [[nodes/llm-self-reported-index-silent-drop.md]] — `llm` cluster (`contract-validation`, `pullie`, `images`, `silent-failure`)
- [[nodes/note-kpi-weekly-cadence-window-blind-spot.md]] — `observability` cluster (`kpi`, `note`, `producer-consumer-sync`, `window-alignment`, `cadence`, `pullie`)
- [[nodes/pipeline-resume-guard-orphaned-early-stage-drafts.md]] — `pullie` cluster (`pipeline`, `orchestration`, `resume`, `orphan`)
- [[nodes/powershell-hash-literal-git.md]] — `powershell` cluster (`git`, `syntax-error`)
- [[nodes/publish-worker-not-idempotent-after-push.md]] — `git` cluster (`idempotency`, `pipeline`, `publish`, `cloudflare-pages`)
- [[nodes/queue-adjacency-same-article-consecutive-posts.md]] — `pullie` cluster (`sns`, `queue`, `scheduling`, `x-twitter`, `dedup`)
- [[nodes/reviewer-checklist-without-applicability-conditions.md]] — `ai-behavior` cluster (`llm-pipeline`, `reviewer`, `checklist`, `scoring`, `weevee`)
- [[nodes/reviewer-flagged-machine-rendered-log-image-as-fabricated.md]] — `reviewer` cluster (`false-positive`, `images`, `provenance`, `send-back-loop`, `weevee`)
- [[nodes/reviewer-send-back-loop-on-unfixable-screenshot-item.md]] — `reviewer` cluster (`send-back-loop`, `structural-constraint`, `screenshots`, `checklist`, `weevee`)
- [[nodes/rotation-starvation-by-unengageable-accounts.md]] — `scheduling` cluster (`starvation`, `x-twitter`, `silent-failure`, `budget`, `sqlite`)
- [[nodes/semantic-graph-relationships.md]] — `system-design` cluster (`knowledge-graph`, `semantics`, `obsidian`)
- [[nodes/slack-api-silent-hang.md]] — `slack` cluster (`api`, `timeout`, `mcp`)
- [[nodes/sqlite-unique-slug-permanent-crash-loop.md]] — `sqlite` cluster (`unique-constraint`, `pipeline`, `pullie`, `slug`, `self-healing`)
- [[nodes/stale-claude-md-duplicate-implementation.md]] — `multi-machine` cluster (`git`, `claude-md`, `session-handoff`, `duplicate-work`)
- [[nodes/stale-pipeline-lock-after-killed-run.md]] — `lock` cluster (`pipeline`, `resume`, `windows`, `process-lifecycle`, `weevee`)
- [[nodes/supabase-v2-types-resolve-never.md]] — `supabase` cluster (`typescript`, `database`, `type-safety`)
- [[nodes/utc-timestamps-render-as-last-night.md]] — `sqlite` cluster (`timezone`, `utc`, `dashboard`, `jst`, `pullie`)
- [[nodes/weekly-guard-day-window-phase-skip.md]] — `scheduling` cluster (`cadence`, `guard`, `idempotency`, `false-alarm`, `pullie`)
- [[nodes/windows-claude-cli-subprocess-needs-cmd-and-gitbash.md]] — `windows` cluster (`claude-code`, `subprocess`, `python`, `headless`, `npm`)
- [[nodes/windows-claude-stream-burst-false-inactivity-kill.md]] — `windows` cluster (`claude-code`, `subprocess`, `streaming`, `timeout`, `buffering`)
- [[nodes/windows-codex-imagegen-triple-failure.md]] — `windows` cluster (`codex`, `imagegen`, `subprocess`, `acl`, `npm-shim`, `sandbox`)
- [[nodes/windows-python3-store-stub-silent-hook-failure.md]] — `windows` cluster (`python`, `hooks`, `claude-code`, `secrets`, `silent-failure`)
- [[nodes/windows-subprocess-cp932-decode-crash.md]] — `windows` cluster (`python`, `subprocess`, `encoding`, `cp932`, `utf8`)
- [[nodes/windows-wsl-sqlite-transient-open-failure.md]] — `sqlite` cluster (`wsl`, `windows`, `wal`, `file-lock`, `pullie`)
- [[nodes/wrangler-toml-referenced-file-missing.md]] — `cloudflare` cluster (`pages`, `d1`, `wrangler`, `deploy`, `lead-pipeline`)
- [[nodes/writer-output-truncated-by-code-fence-misparse.md]] — `parsing` cluster (`llm-output`, `regex`, `writer`, `silent-degradation`, `weevee`)
- [[nodes/x-api-quote-restriction-silent-lane-death.md]] — `api` cluster (`x-twitter`, `policy-change`, `403`, `monitoring`, `silent-failure`)
- [[nodes/x-api-reply-restriction-403.md]] — `api` cluster (`x-twitter`, `policy-change`, `403`, `mcp`)
- [[nodes/x-users-search-ascii-only-query.md]] — `api` cluster (`x-twitter`, `400`, `validation`, `pullie`)

### [Type B] User Corrections (uc-)
- [[nodes/catalog-key-added-without-consumer-sync.md]] — `multi-agent` cluster (`skill-sync`, `screenshot`, `pipeline`)
- [[nodes/uc-abstract-knowledge-label.md]] — `knowledge-design` cluster (`system-design`)
- [[nodes/uc-activity-report-inverted-engagement-direction.md]] — `pullie` cluster (`reporting-integrity`, `llm-summarization`, `direction-ambiguity`, `self-report-bias`)
- [[nodes/uc-agents-must-learn-from-own-failed-work.md]] — `pullie` cluster (`learning-loop`, `self-retrospective`, `knowledge-db`, `agent-design`)
- [[nodes/uc-antigravity-sync-isolation.md]] — `ai-behavior` cluster (`sync-failure`, `r-hazudesu`, `automation`)
- [[nodes/uc-approval-flow-not-operable-from-notification.md]] — `uc` cluster (`hitl`, `discord`, `approval`, `ux`, `pullie`)
- [[nodes/uc-approval-preview-must-exist-in-every-channel.md]] — `pullie` cluster (`approval-flow`, `preview`, `note`, `prosemirror`, `verification`)
- [[nodes/uc-approval-request-local-path-instead-of-url.md]] — `hitl` cluster (`approval-flow`, `stale-assumption`, `cloudflare-pages`, `weevee`)
- [[nodes/uc-article-image-cropped-caption-overlap.md]] — `images` cluster (`captions`, `rehype`, `css`, `preview`, `weevee`)
- [[nodes/uc-article-images-decorative-not-explanatory.md]] — `images` cluster (`content-quality`, `screenshots`, `image-pipeline`, `weevee`)
- [[nodes/uc-articles-contain-operator-facing-justifications.md]] — `editorial` cluster (`tone`, `internal-leak`, `compliance`, `weevee`)
- [[nodes/uc-articles-must-carry-own-positioning.md]] — `pullie` cluster (`positioning`, `content-strategy`, `conversion`, `compliance`)
- [[nodes/uc-articles-too-advanced-for-beginner-readers.md]] — `editorial` cluster (`audience`, `beginner`, `affiliate`, `writer`, `weevee`)
- [[nodes/uc-demo-screens-are-sales-assets.md]] — `uc` cluster (`pullie`, `screenshots`, `demo-quality`, `kintone`, `sales-perception`)
- [[nodes/uc-focus-labels-too-small-after-zoom.md]] — `graph` cluster (`typography`, `zoom`, `readability`, `weevee`)
- [[nodes/uc-gpt-image-japanese-text-was-self-forbidden.md]] — `images` cluster (`gpt-image`, `japanese`, `false-premise`, `weevee`)
- [[nodes/uc-graph-focus-relayout-and-click-feedback.md]] — `graph` cluster (`layout`, `mind-map`, `motion`, `color`, `weevee`)
- [[nodes/uc-graph-hierarchy-zoom-and-fit.md]] — `graph` cluster (`layout`, `zoom`, `taxonomy`, `responsive`, `weevee`)
- [[nodes/uc-handrolled-animation-low-quality-use-gsap-examples.md]] — `animation` cluster (`gsap`, `motion-quality`, `reference-driven`, `weevee`)
- [[nodes/uc-hero-image-abstract-unrelated-to-article.md]] — `images` cluster (`hero`, `meaning`, `ogp`, `weevee`)
- [[nodes/uc-hero-image-cropped-by-edge-to-edge-rule.md]] — `images` cluster (`hero`, `cropping`, `gpt-image`, `weevee`)
- [[nodes/uc-inspection-must-match-reader-conditions.md]] — `pullie` cluster (`visual-inspection`, `viewport`, `verification`, `approval-flow`)
- [[nodes/uc-knowledge-branch-isolation.md]] — `ai-behavior` cluster (`branch-isolation`, `knowledge-propagation`)
- [[nodes/uc-layout-without-design-reference.md]] — `design` cluster (`layout`, `reference-driven`, `top-page`, `weevee`)
- [[nodes/uc-local-pattern-no-generalization.md]] — `ai-behavior` cluster (`generalization`, `system-design`)
- [[nodes/uc-mechanical-automation-wastes-llm-metacognition.md]] — `uc` cluster (`pullie`, `architecture`, `metacognition`, `agent-design`, `llm`)
- [[nodes/uc-notification-instead-of-self-healing.md]] — `uc` cluster (`pullie`, `notification-policy`, `self-healing`, `hootl`)
- [[nodes/uc-own-comparison-article-exposes-product-gap.md]] — `uc` cluster (`pullie`, `product`, `mvp-scope`, `positioning`, `booth`)
- [[nodes/uc-partial-solution-without-automation-path.md]] — `ai-behavior` cluster (`automation`, `system-design`)
- [[nodes/uc-permission-prompt-fatigue.md]] — `ai-behavior` cluster (`permissions`, `claude-code`, `workflow-friction`)
- [[nodes/uc-premature-completion-reports.md]] — `uc` cluster (`pullie`, `verification`, `reporting`, `discipline`)
- [[nodes/uc-probe-must-cover-layout-overflow.md]] — `pullie` cluster (`visual-inspection`, `layout`, `overflow`, `mobile`, `verification`)
- [[nodes/uc-real-but-unrelated-screenshots.md]] — `uc` cluster (`pullie`, `screenshots`, `content-image-consistency`, `kintone`, `inspection-coverage`)
- [[nodes/uc-rejection-should-trigger-immediate-rework.md]] — `uc` cluster (`hitl`, `pipeline`, `feedback-loop`, `ux`, `pullie`)
- [[nodes/uc-repeat-master-push-despite-known-403.md]] — `git` cluster (`permissions`, `repeat-error`)
- [[nodes/uc-reverted-user-config-without-asking-intent.md]] — `uc` cluster (`settings`, `permissions`, `user-intent`, `claude-code`)
- [[nodes/uc-reviewer-verdict-had-no-enforcement-channel.md]] — `uc` cluster (`pullie`, `review-gate`, `llm-judgment`, `enforcement`, `completeness`)
- [[nodes/uc-rewrite-approval-must-declare-itself.md]] — `pullie` cluster (`approval-flow`, `notification`, `rewrite`, `human-in-the-loop`)
- [[nodes/uc-session-promise-vs-system.md]] — `ai-behavior` cluster (`too-ephemeral`, `system-design`)
- [[nodes/uc-site-design-direction-before-content.md]] — `design` cluster (`site-structure`, `top-page`, `brand`, `weevee`)
- [[nodes/uc-skipped-pdca-on-pivot.md]] — `assumption` cluster (`pivot-masking`)
- [[nodes/uc-sns-operation-is-not-just-posting.md]] — `sns` cluster (`x-twitter`, `operation-design`, `proposal`)
- [[nodes/uc-sns-posts-lack-context-and-persona.md]] — `uc` cluster (`pullie`, `sns`, `copywriting`, `persona`, `context`)
- [[nodes/uc-taste-recommendation-without-data.md]] — `ux-judgment` cluster (`branding`, `recommendation-framing`, `data-honesty`)
- [[nodes/uc-tutorial-images-must-cover-every-step.md]] — `uc` cluster (`pullie`, `content-quality`, `screenshots`, `tutorial`)
- [[nodes/uc-typography-must-meet-readability-floor.md]] — `uc` cluster (`pullie`, `typography`, `readability`, `design-port`, `web-frontend`)
- [[nodes/uc-unverified-hazudesu-reporting.md]] — `ai-behavior` cluster (`unverified-claim`, `hazudesu`, `test-verification`)
- [[nodes/uc-verify-artifact-before-human-approval.md]] — `uc` cluster (`pullie`, `approval-flow`, `visual`, `asset-paths`, `llm-contract`)
- [[nodes/uc-visual-inspection-of-rendered-reality.md]] — `uc` cluster (`pullie`, `visual`, `organization`, `knowledge-db`, `multimodal`)
- [[nodes/uc-visualization-without-audit-purpose.md]] — `ai-behavior` cluster (`requirements`, `dashboard`, `verification`)
- [[nodes/uc-x-engagement-should-self-drive.md]] — `sns` cluster (`autonomy`, `hitl`, `notification-design`)

---

*Note: This index is auto-generated by scripts/generate-moc.*
