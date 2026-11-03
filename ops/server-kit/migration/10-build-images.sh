#!/usr/bin/env bash
# 이미지 빌드 + compose 배치 (신 서버에서 실행). 구 서버/운영 무관.
# 사용: sudo ./10-build-images.sh --src /path/to/-H100ADV- --war /path/to/gov-disabled-web-adv-1.0.0.war [--yes]   # 컨텍스트 경로는 WEB_CONTEXT(기본 gov-disabled-web-adv)
#   --src : 저장소 체크아웃 (h100_module_c/ 포함). 태그는 git 짧은 SHA 로 고정
#   --tag NAME : 이미지 태그 직접 지정 (git 없는 소스용, 예: dev-20261023). 미지정 시 git 짧은 SHA
#   --skip-web : module-c 만 빌드(WAR/G0 불필요, 리허설·VM 시험용)
#   --war : 관리자 PC 에서 mvn package 로 만든 ROOT.war (G0: 구 서버 값 하드코딩 없어야 함)
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"
need_root
SRC=""; WAR=""; SKIPWEB=0; TAGARG=""
while [ $# -gt 0 ]; do case "$1" in
  --src) SRC="$2"; shift 2;; --war) WAR="$2"; shift 2;; --skip-web) SKIPWEB=1; shift;; --tag) TAGARG="$2"; shift 2;; --yes) ASSUME_YES=1; shift;; *) echo "알 수 없는 옵션 $1"; exit 2;; esac; done
[ -d "$SRC/h100_module_c" ] || { echo "--src 에 h100_module_c/ 가 없음"; exit 2; }
[ "$SKIPWEB" -eq 1 ] || [ -f "$WAR" ] || { echo "--war 파일 없음 (module-c 만 빌드하려면 --skip-web)"; exit 2; }

SHA=$(git -C "$SRC" rev-parse --short=8 HEAD 2>/dev/null || echo nogit)
DIRTY=$(git -C "$SRC" status --porcelain 2>/dev/null | wc -l)
TAG="${SHA}"
[ "$DIRTY" -gt 0 ] && { warn "작업본에 미커밋 변경 $DIRTY 건 → 태그에 -dirty 부여"; TAG="${SHA}-dirty"; }
if [ -n "$TAGARG" ]; then TAG="$TAGARG"; info "태그 직접 지정: $TAG (git 정보 없음/무시)"; fi
[ "$SHA" = nogit ] && [ -z "$TAGARG" ] && warn "git 정보 없음 → 태그 nogit. 롤백 구분을 위해 --tag dev-YYYYMMDD 권장"
info "이미지 태그: $TAG  (운영 배포 커밋과 일치 여부는 §8 Q2 로 사람이 확인)"

# G0 게이트: WAR 하드코딩 검사 (--skip-web 이면 건너뜀)
if [ "$SKIPWEB" -eq 1 ]; then warn "--skip-web: web 이미지/G0 검사 생략 (컷오버 전에는 반드시 WAR 포함 전체 빌드로 통과해야 함)"; else
/bin/bash "$(dirname "$(readlink -f "$0")")/00-preflight.sh" --war "$WAR" --no-old >"$WORK/preflight-g0.out" 2>&1
if grep -q '^\[FAIL\] G0' "$WORK/preflight-g0.out"; then
  grep '^\[FAIL\] G0' "$WORK/preflight-g0.out" | while read -r l; do bad "$l"; done
  say "→ Java 외부화(T2) 미완료. module_c/DB 부분만 먼저 진행하려면 --war 대신 임시 WAR 로는 진행하지 말고 중단하세요."
  summary; exit 1
fi
ok "G0 통과"
fi

confirm "이미지 빌드 및 $COMPOSE_DIR 배치" || { say "중단"; exit 1; }
HERE=$(dirname "$(readlink -f "$0")")/..
mkdir -p "$COMPOSE_DIR"
[ "$(readlink -f "$HERE/docker/compose.yml")" = "$(readlink -f "$COMPOSE_DIR/compose.yml")" ] || install -m 644 "$HERE/docker/compose.yml" "$COMPOSE_DIR/compose.yml"
[ -f "$HERE/docker/Dockerfile.module-c" ] && [ -f "$HERE/docker/Dockerfile.web" ] || { bad "Dockerfile 없음: $HERE/docker/ (키트의 docker/* 를 /opt/h100/docker/ 에 복사)"; summary; exit 1; }
cat > "$COMPOSE_DIR/.env" <<EOF
H100_TAG=$TAG
H100_UID=$H100_UID
H100_GID=$H100_GID
H100_EVENT_SCHEDULER=${H100_EVENT_SCHEDULER:-OFF}
EOF
chmod 644 "$COMPOSE_DIR/.env"; ok "compose.yml/.env 배치 (EVENT_SCHEDULER 기본 OFF)"

# module-c
docker build -f "$HERE/docker/Dockerfile.module-c" -t "h100/module-c:$TAG" "$SRC" >>"$LOG" 2>&1 \
  && ok "h100/module-c:$TAG 빌드" || bad "module-c 빌드 실패 (로그 참조)"

# web
if [ "$SKIPWEB" -eq 0 ]; then
B=$(mktemp -d); trap 'rm -rf "$B"' EXIT
cp "$WAR" "$B/app.war"; cp /etc/h100/tls/h100-ca.crt "$B/h100-ca.crt" 2>/dev/null || { bad "/etc/h100/tls/h100-ca.crt 없음"; summary; exit 1; }
docker build -f "$HERE/docker/Dockerfile.web" --build-arg H100_UID="$H100_UID" --build-arg H100_GID="$H100_GID" --build-arg WEB_CONTEXT="$WEB_CONTEXT" \
  -t "h100/web:$TAG" "$B" >>"$LOG" 2>&1 && ok "h100/web:$TAG 빌드" || bad "web 빌드 실패 (로그 참조)"
fi

# 이미지 안에 비밀·개인키가 없는지 간이 점검
for img in module-c $([ "$SKIPWEB" -eq 0 ] && echo web); do
  docker run --rm --entrypoint sh "h100/$img:$TAG" -c 'find / -xdev \( -name "*.key" -o -name "*.pem" -o -name ".env" \) 2>/dev/null | grep -vE "^/(etc/ssl|usr/share/ca-certificates|etc/pki|usr/lib/jvm|usr/local/openjdk)" | head -5' 2>/dev/null | grep -q . \
    && warn "$img 이미지에 키/.env 로 보이는 파일 존재 — 확인" || ok "$img 이미지에 키/.env 파일 없음(간이)"
done
docker image ls --format '{{.Repository}}:{{.Tag}} {{.Size}}' | grep '^h100/' | tee -a "$LOG"
say "이전 이미지 보관(롤백용): 최근 3개 태그를 지우지 마세요."
summary
