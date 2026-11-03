#!/usr/bin/env bash
# 신 서버 운영 점검 (읽기 전용 — 설정/규칙/파일을 바꾸지 않음)
#   [2] 재부팅 후 자동 복구   [3] 8189 접근 허용 목록   [4] 백업·로그
# 사용: sudo ./65-ops-check.sh
# 비밀값(.env 값, 키, 비밀번호)은 읽지도 출력하지도 않는다. 시리얼·IP·경로·크기만 출력.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"
need_root
say "== 65-ops-check $(date '+%F %T') =="

# ───────────────────────── [2] 재부팅 후 자동 복구 ─────────────────────────
say ""; say "-- [2] 재부팅 후 자동 복구 (실제 재부팅 시험은 점검창에서 1회 별도 수행)"
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

# ───────────────────────── [3] 8189 접근 허용 목록 ─────────────────────────
say ""; say "-- [3] 8189 접근 허용 목록"
iptables -C DOCKER-USER -p tcp -m conntrack --ctorigdstport 8189 --ctdir ORIGINAL -j H100-8189 2>/dev/null \
  && ok "DOCKER-USER → H100-8189 점프 적용 중" || bad "8189 접근제어 체인이 적용돼 있지 않음 (45-fw-docker-user.sh --apply)"
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

# ───────────────────────── [4] 백업 · 로그 ─────────────────────────
say ""; say "-- [4] 백업 · 로그"
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

summary
