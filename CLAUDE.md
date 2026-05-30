# CLAUDE.md

このリポジトリで作業する際の Claude 向けメモ。

## デプロイ構成

| 層 | ホスティング | 備考 |
|---|---|---|
| フロント (Web) | Cloudflare Workers | 公開URL: `https://income-and-expense.annndddddooooooo.workers.dev/` |
| iOS | Xcode Cloud | リリースビルドで配布 |
| バックエンド (Django API) | DigitalOcean 上の Dokku | API URL: `https://income-and-expense.167.172.65.18.nip.io/api` |

### 接続先設定の場所
- iOS: `ios/IncomeAndExpense/App/AppConfig.swift`（DEBUG=localhost、リリース=本番API URL）
- Web: `frontend/.env.production` の `VITE_API_BASE_URL`、フォールバックは `frontend/src/api/client.ts` / `frontend/src/api/auth.ts`
- バックエンドの `ALLOWED_HOSTS` / `CORS_ALLOWED_ORIGINS` は `config/settings/production.py` で**環境変数から読む**（デフォルト値なし＝未設定だと全拒否）。値はサーバー（Dokku）側の環境変数で管理。

## TODO（別の修正機会にまとめてやる）

### CI/CD: 検証ブランチでの自動ビルド・ステージング整備
「本番相当で動作確認してから main にマージ」を実現するため、以下を整備したい:
- **Cloudflare (フロント)**: ブランチ/PR ごとのプレビューデプロイを有効化し、検証ブランチをプレビューURLで確認できるようにする
- **Dokku (バックエンド)**: 検証ブランチ用のステージングアプリ（**本番とは別DB**）を用意し、検証ブランチ push で自動デプロイ
- **Xcode Cloud (iOS)**: 検証ブランチ用のワークフローを追加
- 原則: 検証ブランチ → ステージング/プレビュー、`main` → 本番。両者を分離し、検証が本番データ・本番URLを汚さないようにする
