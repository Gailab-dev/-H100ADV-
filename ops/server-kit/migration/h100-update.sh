#!/usr/bin/env bash
# 소스 변경분 이미지 재배포 키트 (신 서버/개발서버에서 실행)
#   이미지 빌드(module-c + web) → 컨테이너 교체(h100-deploy.sh --all) → 검증(h100-verify.sh)
#   DB 컨테이너·데이터는 건드리지 않는다. 최초 설치·DB 복원·미디어 동기화는 이 스크립트의 범위가 아니다(런북 참고).
# 사용:
#   sudo ./h100-update.sh --war /path/to/app.war [--src /opt/h100/repo] [--tag NAME] [--yes]
#   sudo ./h100-update.sh --rollback-to <이전태그> [--yes]     (이전 이미지 태그로 되돌림, DB 유지)
#   sudo ./h100-update.sh --status                               (현재 태그·실행 이미지·보유 태그·최근 이력, 변경 없음)
# 사전: gailab-si 로 `git pull --ff-only` 를 끝낸 상태(이 스크립트는 git pull 을 하지 않는다).
#       WAR 는 관리자 PC 에서 같은 커밋으로 mvn package 한 결과를 서버로 복사해 둘 것.
set -uo pipefail
HERE=$(dirname "$(readlink -f "$0")")
. "$HERE/lib.sh"
need_root
export STAMP WORK   # 하위 스크립트(빌드/배포/검증)의 로그를 같은 폴더에 모은다

SRC=/opt/h100/repo; WAR=""; TAGARG=""; ROLLBACK=""; STATUS=0
TAGRE='^[A-Za-z0-9][A-Za-z0-9._-]*$'
need_val() { [ "$1" -ge 2 ] || { echo "옵션 값이 없습니다"; exit 2; }; }
while [ $# -gt 0 ]; do case "$1" in
  --src) need_val $#; SRC="$2"; shift 2;;
  --war) need_val $#; WAR="$2"; shift 2;;
  --tag) need_val $#; TAGARG="$2"; shift 2;;
  --rollback-to) need_val $#; ROLLBACK="$2"; shift 2;;
  --status) STATUS=1; shift;;
  --yes) ASSUME_YES=1; shift;;
  *) echo "알 수 없는 옵션 $1"; exit 2;; esac; done

ENVF="$COMPOSE_DIR/.env"
HIST="$COMPOSE_DIR/deploy-history.log"   # 반영 이력(커밋·태그·결과, 비밀 없음)
cur_tag() { grep -E '^H100_TAG=' "$ENVF" 2>/dev/null | head -1 | cut -d= -f2-; }
hist() { printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$HIST" 2>/dev/null; }
g() { git -c safe.directory="$SRC" -C "$SRC" "$@"; }   # root 로 gailab-si 소유 저장소를 읽을 때 dubious ownership 방지

# ---- 상태 보기 ----
if [ "$STATUS" -eq 1 ]; then
  say "현재 H100_TAG: $(cur_tag)"
  say "실행 중 컨테이너:"; docker ps --filter name=h100- --format '  {{.Names}}  {{.Image}}  {{.Status}}'
  say "보유 이미지(h100/*):"; docker image ls --format '  {{.Repository}}:{{.Tag}}  {{.CreatedSince}}  {{.Size}}' | grep '^  h100/'
  say "최근 반영 이력:"; tail -n 8 "$HIST" 2>/dev/null | sed 's/^/  /'
  exit 0
fi

[ -f "$ENVF" ] || { echo "$ENVF 없음 — 최초 설치는 런북 절차(10-build-images.sh → h100-deploy.sh)로 먼저 진행"; exit 2; }
PREV_TAG=$(cur_tag)

# ---- 이전 태그로 되돌리기 ----
if [ -n "$ROLLBACK" ]; then
  [[ "$ROLLBACK" =~ $TAGRE ]] || { bad "태그 형식 오류: $ROLLBACK"; summary; exit 1; }
  for r in module-c web; do
    docker image inspect "h100/$r:$ROLLBACK" >/dev/null 2>&1 || { bad "이미지 없음: h100/$r:$ROLLBACK ( --status 로 보유 태그 확인)"; summary; exit 1; }
  done
  confirm "이미지 태그 $PREV_TAG → $ROLLBACK 로 되돌려 module-c, web 컨테이너 교체 (DB 유지)" || { say "중단"; exit 1; }
  cp -p "$ENVF" "$ENVF.bak-$STAMP"
  sed -i "s/^H100_TAG=.*/H100_TAG=$ROLLBACK/" "$ENVF" && ok "H100_TAG=$ROLLBACK (백업 $ENVF.bak-$STAMP)" || { bad ".env 수정 실패"; summary; exit 1; }
  bash "$HERE/h100-deploy.sh" --all --yes && ok "컨테이너 교체" || bad "컨테이너 교체 실패 (docker logs h100-module-c / h100-web)"
  bash "$HERE/h100-verify.sh" && ok "검증 통과" || bad "검증 실패 (로그: $WORK)"
  [ "$N_FAIL" -eq 0 ] && R=PASS || R=FAIL
  hist "rollback from=$PREV_TAG to=$ROLLBACK result=$R"
  summary; exit $?
fi

# ---- 이미지 재배포 ----
[ -d "$SRC/h100_module_c" ] || { echo "--src($SRC)에 h100_module_c/ 가 없음"; exit 2; }
[ -n "$WAR" ] && [ -f "$WAR" ] || { echo "--war 파일이 필요합니다(관리자 PC mvn package 결과). 예: --war /opt/h100/war/gov-disabled-web-adv-1.0.0.war"; exit 2; }
[ -z "$TAGARG" ] || [[ "$TAGARG" =~ $TAGRE ]] || { echo "--tag 형식 오류: $TAGARG"; exit 2; }

SHA=$(g rev-parse --short=8 HEAD 2>/dev/null) || SHA=""
if [ -z "$SHA" ]; then
  [ -n "$TAGARG" ] || { bad "git 정보를 읽지 못함(--src 확인) → --tag 로 태그를 직접 지정"; summary; exit 1; }
  SHA=nogit
fi
BRANCH=$(g rev-parse --abbrev-ref HEAD 2>/dev/null || echo "-")
SUBJ=$(g log -1 --format='%s' 2>/dev/null | cut -c1-70)
DIRTY=$(g status --porcelain 2>/dev/null | wc -l)
TAG="${TAGARG:-$SHA}"
if [ "$DIRTY" -gt 0 ]; then
  warn "서버 작업본($SRC)에 미커밋 변경 $DIRTY 건 — 서버에서 소스를 수정하지 않는 것이 원칙"
  [ -n "$TAGARG" ] || TAG="${SHA}-dirty"
fi
# 같은 태그 이미지가 이미 있으면 덮어쓰지 않도록 접미사(같은 커밋에서 WAR 만 다시 빌드한 경우 등)
if docker image inspect "h100/module-c:$TAG" >/dev/null 2>&1 || docker image inspect "h100/web:$TAG" >/dev/null 2>&1; then
  NEWTAG="${TAG}-$(date +%m%d%H%M)"; warn "태그 $TAG 이미지가 이미 있음 → $NEWTAG 로 빌드(기존 이미지 보존)"; TAG="$NEWTAG"
fi
PREV_SCHED=$(grep -E '^H100_EVENT_SCHEDULER=' "$ENVF" | head -1 | cut -d= -f2-); PREV_SCHED=${PREV_SCHED:-OFF}

say "== 이미지 재배포 계획 =="
say "  소스      : $SRC  ($BRANCH @ $SHA)  $SUBJ"
say "  WAR       : $WAR ($(stat -c %s "$WAR" 2>/dev/null) bytes, $(date -r "$WAR" '+%F %T' 2>/dev/null))"
say "  새 태그   : $TAG   (이전 태그: ${PREV_TAG:-없음} → 롤백 가능)"
say "  교체 대상 : h100-module-c, h100-web   (h100-db 유지, event_scheduler=$PREV_SCHED 유지)"
say "  ※ 이 스크립트는 DB 를 변경하지 않는다. 이번 반영에 DB 스키마 변경이 있으면 먼저 25-db-migrate.sh (백업 후)"
confirm "위 내용으로 이미지 빌드 후 컨테이너 교체" || { say "중단"; exit 1; }

cp -p "$ENVF" "$ENVF.bak-$STAMP"   # 빌드가 실패해도 이전 태그를 잃지 않도록 .env 백업

# 1) 빌드 (태그는 직접 지정: root 가 gailab-si 소유 저장소의 git 정보를 못 읽어 'nogit' 이 되는 문제 방지)
H100_EVENT_SCHEDULER="$PREV_SCHED" bash "$HERE/10-build-images.sh" --src "$SRC" --war "$WAR" --tag "$TAG" --yes
BRC=$?
BUILT=1
for r in module-c web; do docker image inspect "h100/$r:$TAG" >/dev/null 2>&1 || BUILT=0; done
if [ "$BRC" -ne 0 ] || [ "$BUILT" -ne 1 ]; then
  cp -p "$ENVF.bak-$STAMP" "$ENVF"
  bad "이미지 빌드 실패 — .env 를 이전 상태로 복원했고 기존 컨테이너는 변경되지 않았습니다 (로그: $WORK)"
  hist "update sha=$SHA tag=$TAG prev=${PREV_TAG:-none} result=BUILD_FAIL"
  summary; exit 1
fi
ok "이미지 빌드 h100/module-c:$TAG, h100/web:$TAG"

# 2) 컨테이너 교체
if ! bash "$HERE/h100-deploy.sh" --all --yes; then
  bad "컨테이너 교체 실패 (docker logs h100-module-c / h100-web)"
  [ -n "$PREV_TAG" ] && say "→ 되돌리기: sudo $0 --rollback-to $PREV_TAG"
  hist "update sha=$SHA tag=$TAG prev=${PREV_TAG:-none} result=DEPLOY_FAIL"
  summary; exit 1
fi
ok "컨테이너 교체 (module-c, web)"

# 3) 검증
if bash "$HERE/h100-verify.sh"; then ok "검증 통과"; R=PASS
else bad "검증 실패 (로그: $WORK)"; [ -n "$PREV_TAG" ] && say "→ 되돌리기: sudo $0 --rollback-to $PREV_TAG"; R=VERIFY_FAIL; fi
hist "update sha=$SHA tag=$TAG prev=${PREV_TAG:-none} dirty=$DIRTY result=$R"
say "이전 이미지는 지우지 마세요(최근 3개 태그 보존). 보유 태그: sudo $0 --status"
summary
