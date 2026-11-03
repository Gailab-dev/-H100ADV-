#!/usr/bin/env bash
# /etc/h100/web.env (Java 웹 컨테이너 환경파일) 생성·관리. 비밀값은 화면·로그·명령행에 노출하지 않는다.
# (구 이름: 35-web-env.sh — 2026-11-03 이름 변경, 키 추가/목록 기능과 기존 키 보존 동작 추가)
# 사용:
#   sudo ./h100-web-env.sh [--force] [--no-test] [--jdbc-params '옵션']   # DB 접속 3종(H100_DB_URL/USER/PASSWORD) 생성
#   sudo ./h100-web-env.sh --set H100_WEATHER_KEY                          # 키 1개 추가/교체(값은 숨김 입력, 다른 키는 유지)
#   sudo ./h100-web-env.sh --list                                          # 등록된 키 이름만 출력(값 비출력)
#   --force   : 기존 web.env 에 DB 설정이 있어도 백업 후 DB 3종만 다시 씀(그 외 키는 유지)
#   --no-test : 임시 컨테이너로 하는 DB 로그인 시험 생략
# 비밀번호는 /etc/h100/db.env 의 DB_PASS_WEB 에서 읽는다.
# 생성하지 않는 키(필요할 때 --set 으로 추가): H100_AES_KEY(구 서버도 빈 값 → 동일 유지), H100_TRIGGER_TOKEN, H100_ROI_TOKEN, H100_MODULE_C_URL,
#   H100_WEATHER_KEY, H100_PUBLICDATA_KEY 등
# 주의: web.env 는 컨테이너 생성 시점에 읽힌다 → 변경 후 web 컨테이너를 재생성해야 적용된다(안내 출력).
set -uo pipefail
HERE=$(dirname "$(readlink -f "$0")")
. "$HERE/lib.sh"
need_root
ETC=${H100_ETC:-/etc/h100}
TARGET="$ETC/web.env"
FORCE=0; NOTEST=0; SETKEY=""; LIST=0
# 구 서버 JDBC URL 옵션과 동일 (host 만 db:3306 컨테이너로 변경). XML 의 &amp; 는 & 로 환원
PARAMS='useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Seoul&tcpKeepAlive=true&connectTimeout=10000&socketTimeout=60000'
while [ $# -gt 0 ]; do case "$1" in
  --force) FORCE=1; shift;; --no-test) NOTEST=1; shift;; --list) LIST=1; shift;;
  --set) need_val $#; SETKEY="$2"; shift 2;;
  --jdbc-params) need_val $#; PARAMS="$2"; shift 2;;
  *) echo "알 수 없는 옵션 $1 (사용법: 파일 머리말)"; exit 2;; esac; done

# env_file 에서 안전하지 않은 문자: $ ' " \ # 공백 (compose 가 치환/따옴표 처리)
unsafe_val() { printf '%s' "$1" | grep -q "[\$'\"\\\\# ]"; }
RECREATE_HINT="적용하려면 web 컨테이너 재생성: sudo $COMPOSE up -d --force-recreate web"

# ---- 키 목록 ----
if [ "$LIST" -eq 1 ]; then
  [ -f "$TARGET" ] || { bad "$TARGET 없음"; summary; exit 1; }
  say "[INFO] $TARGET ($(stat -c '%a %U:%G' "$TARGET")) 등록된 키(이름만): $(grep -vE '^[[:space:]]*(#|$)' "$TARGET" | sed -E 's/=.*//' | tr '\n' ' ')"
  summary; exit $?
fi

# ---- 키 1개 추가/교체 ----
if [ -n "$SETKEY" ]; then
  [[ "$SETKEY" =~ ^H100_[A-Z0-9_]+$ ]] || { bad "키 이름 형식 오류(H100_ 로 시작, 대문자·숫자·_): $SETKEY"; summary; exit 1; }
  [ -f "$TARGET" ] || { bad "$TARGET 없음 — 먼저 옵션 없이 실행해 DB 설정부터 생성"; summary; exit 1; }
  if [ -t 0 ]; then read -rs -p "$SETKEY 값(입력은 화면에 표시되지 않음): " VAL; echo; else IFS= read -r VAL; fi
  [ -n "$VAL" ] || { bad "빈 값은 설정하지 않음"; summary; exit 1; }
  if unsafe_val "$VAL"; then bad "값에 env_file 에서 위험한 문자($ ' \" \\ # 공백)가 있음 — 값은 출력하지 않음"; unset VAL; summary; exit 1; fi
  TMP=$(mktemp "$ETC/.web.env.XXXXXX") || { bad "임시 파일 생성 실패"; summary; exit 1; }
  chmod 600 "$TMP"
  cp -p "$TARGET" "$WORK/web.env.bak" && chmod 600 "$WORK/web.env.bak" && ok "기존 web.env 백업 → $WORK/web.env.bak"
  EXISTED=0; grep -Eq "^[[:space:]]*$SETKEY=" "$TARGET" && EXISTED=1
  { grep -vE "^[[:space:]]*$SETKEY=" "$TARGET"; printf '%s=%s\n' "$SETKEY" "$VAL"; } > "$TMP"
  unset VAL
  chown --reference="$TARGET" "$TMP" 2>/dev/null; chmod --reference="$TARGET" "$TMP" 2>/dev/null
  mv -f "$TMP" "$TARGET" && ok "$SETKEY $([ "$EXISTED" -eq 1 ] && echo 교체 || echo 추가) 완료(값 비출력, 권한 $(stat -c '%a %U:%G' "$TARGET"))" || { bad "web.env 쓰기 실패"; summary; exit 1; }
  say "[INFO] 현재 키(이름만): $(grep -vE '^[[:space:]]*(#|$)' "$TARGET" | sed -E 's/=.*//' | tr '\n' ' ')"
  say "[INFO] $RECREATE_HINT"
  summary; exit $?
fi

# ---- DB 접속 3종 생성 ----
[ -f "$ETC/db.env" ] || { bad "$ETC/db.env 없음"; summary; exit 1; }
PW=$(grep -m1 '^DB_PASS_WEB=' "$ETC/db.env" | cut -d= -f2-)
[ -n "$PW" ] && ok "db.env: DB_PASS_WEB 설정됨(값 비출력)" || { bad "db.env: DB_PASS_WEB 비어 있음"; summary; exit 1; }
if unsafe_val "$PW"; then
  bad "DB_PASS_WEB 에 env_file 에서 위험한 문자($ ' \" \\ # 공백)가 있음 → 영숫자·_-.@%+=: 위주로 교체 필요(db.env, 계정 비밀번호 ALTER USER 포함). 값은 출력하지 않음"
  summary; exit 1
fi
ok "비밀번호 문자 안전성 확인"

URL="jdbc:mariadb://db:3306/able_park?${PARAMS}"
if [ -s "$TARGET" ] && grep -Eq '^[[:space:]]*H100_DB_(URL|USER|PASSWORD)=' "$TARGET"; then
  [ "$FORCE" -eq 1 ] || { bad "$TARGET 에 이미 DB 설정이 있음 → 다시 쓰려면 --force (백업 후 DB 3종만 교체, 다른 키 유지)"; summary; exit 1; }
  cp -p "$TARGET" "$WORK/web.env.bak" && chmod 600 "$WORK/web.env.bak" && ok "기존 web.env 백업 → $WORK/web.env.bak"
fi

TMP=$(mktemp "$ETC/.web.env.XXXXXX") || { bad "임시 파일 생성 실패"; summary; exit 1; }
chmod 600 "$TMP"
{
  echo "# /etc/h100/web.env — 생성: h100-web-env.sh ($(date '+%F %T')). 비밀 포함: git/Obsidian 기록 금지. 키 추가: h100-web-env.sh --set NAME"
  echo "H100_DB_URL=$URL"
  echo "H100_DB_USER=h100_web"
  echo "H100_DB_PASSWORD=$PW"
  # 기존 파일의 다른 키(예: H100_WEATHER_KEY)는 보존. 주석·DB 3종은 위에서 새로 씀
  [ -s "$TARGET" ] && { grep -vE '^[[:space:]]*(#|$)|^[[:space:]]*H100_DB_(URL|USER|PASSWORD)=' "$TARGET" || true; }
} > "$TMP"
if getent group h100 >/dev/null 2>&1; then chown root:h100 "$TMP"; chmod 640 "$TMP"; else warn "h100 그룹 없음 — 권한 600 root 로 둠(h100-deploy.sh --prepare 먼저)"; fi
mv -f "$TMP" "$TARGET" && ok "web.env 생성: $(stat -c '%a %U:%G' "$TARGET")" || { bad "web.env 쓰기 실패"; summary; exit 1; }
say "[INFO] 포함된 키(이름만): $(grep -vE '^[[:space:]]*(#|$)' "$TARGET" | sed -E 's/=.*//' | tr '\n' ' ')"
say "[INFO] JDBC URL: $URL"
say "[INFO] $RECREATE_HINT"

# DB 로그인 시험: h100 네트워크의 임시 컨테이너에서 h100_web 으로 접속 (비밀번호는 환경변수로만 전달)
if [ "$NOTEST" -eq 0 ]; then
  if docker network inspect h100 >/dev/null 2>&1 && docker image inspect mariadb:10.11 >/dev/null 2>&1; then
    export MYSQL_PWD="$PW"
    R=$(timeout 60 docker run --rm --network h100 -e MYSQL_PWD mariadb:10.11 mariadb -h db -uh100_web able_park -N -e "SELECT COUNT(*) FROM tbl_device" 2>&1 | tr '\n' ' ')
    unset MYSQL_PWD
    echo "$R" | grep -Eq '^[0-9]+ *$' && ok "h100_web 로 db:3306 접속·조회 성공 (tbl_device 행 수: $R)" || bad "h100_web 접속/조회 실패: $(echo "$R" | cut -c1-200)"
  else warn "h100 네트워크 또는 mariadb:10.11 이미지가 없어 접속 시험 생략"; fi
fi
unset PW
summary
