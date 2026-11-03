#!/usr/bin/env bash
# module-c 디바이스 인증(HMAC) fail-closed 점검 — VM 리허설에서 쓰던 hmac-test.sh 를 킷에 편입
# 사용: sudo ./60-hmac-test.sh [--positive] [--url URL] [--serial 시리얼]
#   기본(음성만, 키 미사용):  헤더 없음 → 401 / 존재하지 않는 시리얼 + 0 HMAC → 401
#   --positive : /etc/h100/module-c.env 의 H100_HMAC_KEYS 에서 시리얼 1개로 정상 서명 요청 → 200 기대.
#                테스트 파일 1개(zz_h100_hmac_test_*.png)가 미디어 폴더에 저장되었다가 끝에 삭제된다.
#                키 값은 화면/로그/명령행에 출력하지 않는다(python 이 파일을 직접 읽어 서명만 계산).
#                키 해석이 구현에 따라 다를 수 있어 (hex 디코딩 / 문자열 그대로) 두 방식을 차례로 시도하고
#                성공한 방식 이름만 출력한다.
#   --url      : 기본 https://$SERVER_CERT_IP:8189 (--resolve 로 127.0.0.1 연결, h100-ca 로 검증)
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"
need_root
POS=0; URL=""; SERIAL=""
while [ $# -gt 0 ]; do case "$1" in
  --positive) POS=1; shift;; --url) URL="$2"; shift 2;; --serial) SERIAL="$2"; shift 2;;
  *) echo "알 수 없는 옵션 $1"; exit 2;; esac; done
MODULE_C_ENV=${MODULE_C_ENV:-/etc/h100/module-c.env}
EP=${EP:-/imageFileReceive}
TLS=(--cacert /etc/h100/tls/h100-ca.crt)
if [ -z "$URL" ]; then URL="https://$SERVER_CERT_IP:8189"; TLS+=(--resolve "$SERVER_CERT_IP:8189:127.0.0.1")
else case "$URL" in http://*) TLS=();; esac; fi
say "== 60-hmac-test $(date '+%F %T')  대상 $URL$EP =="

FNAME="zz_h100_hmac_test_${STAMP}.png"
BODY="$WORK/hmac-test.bin"; printf 'H100-HMAC-TEST-%s' "$STAMP" > "$BODY"
HDR="$WORK/hdr.txt"; chmod 600 "$WORK" 2>/dev/null

post() {  # post HEADERFILE → http_code
  curl -s --max-time 15 -o "$WORK/resp.txt" -w '%{http_code}' "${TLS[@]}" -H "@$1" \
    -F "file=@$BODY;filename=$FNAME" "$URL$EP" 2>/dev/null
}
expect() {  # expect 설명 기대코드 실제코드
  if [ "$3" = "$2" ]; then ok "$1 → $3"; else bad "$1 → $3 (기대 $2)  응답: $(head -c 120 "$WORK/resp.txt" 2>/dev/null)"; fi
}

# 1) 음성 테스트
: > "$HDR"; code=$(post "$HDR"); expect "서명 헤더 없음" 401 "$code"
printf 'X-Device-Serial: NO-SUCH-DEVICE\nX-Device-HMAC: %064d\n' 0 > "$HDR"; code=$(post "$HDR"); expect "존재하지 않는 시리얼 + 0 HMAC" 401 "$code"

# 2) 양성 테스트 (선택)
if [ "$POS" -eq 1 ]; then
  [ -r "$MODULE_C_ENV" ] || { bad "$MODULE_C_ENV 를 읽을 수 없음"; summary; exit 1; }
  # python 이 키 파일을 직접 읽는다. 출력: "<시리얼> <방식> <hmac>" 줄들 (키 값은 출력하지 않음)
  CANDS=$(python3 -I - "$MODULE_C_ENV" "$BODY" "$SERIAL" <<'PY'
import sys, json, hmac, hashlib, re
envf, body, want = sys.argv[1], sys.argv[2], sys.argv[3]
raw = None
for ln in open(envf, encoding="utf-8"):
    m = re.match(r'\s*H100_HMAC_KEYS\s*=\s*(.*)\s*$', ln)
    if m: raw = m.group(1); break
if raw is None: print("ERR no-key-line"); sys.exit(0)
raw = raw.strip()
if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in "'\"": raw = raw[1:-1]
try: keys = json.loads(raw)
except Exception: print("ERR json-parse"); sys.exit(0)
if not isinstance(keys, dict) or not keys: print("ERR empty"); sys.exit(0)
serial = want if want in keys else sorted(keys)[0]
k = keys[serial]; data = open(body, "rb").read(); msg = serial.encode() + data
for name, kb in (("hex-decoded", lambda: bytes.fromhex(k)), ("ascii", lambda: k.encode())):
    try: print(serial, name, hmac.new(kb(), msg, hashlib.sha256).hexdigest())
    except Exception: pass
PY
)
  case "$CANDS" in ERR*|"") bad "키 읽기 실패: ${CANDS:-출력 없음} (H100_HMAC_KEYS 형식: {\"시리얼\":\"64hex\",...} 따옴표 없이)";; *)
    okmode=""
    while read -r ser mode mac; do
      printf 'X-Device-Serial: %s\nX-Device-HMAC: %s\n' "$ser" "$mac" > "$HDR"
      code=$(post "$HDR")
      if [ "$code" = 200 ]; then okmode="$mode"; ok "정상 서명(시리얼 $ser, 키 해석=$mode) → 200"; break; fi
    done <<< "$CANDS"
    [ -n "$okmode" ] || bad "정상 서명 요청이 200 이 아님 (마지막 코드 $code): 키 형식(64 hex)/시리얼/H100_HMAC_KEYS 로드 로그 확인 — docker logs h100-module-c | grep -i hmac";;
  esac
  # 테스트 파일 정리 (컨테이너 UID 소유 → root 로 삭제)
  n=$(find "$NEW_MEDIA_DIR" -type f -name "$FNAME" 2>/dev/null | wc -l)
  find "$NEW_MEDIA_DIR" -type f -name "$FNAME" -delete 2>/dev/null
  [ "$n" -ge 1 ] && info "테스트 파일 ${n}개 삭제" || info "저장된 테스트 파일 없음(서명 실패 시 정상)"
else
  info "양성 테스트는 --positive (실제 키 사용, 테스트 파일 1개 기록 후 삭제)"
fi
rm -f "$BODY" "$HDR" "$WORK/resp.txt"
summary
