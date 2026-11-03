#!/usr/bin/env bash
# 컷오버 순간에 신 서버 event_scheduler 를 ON (구 서버는 먼저 정지된 상태여야 함: 이중 실행 방지)
# 사용: sudo ./55-event-scheduler.sh --on | --off [--yes]
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"
need_root
V=""
while [ $# -gt 0 ]; do case "$1" in --on) V=ON; shift;; --off) V=OFF; shift;; --yes) ASSUME_YES=1; shift;; *) echo "알 수 없는 옵션 $1"; exit 2;; esac; done
[ -n "$V" ] || { echo "--on|--off"; exit 2; }
if [ "$V" = ON ]; then
  echo "확인: 구 서버(192.168.0.15) 의 H100 서비스가 정지되어 EVENT(2개)가 더 이상 실행되지 않음을 확인했습니까?"
  confirm "event_scheduler=ON 적용" || { say "중단"; exit 1; }
fi
load_db_env || { summary; exit 1; }
dbx -e "SET GLOBAL event_scheduler=$V" && ok "SET GLOBAL event_scheduler=$V" || bad "적용 실패"
# 재기동 후에도 유지되도록 compose .env 갱신 (db 컨테이너 command 가 이 값을 사용)
if grep -q '^H100_EVENT_SCHEDULER=' "$COMPOSE_DIR/.env"; then sed -i "s/^H100_EVENT_SCHEDULER=.*/H100_EVENT_SCHEDULER=$V/" "$COMPOSE_DIR/.env"
else echo "H100_EVENT_SCHEDULER=$V" >> "$COMPOSE_DIR/.env"; fi
ok ".env H100_EVENT_SCHEDULER=$V (다음 db 재생성 시 유지)"
[ "$(dbx -N -e 'SELECT @@event_scheduler')" = "$V" ] && ok "현재 값 $V 확인" || bad "현재 값 불일치"
summary
