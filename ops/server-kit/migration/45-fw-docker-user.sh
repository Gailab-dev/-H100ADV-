#!/usr/bin/env bash
# 8189 접근제어 — Docker 게시 포트는 INPUT 이 아닌 DOCKER-USER/FORWARD 에서 제어된다.
# (호스트 iptables INPUT DROP 에 "8189 허용"을 넣어도 컨테이너 게시 포트에는 영향 없음)
# 사용: sudo ./45-fw-docker-user.sh --check | --apply [--yes] | --remove [--yes]
# 허용 목록: $DEVICE_ALLOW_FILE (줄당 IP/CIDR). 없으면 $DEFAULT_ALLOW_CIDR 임시 허용(WARN).
# 기존 규칙은 지우지 않음: 전용 체인 H100-8189 만 만들고 DOCKER-USER 맨 앞에서 점프.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"
need_root
ACTION=""
while [ $# -gt 0 ]; do case "$1" in
  --check|--apply|--remove) ACTION="${1#--}"; shift;; --yes) ASSUME_YES=1; shift;; *) echo "알 수 없는 옵션 $1"; exit 2;; esac; done
[ -n "$ACTION" ] || { echo "--check|--apply|--remove"; exit 2; }
CH=H100-8189
JUMP=(-p tcp -m conntrack --ctorigdstport 8189 --ctdir ORIGINAL -j "$CH")

allow_list() {
  if [ -f "$DEVICE_ALLOW_FILE" ]; then grep -Ev '^\s*(#|$)' "$DEVICE_ALLOW_FILE"; else echo "$DEFAULT_ALLOW_CIDR"; fi; }

case "$ACTION" in
check)
  iptables -S DOCKER-USER >/dev/null 2>&1 && ok "DOCKER-USER 존재" || bad "DOCKER-USER 없음"
  iptables -C DOCKER-USER "${JUMP[@]}" 2>/dev/null && ok "DOCKER-USER → $CH 점프 설치됨" || warn "$CH 점프 미설치"
  iptables -S $CH 2>/dev/null | sed 's/^/[INFO] /' | tee -a "$LOG"
  [ -f "$DEVICE_ALLOW_FILE" ] && ok "허용 목록 파일 사용: $DEVICE_ALLOW_FILE" || warn "허용 목록 파일 없음 → 임시로 $DEFAULT_ALLOW_CIDR 사용 (§6-④ 디바이스 IP 미확보)";;
apply)
  confirm "DOCKER-USER 에 $CH 체인(8189 허용 목록 → 그 외 DROP) 적용" || { say "중단"; exit 1; }
  [ -f "$DEVICE_ALLOW_FILE" ] || warn "허용 목록 파일 없음 → $DEFAULT_ALLOW_CIDR 임시 허용"
  iptables -S DOCKER-USER >/dev/null 2>&1 || { bad "DOCKER-USER 없음 (docker 기동 후 재시도)"; summary; exit 1; }
  iptables -t filter -S > "$WORK/iptables-before.rules"; ok "적용 전 규칙 저장 $WORK/iptables-before.rules"
  iptables -N $CH 2>/dev/null; iptables -F $CH
  iptables -A $CH -s 127.0.0.0/8 -j RETURN
  iptables -A $CH -s 172.16.0.0/12 -j RETURN          # 컨테이너 네트워크 내부
  while read -r src; do [ -n "$src" ] && iptables -A $CH -s "$src" -j RETURN && info "허용 $src"; done < <(allow_list)
  iptables -A $CH -m limit --limit 5/min -j LOG --log-prefix "H100-8189-DROP " 2>/dev/null
  iptables -A $CH -j DROP
  iptables -C DOCKER-USER "${JUMP[@]}" 2>/dev/null || iptables -I DOCKER-USER 1 "${JUMP[@]}"
  iptables -C DOCKER-USER "${JUMP[@]}" 2>/dev/null && ok "점프 설치" || bad "점프 설치 실패"
  if command -v netfilter-persistent >/dev/null; then netfilter-persistent save >>"$LOG" 2>&1 && ok "영구 저장(netfilter-persistent)" || warn "영구 저장 실패"
  else warn "영구 저장 수단 미확인 — 기존 7.5절 방식(iptables-save)으로 저장 필요. 재부팅 시 사라질 수 있음"; fi
  say "롤백: $0 --remove  (또는 iptables-restore 로 $WORK/iptables-before.rules 참고)";;
remove)
  confirm "$CH 점프/체인 제거" || { say "중단"; exit 1; }
  while iptables -C DOCKER-USER "${JUMP[@]}" 2>/dev/null; do iptables -D DOCKER-USER "${JUMP[@]}"; done
  iptables -F $CH 2>/dev/null; iptables -X $CH 2>/dev/null
  iptables -S $CH >/dev/null 2>&1 && bad "체인 제거 실패" || ok "$CH 제거";;
esac
summary
