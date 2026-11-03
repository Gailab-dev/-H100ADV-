#!/usr/bin/env bash
# [구 서버(192.168.0.15)에서 실행] DB 덤프 + 테이블별 행 수 — 읽기 전용(SELECT/덤프만, 서비스 변경 없음)
# 사용: ./old-server-dump.sh [출력디렉터리]   (DB 비밀번호는 대화형 입력, 저장/출력 안 함)
# 주의: MariaDB 10.3 mysqldump 는 --set-gtid-purged 미지원(2026-08-25 확인) → 옵션 사용 안 함
set -uo pipefail
OUT=${1:-$HOME/h100-final-dump}
HOST=127.0.0.1; PORT=3307; DBS="able_park"
mkdir -p "$OUT" && chmod 700 "$OUT"
TS=$(date +%Y%m%d-%H%M%S)

read -r -s -p "DB root 비밀번호: " MYSQL_PWD; echo; export MYSQL_PWD
mysql -h"$HOST" -P"$PORT" -uroot -N -e "SELECT 1" >/dev/null || { echo "[FAIL] DB 접속 실패"; exit 1; }

DUMP="$OUT/h100_dump_$TS.sql.gz"
mysqldump -h"$HOST" -P"$PORT" -uroot --single-transaction --routines --triggers --events \
  --default-character-set=utf8mb4 --databases $DBS | gzip > "$DUMP"
[ "${PIPESTATUS[0]}" -eq 0 ] || { echo "[FAIL] mysqldump 실패"; exit 1; }
echo "[PASS] 덤프 생성: $DUMP ($(du -h "$DUMP" | cut -f1))"

CNT="$OUT/counts_$TS.tsv"; : > "$CNT"
for db in $DBS; do
  mysql -h"$HOST" -P"$PORT" -uroot -N -e \
    "SELECT table_name FROM information_schema.tables WHERE table_schema='$db' AND table_type='BASE TABLE' ORDER BY 1" |
  while read -r t; do
    c=$(mysql -h"$HOST" -P"$PORT" -uroot -N -e "SELECT COUNT(*) FROM \`$db\`.\`$t\`")
    printf '%s\t%s\t%s\n' "$db" "$t" "$c" >> "$CNT"
  done
done
echo "[PASS] 행 수 기록: $CNT ($(wc -l < "$CNT") 테이블)"

( cd "$OUT" && sha256sum "$(basename "$DUMP")" "$(basename "$CNT")" > "SHA256SUMS_$TS" )
mysql -h"$HOST" -P"$PORT" -uroot -N -e "SHOW VARIABLES LIKE 'event_scheduler'" | sed 's/^/[INFO] 구 서버 /'
echo "[INFO] 다음: 신 서버로 전송 → scp $OUT/*_$TS* <신서버>:/root/h100-migration/incoming/"
unset MYSQL_PWD
