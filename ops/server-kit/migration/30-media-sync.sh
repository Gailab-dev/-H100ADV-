#!/usr/bin/env bash
# 미디어 동기화 (신 서버가 구 서버에서 pull — 구 서버는 읽기만, 삭제/변경 없음)
# 사용: sudo ./30-media-sync.sh --pre | --final | --normalize | --verify  [--yes]
#   --pre       : 사전 rsync (운영 중, 몇 번 반복 가능)
#   --final     : 컷오버 직전 증분 rsync (구 서비스 정지 후)
#   --normalize : 소유자/권한 정규화 (UID:GID=$H100_UID:$H100_GID, 디렉터리 2775 / 파일 664)
#   --verify    : 하위폴더별 파일 수·용량 대조
# 하위폴더 5개 (Go fileReceive.go 와 Java globals.properties 가 같은 이름을 사용)
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"
need_root
SUBS="output_images output_images_enc output_videos output_videos_enc output_audios"
ACTION=""
while [ $# -gt 0 ]; do case "$1" in
  --pre|--final|--normalize|--verify) ACTION="${1#--}"; shift;; --yes) ASSUME_YES=1; shift;; *) echo "알 수 없는 옵션 $1"; exit 2;; esac; done
[ -n "$ACTION" ] || { echo "--pre|--final|--normalize|--verify 중 하나"; exit 2; }
SSH="ssh -p $OLD_SSH_PORT -o ConnectTimeout=8"

normalize() {
  getent group "$H100_GID" >/dev/null || groupadd -g "$H100_GID" h100
  chown -R "$H100_UID:$H100_GID" "$NEW_MEDIA_DIR"
  find "$NEW_MEDIA_DIR" -type d -exec chmod 2775 {} +
  find "$NEW_MEDIA_DIR" -type f -exec chmod 664 {} +
  bad_owner=$(find "$NEW_MEDIA_DIR" ! -user "$H100_UID" 2>/dev/null | wc -l)
  [ "$bad_owner" -eq 0 ] && ok "소유자 정규화 완료 ($H100_UID:$H100_GID)" || bad "소유자 불일치 $bad_owner 개"
}

verify() {
  for s in $SUBS; do
    old=$($SSH "$OLD_USER@$OLD_HOST" "find '$OLD_MEDIA_DIR/$s' -type f 2>/dev/null | wc -l; du -sb '$OLD_MEDIA_DIR/$s' 2>/dev/null | cut -f1" 2>>"$LOG")
    oc=$(echo "$old" | sed -n 1p); ob=$(echo "$old" | sed -n 2p)
    nc=$(find "$NEW_MEDIA_DIR/$s" -type f 2>/dev/null | wc -l)
    if [ "$oc" = "$nc" ]; then ok "$s 파일 수 일치 ($nc)"
    elif [ "$ACTION" = verify ] && [ "${MODE_VERIFY:-final}" = rehearsal ]; then warn "$s 구=$oc 신=$nc (사전 단계: 운영 중이라 차이 가능)"
    else bad "$s 구=$oc 신=$nc"; fi
    info "$s 용량(바이트) 구=${ob:-?}"
  done
}

case "$ACTION" in
  pre|final)
    mkdir -p "$NEW_MEDIA_DIR"
    confirm "$ACTION rsync: $OLD_USER@$OLD_HOST:$OLD_MEDIA_DIR → $NEW_MEDIA_DIR (구 서버 읽기 전용)" || { say "중단"; exit 1; }
    for s in $SUBS; do
      mkdir -p "$NEW_MEDIA_DIR/$s"
      rsync -rlt --partial --no-owner --no-group --info=stats1 --human-readable \
        -e "ssh -p $OLD_SSH_PORT" "$OLD_USER@$OLD_HOST:$OLD_MEDIA_DIR/$s/" "$NEW_MEDIA_DIR/$s/" >>"$LOG" 2>&1 \
        && ok "rsync $s" || bad "rsync 실패 $s (로그 참조)"
    done
    normalize
    [ "$ACTION" = pre ] && MODE_VERIFY=rehearsal || MODE_VERIFY=final
    ACTION=verify; verify;;
  normalize) normalize;;
  verify) MODE_VERIFY=final; verify;;
esac
df -h "$NEW_MEDIA_DIR" | tail -1 | sed 's/^/[INFO] /' | tee -a "$LOG"
summary
