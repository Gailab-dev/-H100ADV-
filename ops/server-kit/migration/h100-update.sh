#!/usr/bin/env bash
# H100 이미지 빌드 → 컨테이너 교체 → 검증 → 롤백 (신 서버/개발서버). 소스 변경분을 서버에 반영하는 단일 진입점.
# (구 이름: 10-build-images.sh 를 이 스크립트로 통합 — 2026-11-03)
#   WAR 검사(G0) → 이미지 빌드(module-c + web) → 컨테이너 교체(h100-deploy.sh --all) → 검증(h100-verify.sh)
#   DB 컨테이너·데이터는 건드리지 않는다. DB 복원·미디어 동기화는 이 스크립트의 범위가 아니다(런북).
# 사용:
#   sudo ./h100-update.sh --war FILE [--src /opt/h100/repo] [--tag NAME] [--yes]   # 빌드 + 교체 + 검증
#   sudo ./h100-update.sh --war FILE --build-only [--tag NAME] [--yes]              # 이미지만 빌드(최초 설치·리허설), 컨테이너 교체 없음
#   sudo ./h100-update.sh --rollback-to <태그> [--yes]                              # 이미 보유한 이미지 태그로 되돌림(DB 유지)
#   sudo ./h100-update.sh --status                                                  # 현재 태그·실행 이미지·보유 태그·최근 이력(변경 없음)
# 옵션:
#   --src DIR   저장소 체크아웃(h100_module_c/ 포함). 기본 /opt/h100/repo. 이미지 태그 = git 짧은 SHA(+미커밋 시 -dirty)
#   --tag NAME  이미지 태그 직접 지정(git 정보가 없는 소스용). 같은 태그가 이미 있으면 -MMDDHHMM 을 덧붙여 기존 이미지를 보존
#   --skip-g0   WAR 하드코딩 검사 생략(비상용)
# 사전: gailab-si 로 `git pull --ff-only` 를 끝낸 상태(이 스크립트는 git pull 을 하지 않는다).
#       WAR 는 관리자 PC 에서 같은 커밋으로 mvn package 한 결과를 서버로 복사해 둘 것.
#       이번 반영에 DB 스키마 변경이 있으면 이 스크립트 실행 전에 별도로 반영(이 스크립트는 DB 를 변경하지 않음).
set -uo pipefail
HERE=$(dirname "$(readlink -f "$0")")
. "$HERE/lib.sh"
need_root
export STAMP WORK   # 하위 스크립트(배포/검증)의 로그를 같은 폴더에 모은다
KIT=$(readlink -f "$HERE/..")   # 키트 루트(migration/ 과 docker/ 의 부모): /opt/h100 또는 저장소의 ops/server-kit

SRC=/opt/h100/repo; WAR=""; TAGARG=""; ROLLBACK=""; STATUS=0; BUILD_ONLY=0; SKIP_G0=0
TAGRE='^[A-Za-z0-9][A-Za-z0-9._-]*$'
while [ $# -gt 0 ]; do case "$1" in
  --src) need_val $#; SRC="$2"; shift 2;;
  --war) need_val $#; WAR="$2"; shift 2;;
  --tag) need_val $#; TAGARG="$2"; shift 2;;
  --rollback-to) need_val $#; ROLLBACK="$2"; shift 2;;
  --build-only) BUILD_ONLY=1; shift;;
  --skip-g0) SKIP_G0=1; shift;;
  --status) STATUS=1; shift;;
  --yes) ASSUME_YES=1; shift;;
  *) echo "알 수 없는 옵션 $1 (사용법: 파일 머리말)"; exit 2;; esac; done

ENVF="$COMPOSE_DIR/.env"
HIST="$COMPOSE_DIR/deploy-history.log"   # 반영 이력(커밋·태그·결과, 비밀 없음)
cur_tag() { grep -E '^H100_TAG=' "$ENVF" 2>/dev/null | head -1 | cut -d= -f2-; }
hist() { printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$HIST" 2>/dev/null; }
g() { git -c safe.directory="$SRC" -C "$SRC" "$@"; }   # root 로 gailab-si 소유 저장소를 읽을 때 dubious ownership 방지
img_ok() { docker image inspect "h100/$1:$2" >/dev/null 2>&1; }

# G0 게이트: WAR 에 구 서버 값이 하드코딩돼 있으면 중단(구 00-preflight.sh 의 G0). 검사 대상 파일을 못 읽으면 통과시키지 않는다.
check_war_g0() {
  local tmp rc=0 rcx gp
  tmp=$(mktemp -d)
  if command -v unzip >/dev/null 2>&1; then
    unzip -qq -o "$1" 'WEB-INF/spring/root-context.xml' 'WEB-INF/classes/globals.properties' -d "$tmp" 2>/dev/null
  else
    python3 -I -c 'import sys,zipfile
z=zipfile.ZipFile(sys.argv[1]); nm=set(z.namelist())
for n in ("WEB-INF/spring/root-context.xml","WEB-INF/classes/globals.properties"):
    if n in nm: z.extract(n, sys.argv[2])' "$1" "$tmp" 2>/dev/null
  fi
  rcx="$tmp/WEB-INF/spring/root-context.xml"; gp="$tmp/WEB-INF/classes/globals.properties"
  if [ ! -f "$rcx" ] || [ ! -f "$gp" ]; then
    bad "G0: WAR 에서 root-context.xml / globals.properties 를 읽지 못함(WAR 손상 또는 구조 변경) → 검사 불가. 확인 후 재시도(비상 시 --skip-g0)"
    rm -rf "$tmp"; return 1
  fi
  if grep -Eq '192\.168\.0\.15|/home/dsic' "$rcx" "$gp"; then
    bad "G0: WAR 에 구 서버 값(192.168.0.15 또는 /home/dsic)이 하드코딩됨 → 외부화 후 WAR 재빌드 필요"; rc=1
  else ok "G0: WAR 에 구 서버 IP·/home/dsic 하드코딩 없음"; fi
  grep -Eq '\$\{H100_DB_URL' "$rcx" && ok "G0: DB 접속이 H100_DB_URL 로 외부화됨" || warn "G0: root-context.xml 에서 \${H100_DB_URL} 미확인"
  rm -rf "$tmp"; return $rc
}

# 이미지 빌드(module-c + web). .env·기존 컨테이너는 건드리지 않는다. 성공 0.
build_images() {   # 사용: build_images TAG   (전역: SRC WAR KIT)
  local tag="$1" rc=0 b img
  [ -f "$KIT/docker/Dockerfile.module-c" ] && [ -f "$KIT/docker/Dockerfile.web" ] || { bad "Dockerfile 없음: $KIT/docker/ (키트의 docker/* 를 /opt/h100/docker/ 에 설치)"; return 1; }
  [ -f /etc/h100/tls/h100-ca.crt ] || { bad "/etc/h100/tls/h100-ca.crt 없음"; return 1; }
  docker build -f "$KIT/docker/Dockerfile.module-c" -t "h100/module-c:$tag" "$SRC" >"$WORK/build-module-c.log" 2>&1 \
    && ok "h100/module-c:$tag 빌드" || { bad "module-c 빌드 실패 — 마지막 줄($WORK/build-module-c.log):"; tail -n 12 "$WORK/build-module-c.log" | sed 's/^/    /'; rc=1; }
  b=$(mktemp -d)
  cp "$WAR" "$b/app.war" && cp /etc/h100/tls/h100-ca.crt "$b/h100-ca.crt"
  docker build -f "$KIT/docker/Dockerfile.web" --build-arg H100_UID="$H100_UID" --build-arg H100_GID="$H100_GID" --build-arg WEB_CONTEXT="$WEB_CONTEXT" \
    -t "h100/web:$tag" "$b" >"$WORK/build-web.log" 2>&1 \
    && ok "h100/web:$tag 빌드" || { bad "web 빌드 실패 — 마지막 줄($WORK/build-web.log):"; tail -n 12 "$WORK/build-web.log" | sed 's/^/    /'; rc=1; }
  rm -rf "$b"
  # 이미지 안에 비밀·개인키가 없는지 간이 점검
  for img in module-c web; do
    img_ok "$img" "$tag" || continue
    docker run --rm --entrypoint sh "h100/$img:$tag" -c 'find / -xdev \( -name "*.key" -o -name "*.pem" -o -name ".env" \) 2>/dev/null | grep -vE "^/(etc/ssl|usr/share/ca-certificates|etc/pki|usr/lib/jvm|usr/local/openjdk)" | head -5' 2>/dev/null | grep -q . \
      && warn "$img 이미지에 키/.env 로 보이는 파일 존재 — 확인" || ok "$img 이미지에 키/.env 파일 없음(간이)"
  done
  docker image ls --format '{{.Repository}}:{{.Tag}} {{.Size}}' | grep '^h100/' | tee -a "$LOG"
  return $rc
}

# compose.yml 확인(없을 때만 설치) + .env 작성(빌드 성공 후에만 호출)
write_env() {   # 사용: write_env TAG
  mkdir -p "$COMPOSE_DIR"
  # compose.yml: 서버에 이미 있으면 절대 덮어쓰지 않는다(서버에서 고친 설정 보호). 최초 설치(서버에 없음)일 때만 키트본을 설치.
  if [ ! -f "$COMPOSE_DIR/compose.yml" ]; then
    [ -f "$KIT/docker/compose.yml" ] || { bad "compose.yml 없음 ($KIT/docker, $COMPOSE_DIR)"; return 1; }
    install -m 644 "$KIT/docker/compose.yml" "$COMPOSE_DIR/compose.yml" && ok "compose.yml 최초 설치(키트본)" || { bad "compose.yml 설치 실패"; return 1; }
  elif [ -f "$KIT/docker/compose.yml" ] && ! cmp -s "$KIT/docker/compose.yml" "$COMPOSE_DIR/compose.yml"; then
    warn "키트 compose.yml 과 서버 compose.yml 이 다름 → 서버 파일을 그대로 사용(덮어쓰지 않음). 차이 확인: diff -u $COMPOSE_DIR/compose.yml $KIT/docker/compose.yml"
  fi
  cat > "$ENVF" <<EOF
H100_TAG=$1
H100_UID=$H100_UID
H100_GID=$H100_GID
H100_EVENT_SCHEDULER=$PREV_SCHED
EOF
  chmod 644 "$ENVF"; ok ".env 작성 (H100_TAG=$1, EVENT_SCHEDULER=$PREV_SCHED)"
}

# ---- 상태 보기 ----
if [ "$STATUS" -eq 1 ]; then
  say "현재 H100_TAG: $(cur_tag)"
  say "실행 중 컨테이너:"; docker ps --filter name=h100- --format '  {{.Names}}  {{.Image}}  {{.Status}}'
  say "보유 이미지(h100/*):"; docker image ls --format '  {{.Repository}}:{{.Tag}}  {{.CreatedSince}}  {{.Size}}' | grep '^  h100/'
  say "최근 반영 이력:"; tail -n 8 "$HIST" 2>/dev/null | sed 's/^/  /'
  exit 0
fi

HAD_ENV=0; [ -f "$ENVF" ] && HAD_ENV=1
PREV_TAG=$(cur_tag)

# ---- 이전 태그로 되돌리기 ----
if [ -n "$ROLLBACK" ]; then
  [ "$HAD_ENV" -eq 1 ] || { echo "$ENVF 없음 — 아직 설치되지 않은 서버입니다"; exit 2; }
  [[ "$ROLLBACK" =~ $TAGRE ]] || { bad "태그 형식 오류: $ROLLBACK"; summary; exit 1; }
  for r in module-c web; do
    img_ok "$r" "$ROLLBACK" || { bad "이미지 없음: h100/$r:$ROLLBACK ( --status 로 보유 태그 확인)"; summary; exit 1; }
  done
  confirm "이미지 태그 $PREV_TAG → $ROLLBACK 로 전환해 module-c, web 컨테이너 교체 (DB 유지)" || { say "중단"; exit 1; }
  cp -p "$ENVF" "$ENVF.bak-$STAMP"
  sed -i "s/^H100_TAG=.*/H100_TAG=$ROLLBACK/" "$ENVF" && ok "H100_TAG=$ROLLBACK (백업 $ENVF.bak-$STAMP)" || { bad ".env 수정 실패"; summary; exit 1; }
  bash "$HERE/h100-deploy.sh" --all --yes && ok "컨테이너 교체" || bad "컨테이너 교체 실패 (docker logs h100-module-c / h100-web)"
  bash "$HERE/h100-verify.sh" && ok "검증 통과" || bad "검증 실패 (로그: $WORK)"
  [ "$N_FAIL" -eq 0 ] && R=PASS || R=FAIL
  hist "rollback from=${PREV_TAG:-none} to=$ROLLBACK result=$R"
  summary; exit $?
fi

# ---- 빌드 + 교체 + 검증 ----
[ -d "$SRC/h100_module_c" ] || { echo "--src($SRC)에 h100_module_c/ 가 없음"; exit 2; }
[ -n "$WAR" ] && [ -f "$WAR" ] || { echo "--war 파일이 필요합니다(관리자 PC mvn package 결과). 예: --war /opt/h100/war/gov-disabled-web-adv-1.0.0.war"; exit 2; }
WAR=$(readlink -f "$WAR")
[ -z "$TAGARG" ] || [[ "$TAGARG" =~ $TAGRE ]] || { echo "--tag 형식 오류: $TAGARG"; exit 2; }
[ "$HAD_ENV" -eq 1 ] || [ "$BUILD_ONLY" -eq 1 ] || { echo "$ENVF 없음 — 최초 설치입니다: --build-only 로 이미지를 만든 뒤 h100-deploy.sh 로 기동(런북 절차)"; exit 2; }

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
if img_ok module-c "$TAG" || img_ok web "$TAG"; then
  NEWTAG="${TAG}-$(date +%m%d%H%M)"; warn "태그 $TAG 이미지가 이미 있음 → $NEWTAG 로 빌드(기존 이미지 보존)"; TAG="$NEWTAG"
fi
PREV_SCHED=$(grep -E '^H100_EVENT_SCHEDULER=' "$ENVF" 2>/dev/null | head -1 | cut -d= -f2-); PREV_SCHED=${PREV_SCHED:-OFF}

if [ "$SKIP_G0" -eq 1 ]; then warn "--skip-g0: WAR 하드코딩 검사 생략 (컷오버 전에는 반드시 통과해야 함)"
else check_war_g0 "$WAR" || { say "→ WAR 를 수정해 다시 빌드하세요. 이 상태로는 이미지를 만들지 않습니다."; summary; exit 1; }; fi

if [ "$BUILD_ONLY" -eq 1 ]; then say "== 이미지 빌드 계획 =="; else say "== 이미지 재배포 계획 =="; fi
say "  소스      : $SRC  ($BRANCH @ $SHA)  $SUBJ"
say "  WAR       : $WAR ($(stat -c %s "$WAR" 2>/dev/null) bytes, $(date -r "$WAR" '+%F %T' 2>/dev/null))"
say "  새 태그   : $TAG   (이전 태그: ${PREV_TAG:-없음})"
if [ "$BUILD_ONLY" -eq 1 ]; then say "  동작      : 이미지 빌드만 수행(컨테이너 교체 없음)"
else say "  교체 대상 : h100-module-c, h100-web   (h100-db 유지, event_scheduler=$PREV_SCHED 유지, 롤백: --rollback-to ${PREV_TAG:-이전태그})"; fi
say "  ※ 이 스크립트는 DB 를 변경하지 않는다. 이번 반영에 DB 스키마 변경(신규 테이블·컬럼 등)이 있으면 먼저 별도로 반영(백업 후)"
confirm "위 내용으로 진행" || { say "중단"; exit 1; }

# 1) 빌드 (.env·기존 컨테이너는 아직 변경하지 않는다 → 실패해도 서비스 영향 없음)
BUILT=1; build_images "$TAG" || BUILT=0
for r in module-c web; do img_ok "$r" "$TAG" || BUILT=0; done
if [ "$BUILT" -ne 1 ]; then
  bad "이미지 빌드 실패 — .env 와 기존 컨테이너는 변경되지 않았습니다 (로그: $WORK)"
  hist "update sha=$SHA tag=$TAG prev=${PREV_TAG:-none} result=BUILD_FAIL"
  summary; exit 1
fi
ok "이미지 빌드 h100/module-c:$TAG, h100/web:$TAG"

if [ "$BUILD_ONLY" -eq 1 ] && [ "$HAD_ENV" -eq 1 ]; then   # 이미 설치된 서버: .env 는 그대로 두고 이미지만 보관
  hist "build-only sha=$SHA tag=$TAG prev=${PREV_TAG:-none} result=PASS"
  say "이미지만 생성했습니다(적용 안 함). 이 태그로 전환하려면: sudo $0 --rollback-to $TAG"
  summary; exit $?
fi

# 2) .env 갱신(이전 .env 백업) 후 컨테이너 교체
[ "$HAD_ENV" -eq 1 ] && cp -p "$ENVF" "$ENVF.bak-$STAMP"
write_env "$TAG" || { summary; exit 1; }
if [ "$BUILD_ONLY" -eq 1 ]; then   # 최초 설치: 이미지·compose.yml/.env 까지만
  hist "build-only sha=$SHA tag=$TAG prev=none result=PASS"
  say "다음 단계(런북): sudo ./h100-deploy.sh --db-only → DB 복원 → sudo ./h100-deploy.sh --all → sudo ./h100-verify.sh"
  summary; exit $?
fi
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
