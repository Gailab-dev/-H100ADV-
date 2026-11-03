#!/usr/bin/env bash
# 신 서버 H100 검증 (읽기 전용 — 설정/규칙/파일을 바꾸지 않음. 기동된 컨테이너에 GET/핸드셰이크만)
# (구 이름: 50-verify.sh + 65-ops-check.sh 를 이 스크립트로 통합 — 2026-11-03)
# 사용: sudo ./h100-verify.sh [--cutover] [--ops]
#   (옵션 없음) 기동 직후 건강 검증 — 컨테이너·포트·TLS·무서명 거절·web·DB·로그 위생   (h100-update.sh 가 자동 실행)
#   --cutover   event_scheduler ON 을 기대(컷오버 후)
#   --ops       위 검증에 더해 운영 점검 — 재부팅 후 자동 복구, 8189 접근 허용 목록, 백업·로그·디스크
# 비밀값(.env 값, 키, 비밀번호)은 읽지도 출력하지도 않는다. 시리얼·IP·경로·크기만 출력.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"
need_root
CUT=0; OPS=0
while [ $# -gt 0 ]; do case "$1" in --cutover) CUT=1; shift;; --ops) OPS=1; shift;; *) echo "알 수 없는 옵션 $1 (사용법: 파일 머리말)"; exit 2;; esac; done
say "== h100-verify $(date '+%F %T')$([ "$OPS" -eq 1 ] && echo ' (+ops)') =="

# 1. 컨테이너
for c in h100-db h100-module-c h100-web; do
  s=$(timeout 20 docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' $c 2>/dev/null)
  [ "$s" = healthy ] && ok "$c healthy" || bad "$c 상태: ${s:-없음}"
  r=$(timeout 20 docker inspect -f '{{.RestartCount}}' $c 2>/dev/null); [ "${r:-0}" -le 2 ] && ok "$c 재시작 ${r:-0}회" || warn "$c 재시작 ${r}회 (크래시 루프 의심)"
done

# 2. 포트 노출 범위
bind_of() { docker port "$1" "$2" 2>/dev/null | head -1; }
B=$(bind_of h100-module-c 8189/tcp); echo "$B" | grep -q '^0.0.0.0' && ok "module-c 8189 게시: $B (접근제어는 DOCKER-USER)" || bad "module-c 8189 게시 이상: ${B:-없음}"
B=$(bind_of h100-web 8080/tcp);      echo "$B" | grep -q '^127.0.0.1:8300' && ok "web 127.0.0.1:8300 바인딩" || bad "web 바인딩 이상: ${B:-없음}"
B=$(bind_of h100-db 3306/tcp);       echo "$B" | grep -q "^127.0.0.1:$DB_HOST_PORT" && ok "db 127.0.0.1:$DB_HOST_PORT 바인딩" || bad "db 바인딩 이상: ${B:-없음}"
iptables -C DOCKER-USER -p tcp -m conntrack --ctorigdstport 8189 --ctdir ORIGINAL -j H100-8189 2>/dev/null && ok "8189 접근제어 체인 적용됨" || warn "8189 접근제어(45-fw) 미적용 — 현재 LAN 전체에 열려 있음"

# 3. TLS (module-c): h100-ca 체인 + SAN
T=/etc/h100/tls
OUT=$(echo | timeout 8 openssl s_client -connect 127.0.0.1:8189 -CAfile $T/h100-ca.crt -verify_ip "$SERVER_CERT_IP" 2>&1)
echo "$OUT" | grep -q 'Verification: OK\|Verify return code: 0' && ok "module-c TLS: h100-ca 체인 + IP($SERVER_CERT_IP) 검증 OK" || bad "module-c TLS 검증 실패 (SAN/체인 확인)"
echo "$OUT" | grep -Eo 'Protocol *: *TLSv[0-9.]+|New, TLSv[0-9.]+' | head -1 | sed 's/^/[INFO] /' | tee -a "$LOG"

# 4. fail-closed: 서명 없는 요청은 거절되어야 함 (4xx). 200 이면 인증 우회 의심
#    (FileReceive 계열은 HMAC 필수 → 401. 나머지 라우트의 인증 여부는 소스 확인 대상: 런북 §8)
for p in /imageFileReceive /insertEventData; do
  code=$(curl -sk --max-time 8 -o /dev/null -w '%{http_code}' -X POST "https://127.0.0.1:8189$p" -d '{}' -H 'Content-Type: application/json')
  case "$code" in 4??) ok "무서명 POST $p → $code (거절)";; 000) bad "무서명 POST $p 연결 실패";; *) bad "무서명 POST $p → $code (거절이 아님: HMAC 점검)";; esac
done

# 5. Java (Tomcat) 직접/nginx 경유
WPATH="/$WEB_CONTEXT/"; [ "$WEB_CONTEXT" = ROOT ] && WPATH="/"
code=$(curl -s --max-time 10 -o /dev/null -w '%{http_code}' "http://127.0.0.1:8300$WPATH")
case "$code" in 200|302|401|403) ok "web 직접 GET $WPATH → $code";; *) bad "web 직접 GET $WPATH → $code";; esac
code=$(curl -s --max-time 10 -o /dev/null -w '%{http_code}' "http://127.0.0.1:8300/imgFile/")
case "$code" in 200|403|404) ok "web /imgFile Context 응답 → $code (Context 동작 확인용: 앱 404 HTML 아님은 별도 확인)";; *) warn "web /imgFile → $code";; esac
code=$(curl -sk --max-time 10 -o /dev/null -w '%{http_code}' --resolve "x:443:127.0.0.1" "https://$SERVER_CERT_IP/" 2>/dev/null)
case "$code" in 200|302|401|403) ok "nginx 경유(https://$SERVER_CERT_IP/) → $code (upstream was_9→8300)";; *) warn "nginx 경유 응답 $code — upstream/server_name 확인(실제 GET 경로로 재확인)";; esac
timeout 20 docker exec h100-web sh -c 'ls /media >/dev/null && touch /media/output_videos/.w_test && rm -f /media/output_videos/.w_test' 2>/dev/null && ok "web 컨테이너 미디어 읽기/쓰기" || bad "web 컨테이너 미디어 접근 실패 (UID/권한)"
timeout 20 docker exec h100-module-c sh -c 'touch /media/output_images_enc/.w_test && rm -f /media/output_images_enc/.w_test' 2>/dev/null && ok "module-c 미디어 쓰기" || bad "module-c 미디어 쓰기 실패 (UID/권한)"

# 6. DB
load_db_env && {
  for db in $EXPECT_DB_SCHEMAS; do
    n=$(dbx -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$db'" 2>/dev/null); [ "${n:-0}" -gt 0 ] && ok "DB $db 테이블 ${n}개" || bad "DB $db 비어있음"; done
  ev=$(dbx -N -e "SELECT @@event_scheduler"); if [ $CUT -eq 1 ]; then [ "$ev" = ON ] && ok "event_scheduler=ON" || bad "컷오버인데 event_scheduler=$ev"; else [ "$ev" = OFF ] && ok "event_scheduler=OFF(사전 단계)" || warn "event_scheduler=$ev"; fi
  dbx -N -e "SELECT COUNT(*) FROM able_park.tbl_event_data" 2>/dev/null | sed 's/^/[INFO] tbl_event_data 행 수(참고): /' | tee -a "$LOG"
}

# 7. 로그 위생 (B-03: 기동 시 DSN 출력)
timeout 20 docker logs h100-module-c 2>&1 | grep -Eq '@tcp\(' && warn "module-c 로그에 DSN(비밀번호 포함 가능)이 출력됨 — journal/로그 접근 제한, 소스 수정(T2) 대상" || ok "module-c 로그에 DSN 출력 없음"
timeout 20 docker logs h100-module-c 2>&1 | tail -20 | grep -Eiq 'panic|fatal|error' && warn "module-c 최근 로그에 error/fatal 문구 — 확인" || ok "module-c 최근 로그 이상 없음"
timeout 20 docker logs h100-web 2>&1 | grep -Eq 'Server startup in' && ok "Tomcat 기동 완료 로그" || warn "Tomcat 기동 완료 로그 미확인"

if [ "$OPS" -eq 1 ]; then
# ───────────────────────── [ops-1] 재부팅 후 자동 복구 ─────────────────────────
say ""; say "-- [ops-1] 재부팅 후 자동 복구 (실제 재부팅 시험은 점검창에서 1회 별도 수행)"
for u in docker containerd nginx; do
  systemctl is-enabled "$u" >/dev/null 2>&1 && ok "$u 부팅 시 자동 시작" || bad "$u 가 부팅 시 자동 시작이 아님"
done
for c in h100-db h100-module-c h100-web; do
  p=$(docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' "$c" 2>/dev/null)
  case "$p" in unless-stopped|always) ok "$c restart=$p";; *) bad "$c restart 정책: ${p:-컨테이너 없음}";; esac
done

# 8189 방화벽 체인 영구 저장 여부
persist=""
if [ -f /etc/iptables/rules.v4 ] && grep -q 'H100-8189' /etc/iptables/rules.v4; then persist=/etc/iptables/rules.v4; fi
[ -z "$persist" ] && persist=$(grep -rls 'H100-8189' /etc/systemd/system /etc/network /etc/rc.local /usr/local/sbin /usr/local/bin 2>/dev/null | head -1)
if [ -n "$persist" ]; then
  ok "H100-8189 체인 저장 위치: $persist"
else
  warn "H100-8189 체인이 영구 저장돼 있지 않음 — 재부팅하면 8189 접근제어가 사라짐 (netfilter-persistent save 필요)"
fi
if [ "$persist" = /etc/iptables/rules.v4 ]; then
  grep -Eq -- '^-A DOCKER-USER .*-j H100-8189' "$persist" && grep -q '^:H100-8189' "$persist" \
    && ok "저장 규칙에 체인·DOCKER-USER 점프 모두 있음" || warn "저장 규칙에 체인 또는 DOCKER-USER 점프가 빠져 있음"
  systemctl is-enabled netfilter-persistent >/dev/null 2>&1 && ok "netfilter-persistent 부팅 시 복원" || warn "rules.v4 는 있으나 netfilter-persistent 가 활성 아님"
  a=$(iptables-save 2>/dev/null | grep -E 'H100-8189' | sort); b=$(grep -E 'H100-8189' "$persist" | sort)
  [ "$a" = "$b" ] && ok "실행 중 규칙 = 저장 규칙" || warn "실행 중 규칙과 저장 규칙이 다름 — 변경 후 netfilter-persistent save 필요"
fi

# 설정 파일 권한 (값은 읽지 않음)
for f in db.env module-c.env web.env database.yml; do
  p=/etc/h100/$f; [ -f "$p" ] || { warn "$p 없음"; continue; }
  m=$(mode_of "$p"); case "$m" in 600|640|400|440) ok "$p 권한 $m";; *) warn "$p 권한 $m (600/640 권장)";; esac
done
if [ -d /etc/h100/tls ]; then
  k=$(find /etc/h100/tls -type f -name '*key*' -perm /o+r 2>/dev/null | head -3)
  [ -z "$k" ] && ok "TLS 개인키가 other 읽기 불가" || warn "TLS 개인키가 모두에게 읽힘: $k"
fi

# 시간 동기화 (module_d↔module_c HMAC·ROI 요청은 시각 허용오차 ±5분)
[ "$(timedatectl show -p NTPSynchronized --value 2>/dev/null)" = yes ] && ok "시간 동기화(NTP) 정상" || warn "NTP 동기화 아님 — 디바이스 HMAC/ROI 시각 검증에 영향 가능"

# 디스크
for d in / /var/lib/h100 /var/lib/docker /var/log/h100; do
  [ -e "$d" ] || continue
  u=$(df -P "$d" | awk 'NR==2{gsub("%","",$5);print $5}')
  [ "${u:-0}" -lt 80 ] && ok "디스크 $d 사용률 ${u}%" || warn "디스크 $d 사용률 ${u}% (80% 이상)"
done

# ───────────────────────── [ops-2] 8189 접근 허용 목록 ─────────────────────────
say ""; say "-- [ops-2] 8189 접근 허용 목록"
iptables -C DOCKER-USER -p tcp -m conntrack --ctorigdstport 8189 --ctdir ORIGINAL -j H100-8189 2>/dev/null \
  && ok "DOCKER-USER → H100-8189 점프 적용 중" || bad "8189 접근제어 체인이 적용돼 있지 않음 (서버의 45-fw-docker-user.sh --apply)"
iptables -S H100-8189 2>/dev/null | grep -- '-j RETURN' | sed 's/^/[INFO] 현재 허용: /' | tee -a "$LOG"
if [ -f "$DEVICE_ALLOW_FILE" ]; then
  ok "허용 목록 파일 있음: $DEVICE_ALLOW_FILE"
  grep -Ev '^\s*(#|$)' "$DEVICE_ALLOW_FILE" | sed 's/^/[INFO] 목록: /' | tee -a "$LOG"
else
  warn "허용 목록 파일 없음 → 임시로 $DEFAULT_ALLOW_CIDR 전체 허용 중 (운영 디바이스 IP 만 허용하도록 좁혀야 함)"
fi
if load_db_env; then
  info "tbl_device 의 사설 IP 장치 (허용 목록 후보):"
  dbx -t -e "SELECT dv_id, dv_name, dv_ip, dv_serial_number FROM able_park.tbl_device WHERE dv_ip LIKE '10.%' OR dv_ip LIKE '192.168.%' OR dv_ip LIKE '172.%' ORDER BY dv_id" 2>/dev/null | sed 's/^/[INFO] /' | tee -a "$LOG"
fi
python3 - <<'PY' 2>/dev/null | sed 's/^/[INFO] /' | tee -a "$LOG"
import json
try:
    for l in open('/etc/h100/module-c.env'):
        if l.startswith('H100_HMAC_KEYS='):
            v = l.split('=', 1)[1].strip().strip("'\"")
            ks = sorted(json.loads(v).keys())
            print('module-c 에 HMAC 키가 등록된 시리얼 %d개: %s (키 값은 출력하지 않음)' % (len(ks), ks))
except Exception as e:
    print('HMAC 시리얼 목록 확인 실패: %s' % type(e).__name__)
PY
n=$(journalctl -k --since "24 hours ago" 2>/dev/null | grep -c 'H100-8189-DROP')
info "최근 24시간 8189 차단(DROP) 로그: ${n:-0}건"
journalctl -k --since "24 hours ago" 2>/dev/null | grep 'H100-8189-DROP' | grep -o 'SRC=[0-9.]*' | sort | uniq -c | sort -rn | head -5 | sed 's/^/[INFO] 차단 출처 /' | tee -a "$LOG"

# ───────────────────────── [ops-3] 백업 · 로그 ─────────────────────────
say ""; say "-- [ops-3] 백업 · 로그"
f=$(grep -rlsE 'mariadb-dump|mysqldump|h100[-_ ]?backup' /etc/cron.d /etc/cron.daily /etc/cron.weekly /var/spool/cron/crontabs /etc/systemd/system 2>/dev/null | head -3 | tr '\n' ' ')
t=$(systemctl list-timers --all --no-legend 2>/dev/null | grep -iE 'h100|backup|dump' | head -3)
if [ -n "$f$t" ]; then ok "정기 백업 설정 흔적: ${f}${t:+(timer)}"; else warn "정기 DB 백업 설정 없음 (cron/timer 에서 mariadb-dump 를 찾지 못함)"; fi
info "최근 SQL 덤프 파일(최신 5건):"
find /var/backups /opt/h100 /root /home -maxdepth 4 -type f \( -name '*.sql' -o -name '*.sql.gz' -o -name '*.sql.zst' \) -printf '%TY-%Tm-%Td %TH:%TM  %s bytes  %p\n' 2>/dev/null | sort | tail -5 | sed 's/^/[INFO]   /' | tee -a "$LOG"

for c in h100-db h100-module-c h100-web; do
  o=$(docker inspect -f '{{.HostConfig.LogConfig.Type}}{{range $k,$v := .HostConfig.LogConfig.Config}} {{$k}}={{$v}}{{end}}' "$c" 2>/dev/null)
  case "$o" in
    *max-size*) ok "$c 도커 로그 제한: $o";;
    "") warn "$c 로그 설정 확인 불가";;
    *) warn "$c 도커 로그 크기 제한 없음 ($o) — daemon.json 의 log-opts max-size/max-file 권장";;
  esac
done
for d in /var/log/h100/module_c /var/log/h100/web; do
  [ -d "$d" ] || { warn "$d 없음"; continue; }
  info "$d : $(du -sh "$d" 2>/dev/null | cut -f1), 파일 $(find "$d" -type f | wc -l)개, 가장 오래된 $(find "$d" -type f -printf '%TY-%m-%d\n' 2>/dev/null | sort | head -1)"
done
lr=$(grep -ls '/var/log/h100' /etc/logrotate.d/* 2>/dev/null | head -1)
[ -n "$lr" ] && ok "logrotate 설정 있음: $lr" || warn "/var/log/h100 에 대한 logrotate 설정 없음 — 로그가 계속 쌓임"
info "nginx 로그 크기: $(du -sh /var/log/nginx 2>/dev/null | cut -f1)"

if load_db_env; then
  dbx -N -e "SELECT CONCAT(table_schema,' ',ROUND(SUM(data_length+index_length)/1024/1024),' MB') FROM information_schema.tables WHERE table_schema='able_park' GROUP BY table_schema" 2>/dev/null | sed 's/^/[INFO] DB 크기 /' | tee -a "$LOG"
  dbx -N -e "SELECT @@event_scheduler" 2>/dev/null | sed 's/^/[INFO] event_scheduler=/' | tee -a "$LOG"
fi
timeout 90 du -sh /var/lib/h100/media/* 2>/dev/null | sed 's/^/[INFO] 미디어 /' | tee -a "$LOG"
docker system df 2>/dev/null | sed 's/^/[INFO] /' | tee -a "$LOG"
fi
summary
