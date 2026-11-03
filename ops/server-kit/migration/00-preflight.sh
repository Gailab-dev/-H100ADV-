#!/usr/bin/env bash
# 신 서버 사전 점검 (읽기 전용 — 아무것도 변경하지 않음)
# 사용: sudo ./00-preflight.sh [--war /path/ROOT.war] [--no-old]
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"
need_root

WAR=""; CHECK_OLD=1
while [ $# -gt 0 ]; do case "$1" in
  --war) WAR="$2"; shift 2;; --no-old) CHECK_OLD=0; shift;; *) echo "알 수 없는 옵션 $1"; exit 2;; esac; done

say "== 00-preflight  $(date '+%F %T')  host=$(hostname) =="

# 1. Docker
if docker info >/dev/null 2>&1; then ok "docker 데몬 동작 ($(docker --version | cut -d, -f1))"; else bad "docker 데몬 접근 불가"; fi
if docker compose version >/dev/null 2>&1; then ok "docker compose 사용 가능"; else bad "docker compose 플러그인 없음"; fi

# 2. 디스크 (미디어 9.6GiB ×(사전+최종 여유) + DB + 이미지)
FREE_GB=$(df -BG --output=avail /var/lib 2>/dev/null | tail -1 | tr -dc '0-9')
if [ "${FREE_GB:-0}" -ge 60 ]; then ok "/var/lib 여유 ${FREE_GB}GiB";
elif [ "${FREE_GB:-0}" -ge 30 ]; then warn "/var/lib 여유 ${FREE_GB}GiB (60GiB 이상 권장)"; else bad "/var/lib 여유 ${FREE_GB:-?}GiB (30GiB 미만)"; fi

# 3. UID/GID, 디렉터리
getent group "$H100_GID" >/dev/null && ok "GID $H100_GID 존재" || warn "GID $H100_GID 없음 → h100-deploy.sh --prepare 가 생성"
for d in /opt/h100/docker /etc/h100 /etc/h100/tls "$NEW_MEDIA_DIR" /var/lib/h100/db /var/log/h100/module_c /var/log/h100/web; do
  [ -d "$d" ] && ok "디렉터리 $d" || warn "디렉터리 없음 $d → h100-deploy.sh --prepare 가 생성"
done

# 4. 설정 파일 (값은 출력하지 않음)
chk_file() { # file maxmode
  if [ -f "$1" ]; then m=$(mode_of "$1"); [ "$m" -le "$2" ] && ok "$1 존재 (mode $m)" || bad "$1 권한 과다 (mode $m, 최대 $2)"; else bad "$1 없음"; fi; }
chk_file /etc/h100/db.env 640
chk_file /etc/h100/module-c.env 640
chk_file /etc/h100/database.yml 640
chk_file /etc/h100/web.env 640
[ -f /etc/h100/db.env ] && for k in MARIADB_ROOT_PASSWORD DB_PASS_MODULE_C DB_PASS_WEB; do has_key /etc/h100/db.env $k && ok "db.env: $k 설정됨" || bad "db.env: $k 비어있음"; done
[ -f /etc/h100/module-c.env ] && { has_key /etc/h100/module-c.env H100_HMAC_KEYS && ok "module-c.env: H100_HMAC_KEYS 설정됨 (미설정 시 전체 인증 실패)" || bad "module-c.env: H100_HMAC_KEYS 비어있음"; }
[ -f /etc/h100/web.env ] && for k in H100_DB_URL H100_DB_USER H100_DB_PASSWORD H100_AES_KEY; do has_key /etc/h100/web.env $k && ok "web.env: $k 설정됨" || warn "web.env: $k 비어있음 (T2 외부화 전이면 정상)"; done

# 5. 인증서
T=/etc/h100/tls
if [ -f $T/server.cert.pem ] && [ -f $T/server.key.pem ] && [ -f $T/h100-ca.crt ]; then
  ok "TLS 파일 3종 존재"
  SAN=$(openssl x509 -in $T/server.cert.pem -noout -ext subjectAltName 2>/dev/null | tr -d ' ')
  echo "$SAN" | grep -q "IPAddress:$SERVER_CERT_IP" && ok "인증서 SAN 에 $SERVER_CERT_IP 포함" || bad "인증서 SAN 에 $SERVER_CERT_IP 없음 (B4: IP 인수 시 새 인증서 필요)"
  openssl verify -CAfile $T/h100-ca.crt $T/server.cert.pem >/dev/null 2>&1 && ok "인증서가 h100-ca 로 검증됨" || bad "인증서 체인 검증 실패"
  openssl x509 -in $T/server.cert.pem -noout -checkend $((30*86400)) >/dev/null && ok "인증서 만료까지 30일 이상" || warn "인증서 30일 내 만료"
  A=$(openssl x509 -in $T/server.cert.pem -noout -pubkey 2>/dev/null | sha256sum | cut -c1-16)
  B=$(openssl pkey -in $T/server.key.pem -pubout 2>/dev/null | sha256sum | cut -c1-16)
  [ "$A" = "$B" ] && ok "인증서-개인키 쌍 일치" || bad "인증서-개인키 불일치"
  km=$(mode_of $T/server.key.pem); [ "$km" -le 640 ] && ok "개인키 권한 $km" || bad "개인키 권한 과다 $km (640 이하)"
  find /etc/h100 -name '*ca*key*' -o -name 'rootCA.key' 2>/dev/null | grep -q . && bad "/etc/h100 아래 CA 개인키로 보이는 파일 존재" || ok "/etc/h100 에 CA 개인키 없음"
else bad "TLS 파일 누락 ($T/server.cert.pem, server.key.pem, h100-ca.crt)"; fi

# 6. 포트 충돌 / 현재 점유자
listen_of() { ss -H -ltnp "sport = :$1" 2>/dev/null | awk '{print $4" "$6}' | head -3; }
for p in 8189 8300 "$DB_HOST_PORT"; do
  L=$(listen_of "$p")
  if [ -z "$L" ]; then ok "포트 $p 비어있음"
  elif echo "$L" | grep -q 'docker-proxy'; then info "포트 $p 는 docker 가 사용 중: $L"
  else warn "포트 $p 점유: $L → 배포 전 해제 필요(예: 시험 설치 h100_module_c / was-9)"; fi
done
systemctl is-active h100_module_c >/dev/null 2>&1 && warn "호스트 systemd h100_module_c 동작 중(9월 시험 설치) → 8189 충돌. h100-deploy.sh --stop-host-module-c 로 정지" || ok "호스트 h100_module_c 비활성"
docker ps --format '{{.Names}} {{.Ports}}' 2>/dev/null | grep -E ':(8189|8300|3310)->' | grep -v '^h100-' | grep -q . && bad "다른 컨테이너가 8189/8300/3310 게시 중" || ok "다른 컨테이너와 게시 포트 충돌 없음"

# 7. 방화벽 (Docker 게시 포트는 INPUT 이 아니라 DOCKER-USER 체인)
POL=$(iptables -S INPUT 2>/dev/null | awk '/^-P INPUT/{print $3}')
info "iptables INPUT 기본정책: ${POL:-?}"
iptables -S DOCKER-USER >/dev/null 2>&1 && ok "DOCKER-USER 체인 존재" || warn "DOCKER-USER 체인 없음(docker 기동 후 생성됨)"

# 8. compose 정합성
if [ -f "$COMPOSE_DIR/compose.yml" ] && [ -f "$COMPOSE_DIR/.env" ]; then
  $COMPOSE config -q >>"$LOG" 2>&1 && ok "compose.yml 문법/변수 확인" || bad "compose config 오류 (로그 참조)"
else warn "compose.yml/.env 아직 없음 ($COMPOSE_DIR) → 10-build-images.sh 또는 수동 배치 필요"; fi

# 9. WAR 외부화 게이트 (G0)
if [ -n "$WAR" ]; then
  if [ -f "$WAR" ]; then
    TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
    unzip -qq -o "$WAR" 'WEB-INF/spring/root-context.xml' 'WEB-INF/classes/globals.properties' -d "$TMP" 2>/dev/null
    if grep -Eq '192\.168\.0\.15|/home/dsic' "$TMP"/WEB-INF/spring/root-context.xml "$TMP"/WEB-INF/classes/globals.properties 2>/dev/null; then
      bad "G0: WAR 에 구 서버 값(192.168.0.15 또는 /home/dsic)이 하드코딩됨 → B-01/B-02 외부화(T2) 후 재빌드 필요"
    else ok "G0: WAR 에 구 서버 IP·/home/dsic 하드코딩 없음"; fi
    grep -Eq '\$\{H100_DB_URL' "$TMP"/WEB-INF/spring/root-context.xml 2>/dev/null && ok "G0: DB 접속이 H100_DB_URL 로 외부화됨" || warn "G0: root-context.xml 에서 \${H100_DB_URL} 미확인"
  else bad "WAR 파일 없음: $WAR"; fi
else info "WAR 게이트(G0) 생략 (--war 미지정)"; fi

# 10. 구 서버 접근 (읽기 전용 확인만)
if [ "$CHECK_OLD" -eq 1 ]; then
  if timeout 6 bash -c "exec 3<>/dev/tcp/$OLD_HOST/$OLD_SSH_PORT" 2>/dev/null; then ok "구 서버 $OLD_HOST:$OLD_SSH_PORT TCP 연결 가능"; else warn "구 서버 SSH 포트 연결 불가"; fi
  command -v rsync >/dev/null && ok "rsync 설치됨" || bad "rsync 없음 (apt install rsync)"
fi

summary
