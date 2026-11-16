#!/usr/bin/env bash
# =============================================================================
#  [2번] 두 번째 이후 패치 — 바이너리(h100_module_d) 한 개만 교체한다
#        인증서(ssl/)와 .env 는 건드리지 않는다. 교체 전·후 해시를 비교해 확인한다.
#
#   ./2_patch_binary.sh check                  점검만 (아무것도 바꾸지 않음)
#   ./2_patch_binary.sh apply [옵션]           교체 실행 (확인 후 진행, 실패 시 자동 복구)
#   ./2_patch_binary.sh rollback [백업폴더]    직전 백업으로 되돌리기 (생략하면 가장 최근 백업)
#
#   옵션:  --sync-paths   .env 의 경로 키 4개(FILE_PATH, AUDIO_PATH, ROI_FILE_PATH, ROI_SNAPSHOT_DIR)만
#                         h100-device.conf 값으로 맞춘다. (경로 변경 안내가 있을 때만 사용. 비밀값은 건드리지 않음)
#          --paths-only   바이너리는 교체하지 않고 .env 경로 키 4개만 맞춘다 (경로 변경만 있을 때. payload 불필요, --sync-paths 포함)
#          --force        현재 바이너리와 같은 해시여도 다시 교체
#          --no-sums      SHA256SUMS 검증 생략(권장하지 않음)
#          --dry-run      계획만 출력하고 종료
#          --yes          확인 질문 생략
#
#  필요한 payload (키트 폴더의 payload/):  h100_module_d , SHA256SUMS
#  경로·이름은 h100-device.conf 에서만 바꾼다. 이 스크립트는 수정하지 않는다.
# =============================================================================
set -uo pipefail
KIT_DIR=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
# shellcheck source=lib.sh
. "$KIT_DIR/lib.sh"

ACTION=${1:-}; shift || true
SYNC=0; PATHS_ONLY=0; FORCE=0; NO_SUMS=0; DRY=0; RB_DIR=""
if [ "$ACTION" = rollback ] && [ $# -gt 0 ] && [ "${1#--}" = "$1" ]; then RB_DIR=$1; shift; fi
while [ $# -gt 0 ]; do case "$1" in
  --sync-paths) SYNC=1; shift;; --paths-only) PATHS_ONLY=1; SYNC=1; shift;; --force) FORCE=1; shift;; --no-sums) NO_SUMS=1; shift;;
  --dry-run) DRY=1; shift;; --yes) ASSUME_YES=1; shift;;
  *) echo "알 수 없는 옵션: $1"; sed -n '2,24p' "$0"; exit 2;; esac; done
case "$ACTION" in check|apply|rollback) ;; *) sed -n '2,24p' "$0"; exit 2;; esac

load_conf
init_log patch-binary
P_BIN="$PAYLOAD_DIR/$BIN_NAME"
say "== [2번] 바이너리 패치 ($ACTION) $(date '+%F %T') =="
info "장비 시리얼 $DEVICE_SERIAL  /  module_d 폴더 $MODULE_D_DIR"

preflight() {
  installed_preflight
  if [ "$ACTION" != rollback ] && [ $PATHS_ONLY -eq 0 ]; then
    say ""; say "-- 패치 파일(payload)"
    if [ -f "$P_BIN" ]; then
      ok "있음: payload/$BIN_NAME (sha256 $(sha "$P_BIN" | cut -c1-16)…)"
      NO_SUMS=$NO_SUMS payload_verify "$BIN_NAME"; elf_arch_ok "$P_BIN"
      [ "$(sha "$P_BIN")" = "$(sha "$BIN")" ] && { [ $FORCE -eq 1 ] && info "현재와 같은 파일이지만 --force 로 진행" || warn "payload 바이너리가 현재 설치된 것과 동일함 (교체할 필요 없음)"; }
    else bad "없음: payload/$BIN_NAME"; fi
    [ "${PATH_MISMATCH:-0}" -gt 0 ] && [ $SYNC -eq 0 ] && info "경로 불일치가 있으면 안내서(경로 변경)에 따라 --sync-paths 를 함께 쓰세요. 이번에 경로 변경이 없다면 무시해도 됩니다."
  fi
}

do_apply() {
  [ $FAIL -eq 0 ] || die "사전 점검 실패 항목이 있어 패치하지 않습니다. 위 [FAIL] 을 해결한 뒤 다시 실행하세요."
  [ $PATHS_ONLY -eq 1 ] || [ "$(sha "$P_BIN")" != "$(sha "$BIN")" ] || [ $FORCE -eq 1 ] || die "payload 바이너리가 이미 설치된 것과 같습니다 (--force 로 강제 가능)"
  if [ $PATHS_ONLY -eq 1 ]; then say ""; say "계획(--paths-only): 서비스 정지(수 초) → .env 백업 → .env 경로 키 4개 맞춤 → 서비스 시작 → 점검  (바이너리는 교체하지 않음)"
  else say ""; say "계획: 서비스 정지(수 초) → 현재 바이너리 백업 → 새 바이너리 교체(소유·권한 유지) → $( [ $SYNC -eq 1 ] && echo '.env 경로 키 4개 맞춤 → ')서비스 시작 → 점검"; fi
  say "      영상(HLS)·파일 전송이 이 시간 동안 잠시 끊깁니다. 인증서(ssl/)·logs·hls 는 건드리지 않습니다."
  [ $SYNC -eq 1 ] && say "      --sync-paths: .env 의 FILE_PATH / AUDIO_PATH / ROI_FILE_PATH / ROI_SNAPSHOT_DIR 만 바뀝니다 (경로 값, 비밀 아님)."
  [ $DRY -eq 1 ] && { say ""; say "(--dry-run) 계획만 출력했고 아무것도 바꾸지 않았음"; summary; exit 0; }
  confirm "진행할까요?" || { say "중단"; exit 1; }

  local before after owner grp mode
  [ $SYNC -eq 1 ] && before=$(state_snapshot noenv) || before=$(state_snapshot)
  backup_open patch
  [ $PATHS_ONLY -eq 1 ] || backup_file "$BIN" || die "바이너리 백업 실패 — 중단"
  [ $SYNC -eq 1 ] && { backup_file "$ENVF" || die ".env 백업 실패 — 중단"; }
  ok "백업 완료: $BK"
  owner=$(fowner "$BIN"); grp=${owner##*:}; owner=${owner%%:*}; mode=$(fmode "$BIN")

  svc_stop
  if [ $PATHS_ONLY -eq 0 ]; then
    if ! install_file "$P_BIN" "$BIN" "$owner" "$grp" "$mode" || [ "$(sha "$BIN")" != "$(sha "$P_BIN")" ]; then bad "교체 실패/해시 불일치"; restore_all; summary; exit 1; fi
    ok "바이너리 교체 완료 (소유 $owner:$grp, 권한 $mode 유지)"
  fi
  if [ $SYNC -eq 1 ]; then
    for pair in "FILE_PATH:$OUTPUT_DIR" "AUDIO_PATH:$VOICE_DIR" "ROI_FILE_PATH:$ROIS_JSON" "ROI_SNAPSHOT_DIR:$ROI_SNAPSHOT_DIR"; do
      k=${pair%%:*}; v=${pair#*:}; old=$(envval "$k")
      [ "$old" = "$v" ] && continue
      tmp=$(mktemp); rt cat "$ENVF" > "$tmp"; env_set_file "$tmp" "$k" "$v"
      o=$(fowner "$ENVF"); m=$(fmode "$ENVF"); install_file "$tmp" "$ENVF" "${o%%:*}" "${o##*:}" "$m"; rm -f "$tmp"
      ok ".env $k : '${old:-(없음)}' → '$v'"
    done
    for d in "$OUTPUT_DIR" "$IMAGE_DIR" "$VIDEO_DIR" "$VIDEO_ALWAYS_DIR" "$VOICE_DIR" "$ROI_SNAPSHOT_DIR"; do [ -d "$d" ] || { rt mkdir -p "$d" && rt chown "$SERVICE_USER:$SERVICE_GROUP" "$d" && info "폴더 생성: $d"; }; done
  fi
  svc_start; sleep 5
  if [ $PATHS_ONLY -eq 1 ]; then hmode=auto; else hmode=new; fi
  if ! health $hmode; then bad "새 바이너리 확인 실패 → 자동 복구"; restore_all; summary; exit 1; fi
  [ $SYNC -eq 1 ] && after=$(state_snapshot noenv) || after=$(state_snapshot)
  if [ "$before" = "$after" ]; then ok "인증서(ssl/)$( [ $SYNC -eq 0 ] && echo '·.env')가 교체 전후 동일 (SHA256 비교)"
  else bad "교체 전후로 인증서/설정 파일이 달라짐!"; diff <(echo "$before") <(echo "$after") | sed 's/^/        /' | tee -a "$LOG"; restore_all; summary; exit 1; fi
  baseline_compare || warn "인증서 기준 해시와 다름 — 교체 전에도 다른 상태였는지 확인 필요"
  backup_prune
  say ""; say "롤백이 필요하면:  ./2_patch_binary.sh rollback   (백업: $BK)"
  summary; [ $FAIL -eq 0 ]
}

do_rollback() {
  local dir=${RB_DIR:-$(latest_backup)}
  [ -n "$dir" ] && [ -d "$dir" ] || die "롤백할 백업이 없습니다"
  say ""; say "롤백 대상 백업: $dir"; sed 's/^[^|]*|\([^|]*\)|.*/   - \1/' "$dir/files.map" | tee -a "$LOG"
  confirm "이 백업으로 되돌릴까요?" || { say "중단"; exit 1; }
  BK=$dir; svc_stop; backup_restore "$dir" || true; svc_start; sleep 4
  health old; baseline_compare || true
  summary; [ $FAIL -eq 0 ]
}

case "$ACTION" in
  check) preflight; summary; [ $FAIL -eq 0 ];;
  apply) preflight; do_apply;;
  rollback) do_rollback;;
esac
