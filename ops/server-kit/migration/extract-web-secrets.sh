#!/usr/bin/env bash
# [구 서버(192.168.0.15)에서 root 로 실행] 신 서버 web.env 에 옮길 비밀값(H100_AES_KEY)을 구 WAR 설정에서 파일로 추출
# 원칙: 값은 화면·로그에 출력하지 않는다(형식·길이·검증 결과만). 결과 파일은 600, 구 서버 원본은 읽기만.
# 사용: sudo ./extract-web-secrets.sh
set -uo pipefail
[ "$(id -u)" -eq 0 ] || { echo "root 로 실행하세요 (sudo)"; exit 2; }
APP=${APP:-/usr/share/tomcat9_jdk17/apache-tomcat-9.0.106/webapps2/gov-disabled-web-adv}
GP="$APP/WEB-INF/classes/globals.properties"
OUTDIR=${OUTDIR:-/root/h100-snapshots}
OUT="$OUTDIR/web-secrets-$(date +%Y%m%d).env"
ok()   { printf '[PASS] %s\n' "$*"; }
bad()  { printf '[FAIL] %s\n' "$*"; FAIL=1; }
info() { printf '[INFO] %s\n' "$*"; }
FAIL=0
[ -f "$GP" ] && ok "globals.properties 존재" || { bad "없음: $GP"; exit 1; }

# 1) external.crypto.aes-key (마지막 정의 사용)
line=$(grep -E '^[[:space:]]*external\.crypto\.aes-key[[:space:]]*=' "$GP" | tail -1)
[ -n "$line" ] || { bad "external.crypto.aes-key 정의 없음"; exit 1; }
v=${line#*=}; v=$(printf '%s' "$v" | tr -d '\r' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
if [[ "$v" =~ ^\$\{([A-Za-z0-9_.]+):(.*)\}$ ]]; then
  FORM="환경변수 참조(${BASH_REMATCH[1]}) + 기본값"; v="${BASH_REMATCH[2]}"
elif [[ "$v" =~ ^\$\{([A-Za-z0-9_.]+)\}$ ]]; then
  FORM="환경변수 참조(${BASH_REMATCH[1]}), 기본값 없음"; v=""
else
  FORM="평문 값"
fi
info "H100_AES_KEY 형식: $FORM, 값 길이=${#v}"
if [[ "$v" =~ ^[0-9a-fA-F]{64}$ ]]; then ok "64자 hex 형식 확인(값 비출력)"
else bad "64자 hex 가 아님 — 구 서버에 실제 키 값이 없거나 다른 형식. 파일을 만들지 않음"; exit 1; fi

umask 077; mkdir -p "$OUTDIR"; chmod 700 "$OUTDIR"
printf 'H100_AES_KEY=%s\n' "$v" > "$OUT"; chmod 600 "$OUT"
ok "추출 파일 생성: $OUT ($(wc -c < "$OUT") bytes, 600)"
( cd "$OUTDIR" && sha256sum "$(basename "$OUT")" > "$(basename "$OUT").sha256" ) && ok "체크섬: $OUT.sha256"

# 2) JDBC URL (host/port/옵션 확인용; 비밀번호성 파라미터는 가림)
info "구 서버 JDBC URL (비밀번호 파라미터 가림):"
grep -rhoE 'jdbc:[^"<[:space:]]*' "$APP/WEB-INF" --include=*.xml --include=*.properties 2>/dev/null \
  | sed -E 's/([?&;](password|pwd|pass|user|username)=)[^&;]*/\1<숨김>/Ig' | sort -u | sed 's/^/[INFO]   /'
unset v line
[ "$FAIL" -eq 0 ] && echo "OVERALL: PASS" || { echo "OVERALL: FAIL"; exit 1; }
