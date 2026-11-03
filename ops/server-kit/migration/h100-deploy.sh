#!/usr/bin/env bash
# 컨테이너 준비·기동·정지 (신 서버/개발서버). 이미지를 빌드하지는 않는다 → 빌드는 h100-update.sh
# (구 이름: 40-up.sh + h100-rollback.sh 를 이 스크립트로 통합 — 2026-11-03)
# 사용: sudo ./h100-deploy.sh --prepare | --db-only | --module-c | --all [--stop-host-module-c] [--yes]
#       sudo ./h100-deploy.sh --stop [--restore-host-service] [--remove-fw] [--purge-db] [--yes]
#   --prepare : h100 그룹/사용자, 디렉터리, 권한 생성 (설정 파일 값은 건드리지 않음)
#   --db-only : h100-db 만 기동 (복원 전 단계)
#   --module-c: db + module-c 만 기동 (web 이미지 없는 리허설용)
#   --all     : db + module-c + web 기동 후 healthy 대기 (현재 .env 의 H100_TAG 이미지로 교체)
#   --stop-host-module-c : 9월 시험 설치(systemd h100_module_c, 8189) 정지·비활성(삭제 아님, 파일 보존)
#   --stop    : compose 컨테이너 정지(down). 데이터(미디어/DB 볼륨)와 이미지는 보존.
#               ※ 이미지 태그를 이전 버전으로 되돌리는 것은 --stop 이 아니라 h100-update.sh --rollback-to
#     --restore-host-service : 9월 시험 설치 systemd h100_module_c 복원
#     --remove-fw            : 8189 접근제어 체인 제거(서버의 45-fw-docker-user.sh 필요)
#     --purge-db             : /var/lib/h100/db 를 이름 변경(삭제 아님)하여 DB를 초기 상태로
#   ※ 구 서버(운영) 서비스 재기동은 사람이 직접 한다(런북 §6).
set -uo pipefail
HERE=$(dirname "$(readlink -f "$0")")
. "$HERE/lib.sh"
need_root
ACTION=""; STOP_HOST=0; HOST=0; FW=0; PURGE=0
while [ $# -gt 0 ]; do case "$1" in
  --prepare|--db-only|--module-c|--all|--stop) ACTION="${1#--}"; shift;;
  --stop-host-module-c) STOP_HOST=1; shift;;
  --restore-host-service) HOST=1; shift;; --remove-fw) FW=1; shift;; --purge-db) PURGE=1; shift;;
  --yes) ASSUME_YES=1; shift;; *) echo "알 수 없는 옵션 $1"; exit 2;; esac; done
[ -n "$ACTION" ] || { echo "--prepare|--db-only|--module-c|--all|--stop  (자세한 사용법: 파일 머리말)"; exit 2; }
if [ "$ACTION" != stop ] && [ $((HOST + FW + PURGE)) -gt 0 ]; then
  echo "--restore-host-service / --remove-fw / --purge-db 는 --stop 과 함께만 사용"; exit 2; fi

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
    systemctl stop h100_module_c && systemctl disable h100_module_c && ok "호스트 h100_module_c 정지/비활성 (복원: h100-deploy.sh --stop --restore-host-service)" || bad "정지 실패"
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
  ok "준비 완료 — 이제 /etc/h100/*.env, database.yml, tls/ 를 채우세요 (conf/env-templates.md, web.env 는 h100-web-env.sh)"
  # 설정 파일이 있다면 컨테이너가 읽을 수 있게 그룹 권한만 맞춤
  for f in /etc/h100/*.env /etc/h100/database.yml /etc/h100/tls/*; do
    [ -f "$f" ] && { chown root:"$H100_GID" "$f"; chmod 640 "$f"; }; done
  ok "/etc/h100 파일 권한 640 root:h100 정리";;
db-only)
  [ -f "$COMPOSE_DIR/compose.yml" ] || { bad "compose.yml 없음 (h100-update.sh --war … --build-only 먼저)"; summary; exit 1; }
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
stop)
  confirm "H100 컨테이너를 정지합니다 (데이터·이미지 보존)." || { say "중단"; exit 1; }
  $COMPOSE down >>"$LOG" 2>&1 && ok "compose down (볼륨/이미지 보존)" || bad "compose down 실패 (로그 참조)"
  if [ "$FW" -eq 1 ]; then
    if [ -f "$HERE/45-fw-docker-user.sh" ]; then
      bash "$HERE/45-fw-docker-user.sh" --remove --yes >>"$LOG" 2>&1 && ok "8189 체인 제거" || bad "8189 체인 제거 실패"
    else warn "45-fw-docker-user.sh 가 이 폴더에 없음 → 8189 체인은 직접 제거 (iptables -D DOCKER-USER … / 서버의 이관용 스크립트 사용)"; fi
  fi
  if [ "$HOST" -eq 1 ]; then
    systemctl enable --now h100_module_c >>"$LOG" 2>&1 && ok "호스트 h100_module_c 복원" || bad "호스트 h100_module_c 복원 실패"; fi
  if [ "$PURGE" -eq 1 ]; then
    mv /var/lib/h100/db "/var/lib/h100/db.rolledback-$STAMP" && mkdir -p /var/lib/h100/db && ok "DB 데이터를 db.rolledback-$STAMP 로 이동(삭제 아님)" || bad "DB 이동 실패"; fi
  say "※ 운영 롤백(구 서버): 정지했던 h100_module_c / tomcat9_jdk17 재기동, 필요 시 IP·포트 원복. 구 서버는 최소 1주 보존.";;
esac
summary
