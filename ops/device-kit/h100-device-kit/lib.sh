#!/usr/bin/env bash
# H100 엣지 키트 공통 함수 — 직접 실행하지 않고 각 스크립트가 source 합니다. (경로·이름은 수정하지 말고 h100-device.conf 에서 바꾸세요)
# 비밀값(.env 값, 개인키, HMAC 키, RTSP 계정)은 화면·로그에 출력하지 않습니다.

PASS=0; FAIL=0; WARN=0
ASSUME_YES=${ASSUME_YES:-0}
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
rt() { $SUDO "$@"; }                       # root 권한으로 실행 (이미 root 면 그대로)

# ---------- 출력 · 기록 ----------
init_log() {
  mkdir -p "$LOG_DIR" 2>/dev/null && chmod 700 "$KIT_STATE_DIR" "$LOG_DIR" 2>/dev/null
  LOG="$LOG_DIR/$1-$(date +%Y%m%d-%H%M%S).log"; : > "$LOG"
}
say()  { printf '%s\n' "$*" | tee -a "${LOG:-/dev/null}"; }
ok()   { PASS=$((PASS+1)); say "[ OK ] $*"; }
bad()  { FAIL=$((FAIL+1)); say "[FAIL] $*"; }
warn() { WARN=$((WARN+1)); say "[WARN] $*"; }
info() { say "[INFO] $*"; }
die()  { say "[중단] $*"; exit 1; }
summary() { say ""; say "결과: OK=$PASS  경고=$WARN  실패=$FAIL   (기록: ${LOG:-없음})"; }
confirm() {
  [ "$ASSUME_YES" = 1 ] && return 0
  local a; read -r -p "$1 (yes 입력) " a; [ "$a" = yes ]
}

# ---------- 설정 로드 ----------
load_conf() {
  CONF="${H100_CONF:-$KIT_DIR/h100-device.conf}"
  [ -f "$CONF" ] || { echo "설정 파일이 없습니다: $CONF"; exit 1; }
  # shellcheck disable=SC1090
  . "$CONF"
  PAYLOAD_DIR="${PAYLOAD_DIR:-$KIT_DIR/payload}"
  BIN="$MODULE_D_DIR/$BIN_NAME"; ENVF="$MODULE_D_DIR/.env"
  if [ -z "${DEVICE_SERIAL:-}" ] && [ -r /proc/device-tree/serial-number ]; then
    DEVICE_SERIAL=$(tr -d '\0\n\r ' < /proc/device-tree/serial-number)
  fi
  CRT_NAME="device-${DEVICE_SERIAL}.crt"; KEY_NAME="device-${DEVICE_SERIAL}.key"
  CRT="$SSL_DIR/$CRT_NAME"; KEY="$SSL_DIR/$KEY_NAME"; CA="$SSL_DIR/$CA_CERT_NAME"
  # 이미지/영상 폴더명은 module_d 소스에 고정 — 설정이 어긋나면 막는다
  [ "$IMAGE_DIR" = "$OUTPUT_DIR/image" ] && [ "$VIDEO_DIR" = "$OUTPUT_DIR/video" ] \
    || die "h100-device.conf: IMAGE_DIR/VIDEO_DIR 는 OUTPUT_DIR/image, OUTPUT_DIR/video 여야 합니다 (module_d 소스에 고정된 이름)"
  [ -n "$DEVICE_SERIAL" ] || die "장비 시리얼을 알 수 없습니다. h100-device.conf 의 DEVICE_SERIAL 을 채우세요."
  printf '%s' "$DEVICE_SERIAL" | grep -Eq '^[0-9]{6,20}$' || die "DEVICE_SERIAL 형식 이상(숫자만 6~20자): 설정 파일 확인"
}

# ---------- 파일 · 해시 ----------
sha() { rt sha256sum "$1" 2>/dev/null | cut -d' ' -f1; }
fmode() { rt stat -c '%a' "$1" 2>/dev/null; }
fowner() { rt stat -c '%U:%G' "$1" 2>/dev/null; }

# ---------- .env 읽기·쓰기 (값은 출력하지 않음) ----------
envval() {   # envval KEY  → 값 (따옴표 제거). 파일이 없으면 빈 값
  local v; v=$(rt cat "$ENVF" 2>/dev/null | grep -E "^[[:space:]]*$1=" | tail -1 | cut -d= -f2-)
  v=${v%\"}; v=${v#\"}; v=${v%\'}; v=${v#\'}; printf '%s' "$v"
}
env_quote() {  # 값을 .env 에 쓸 형태로. 안전한 문자만이면 그대로, 아니면 작은따옴표(변수 치환 없음)
  case "$1" in *\'*|*$'\n'*|*$'\r'*) return 1;; esac
  if printf '%s' "$1" | grep -Eq '^[A-Za-z0-9_./:@%+=,-]+$'; then printf '%s' "$1"; else printf "'%s'" "$1"; fi
}
env_set_file() {  # env_set_file 파일 KEY VALUE  — 해당 키 줄만 교체(없으면 추가), 나머지 줄은 그대로
  local f="$1" k="$2" v q tmp; v="$3"
  q=$(env_quote "$v") || die ".env 에 쓸 수 없는 문자(작은따옴표·줄바꿈)가 $k 값에 있습니다"
  tmp=$(mktemp)
  K="$k" Q="$q" awk 'BEGIN{k=ENVIRON["K"];q=ENVIRON["Q"];d=0}
     $0 ~ "^[[:space:]]*" k "=" { if(!d){print k "=" q; d=1}; next } {print}
     END{ if(!d) print k "=" q }' "$f" > "$tmp" && cat "$tmp" > "$f"
  rm -f "$tmp"
}

# ---------- 백업 · 복구 ----------
backup_open() {   # backup_open 태그 → $BK
  mkdir -p "$BACKUP_DIR" && chmod 700 "$KIT_STATE_DIR" "$BACKUP_DIR" 2>/dev/null
  BK="$BACKUP_DIR/$(date +%Y%m%d-%H%M%S)-$1"; mkdir -p "$BK" && chmod 700 "$BK"; : > "$BK/files.map"
}
backup_file() {   # backup_file 원본경로  — 내용·소유·권한을 files.map 에 기록
  local src="$1" name
  [ -e "$src" ] || return 0
  name="$(printf '%s' "$src" | sha256sum | cut -c1-8)_$(basename "$src")"
  rt cp -p "$src" "$BK/$name" && rt chown "$(id -un)" "$BK/$name" && chmod 600 "$BK/$name" || return 1
  printf '%s|%s|%s|%s\n' "$name" "$src" "$(fowner "$src")" "$(fmode "$src")" >> "$BK/files.map"
}
backup_restore() {  # backup_restore 백업폴더 — 기록된 파일을 원래 위치·소유·권한으로 되돌림
  local dir="$1" name orig og mode rc=0
  [ -f "$dir/files.map" ] || { bad "files.map 없음: $dir"; return 1; }
  while IFS='|' read -r name orig og mode; do
    [ -n "$name" ] || continue
    rt install -o "${og%%:*}" -g "${og##*:}" -m "$mode" "$dir/$name" "$orig.rst.tmp" && rt mv -f "$orig.rst.tmp" "$orig" \
      && ok "복원: $orig" || { bad "복원 실패: $orig"; rc=1; }
  done < "$dir/files.map"
  return $rc
}
backup_prune() {
  local n=0 d
  [ -d "$BACKUP_DIR" ] || return 0
  while IFS= read -r d; do
    n=$((n+1)); [ $n -le "$KEEP_BACKUPS" ] && continue
    case "$d" in "$BACKUP_DIR"/*) rm -rf --one-file-system -- "$d" && info "오래된 백업 삭제: $(basename "$d")";; esac
  done < <(ls -1dt "$BACKUP_DIR"/*/ 2>/dev/null | sed 's#/$##')
}
latest_backup() { ls -1dt "$BACKUP_DIR"/*/ 2>/dev/null | head -1 | sed 's#/$##'; }

# ---------- 상태 기록 (.env · ssl 해시) ----------
state_snapshot() {   # 현재 .env 와 ssl/* 의 해시 (전·후 비교용). 인자 "noenv" 면 .env 제외
  { [ "${1:-}" != noenv ] && [ -f "$ENVF" ] && echo ".env $(sha "$ENVF")"
    for f in "$SSL_DIR"/*; do [ -f "$f" ] && echo "ssl/$(basename "$f") $(sha "$f")"; done
  } | sort
}
baseline_compare() {   # 저장해 둔 인증서 해시 목록과 현재 파일 비교 (파일명 기준)
  local n=0 nb=0 h f cur
  [ -f "$SSL_BASELINE" ] || { warn "인증서 기준 해시 목록 없음: $SSL_BASELINE (비교 생략)"; return 0; }
  while read -r h f; do
    [ -n "$h" ] || continue
    f=$(basename "${f#\*}"); cur=$(sha "$SSL_DIR/$f"); n=$((n+1))
    if [ "$cur" = "$h" ]; then ok "ssl/$f 가 기준 해시와 일치"; else bad "ssl/$f 가 기준 해시와 다르거나 없음"; nb=$((nb+1)); fi
  done < "$SSL_BASELINE"
  [ $n -gt 0 ] || warn "기준 해시 목록이 비어 있음"
  return $nb
}
baseline_write() {   # 현재 ssl/* 를 기준 해시로 저장 (인증서를 바꾸거나 새로 설치한 직후에만)
  ( cd "$SSL_DIR" && rt sha256sum -- * ) > "$SSL_BASELINE.tmp" 2>/dev/null && mv -f "$SSL_BASELINE.tmp" "$SSL_BASELINE" \
    && chmod 600 "$SSL_BASELINE" && ok "인증서 기준 해시 갱신: $SSL_BASELINE" || warn "기준 해시 저장 실패"
}

# ---------- 패치 파일(payload) 검증 ----------
payload_verify() {   # payload_verify 상대경로...  — SHA256SUMS 의 해당 항목만 골라 복사 손상 여부 확인
  local rel tmp
  if [ -f "$PAYLOAD_DIR/SHA256SUMS" ]; then
    tmp=$(mktemp)
    for rel in "$@"; do
      # 윈도우(PowerShell)에서 만든 파일(CRLF·대문자 해시)도 읽을 수 있게 정규화
      awk -v r="$rel" '{sub(/\r$/,"")} $2==r {print tolower($1) "  " $2}' "$PAYLOAD_DIR/SHA256SUMS" > "$tmp.one"
      [ -s "$tmp.one" ] || { bad "SHA256SUMS 에 $rel 항목이 없음"; rm -f "$tmp" "$tmp.one"; return 1; }
      cat "$tmp.one" >> "$tmp"; rm -f "$tmp.one"
    done
    if ( cd "$PAYLOAD_DIR" && sha256sum -c --quiet "$tmp" ) >>"${LOG:-/dev/null}" 2>&1; then
      ok "패치 파일 SHA256 검증 통과 (복사 중 손상·변경 없음): $*"; rm -f "$tmp"
    else bad "패치 파일 SHA256 불일치 — 복사 중 손상 또는 파일이 바뀜. 다시 복사하세요."; rm -f "$tmp"; return 1; fi
  elif [ "${NO_SUMS:-0}" = 1 ]; then
    warn "SHA256SUMS 검증을 건너뜀(--no-sums) — 복사 손상을 확인하지 못합니다"
  else
    bad "payload/SHA256SUMS 가 없습니다. 관리자 PC 에서 admin_make_sums.sh 로 만든 파일을 함께 복사하세요."; return 1
  fi
}
elf_arch_ok() {   # 바이너리가 이 장비용(aarch64)인지
  command -v file >/dev/null 2>&1 || { warn "file 명령이 없어 바이너리 아키텍처 확인을 건너뜀"; return 0; }
  file "$1" | grep -q 'ELF 64-bit.*aarch64' && ok "바이너리 아키텍처 aarch64" || { bad "aarch64 ELF 바이너리가 아님: $1"; return 1; }
}

# ---------- 인증서 검사 ----------
cert_fp() { openssl x509 -in "$1" -noout -fingerprint -sha256 2>/dev/null | cut -d= -f2; }
pub_of_cert() { openssl x509 -in "$1" -noout -pubkey 2>/dev/null | sha256sum | cut -d' ' -f1; }
pub_of_key()  { openssl pkey -in "$1" -pubout 2>/dev/null | sha256sum | cut -d' ' -f1; }

cert_set_check() {  # cert_set_check 인증서 개인키 CA  — 짝·체인·만료·SAN 검사 (개인키 내용은 출력하지 않음)
  local crt="$1" key="$2" ca="$3" fp rc=0 end
  [ -r "$crt" ] && [ -r "$key" ] && [ -r "$ca" ] || { bad "인증서/개인키/CA 파일을 읽을 수 없음"; return 1; }
  openssl x509 -in "$crt" -noout 2>/dev/null && ok "장비 인증서 형식 OK" || { bad "장비 인증서(PEM)를 읽을 수 없음"; rc=1; }
  openssl pkey -in "$key" -noout 2>/dev/null && ok "개인키 형식 OK" || { bad "개인키(PEM)를 읽을 수 없음 (암호가 걸렸거나 손상)"; rc=1; }
  openssl x509 -in "$ca" -noout 2>/dev/null && ok "CA 인증서 형식 OK" || { bad "CA 인증서(PEM)를 읽을 수 없음"; rc=1; }
  [ $rc -eq 0 ] || return 1
  [ "$(pub_of_cert "$crt")" = "$(pub_of_key "$key")" ] && ok "인증서와 개인키가 한 쌍임" || { bad "인증서와 개인키가 서로 짝이 아님 (파일을 잘못 복사했거나 키가 바뀜)"; rc=1; }
  openssl verify -CAfile "$ca" "$crt" >/dev/null 2>&1 && ok "장비 인증서가 CA 로 검증됨 (체인 OK)" || { bad "장비 인증서가 이 CA 로 검증되지 않음"; rc=1; }
  openssl x509 -in "$crt" -noout -checkend 0 >/dev/null 2>&1 || { bad "장비 인증서가 이미 만료됨"; rc=1; }
  if openssl x509 -in "$crt" -noout -checkend $((CERT_MIN_DAYS*86400)) >/dev/null 2>&1; then ok "장비 인증서 유효기간 ${CERT_MIN_DAYS}일 이상 남음"; else warn "장비 인증서 만료가 ${CERT_MIN_DAYS}일 이내"; fi
  end=$(openssl x509 -in "$crt" -noout -enddate 2>/dev/null | cut -d= -f2); info "장비 인증서 만료일: $end"
  info "장비 인증서 주체: $(openssl x509 -in "$crt" -noout -subject 2>/dev/null | sed 's/^subject= *//')"
  openssl x509 -in "$crt" -noout -text 2>/dev/null | grep -A1 'Subject Alternative Name' | grep -q 'IP Address' \
    && ok "인증서 SAN 에 IP 주소 있음" || warn "인증서 SAN 에 IP 주소가 없음 (새로 발급할 때는 IP SAN 을 포함하세요)"
  fp=$(cert_fp "$ca"); info "CA 지문(SHA256): $fp"
  if [ -n "${CA_FINGERPRINT_SHA256:-}" ]; then
    [ "$fp" = "$CA_FINGERPRINT_SHA256" ] && ok "CA 지문이 설정값(CA_FINGERPRINT_SHA256)과 일치" || { bad "CA 지문이 설정값과 다름 — 다른 CA 파일일 수 있음"; rc=1; }
  else
    warn "CA_FINGERPRINT_SHA256 미설정 — CA 교체 여부를 자동 비교하지 못함 (설정 파일에 지문을 적어 두면 방지됨)"
  fi
  return $rc
}
key_perm_fix() {  # key_perm_fix 파일  — 개인키는 서비스 계정 소유·600
  rt chown "$SERVICE_USER:$SERVICE_GROUP" "$1" && rt chmod 600 "$1" && ok "개인키 권한 600 ($SERVICE_USER)" || bad "개인키 권한 설정 실패: $1"
}

# ---------- 폴더 · 설정(.env) 검사 ----------
as_svc() { if [ "$(id -un)" = "$SERVICE_USER" ]; then "$@"; else sudo -u "$SERVICE_USER" "$@"; fi; }
dirs_check() {   # 저장 폴더가 있고 서비스 계정이 쓸 수 있는지
  local d
  for d in "$IMAGE_DIR" "$VIDEO_DIR" "$VIDEO_ALWAYS_DIR" "$VOICE_DIR" "$ROI_SNAPSHOT_DIR"; do
    if [ -d "$d" ]; then as_svc test -w "$d" && ok "폴더 OK (쓰기 가능): $d" || bad "폴더에 쓸 수 없음($SERVICE_USER): $d"; else warn "폴더 없음: $d"; fi
  done
  [ -e "$ROIS_JSON" ] && ok "rois.json 있음: $ROIS_JSON" || warn "rois.json 없음: $ROIS_JSON (Python 이 만들기 전이면 정상)"
}
env_paths_check() {   # .env 의 경로 키가 설정 파일과 같은지 → 다른 항목 수를 반환
  local n=0 k want got
  for pair in "FILE_PATH:$OUTPUT_DIR" "AUDIO_PATH:$VOICE_DIR" "ROI_FILE_PATH:$ROIS_JSON" "ROI_SNAPSHOT_DIR:$ROI_SNAPSHOT_DIR"; do
    k=${pair%%:*}; want=${pair#*:}; got=$(envval "$k")
    if [ "$got" = "$want" ]; then ok ".env $k = 설정 파일과 동일 ($want)"
    else warn ".env $k = '${got:-(없음)}'  ≠  설정 파일 '$want'   → 경로만 맞추려면 '2_patch_binary.sh apply --paths-only', 바이너리 패치와 함께면 '--sync-paths'"; n=$((n+1)); fi
  done
  return $n
}
env_check() {   # .env 필수 키·형식 (값은 출력하지 않음)
  local k v n
  [ -f "$ENVF" ] || { bad ".env 없음: $ENVF"; return 1; }
  info ".env 권한 $(fmode "$ENVF") 소유 $(fowner "$ENVF")  (키 값은 출력하지 않음)"
  for k in PORT FILE_SEND_SCH_TIME HLS_DIR FILE_PATH CLOUD_RECEIVE_IP TLS_CERT_FILE TLS_KEY_FILE CA_CERT_FILE DEVICE_SERIAL DEVICE_HMAC_KEY RTSP_URL; do
    [ -n "$(envval $k)" ] && ok ".env $k 있음" || bad ".env $k 없음 또는 비어 있음"
  done
  v=$(envval CLOUD_RECEIVE_IP); info "CLOUD_RECEIVE_IP=$v"
  case "$v" in *:[0-9]*) ok "CLOUD_RECEIVE_IP 에 포트 포함";; *) bad "CLOUD_RECEIVE_IP 에 :포트 없음 (예 192.168.0.115:8189)";; esac
  v=$(envval FILE_SEND_SCH_TIME); n=$(printf '%s' "$v" | awk '{print NF}')
  [ "${n:-0}" -eq 6 ] && ok "FILE_SEND_SCH_TIME 6칸 (새 바이너리는 형식 오류 시 시작하지 않음)" || bad "FILE_SEND_SCH_TIME 이 6칸이 아님(${n:-0}칸)"
  v=$(envval DEVICE_HMAC_KEY); printf '%s' "$v" | grep -Eq '^[0-9a-fA-F]{64}$' && ok "DEVICE_HMAC_KEY 형식 OK (hex 64자)" || bad "DEVICE_HMAC_KEY 형식 이상 (hex 64자 아님)"
  v=$(envval DEVICE_SERIAL); [ "$v" = "$DEVICE_SERIAL" ] && ok ".env DEVICE_SERIAL 이 장비 시리얼과 일치" || bad ".env DEVICE_SERIAL 이 장비 시리얼과 다름"
  for k in TLS_CERT_FILE TLS_KEY_FILE CA_CERT_FILE; do v=$(envval $k); [ -n "$v" ] && { rt test -f "$v" && ok "$k 가 가리키는 파일 존재" || bad "$k 가 가리키는 파일 없음: $v"; }; done
  for k in H100_TRIGGER_TOKEN H100_AES_KEY; do [ -n "$(envval $k)" ] && info "(이상탐지용) $k 설정됨" || info "(이상탐지용) $k 없음 — 해당 기능은 요청을 거부(401/503), 기존 동작엔 영향 없음"; done
}
time_check() {
  info "장비 시각: $(date '+%F %T %Z')  / NTP 동기화: $(timedatectl show -p NTPSynchronized --value 2>/dev/null || echo 확인불가)"
  [ "$(timedatectl show -p NTPSynchronized --value 2>/dev/null)" = yes ] && ok "시간 동기화(NTP) 정상" || warn "NTP 동기화 아님 — 서버와 ±5분 넘게 어긋나면 ROI·촬영 요청 인증이 거부됨"
}
server_check() {   # 서버(module_c) TLS 도달성 — CA 로 서버 인증서를 검증
  local target="$1" ca="$2" code rc
  code=$(curl -sS -m 6 --cacert "$ca" -o /dev/null -w '%{http_code}' "https://$target/healthcheck" 2>>"${LOG:-/dev/null}"); rc=$?
  if [ $rc -eq 0 ] && [ "$code" != 000 ]; then ok "서버 $target TLS 연결·CA 검증 성공 (HTTP $code)"; return 0; fi
  case $rc in
    60) warn "서버 인증서 검증 실패(curl 60) — CA 파일이 서버 CA 와 다르거나 서버 인증서 SAN 문제";;
    28|7) warn "서버 $target 에 연결 불가(curl $rc) — 네트워크 또는 서버 8189 허용 목록에 이 장비 IP 가 없음";;
    *) warn "서버 $target 연결 확인 실패(curl $rc)";;
  esac
  return 1
}

# ---------- 서비스 ----------
svc_active() { systemctl is-active --quiet "$SERVICE_NAME"; }
svc_stop()  { rt systemctl stop "$SERVICE_NAME"; }
svc_start() { rt systemctl start "$SERVICE_NAME"; }
health() {   # health new|old — 새 바이너리는 /healthz 200 과 /detection/trigger 401 을 확인
  local port code; port=$(envval PORT); port=${port:-$PORT}
  svc_active || { bad "서비스 $SERVICE_NAME 가 실행 중이 아님"; return 1; }
  ok "서비스 $SERVICE_NAME 실행 중"
  if [ "${1:-new}" = auto ]; then   # 바이너리를 바꾸지 않은 경우: /healthz 가 있으면 새 버전 점검, 없으면(구 버전) 포트 응답만 확인
    code=$(curl -sk -m 5 -o /dev/null -w '%{http_code}' "https://127.0.0.1:${port}/healthz")
    [ "$code" = 200 ] && set -- new || set -- old
  fi
  if [ "${1:-new}" = old ]; then
    code=$(curl -sk -m 5 -o /dev/null -w '%{http_code}' "https://127.0.0.1:${port}/")
    [ "$code" != 000 ] && ok "TLS 포트 $port 응답 (HTTP $code)" || { bad "TLS 포트 $port 무응답"; return 1; }
  else
    code=$(curl -sk -m 5 -o /dev/null -w '%{http_code}' "https://127.0.0.1:${port}/healthz")
    [ "$code" = 200 ] && ok "/healthz 200 (새 버전 응답)" || { bad "/healthz 응답 $code"; return 1; }
    code=$(curl -sk -m 5 -o /dev/null -w '%{http_code}' -X POST "https://127.0.0.1:${port}/detection/trigger")
    [ "$code" = 401 ] && ok "/detection/trigger 인증 없이 401 (정상 거부)" || warn "/detection/trigger 응답 $code (401 기대)"
  fi
  info "최근 서비스 로그:"; journalctl -u "$SERVICE_NAME" -n 6 --no-pager 2>/dev/null | sed 's/^/        /' | tee -a "${LOG:-/dev/null}" >/dev/null
  return 0
}
served_cert_is() {   # 서비스가 실제로 내보내는 인증서가 해당 파일과 같은지
  local port got want; port=$(envval PORT); port=${port:-$PORT}
  got=$(echo | timeout 8 openssl s_client -connect "127.0.0.1:${port}" 2>/dev/null | openssl x509 -noout -fingerprint -sha256 2>/dev/null | cut -d= -f2)
  want=$(cert_fp "$1")
  [ -n "$got" ] && [ "$got" = "$want" ] && ok "서비스가 내보내는 인증서가 새 파일과 일치" || { bad "서비스가 내보내는 인증서가 새 파일과 다름/확인 불가"; return 1; }
}
install_file() {   # install_file 원본 대상 소유 그룹 모드  — 임시파일로 복사 후 mv (중간에 끊겨도 반쪽 파일이 남지 않음)
  rt install -o "$3" -g "$4" -m "$5" "$1" "$2.new.tmp" && rt mv -f "$2.new.tmp" "$2"
}

# ---------- 설치된 장비의 공통 사전 점검 (2번·3번 스크립트 공용) ----------
installed_preflight() {
  say ""; say "-- 현재 설치 상태"
  for c in openssl curl awk sha256sum systemctl install; do command -v $c >/dev/null 2>&1 || bad "필요한 명령이 없음: $c"; done
  [ -f "$BIN" ] && ok "현재 바이너리 있음 (sha256 $(sha "$BIN" | cut -c1-16)…  소유 $(fowner "$BIN")  권한 $(fmode "$BIN"))" || bad "설치된 바이너리가 없음: $BIN — 최초 설치는 1_install_first.sh"
  svc_active && ok "서비스 $SERVICE_NAME 실행 중" || warn "서비스 $SERVICE_NAME 가 실행 중이 아님"
  info "systemd: $(systemctl cat "$SERVICE_NAME" 2>/dev/null | grep -E '^(User|WorkingDirectory|ExecStart)=' | tr '\n' ' ')"
  time_check
  say ""; say "-- 설정(.env)"
  env_check
  env_paths_check; export PATH_MISMATCH=$?   # 2번 스크립트에서 사용
  say ""; say "-- 폴더"
  dirs_check
  say ""; say "-- 인증서 (현재 상태 — 기준 해시와 비교)"
  baseline_compare || true
  cert_set_check "$CRT" "$KEY" "$CA" >/dev/null 2>&1 && ok "현재 인증서 세트 정상 (짝·체인·만료)" || warn "현재 인증서 세트 점검에서 문제가 있음 — 3_patch_with_cert.sh 가 필요할 수 있음"
  [ "$(fmode "$KEY")" = 600 ] && ok "개인키 권한 600" || warn "개인키 권한 $(fmode "$KEY") (600 권장)"
  server_check "$(envval CLOUD_RECEIVE_IP)" "$CA" || true
}
restore_all() {   # 실패 시 자동 복구: 백업된 파일을 되돌리고 서비스 재시작 ($BK 필요)
  say "↩ 자동 복구: $BK"
  svc_stop; backup_restore "$BK"; svc_start; sleep 4
  health old && ok "복구 후 서비스 정상" || bad "복구 후에도 문제가 있음 — 수동 확인 필요 (백업: $BK)"
}
