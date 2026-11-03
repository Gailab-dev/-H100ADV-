#!/usr/bin/env bash
# 신 서버 H100 검증 (읽기 전용, 기동된 컨테이너에 GET/핸드셰이크만)
# (구 이름: 50-verify.sh — 2026-11-03 파일명 변경, 내용·동작 동일)
# 사용: sudo ./h100-verify.sh [--cutover]   (--cutover: event_scheduler ON 기대)
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"
need_root
CUT=0; [ "${1:-}" = "--cutover" ] && CUT=1
say "== h100-verify $(date '+%F %T') =="

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
summary
