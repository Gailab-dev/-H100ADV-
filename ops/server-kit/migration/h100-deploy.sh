#!/usr/bin/env bash
# 컨테이너 준비/기동 (신 서버)
# (구 이름: 40-up.sh — 2026-11-03 파일명 변경, 내용·동작 동일)
# 사용: sudo ./h100-deploy.sh --prepare | --db-only | --module-c | --all [--stop-host-module-c] [--yes]
#   --prepare : h100 그룹/사용자, 디렉터리, 권한 생성 (설정 파일 값은 건드리지 않음)
#   --db-only : h100-db 만 기동 (복원 전 단계)
#   --module-c: db + module-c 만 기동 (web 이미지 없는 리허설용)
#   --all     : db + module-c + web 기동 후 healthy 대기
#   --stop-host-module-c : 9월 시험 설치(systemd h100_module_c, 8189) 정지·비활성(삭제 아님, 파일 보존)
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"
need_root
ACTION=""; STOP_HOST=0
while [ $# -gt 0 ]; do case "$1" in
  --prepare|--db-only|--module-c|--all) ACTION="${1#--}"; shift;; --stop-host-module-c) STOP_HOST=1; shift;;
  --yes) ASSUME_YES=1; shift;; *) echo "알 수 없는 옵션 $1"; exit 2;; esac; done
[ -n "$ACTION" ] || { echo "--prepare|--db-only|--module-c|--all"; exit 2; }

wait_healthy() { # name timeout
  local n=$1 t=$2 i=0
  while [ $i -lt $t ]; do
    s=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$n" 2>/dev/null)
    [ "$s" = healthy ] && return 0; sleep 5; i=$((i+5)); done; return 1; }

# 9월 시험 설치(systemd h100_module_c)가 호스트 8189 를 점유하면 컨테이너 게시가 실패한다
stop_host_module_c() {
  systemctl is-active h100_module_c >/dev/null 2>&1 || return 0
  if [ "$STOP_HOST" -eq 1 ]; then
    confirm "시험 설치 h100_module_c(systemd, 호스트 8189) 를 정지·비활성화" || { say "중단"; exit 1; }
    systemctl stop h100_module_c && systemctl disable h100_module_c && ok "호스트 h100_module_c 정지/비활성 (롤백: systemctl enable --now h100_module_c)" || bad "정지 실패"
  else bad "호스트 h100_module_c 가 8189 점유 중 → --stop-host-module-c"; summary; exit 1; fi
}

case "$ACTION" in
prepare)
  confirm "그룹/사용자/디렉터리 준비 (UID:GID=$H100_UID:$H100_GID)" || { say "중단"; exit 1; }
  getent group "$H100_GID" >/dev/null || groupadd -g "$H100_GID" h100
  id -u "$H100_UID" >/dev/null 2>&1 || useradd -r -u "$H100_UID" -g "$H100_GID" -s /usr/sbin/nologin -M h100
  install -d -m 750 -o root -g "$H100_GID" /etc/h100 /etc/h100/tls
  install -d -m 755 -o "$H100_UID" -g "$H100_GID" "$NEW_MEDIA_DIR" /var/log/h100/module_c /var/log/h100/web
  install -d -m 755 /var/lib/h100/db /opt/h100/docker /opt/h100/migration
  chmod 2775 "$NEW_MEDIA_DIR"
  # DB 데이터 디렉터리: mariadb 이미지 내부 mysql 계정(uid 999)이 소유 → 컨테이너가 최초 기동 시 초기화
  ok "준비 완료 — 이제 /etc/h100/*.env, database.yml, tls/ 를 채우세요 (conf/env-templates.md)"
  # 설정 파일이 있다면 컨테이너가 읽을 수 있게 그룹 권한만 맞춤
  for f in /etc/h100/*.env /etc/h100/database.yml /etc/h100/tls/*; do
    [ -f "$f" ] && { chown root:"$H100_GID" "$f"; chmod 640 "$f"; }; done
  ok "/etc/h100 파일 권한 640 root:h100 정리";;
db-only)
  [ -f "$COMPOSE_DIR/compose.yml" ] || { bad "compose.yml 없음 (10-build-images.sh 먼저)"; summary; exit 1; }
  confirm "h100-db 컨테이너 기동" || { say "중단"; exit 1; }
  $COMPOSE up -d db >>"$LOG" 2>&1 && ok "db 기동 요청" || { bad "db 기동 실패"; summary; exit 1; }
  wait_healthy h100-db 120 && ok "h100-db healthy" || bad "h100-db healthy 대기 초과 (docker logs h100-db)";;
module-c)
  stop_host_module_c
  ss -H -ltnp 'sport = :8189' | grep -v docker-proxy | grep -q . && { bad "호스트 8189 를 다른 프로세스가 점유 중 (ss -ltnp 'sport = :8189')"; summary; exit 1; }
  confirm "db + module-c 기동 (web 제외)" || { say "중단"; exit 1; }
  $COMPOSE up -d db module-c >>"$LOG" 2>&1 && ok "compose up (db, module-c)" || { bad "compose up 실패 (로그 참조)"; summary; exit 1; }
  for c in h100-db h100-module-c; do
    wait_healthy "$c" 120 && ok "$c healthy" || bad "$c healthy 대기 초과 (docker logs $c)"; done
  $COMPOSE ps | tee -a "$LOG";;
all)
  stop_host_module_c
  ss -H -ltnp 'sport = :8300' | grep -v docker-proxy | grep -q . && { bad "호스트 8300 점유(was-9?) → 해제 후 재시도"; summary; exit 1; }
  confirm "db + module-c + web 기동" || { say "중단"; exit 1; }
  $COMPOSE up -d >>"$LOG" 2>&1 && ok "compose up" || { bad "compose up 실패 (로그 참조)"; summary; exit 1; }
  for c in h100-db h100-module-c h100-web; do
    wait_healthy "$c" 180 && ok "$c healthy" || bad "$c healthy 대기 초과 (docker logs $c)"; done
  $COMPOSE ps | tee -a "$LOG";;
esac
summary
