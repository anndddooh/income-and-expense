#!/usr/bin/env bash
# VPS（Dokku ホスト）上の 3 アプリの日次 DB バックアップが今日成功したかを確かめ、
# 確認できないアプリがあれば LINE（公式アカウント「サーバー通知」）に知らせる。
#
# 置き場所: /usr/local/bin/backup-check.sh（この控えは income-and-expense リポジトリの tools/）
# 実行: root の crontab で毎日 04:45 JST（45 19 * * * UTC）。各アプリのバックアップより後、
#       cardfolio の相場取得（05:00 JST）より前。
# 設定: /root/.line-notify.env（root のみ読める）に LINE_CHANNEL_ACCESS_TOKEN と LINE_TO_USER_ID。
# 記録: /var/log/backup-check.log
#
# 使い方:
#   backup-check.sh            # 確認して、問題があるときだけ LINE に送る
#   backup-check.sh --dry-run  # 確認だけして結果を表示する（LINE には送らない）
#   backup-check.sh --test     # LINE にテストメッセージを 1 通送る
set -u

ENV_FILE=/root/.line-notify.env
DOKKU=/usr/bin/dokku
# バックアップのファイル名・実行記録は UTC 日付。04:45 JST の時点では同じ UTC 日付になる。
# 動作確認用に BACKUP_CHECK_DATE=YYYY-MM-DD で日付を差し替えられる。
TODAY_ISO=${BACKUP_CHECK_DATE:-$(date -u +%Y-%m-%d)}
TODAY=${TODAY_ISO//-/}

log() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $*"; }

send_line() {
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  local body
  body=$(MSG="$1" TO="$LINE_TO_USER_ID" python3 -c '
import json, os
print(json.dumps({"to": os.environ["TO"], "messages": [{"type": "text", "text": os.environ["MSG"]}]}))
')
  local code
  code=$(curl -sS -o /tmp/backup-check-line.out -w '%{http_code}' \
    -X POST https://api.line.me/v2/bot/message/push \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer ${LINE_CHANNEL_ACCESS_TOKEN}" \
    --data "$body")
  if [ "$code" = "200" ]; then
    log "LINE に送信しました"
  else
    log "LINE への送信に失敗しました (HTTP $code): $(head -c 300 /tmp/backup-check-line.out)"
    return 1
  fi
}

# ログに今日の日付の「R2 にアップロードしました」があるか（root の crontab で動くアプリ用）
check_log() {
  local name=$1 logfile=$2
  if grep -q "R2 にアップロードしました: .*${name}-${TODAY}T" "$logfile" 2>/dev/null; then
    return 0
  fi
  local last
  last=$(grep -o "${name}-[0-9]\{8\}T[0-9]\{6\}Z" "$logfile" 2>/dev/null | tail -n 1)
  echo "${name}: 今日のアップロードがログにありません（最後の成功: ${last:-記録なし}）"
  return 1
}

# cardfolio は Dokku cron で動くので、実行記録（ScheduledJobRun）で確かめる
check_cardfolio() {
  local result
  result=$("$DOKKU" run cardfolio python manage.py dumpdata notifications.scheduledjobrun 2>/dev/null \
    | TODAY_ISO="$TODAY_ISO" python3 -c '
import json, os, sys
text = sys.stdin.read()
try:
    rows = json.loads(text[text.index("["):])
except Exception:
    print("実行記録を読めませんでした"); sys.exit()
runs = [r["fields"] for r in rows
        if r["fields"]["name"] == "backup_db" and r["fields"]["started_at"].startswith(os.environ["TODAY_ISO"])]
if any(f["status"] == "ok" for f in runs):
    print("OK")
elif runs:
    print("今日の実行が「%s」で終わっています" % runs[-1]["status"])
else:
    print("今日の実行記録がありません")
')
  if [ "$result" = "OK" ]; then
    return 0
  fi
  echo "cardfolio: ${result:-実行記録を読めませんでした}"
  return 1
}

main() {
  if [ "${1:-}" = "--test" ]; then
    send_line "【サーバー通知】テストです。DB バックアップの見張りから LINE に届くことを確かめています。"
    return
  fi

  local problems=()
  local msg
  msg=$(check_log rentalist /var/log/rentalist-backup.log) || problems+=("$msg")
  msg=$(check_log income-and-expense /var/log/income-and-expense-backup.log) || problems+=("$msg")
  msg=$(check_cardfolio) || problems+=("$msg")

  if [ ${#problems[@]} -eq 0 ]; then
    log "OK: 3 アプリとも今日のバックアップを確認しました"
    return
  fi

  local text="【サーバー通知】今朝の DB バックアップが確認できないアプリがあります"
  for p in "${problems[@]}"; do
    text+=$'\n'"・$p"
  done
  text+=$'\n'"手順: income-and-expense の docs/db-backup.md"
  log "NG: ${problems[*]}"

  if [ "${1:-}" = "--dry-run" ]; then
    echo "$text"
    return
  fi
  send_line "$text"
}

main "$@"
