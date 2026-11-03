#!/usr/bin/env bash
# 신 서버 쪽 롤백 (구 서버 서비스 재기동은 사람이 직접 — 런북 §6)
# (구 이름: 90-rollback.sh — 2026-11-03 파일명 변경, 내용·동작 동일)
# 사용: sudo ./h100-rollback.sh [--restore-host-service] [--remove-fw] [--purge-db] [--yes]
#   기본: compose 컨테이너 정지(down). 데이터(미디어/DB 볼륨)와 이미지는 보존.
#   --restore-host-service : 9월 시험 설치 systemd h100_module_c 복원
#   --remove-fw            : 45-fw 의 8189 체인 제거
#   --purge-db             : /var/lib/h100/db 를 이름 변경(삭제 아님)하여 DB를 초기 상태로
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"
need_root
HOST=0; FW=0; PURGE=0
while [ $# -gt 0 ]; do case "$1" in
  --restore-host-service) HOST=1; shift;; --remove-fw) FW=1; shift;; --purge-db) PURGE=1; shift;;
  --yes) ASSUME_YES=1; shift;; *) echo "알 수 없는 옵션 $1"; exit 2;; esac; done
confirm "신 서버 H100 컨테이너를 정지합니다 (데이터 보존)." || { say "중단"; exit 1; }
$COMPOSE down >>"$LOG" 2>&1 && ok "compose down (볼륨/이미지 보존)" || bad "compose down 실패"
[ "$FW" -eq 1 ] && { "$(dirname "$(readlink -f "$0")")/45-fw-docker-user.sh" --remove --yes >>"$LOG" 2>&1 && ok "8189 체인 제거" || bad "8189 체인 제거 실패"; }
[ "$HOST" -eq 1 ] && { systemctl enable --now h100_module_c >>"$LOG" 2>&1 && ok "호스트 h100_module_c 복원" || bad "호스트 h100_module_c 복원 실패"; }
if [ "$PURGE" -eq 1 ]; then
  mv /var/lib/h100/db "/var/lib/h100/db.rolledback-$STAMP" && mkdir -p /var/lib/h100/db && ok "DB 데이터를 db.rolledback-$STAMP 로 이동(삭제 아님)" || bad "DB 이동 실패"; fi
say "※ 운영 롤백(구 서버): 정지했던 h100_module_c / tomcat9_jdk17 재기동, 필요 시 IP·포트 원복. 구 서버는 최소 1주 보존."
summary
