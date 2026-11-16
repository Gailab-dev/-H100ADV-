#!/usr/bin/env bash
# =============================================================================
#  [1번] 최초 설치 — 새 엣지(Jetson)에 module_d 를 처음 설치하고 인증서 키를 배포한다
#
#   ./1_install_first.sh check                       점검만 (아무것도 바꾸지 않음)
#   ./1_install_first.sh apply [옵션]                설치 실행 (확인 후 진행)
#
#   옵션:  --hmac-key-file <파일>   장비 HMAC 키(64자 hex 한 줄). 없으면 숨김 입력으로 받음
#          --rtsp-file <파일>       카메라 RTSP 주소(한 줄). 없으면 숨김 입력으로 받음
#          --no-start               설치만 하고 서비스는 시작하지 않음
#          --wipe-payload-key       설치 성공 후 payload 안의 개인키 사본을 덮어쓰기 삭제
#          --reinstall              이미 설치된 장비에 다시 설치(기존 파일은 모두 백업)
#          --no-sums                SHA256SUMS 검증 생략(권장하지 않음)
#          --dry-run                계획만 출력하고 종료
#          --yes                    확인 질문 생략
#
#  필요한 payload (키트 폴더의 payload/):
#     h100_module_d                      module_d 바이너리 (linux/arm64)
#     certs/h100-ca.crt                  내부 CA 공개 인증서
#     certs/device-<시리얼>.crt          이 장비의 인증서
#     certs/device-<시리얼>.key          이 장비의 개인키   ← 복사·붙여넣기 금지, 파일 그대로 복사
#     SHA256SUMS                         위 파일들의 해시 (관리자 PC 에서 admin_make_sums.sh 로 생성)
#
#  경로·이름은 h100-device.conf 에서만 바꾼다. 이 스크립트는 수정하지 않는다.
# =============================================================================
set -uo pipefail
KIT_DIR=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
# shellcheck source=lib.sh
. "$KIT_DIR/lib.sh"

ACTION=${1:-}; shift || true
HMAC_FILE=""; RTSP_FILE=""; NO_START=0; WIPE=0; REINSTALL=0; NO_SUMS=0; DRY=0
while [ $# -gt 0 ]; do case "$1" in
  --hmac-key-file) HMAC_FILE=${2:-}; shift 2;; --rtsp-file) RTSP_FILE=${2:-}; shift 2;;
  --no-start) NO_START=1; shift;; --wipe-payload-key) WIPE=1; shift;; --reinstall) REINSTALL=1; shift;;
  --no-sums) NO_SUMS=1; shift;; --dry-run) DRY=1; shift;; --yes) ASSUME_YES=1; shift;;
  *) echo "알 수 없는 옵션: $1"; sed -n '2,30p' "$0"; exit 2;; esac; done
case "$ACTION" in check|apply) ;; *) sed -n '2,30p' "$0"; exit 2;; esac

load_conf
init_log install-first
UNIT="$SYSTEMD_DIR/$SERVICE_NAME.service"
P_BIN="$PAYLOAD_DIR/$BIN_NAME"; P_CA="$PAYLOAD_DIR/certs/$CA_CERT_NAME"; P_CRT="$PAYLOAD_DIR/certs/$CRT_NAME"; P_KEY="$PAYLOAD_DIR/certs/$KEY_NAME"

say "== [1번] 최초 설치 ($ACTION) $(date '+%F %T') =="
info "장비 시리얼 $DEVICE_SERIAL  /  기준 폴더 $H100_HOME  /  module_d 폴더 $MODULE_D_DIR"

preflight() {
  say ""; say "-- 사전 점검"
  for c in openssl curl awk sha256sum systemctl install; do command -v $c >/dev/null 2>&1 && ok "명령 있음: $c" || bad "필요한 명령이 없음: $c"; done
  command -v ffmpeg >/dev/null 2>&1 || [ -x "$FFMPEG_PATH" ] && ok "ffmpeg 사용 가능($FFMPEG_PATH)" || warn "ffmpeg 를 찾을 수 없음($FFMPEG_PATH) — 영상(HLS)이 만들어지지 않음"
  [ "$(uname -m)" = aarch64 ] && ok "CPU aarch64" || warn "CPU 가 $(uname -m) — 이 키트의 바이너리는 aarch64 용"
  if [ "$(id -u)" -ne 0 ]; then sudo -n true 2>/dev/null && ok "sudo 사용 가능" || info "sudo 암호 입력이 필요할 수 있음"; fi
  id "$SERVICE_USER" >/dev/null 2>&1 && ok "서비스 계정 있음: $SERVICE_USER" || bad "서비스 계정이 없음: $SERVICE_USER (h100-device.conf SERVICE_USER)"
  printf '%s' "$CLOUD_RECEIVE_IP" | grep -Eq '^[0-9a-zA-Z.-]+:[0-9]+$' && ok "CLOUD_RECEIVE_IP=$CLOUD_RECEIVE_IP" || bad "h100-device.conf 의 CLOUD_RECEIVE_IP 를 'IP:포트' 형식으로 채우세요 (예 192.168.0.115:8189)"
  printf '%s' "$FILE_SEND_SCH_TIME" | awk '{exit !(NF==6)}' && ok "FILE_SEND_SCH_TIME 6칸" || bad "FILE_SEND_SCH_TIME 은 6칸(초 분 시 일 월 요일)"
  time_check

  say ""; say "-- 설치 상태"
  if [ -e "$BIN" ] || [ -e "$UNIT" ] || [ -e "$ENVF" ]; then
    if [ $REINSTALL -eq 1 ]; then warn "이미 설치된 흔적이 있음 — --reinstall 이므로 기존 파일을 모두 백업 후 진행"
    else bad "이미 설치된 장비입니다(바이너리/서비스/.env 중 존재). 바이너리만 바꾸려면 2_patch_binary.sh, 인증서도 바꾸려면 3_patch_with_cert.sh 를 쓰세요."; fi
  else ok "신규 설치 대상 (기존 설치 흔적 없음)"; fi

  say ""; say "-- 패치 파일(payload)"
  for f in "$P_BIN" "$P_CA" "$P_CRT" "$P_KEY"; do [ -f "$f" ] && ok "있음: ${f#"$KIT_DIR"/}" || bad "없음: ${f#"$KIT_DIR"/}"; done
  [ -f "$P_BIN" ] && [ -f "$P_CA" ] && [ -f "$P_CRT" ] && [ -f "$P_KEY" ] || return
  NO_SUMS=$NO_SUMS payload_verify "$BIN_NAME" "certs/$CA_CERT_NAME" "certs/$CRT_NAME" "certs/$KEY_NAME"
  elf_arch_ok "$P_BIN"
  say ""; say "-- 인증서 점검 (payload)"
  cert_set_check "$P_CRT" "$P_KEY" "$P_CA"
  [ "$(fmode "$P_KEY")" = 600 ] || info "payload 개인키 권한이 $(fmode "$P_KEY") — 설치 시 600 으로 설정됨(원본 payload 는 바꾸지 않음)"
  say ""; say "-- 서버 연결"
  server_check "$CLOUD_RECEIVE_IP" "$P_CA" || info "서버 연결이 안 되면: 서버 8189 허용 목록(device-allow.list)에 이 장비 IP 를 등록했는지 확인 (MANUAL.md §6)"
}

read_secret() {   # read_secret 프롬프트 파일옵션 → 값을 SECRET 에 (화면 출력 없음)
  SECRET=""
  if [ -n "$2" ]; then [ -r "$2" ] || die "파일을 읽을 수 없음: $2"; SECRET=$(head -n1 "$2" | tr -d '\r\n ')
  else [ "$ASSUME_YES" = 1 ] && [ ! -t 0 ] && die "$1 : --yes 로 무인 실행할 때는 파일 옵션이 필요합니다"
       read -r -s -p "$1: " SECRET; echo; fi
}

do_apply() {
  [ $FAIL -eq 0 ] || die "사전 점검 실패 항목이 있어 설치하지 않습니다. 위 [FAIL] 을 해결한 뒤 다시 실행하세요."
  say ""; say "-- 비밀값 입력 (화면에 표시·기록되지 않음)"
  read_secret "장비 HMAC 키(64자 hex)" "$HMAC_FILE"; HMAC_KEY=$SECRET
  printf '%s' "$HMAC_KEY" | grep -Eq '^[0-9a-fA-F]{64}$' || die "HMAC 키 형식 오류 (hex 64자여야 함)"
  ok "HMAC 키 형식 OK"
  read_secret "카메라 RTSP 주소(rtsp://…)" "$RTSP_FILE"; RTSP=$SECRET
  printf '%s' "$RTSP" | grep -Eq '^rtsps?://[^ ]+$' || die "RTSP 주소 형식 오류 (rtsp:// 로 시작, 공백 없음)"
  ok "RTSP 주소 형식 OK"

  say ""; say "계획:"
  say "  1) 폴더 생성: $IMAGE_DIR, $VIDEO_DIR, $VIDEO_ALWAYS_DIR, $VOICE_DIR, $ROI_SNAPSHOT_DIR, $MODULE_D_DIR/{ssl,logs,hls}"
  say "  2) 바이너리 설치: $BIN (root:root 755)"
  say "  3) 인증서 배포: $SSL_DIR 에 CA·장비 인증서·개인키(600, $SERVICE_USER)"
  say "  4) .env 생성 (600, $SERVICE_USER) — 경로는 h100-device.conf 값, 비밀값은 방금 입력한 값"
  say "  5) systemd 서비스 $SERVICE_NAME 등록·활성화$( [ $NO_START -eq 1 ] && echo ' (시작은 하지 않음)' || echo ' 후 시작')"
  say "  6) 점검(/healthz, 인증서 일치) 후 인증서 기준 해시 저장: $SSL_BASELINE"
  [ $DRY -eq 1 ] && { say ""; say "(--dry-run) 계획만 출력했고 아무것도 바꾸지 않았음"; summary; exit 0; }
  confirm "진행할까요?" || { say "중단"; exit 1; }

  backup_open install
  if [ $REINSTALL -eq 1 ]; then for f in "$BIN" "$ENVF" "$CRT" "$KEY" "$CA" "$UNIT"; do backup_file "$f"; done; info "기존 파일 백업: $BK"; svc_stop 2>/dev/null; fi

  # 1) 폴더
  for d in "$IMAGE_DIR" "$VIDEO_DIR" "$VIDEO_ALWAYS_DIR" "$VOICE_DIR" "$ROI_SNAPSHOT_DIR" "$MODULE_D_DIR/logs" "$HLS_DIR"; do
    rt mkdir -p "$d" && rt chown "$SERVICE_USER:$SERVICE_GROUP" "$d" || { bad "폴더 생성 실패: $d"; exit 1; }
  done
  for d in "$OUTPUT_DIR" "$MODULE_D_DIR"; do rt chown "$SERVICE_USER:$SERVICE_GROUP" "$d" 2>/dev/null; done
  rt mkdir -p "$SSL_DIR" && rt chown "$SERVICE_USER:$SERVICE_GROUP" "$SSL_DIR" && rt chmod 700 "$SSL_DIR"
  ok "폴더 생성·권한 설정 완료"

  # 2) 바이너리
  install_file "$P_BIN" "$BIN" root root 755 && [ "$(sha "$BIN")" = "$(sha "$P_BIN")" ] && ok "바이너리 설치 (해시 일치)" || { bad "바이너리 설치 실패"; exit 1; }

  # 3) 인증서 — 파일 그대로 복사하고 해시로 검증
  install_file "$P_CA"  "$CA"  "$SERVICE_USER" "$SERVICE_GROUP" 644
  install_file "$P_CRT" "$CRT" "$SERVICE_USER" "$SERVICE_GROUP" 644
  install_file "$P_KEY" "$KEY" "$SERVICE_USER" "$SERVICE_GROUP" 600
  for pair in "$P_CA:$CA" "$P_CRT:$CRT" "$P_KEY:$KEY"; do
    [ "$(sha "${pair%%:*}")" = "$(sha "${pair#*:}")" ] && ok "배포 후 해시 일치: $(basename "${pair#*:}")" || { bad "배포 후 해시 불일치: $(basename "${pair#*:}")"; exit 1; }
  done
  cert_set_check "$CRT" "$KEY" "$CA" >/dev/null 2>&1 && ok "설치된 인증서 세트 검증 통과" || { bad "설치된 인증서 세트 검증 실패"; exit 1; }

  # 4) .env
  umask 077; TMPENV=$(mktemp); : > "$TMPENV"
  for kv in "PORT=$PORT" "FILE_SEND_SCH_TIME=$FILE_SEND_SCH_TIME" "HLS_DIR=$HLS_DIR" "FFMPEG_PATH=$FFMPEG_PATH" "SEGMENT_TIME=$SEGMENT_TIME" \
            "RTSP_URL=$RTSP" "FILE_PATH=$OUTPUT_DIR" "AUDIO_PATH=$VOICE_DIR" "CLOUD_RECEIVE_IP=$CLOUD_RECEIVE_IP" \
            "TLS_CERT_FILE=$CRT" "TLS_KEY_FILE=$KEY" "CA_CERT_FILE=$CA" "DEVICE_HMAC_KEY=$HMAC_KEY" "DEVICE_SERIAL=$DEVICE_SERIAL" \
            "ROI_FILE_PATH=$ROIS_JSON" "ROI_SNAPSHOT_DIR=$ROI_SNAPSHOT_DIR"; do
    env_set_file "$TMPENV" "${kv%%=*}" "${kv#*=}"
  done
  [ -n "$ROI_SNAPSHOT_URL" ] && env_set_file "$TMPENV" ROI_SNAPSHOT_URL "$ROI_SNAPSHOT_URL"
  install_file "$TMPENV" "$ENVF" "$SERVICE_USER" "$SERVICE_GROUP" 600; rm -f "$TMPENV"; unset HMAC_KEY RTSP SECRET
  ok ".env 생성 (권한 600) — 비밀값은 화면·로그에 기록하지 않음"

  # 5) systemd
  TMPU=$(mktemp); cat > "$TMPU" <<EOF
[Unit]
Description=H100 module_d (edge)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$MODULE_D_DIR
ExecStart=$BIN
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  install_file "$TMPU" "$UNIT" root root 644; rm -f "$TMPU"
  rt systemctl daemon-reload && rt systemctl enable "$SERVICE_NAME" >/dev/null 2>&1 && ok "systemd 서비스 등록·활성화: $SERVICE_NAME"
  if [ $NO_START -eq 1 ]; then info "--no-start: 서비스를 시작하지 않았음. 시작: sudo systemctl start $SERVICE_NAME"
  else
    svc_start; sleep 5
    if health new && served_cert_is "$CRT"; then ok "설치 후 점검 통과"; else bad "설치 후 점검 실패 — 'journalctl -u $SERVICE_NAME -n 50' 확인. 되돌리려면 서비스 정지 후 폴더 정리 또는 --reinstall 백업($BK) 참조"; fi
  fi
  baseline_write
  if [ $WIPE -eq 1 ] && [ $FAIL -eq 0 ]; then shred -u "$P_KEY" 2>/dev/null && ok "payload 의 개인키 사본을 덮어쓰기 삭제" || warn "payload 개인키 삭제 실패(수동 삭제 필요: $P_KEY)"
  else warn "payload 에 개인키 사본이 남아 있음 — 설치 확인 후 삭제 권장:  shred -u $P_KEY   (또는 --wipe-payload-key)"; fi
  backup_prune
  say ""; say "★ 서버 쪽 후속 작업 (서버 담당자): 8189 허용 목록에 이 장비 IP 등록 + HMAC 키 등록 (시리얼 $DEVICE_SERIAL) → MANUAL.md §6"
  summary; [ $FAIL -eq 0 ]
}

preflight
if [ "$ACTION" = check ]; then summary; [ $FAIL -eq 0 ]; else do_apply; fi
