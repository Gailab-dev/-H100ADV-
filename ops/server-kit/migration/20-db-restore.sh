#!/usr/bin/env bash
# DB 복원 + 앱 계정 생성 + 행 수 대조 (신 서버, h100-db 컨테이너 기동 후)
# 사용: sudo ./20-db-restore.sh --dump FILE.sql.gz --counts counts_*.tsv --mode rehearsal|final [--replace] [--yes]
#  rehearsal: 운영 중 덤프라 행 수 차이는 WARN (사전 리허설)
#  final    : 구 서비스 정지 후 덤프. 행 수 불일치는 FAIL
# 안전: 기존 데이터가 있으면 --replace 없이는 중단, --replace 시 교체 전 현재 DB를 $WORK 에 백업
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"
need_root
DUMP=""; COUNTS=""; MODE=""; REPLACE=0
while [ $# -gt 0 ]; do case "$1" in
  --dump) DUMP="$2"; shift 2;; --counts) COUNTS="$2"; shift 2;; --mode) MODE="$2"; shift 2;;
  --replace) REPLACE=1; shift;; --yes) ASSUME_YES=1; shift;; *) echo "알 수 없는 옵션 $1"; exit 2;; esac; done
[ -f "$DUMP" ] && [ -f "$COUNTS" ] && { [ "$MODE" = rehearsal ] || [ "$MODE" = final ]; } || { echo "옵션 확인: --dump --counts --mode"; exit 2; }

# 무결성: SHA256SUMS 가 같은 폴더에 있으면 검증
SUMS=$(ls "$(dirname "$DUMP")"/SHA256SUMS_* 2>/dev/null | head -1)
if [ -n "$SUMS" ]; then ( cd "$(dirname "$DUMP")" && sha256sum -c --ignore-missing "$SUMS" >/dev/null 2>&1 ) && ok "덤프 SHA256 검증" || { bad "덤프 SHA256 불일치"; summary; exit 1; }
else warn "SHA256SUMS 파일 없음 — 전송 무결성 미검증"; fi

load_db_env || { summary; exit 1; }
docker inspect -f '{{.State.Health.Status}}' h100-db 2>/dev/null | grep -q healthy && ok "h100-db healthy" || { bad "h100-db 가 healthy 가 아님 (h100-deploy.sh --db-only 먼저)"; summary; exit 1; }

# 기존 데이터 확인
for db in $EXPECT_DB_SCHEMAS; do
  n=$(dbx -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$db'" 2>/dev/null)
  if [ "${n:-0}" -gt 0 ]; then
    [ "$REPLACE" -eq 1 ] || { bad "$db 에 이미 테이블 ${n}개 존재 → --replace 필요"; summary; exit 1; }
    BK="$WORK/pre-replace-$db.sql.gz"
    docker exec -e MYSQL_PWD h100-db mariadb-dump -uroot --single-transaction --routines --triggers --events --databases "$db" | gzip > "$BK" \
      && ok "교체 전 백업 $BK" || { bad "교체 전 백업 실패"; summary; exit 1; }
  fi
done
confirm "DB 복원 ($MODE): 기존 $EXPECT_DB_SCHEMAS 를 덮어씁니다." || { say "중단"; exit 1; }

# 복원: DEFINER 를 root@localhost 로 치환 (이벤트 2개의 DEFINER 가 root@% 였음)
for db in $EXPECT_DB_SCHEMAS; do dbx -e "DROP DATABASE IF EXISTS \`$db\`; CREATE DATABASE \`$db\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" || { bad "DB $db 생성 실패"; summary; exit 1; }; done
zcat "$DUMP" | sed -E 's/DEFINER=`[^`]+`@`[^`]+`/DEFINER=`root`@`localhost`/g' | dbx >>"$LOG" 2>&1 \
  && ok "덤프 복원 완료" || { bad "복원 실패 (로그 참조)"; summary; exit 1; }

# 앱 계정 (컨테이너 네트워크 172.31.100.% 에서만 접속). 비밀번호는 stdin 으로만 전달
dbx >>"$LOG" 2>&1 <<SQL && ok "앱 계정 생성/권한 부여 (h100_module_c, h100_web)" || bad "계정 생성 실패"
CREATE USER IF NOT EXISTS 'h100_module_c'@'172.31.100.%' IDENTIFIED BY '${DB_PASS_MODULE_C}';
ALTER USER 'h100_module_c'@'172.31.100.%' IDENTIFIED BY '${DB_PASS_MODULE_C}';
GRANT SELECT,INSERT,UPDATE,DELETE ON able_park.* TO 'h100_module_c'@'172.31.100.%';
CREATE USER IF NOT EXISTS 'h100_web'@'172.31.100.%' IDENTIFIED BY '${DB_PASS_WEB}';
ALTER USER 'h100_web'@'172.31.100.%' IDENTIFIED BY '${DB_PASS_WEB}';
GRANT SELECT,INSERT,UPDATE,DELETE ON able_park.* TO 'h100_web'@'172.31.100.%';
FLUSH PRIVILEGES;
SQL
dbx -N -e "SELECT user,host FROM mysql.user WHERE user LIKE 'h100_%'" | sed 's/^/[INFO] /' | tee -a "$LOG"
dbx -N -e "SELECT COUNT(*) FROM mysql.user WHERE user='root' AND host='%'" | grep -q '^0$' && ok "root@% 계정 없음" || warn "root@% 계정 존재 — 제거 검토 (R3)"

# 행 수 대조
# 주의: dbx 는 docker exec -i 라 stdin 을 먹는다 → 목록은 fd 3 으로 읽고 dbx 에는 </dev/null 을 준다
EXP=$(grep -c . "$COUNTS")
MISS=0; DIFF=0; TOT=0
while IFS=$'\t' read -r -u 3 db t c; do
  [ -z "$db" ] && continue
  TOT=$((TOT+1))
  n=$(dbx -N -e "SELECT COUNT(*) FROM \`$db\`.\`$t\`" 2>/dev/null </dev/null)
  if [ -z "$n" ]; then MISS=$((MISS+1)); say "  누락 테이블 $db.$t"
  elif [ "$n" != "$c" ]; then DIFF=$((DIFF+1)); say "  행 수 차이 $db.$t 구=$c 신=$n"; fi
done 3< "$COUNTS"
[ "$TOT" -eq "$EXP" ] && ok "대조 대상 ${TOT}개 전부 검사 (counts 파일 ${EXP}줄)" || bad "검사 ${TOT}개 ≠ counts 파일 ${EXP}줄 (검증 루프 이상)"
[ "$MISS" -eq 0 ] && ok "테이블 ${TOT}개 모두 존재" || bad "누락 테이블 ${MISS}개"
if [ "$DIFF" -eq 0 ]; then ok "행 수 전부 일치"
elif [ "$MODE" = rehearsal ]; then warn "행 수 차이 ${DIFF}개 (리허설: 운영 중 덤프라 예상됨, 최종에서는 0이어야 함)"
else bad "행 수 불일치 ${DIFF}개 (final)"; fi

# 이벤트: 복원 후 스케줄러 OFF 유지, 이벤트 정의 확인
dbx -N -e "SELECT COUNT(*) FROM information_schema.events WHERE event_schema IN ('able_park')" | sed 's/^/[INFO] 복원된 EVENT 수: /' | tee -a "$LOG"
dbx -N -e "SELECT @@event_scheduler" | grep -qx 'OFF' && ok "event_scheduler=OFF (컷오버 시점에 ON)" || warn "event_scheduler 가 OFF 가 아님 — 구/신 동시 실행 주의"
summary
