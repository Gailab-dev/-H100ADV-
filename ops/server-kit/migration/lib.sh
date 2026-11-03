#!/usr/bin/env bash
# 공통 함수. 각 h100-*.sh 가 source 한다. 단독 실행 금지. (이름 유지: 서버에 남은 이관용 스크립트도 이 파일을 사용)
# 원칙: 구 서버(운영)는 읽기 전용 / 비밀값은 출력·로그에 남기지 않음 / PASS·FAIL 결과 파일 / 위험 단계는 --yes 필요

MIG_DIR=${MIG_DIR:-/opt/h100/migration}
# shellcheck disable=SC1091
[ -f "$MIG_DIR/migration.conf" ] && . "$MIG_DIR/migration.conf"

: "${OLD_HOST:=192.168.0.15}" "${OLD_USER:=dsic}" "${OLD_SSH_PORT:=22}"
: "${OLD_MEDIA_DIR:=/home/dsic/Desktop/H100_system}" "${NEW_MEDIA_DIR:=/var/lib/h100/media}"
: "${H100_UID:=3100}" "${H100_GID:=3100}" "${SERVER_CERT_IP:=192.168.0.115}"
: "${WEB_CONTEXT:=gov-disabled-web-adv}"   # Tomcat 컨텍스트 경로(구 서버와 동일). ROOT 로 배포하려면 migration.conf 에 WEB_CONTEXT=ROOT
: "${DB_HOST_PORT:=3310}" "${EXPECT_DB_SCHEMAS:=able_park}"
: "${DEVICE_ALLOW_FILE:=/etc/h100/device-allow.list}" "${DEFAULT_ALLOW_CIDR:=192.168.0.0/24}"
COMPOSE_DIR=${COMPOSE_DIR:-/opt/h100/docker}
COMPOSE="docker compose -f $COMPOSE_DIR/compose.yml --env-file $COMPOSE_DIR/.env"

STAMP=${STAMP:-$(date +%Y%m%d-%H%M%S)}
WORK=${WORK:-/root/h100-migration/$STAMP}
mkdir -p "$WORK" && chmod 700 "$WORK"
SCRIPT_NAME=$(basename "${0:-script}" .sh)
LOG="$WORK/$SCRIPT_NAME.log"
RESULT="$WORK/RESULT_$SCRIPT_NAME.txt"
: > "$RESULT"
N_PASS=0; N_FAIL=0; N_WARN=0
ASSUME_YES=0

say()  { printf '%s\n' "$*" | tee -a "$LOG"; }
ok()   { printf '[PASS] %s\n' "$*" | tee -a "$LOG" "$RESULT"; N_PASS=$((N_PASS+1)); }
bad()  { printf '[FAIL] %s\n' "$*" | tee -a "$LOG" "$RESULT"; N_FAIL=$((N_FAIL+1)); }
warn() { printf '[WARN] %s\n' "$*" | tee -a "$LOG" "$RESULT"; N_WARN=$((N_WARN+1)); }
info() { printf '[INFO] %s\n' "$*" | tee -a "$LOG"; }

need_root() { [ "$(id -u)" -eq 0 ] || { echo "root 로 실행하세요 (sudo)"; exit 2; }; }
need_val() { [ "$1" -ge 2 ] || { echo "옵션 값이 없습니다"; exit 2; }; }   # 값이 필요한 옵션: need_val $# 후 shift 2 (값 누락 시 무한 루프 방지)

confirm() {  # confirm "설명"  → --yes 이거나 대화형 yes 입력일 때만 진행
  [ "$ASSUME_YES" -eq 1 ] && return 0
  [ -t 0 ] || { echo "비대화형 실행: --yes 필요"; return 1; }
  read -r -p "$1  진행하려면 yes 입력: " a; [ "$a" = "yes" ]
}

summary() {
  say "----------------------------------------------"
  say "PASS=$N_PASS  FAIL=$N_FAIL  WARN=$N_WARN   (로그: $LOG)"
  if [ "$N_FAIL" -eq 0 ]; then echo "OVERALL: PASS" | tee -a "$LOG" "$RESULT"; return 0
  else echo "OVERALL: FAIL" | tee -a "$LOG" "$RESULT"; return 1; fi
}

mode_of() { stat -c '%a' "$1" 2>/dev/null; }

# 비밀값 키 존재 확인 (값은 출력하지 않음): has_key FILE KEY
has_key() { grep -Eq "^[[:space:]]*$2[[:space:]]*=[[:space:]]*[^[:space:]]" "$1" 2>/dev/null; }

# DB 루트 비밀번호 로드 (환경변수로만 전달, 명령행에 값 노출 없음)
load_db_env() {
  [ -f /etc/h100/db.env ] || { bad "/etc/h100/db.env 없음"; return 1; }
  set -a; # shellcheck disable=SC1091
  . /etc/h100/db.env; set +a
  export MYSQL_PWD="$MARIADB_ROOT_PASSWORD"
}
dbx() { docker exec -i -e MYSQL_PWD h100-db mariadb -uroot "$@"; }
