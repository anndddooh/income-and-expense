# 本番 DB の日次バックアップ（Neon → Cloudflare R2）

Neon の Point-in-Time Restore は無料プランだと数時間〜最大24時間しか遡れない。
気づくのが遅れた誤削除や Neon 側の障害に備え、`backup_db` 管理コマンドで毎日の論理バックアップを
Cloudflare R2 に退避する。Rentalist（同じ VPS の `rentalist-api`）と同じ方式。

```
VPS root の cron（毎日 03:45 JST）
  → dokku run income-and-expense python manage.py backup_db
  → dumpdata（JSON）+ gzip
  → R2: <バケット>/income-and-expense/db-backups/income-and-expense-<UTC時刻>.json.gz
  → 30 世代を超えた古い分を自動削除
```

## 1. R2 の用意（初回のみ）

1. Cloudflare ダッシュボード → R2 → バックアップ用バケットを用意する。
   - Rentalist の `rentalist-backups` を共有してよい。キーの接頭辞
     （`BACKUP_PREFIX`、既定 `income-and-expense/db-backups/`）でアプリを分けているため、
     世代削除は自アプリの分にしか効かない。
   - 公開設定は不要（非公開のまま）。
2. R2 → API トークンを管理 → 「オブジェクト読み取りと書き込み」で対象バケットに限定したトークンを作る。
   Access Key ID / Secret Access Key / エンドポイント（`https://<アカウントID>.r2.cloudflarestorage.com`）を控える。
   **値はチャットや git に貼らない。**

## 2. Dokku に設定（初回のみ）

VPS 上の端末で直接実行する（値はチャットに貼らない）。

```bash
ssh dokku@167.172.65.18 config:set --no-restart income-and-expense \
  BACKUP_R2_BUCKET_NAME=rentalist-backups \
  BACKUP_R2_ACCESS_KEY_ID=... \
  BACKUP_R2_SECRET_ACCESS_KEY=... \
  BACKUP_R2_ENDPOINT_URL=https://<アカウントID>.r2.cloudflarestorage.com
# 保持世代を変える場合（既定30）: BACKUP_RETENTION=30
ssh dokku@167.172.65.18 ps:rebuild income-and-expense   # buildpack は env をビルド時に焼き込むため必須
```

## 3. 手動実行で動作確認

```bash
ssh dokku@167.172.65.18 run income-and-expense python manage.py backup_db
# → R2 にアップロードしました: s3://.../income-and-expense/db-backups/income-and-expense-YYYYMMDDThhmmssZ.json.gz
```

R2 に接続せず中身だけ確かめたい場合は `--local-only`（コンテナ内のカレントに gz を出力して終了する）。

## 4. cron で毎日実行

```bash
ssh root@167.172.65.18
crontab -e
# 以下を追記（Rentalist の 18:15 UTC と重ならないよう 30 分ずらす）
45 18 * * * /usr/bin/dokku run income-and-expense python manage.py backup_db >> /var/log/income-and-expense-backup.log 2>&1
```

- cron の時刻は UTC。`45 18` = 翌 03:45 JST。
- 実行ログは `/var/log/income-and-expense-backup.log`。失敗時はここを見る。
- 翌朝 `tail /var/log/income-and-expense-backup.log` と R2 ダッシュボードで 1 件増えていることを確認する。

## 5. 復旧手順

`dokku run` は毎回まっさらなコンテナで動き、ホストのファイルが見えない。
そのため**手元の作業マシンで `DATABASE_URL` を復旧先に向けて実行する**。

1. Cloudflare ダッシュボード → R2 → バケット → `income-and-expense/db-backups/` から最新の `.json.gz` をダウンロードする。
   R2 のトークンを VPS の IP に限定している場合は、手元から `aws s3 cp` などで取ると AccessDenied になる（Rentalist で確認済み）。
2. 復旧先の空 DB を用意する（Neon の新しいブランチなど）。接続は **Direct URL（`-pooler` なし）**を使う。
3. スキーマを作ってから流し込む。`loaddata` は `.json.gz` をそのまま読める（解凍は不要）。

```bash
export DATABASE_URL="postgresql://...（復旧先・Direct URL）...?sslmode=require"
DJANGO_SETTINGS_MODULE=config.settings.production ./django_env/bin/python manage.py migrate --noinput
DJANGO_SETTINGS_MODULE=config.settings.production ./django_env/bin/python manage.py loaddata income-and-expense-XXXX.json.gz
```

4. 件数を確かめたら、Dokku の `DATABASE_URL` を新しい DB に差し替えて `ps:rebuild` する。
5. ダウンロードしたダンプは本番データそのものなので、作業後に削除する。

contenttypes / auth.permission / session / admin ログは `migrate` で再生成されるか不要なため、ダンプから除外している。

## 6. 復元テストの記録

| 日付 | 元データ | 復元先 | 結果 |
| --- | --- | --- | --- |
| 2026-11-12 | ローカル PostgreSQL（2,524 オブジェクト） | 空の SQLite に migrate → loaddata | 全件復元、モデル別件数一致 |

本番のダンプでの復元テストは、cron 稼働後にステージング用の Neon ブランチで実施して追記する。
