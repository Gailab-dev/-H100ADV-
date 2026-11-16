#!/usr/bin/env bash
# =============================================================================
#  [3번] 패치 + 인증서 교체 — 바이너리와 장비 인증서(개인키 포함)를 함께(또는 인증서만) 바꾼다
#        기존 인증서 세트는 통째로 백업하고, 새 세트를 검증(짝·체인·만료·CA 지문)한 뒤에만 교체한다.
#
#   ./3_patch_with_cert.sh check                 점검만 (아무것도 바꾸지 않음)
#   ./3_patch_with_cert.sh gen-csr [--ip IP]     (선택) 장비에서 새 개인키+CSR 생성 — 개인키가 장비 밖으로 나가지 않음
#   ./3_patch_with_cert.sh apply [옵션]          교체 실행 (확인 후 진행, 실패 시 자동 복구)
#   ./3_patch_with_cert.sh rollback [백업폴더]   직전 백업(바이너리+인증서)으로 되돌리기
#
#   옵션:  --cert-only          바이너리는 그대로 두고 인증서만 교체
#          --use-local-key      payload 에 개인키가 없고, gen-csr 로 장비에서 만든 개인키를 쓸 때
#          --allow-ca-change    CA 인증서 자체가 바뀌는 경우 허용 (서버가 새 CA 를 먼저 신뢰하도록 설정돼 있어야 함)
#          --wipe-payload-key   성공 후 payload 안의 개인키 사본을 덮어쓰기 삭제
#          --sync-paths         .env 경로 키 4개를 h100-device.conf 값으로 맞춤 (2번 스크립트와 동일)
#          --no-sums            SHA256SUMS 검증 생략(권장하지 않음)
#          --dry-run            계획만 출력하고 종료
#          --yes                확인 질문 생략
#
#  필요한 payload (키트 폴더의 payload/):
#     h100_module_d                      (--cert-only 가 아니면) 새 바이너리
#     certs/device-<시리얼>.crt          새 장비 인증서
#     certs/device-<시리얼>.key          새 장비 개인키   ← --use-local-key 면 불필요 (복사·붙여넣기 금지, 파일 그대로 복사)
#     certs/h100-ca.crt                  (선택) CA 인증서. 없으면 현재 CA 를 사용
#     SHA256SUMS                         위 파일들의 해시 (관리자 PC 에서 admin_make_sums.sh 로 생성)
#
#  경로·이름은 h100-device.conf 에서만 바꾼다. 이 스크립트는 수정하지 않는다.
# =============================================================================
set -uo pipefail
KIT_DIR=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
# shellcheck source=lib.sh
. "$KIT_DIR/lib.sh"

ACTION=${1:-}; shift || true
CERT_ONLY=0; LOCAL_KEY=0; CA_CHANGE=0; WIPE=0; SYNC=0; NO_SUMS=0; DRY=0; RB_DIR=""; CSR_IP=""
if [ "$ACTION" = rollback ] && [ $# -gt 0 ] && [ "${1#--}" = "$1" ]; then RB_DIR=$1; shift; fi
while [ $# -gt 0 ]; do case "$1" in
  --cert-only) CERT_ONLY=1; shift;; --use-local-key) LOCAL_KEY=1; shift;; --allow-ca-change) CA_CHANGE=1; shift;;
  --wipe-payload-key) WIPE=1; shift;; --sync-paths) SYNC=1; shift;; --no-sums) NO_SUMS=1; shift;;
  --dry-run) DRY=1; shift;; --yes) ASSUME_YES=1; shift;; --ip) CSR_IP=${2:-}; shift 2;;
  *) echo "알 수 없는 옵션: $1"; sed -n '2,32p' "$0"; exit 2;; esac; done
case "$ACTION" in check|gen-csr|apply|rollback) ;; *) sed -n '2,32p' "$0"; exit 2;; esac

load_conf
init_log patch-with-cert
P_BIN="$PAYLOAD_DIR/$BIN_NAME"; P_CA="$PAYLOAD_DIR/certs/$CA_CERT_NAME"; P_CRT="$PAYLOAD_DIR/certs/$CRT_NAME"; P_KEY="$PAYLOAD_DIR/certs/$KEY_NAME"
CSR_DIR="$KIT_STATE_DIR/csr"; L_KEY="$CSR_DIR/$KEY_NAME.pending"; L_CSR="$CSR_DIR/device-${DEVICE_SERIAL}.csr"
say "== [3번] 패치 + 인증서 교체 ($ACTION) $(date '+%F %T') =="
info "장비 시리얼 $DEVICE_SERIAL  /  module_d 폴더 $MODULE_D_DIR"

do_gen_csr() {   # 장비에서 새 개인키와 CSR 만 만든다 (운영 중인 파일은 건드리지 않음)
  local ip=${CSR_IP:-$(hostname -I 2>/dev/null | awk '{print $1}')}
  printf '%s' "$ip" | grep -Eq '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' || die "장비 IP 를 알 수 없습니다. --ip <장비IP> 로 지정하세요."
  [ -e "$L_KEY" ] && die "이미 생성된 대기 키가 있습니다($L_KEY). 쓰지 않을 거면 shred -u 로 지운 뒤 다시 실행하세요."
  mkdir -p "$CSR_DIR" && chmod 700 "$KIT_STATE_DIR" "$CSR_DIR"
  ( umask 077; openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$L_KEY" 2>/dev/null ) || die "개인키 생성 실패"
  openssl req -new -key "$L_KEY" -subj "/CN=device-$DEVICE_SERIAL" \
    -addext "subjectAltName=IP:$ip,DNS:device-$DEVICE_SERIAL" -out "$L_CSR" 2>/dev/null || die "CSR 생성 실패 (openssl 1.1.1 이상 필요)"
  chmod 600 "$L_KEY"
  ok "새 개인키 생성 (장비 안에만 있음, 권한 600): $L_KEY"
  ok "CSR 생성: $L_CSR  (SAN: IP $ip, DNS device-$DEVICE_SERIAL)"
  say ""; say "다음 단계: ① 위 .csr 파일(공개 정보)을 관리자 PC 로 복사 → ② 관리자 PC 에서 admin_issue_device_cert.sh --csr 로 서명 → ③ 받은 .crt 를 payload/certs/ 에 넣고 SHA256SUMS 갱신 → ④ 이 스크립트 apply --use-local-key"
  summary
}

candidate_check() {   # 새 인증서 세트(payload 또는 대기 키)를 적용 전에 검증
  say ""; say "-- 새 인증서 세트 (payload)"
  NEW_CRT="$P_CRT"; NEW_CA="$CA"; NEW_KEY="$P_KEY"
  [ -f "$P_CRT" ] && ok "있음: payload/certs/$CRT_NAME" || bad "없음: payload/certs/$CRT_NAME"
  [ -f "$P_CA" ] && { NEW_CA="$P_CA"; ok "있음: payload/certs/$CA_CERT_NAME (새 CA 파일)"; } || info "payload 에 CA 파일 없음 → 현재 CA 사용"
  if [ $LOCAL_KEY -eq 1 ]; then NEW_KEY="$L_KEY"; [ -f "$L_KEY" ] && ok "장비에서 만든 대기 개인키 사용" || bad "대기 개인키 없음 — 먼저 gen-csr 실행"
  else [ -f "$P_KEY" ] && ok "있음: payload/certs/$KEY_NAME" || bad "없음: payload/certs/$KEY_NAME (장비에서 만든 키를 쓰려면 --use-local-key)"; fi
  [ -f "$NEW_CRT" ] && [ -f "$NEW_KEY" ] || return 1
  local list=("certs/$CRT_NAME"); [ -f "$P_CA" ] && list+=("certs/$CA_CERT_NAME"); [ $LOCAL_KEY -eq 0 ] && list+=("certs/$KEY_NAME")
  [ $CERT_ONLY -eq 0 ] && list+=("$BIN_NAME")
  NO_SUMS=$NO_SUMS payload_verify "${list[@]}"
  cert_set_check "$NEW_CRT" "$NEW_KEY" "$NEW_CA"
  # CA 교체 여부
  if [ "$(cert_fp "$NEW_CA")" = "$(cert_fp "$CA")" ]; then ok "CA 인증서가 현재와 동일 (CA 변경 없음)"
  elif [ $CA_CHANGE -eq 1 ]; then warn "CA 인증서가 바뀜(--allow-ca-change) — 서버(module_c)가 새 CA 를 신뢰하도록 먼저 설정돼 있어야 함"
  else bad "CA 인증서가 현재와 다름 — CA 교체가 의도라면 --allow-ca-change, 아니면 payload 파일을 확인하세요"; fi
  [ "$(sha "$NEW_CRT")" = "$(sha "$CRT")" ] && [ "$(sha "$NEW_KEY")" = "$(sha "$KEY")" ] && warn "새 인증서·개인키가 현재와 동일 (교체할 내용이 없음)"
  if [ $CERT_ONLY -eq 0 ]; then
    say ""; say "-- 새 바이너리 (payload)"
    if [ -f "$P_BIN" ]; then ok "있음: payload/$BIN_NAME (sha256 $(sha "$P_BIN" | cut -c1-16)…)"; elf_arch_ok "$P_BIN"
    else bad "없음: payload/$BIN_NAME (인증서만 바꾸려면 --cert-only)"; fi
  fi
}

do_apply() {
  [ $FAIL -eq 0 ] || die "사전 점검 실패 항목이 있어 진행하지 않습니다. 위 [FAIL] 을 해결한 뒤 다시 실행하세요."
  say ""; say "계획: 서비스 정지(수 초) → 현재 $( [ $CERT_ONLY -eq 0 ] && echo '바이너리·')인증서 세트(CA·인증서·개인키) 백업 → 새 인증서 세트 $( [ $CERT_ONLY -eq 0 ] && echo '및 바이너리 ')교체(개인키 600) → 서비스 시작 → 점검(서비스가 새 인증서를 내보내는지 확인)"
  say "      .env 는 $( [ $SYNC -eq 1 ] && echo '경로 키 4개만 변경' || echo '변경하지 않음 (인증서 파일 이름이 같으므로 경로 수정 불필요)')"
  say "      영상(HLS)·파일 전송이 이 시간 동안 잠시 끊깁니다."
  [ $DRY -eq 1 ] && { say ""; say "(--dry-run) 계획만 출력했고 아무것도 바꾸지 않았음"; summary; exit 0; }
  confirm "진행할까요?" || { say "중단"; exit 1; }

  local owner grp mode
  ENV_BEFORE=$(sha "$ENVF")
  backup_open cert
  for f in "$CRT" "$KEY" "$CA"; do backup_file "$f" || die "백업 실패: $f"; done
  [ $CERT_ONLY -eq 0 ] && { backup_file "$BIN" || die "바이너리 백업 실패"; }
  [ $SYNC -eq 1 ] && { backup_file "$ENVF" || die ".env 백업 실패"; }
  ok "백업 완료 (인증서 세트 포함, 권한 700 폴더): $BK"

  svc_stop
  if [ $CERT_ONLY -eq 0 ]; then
    owner=$(fowner "$BIN"); grp=${owner##*:}; owner=${owner%%:*}; mode=$(fmode "$BIN")
    if ! install_file "$P_BIN" "$BIN" "$owner" "$grp" "$mode" || [ "$(sha "$BIN")" != "$(sha "$P_BIN")" ]; then bad "바이너리 교체 실패/해시 불일치"; restore_all; summary; exit 1; fi
    ok "바이너리 교체 완료 (소유·권한 유지)"
  fi
  # 인증서 세트: 개인키 → 인증서 → CA 순. 모두 임시파일로 복사 후 mv, 해시로 확인
  install_file "$NEW_KEY" "$KEY" "$SERVICE_USER" "$SERVICE_GROUP" 600
  install_file "$NEW_CRT" "$CRT" "$SERVICE_USER" "$SERVICE_GROUP" 644
  [ "$NEW_CA" != "$CA" ] && install_file "$NEW_CA" "$CA" "$SERVICE_USER" "$SERVICE_GROUP" 644
  for pair in "$NEW_KEY:$KEY" "$NEW_CRT:$CRT" "$NEW_CA:$CA"; do
    [ "$(sha "${pair%%:*}")" = "$(sha "${pair#*:}")" ] || { bad "배포 후 해시 불일치: $(basename "${pair#*:}")"; restore_all; summary; exit 1; }
  done
  ok "인증서 세트 교체 완료 — 배포 후 해시 일치, 개인키 권한 600 ($SERVICE_USER)"
  cert_set_check "$CRT" "$KEY" "$CA" >/dev/null 2>&1 || { bad "교체된 인증서 세트 검증 실패"; restore_all; summary; exit 1; }
  if [ $SYNC -eq 1 ]; then
    for pair in "FILE_PATH:$OUTPUT_DIR" "AUDIO_PATH:$VOICE_DIR" "ROI_FILE_PATH:$ROIS_JSON" "ROI_SNAPSHOT_DIR:$ROI_SNAPSHOT_DIR"; do
      k=${pair%%:*}; v=${pair#*:}; old=$(envval "$k"); [ "$old" = "$v" ] && continue
      tmp=$(mktemp); rt cat "$ENVF" > "$tmp"; env_set_file "$tmp" "$k" "$v"
      o=$(fowner "$ENVF"); m=$(fmode "$ENVF"); install_file "$tmp" "$ENVF" "${o%%:*}" "${o##*:}" "$m"; rm -f "$tmp"
      ok ".env $k : '${old:-(없음)}' → '$v'"
    done
  fi
  svc_start; sleep 5
  if [ $CERT_ONLY -eq 1 ]; then h=old; else h=new; fi
  if ! health $h || ! served_cert_is "$CRT"; then bad "교체 후 점검 실패 → 자동 복구"; restore_all; summary; exit 1; fi
  if [ $SYNC -eq 0 ] && [ "$(sha "$ENVF")" != "$ENV_BEFORE" ]; then bad ".env 가 교체 중 바뀜 → 자동 복구"; restore_all; summary; exit 1; fi
  ok "서비스가 새 인증서로 정상 동작"
  server_check "$(envval CLOUD_RECEIVE_IP)" "$CA" || warn "서버 연결 확인 실패 — 서버 쪽 CA·허용 목록을 확인하세요 (롤백 가능)"
  baseline_write
  if [ $LOCAL_KEY -eq 1 ]; then shred -u "$L_KEY" "$L_CSR" 2>/dev/null; info "대기 개인키·CSR 정리 완료 (설치된 키는 ssl/ 에 있음)"; fi
  if [ $WIPE -eq 1 ] && [ $LOCAL_KEY -eq 0 ]; then shred -u "$P_KEY" 2>/dev/null && ok "payload 의 개인키 사본을 덮어쓰기 삭제" || warn "payload 개인키 삭제 실패(수동 삭제 필요)"
  elif [ $LOCAL_KEY -eq 0 ]; then warn "payload 에 개인키 사본이 남아 있음 — 확인 후 삭제 권장:  shred -u $P_KEY   (또는 --wipe-payload-key)"; fi
  backup_prune
  say ""; say "롤백이 필요하면:  ./3_patch_with_cert.sh rollback   (백업: $BK)"
  say "★ 서버 쪽: 새 인증서에 IP SAN 이 포함돼 있다면 서버의 H100_DEVICE_TLS_HOSTNAME_CHECK 를 true 로 되돌릴 수 있음 → MANUAL.md §6"
  summary; [ $FAIL -eq 0 ]
}

do_rollback() {
  local dir=${RB_DIR:-$(latest_backup)}
  [ -n "$dir" ] && [ -d "$dir" ] || die "롤백할 백업이 없습니다"
  say ""; say "롤백 대상 백업: $dir"; sed 's/^[^|]*|\([^|]*\)|.*/   - \1/' "$dir/files.map" | tee -a "$LOG"
  confirm "이 백업으로 되돌릴까요?" || { say "중단"; exit 1; }
  BK=$dir; svc_stop; backup_restore "$dir" || true; svc_start; sleep 4
  health old; served_cert_is "$CRT" || true; baseline_write
  summary; [ $FAIL -eq 0 ]
}

case "$ACTION" in
  gen-csr)  do_gen_csr;;
  check)    installed_preflight; candidate_check; summary; [ $FAIL -eq 0 ];;
  apply)    installed_preflight; candidate_check; do_apply;;
  rollback) do_rollback;;
esac
