# Cluster: API / ネットワークエラー

> Layer 1 Community Summary — 関連ノードの蒸留サマリー。
> ネットワークリクエスト・外部API・非同期処理を扱うタスク時にロードする。

**対象タグ**: `api`, `network`, `timeout`, `rate-limit`, `slack`, `mcp`

---

## 蒸留ルール（Distilled Rules）

### R1: レートリミット — 同時リクエストは必ずスロットリング
外部APIへの並列・大量リクエストは 429 Too Many Requests を引き起こす。
- **対策**: 常に exponential backoff + 同時接続数の上限を実装する（上限は 5 程度から始める）
- **禁止**: 制限なしの無制限並列リクエスト
- **必須**: レスポンスのステータスコードを確認してからボディをパースする
- 詳細: [[../nodes/api-rate-limit-exceeded.md]]

### R2: タイムアウト — await を素のまま使わない
外部APIの `await` はサイレントに永久ブロックする可能性がある。
- **対策**: 全ての外部API呼び出しに明示的なタイムアウトを設ける
  - JavaScript: `Promise.race([apiCall(), timeout(10000)])`
  - Python: `asyncio.wait_for(coro, timeout=10)`
- **禁止**: `await externalApi()` のみ（タイムアウトなし）
- 詳細: [[../nodes/slack-api-silent-hang.md]]

### R3: プラットフォームのポリシー変更 — ラッパー経由でも回避にならない
外部プラットフォーム（X/Twitter等）のAPIは、ポリシー変更で特定機能が予告なく403化する。
- **対策**: 403等の恒久エラーは自己修復リトライでなく代替経路（UI操作・別エンドポイント）へ切替
- **禁止**: 「MCP/SDK経由だから制限が違う」という仮定（制限は常にプラットフォーム側で判定）
- **兆候**: 新機能が最初から一度も成功しない → コードでなく前提（利用可否・権限・ポリシー）を疑う
- 詳細: [[../nodes/x-api-reply-restriction-403.md]]

---

## クイック参照テーブル

| 状況 | 適用するルール |
|---|---|
| 複数URL・複数リソースへの並列リクエストを書く | R1: スロットリング + exponential backoff |
| 外部API（Slack, GitHub, etc.）の await を書く | R2: タイムアウトで包む |
| MCPツール・長時間スクリプト内のAPI呼び出し | R2: 必ずタイムアウトを実装 |
| 429 エラーが発生した | R1: retry ロジックが抜けている |
| 403 が新機能で最初から出続ける | R3: プラットフォーム規制を疑い経路を切替 |

---

## このクラスターのノード一覧

- [[../nodes/api-rate-limit-exceeded.md]] — `api`, `rate-limit`, `network`
- [[../nodes/slack-api-silent-hang.md]] — `slack`, `api`, `timeout`, `mcp`
- [[../nodes/x-api-reply-restriction-403.md]] — `api`, `x-twitter`, `policy-change`, `403`, `mcp`

---

*Last updated: 2026-08-14 | Node count: 3*
