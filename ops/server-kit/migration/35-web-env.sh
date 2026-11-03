#!/usr/bin/env bash
# /etc/h100/web.env 생성 (Java 웹 컨테이너용). 비밀번호는 /etc/h100/db.env 의 DB_PASS_WEB 에서 읽고 화면·로그에 출력하지 않는다.
# 포함: H100_DB_URL / H100_DB_USER / H100_DB_PASSWORD
# 제외(의도적): H100_AES_KEY(구 서버도 빈 값 → 동일 유지), H100_TRIGGER_TOKEN, H100_ROI_TOKEN, H100_MODULE_C_URL — 이전 후 기능 활성화 때 추가
# 사용: sudo ./35-web-env.sh [--force] [--no-test] [--jdbc-params '옵션']
#   --force : 기존 web.env 에 값이 있어도 백업 후 덮어씀
#   --no-test: 임시 컨테이너로 하는 DB 로그인 시험 생략
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"
need_root
ETC=${H100_ETC:-/etc/h100}
FORCE=0; NOTEST=0
# 구 서버 JDBC URL 옵션과 동일 (host 만 db:3306 컨테이너로 변경). XML 의 &amp; 는 & 로 환원
PARAMS='useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Seoul&tcpKeepAlive=true&connectTimeout=10000&socketTimeout=60000'
while [ $# -gt 0 ]; do case "$1" in
  --force) FORCE=1; shift;; --no-test) NOTEST=1; shift;; --jdbc-params) PARAMS="$2"; shift 2;; *) echo "알 수 없는 옵션 $1"; exit 2;; esac; done

[ -f "$ETC/db.env" ] || { bad "$ETC/db.env 없음"; summary; exit 1; }
PW=$(grep -m1 '^DB_PASS_WEB=' "$ETC/db.env" | cut -d= -f2-)
[ -n "$PW" ] && ok "db.env: DB_PASS_WEB 설정됨(값 비출력)" || { bad "db.env: DB_PASS_WEB 비어 있음"; summary; exit 1; }
# env_file 에서 안전하지 않은 문자: $ ' " \ # 공백 (compose 가 치환/따옴표 처리)
if printf '%s' "$PW" | grep -q "[\$'\"\\\\# ]"; then
  bad "DB_PASS_WEB 에 env_file 에서 위험한 문자($ ' \" \\ # 공백)가 있음 → 영숫자·_-.@%+=: 위주로 교체 필요(db.env, 계정 비밀번호 ALTER USER 포함). 값은 출력하지 않음"
  summary; exit 1
fi
ok "비밀번호 문자 안전성 확인"

URL="jdbc:mariadb://db:3306/able_park?${PARAMS}"
TARGET="$ETC/web.env"
if [ -s "$TARGET" ] && grep -Eq '^[[:space:]]*H100_DB_(URL|USER|PASSWORD)=' "$TARGET"; then
  [ "$FORCE" -eq 1 ] || { bad "$TARGET 에 이미 DB 설정이 있음 → 덮어쓰려면 --force (백업 후 진행)"; summary; exit 1; }
  cp -p "$TARGET" "$WORK/web.env.bak" && chmod 600 "$WORK/web.env.bak" && ok "기존 web.env 백업 → $WORK/web.env.bak"
fi

TMP=$(mktemp "$ETC/.web.env.XXXXXX") || { bad "임시 파일 생성 실패"; summary; exit 1; }
chmod 600 "$TMP"
{
  echo "# /etc/h100/web.env — 생성: 35-web-env.sh ($(date '+%F %T')). 비밀 포함: git/Obsidian 기록 금지"
  echo "H100_DB_URL=$URL"
  echo "H100_DB_USER=h100_web"
  echo "H100_DB_PASSWORD=$PW"
  echo "# H100_AES_KEY / H100_TRIGGER_TOKEN / H100_ROI_TOKEN / H100_MODULE_C_URL : 구 서버도 미설정 → 기능 활성화 때 추가"
} > "$TMP"
if getent group h100 >/dev/null 2>&1; then chown root:h100 "$TMP"; chmod 640 "$TMP"; else warn "h100 그룹 없음 — 권한 600 root 로 둠(h100-deploy.sh --prepare 먼저)"; fi
mv -f "$TMP" "$TARGET" && ok "web.env 생성: $(stat -c '%a %U:%G' "$TARGET")" || { bad "web.env 쓰기 실패"; summary; exit 1; }
say "[INFO] 포함된 키(이름만): $(grep -vE '^[[:space:]]*(#|$)' "$TARGET" | sed -E 's/=.*//' | tr '\n' ' ')"
say "[INFO] JDBC URL: $URL"

# DB 로그인 시험: h100 네트워크의 임시 컨테이너에서 h100_web 으로 접속 (비밀번호는 환경변수로만 전달)
if [ "$NOTEST" -eq 0 ]; then
  if docker network inspect h100 >/dev/null 2>&1 && docker image inspect mariadb:10.11 >/dev/null 2>&1; then
    export MYSQL_PWD="$PW"
    R=$(timeout 60 docker run --rm --network h100 -e MYSQL_PWD mariadb:10.11 mariadb -h db -uh100_web able_park -N -e "SELECT COUNT(*) FROM tbl_device; SELECT COUNT(*) FROM tbl_roi_history" 2>&1 | tr '\n' ' ')
    unset MYSQL_PWD
    echo "$R" | grep -Eq '^[0-9]+ [0-9]+ *$' && ok "h100_web 로 db:3306 접속·조회 성공 (tbl_device, tbl_roi_history 조회: $R)" || bad "h100_web 접속/조회 실패: $(echo "$R" | cut -c1-200)"
  else warn "h100 네트워크 또는 mariadb:10.11 이미지가 없어 접속 시험 생략"; fi
fi
unset PW
summary
