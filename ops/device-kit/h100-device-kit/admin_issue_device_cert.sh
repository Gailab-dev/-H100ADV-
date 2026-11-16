#!/usr/bin/env bash
# [관리자 PC 전용] 장비 인증서 발급 — CA 개인키는 이 PC 에서만 쓰고, 장비·서버·키트로 복사하지 않는다.
#
#  방식 A (기존 방식): 관리자 PC 에서 장비 개인키+인증서를 함께 만든다 → payload/certs/ 에 3개 파일(CA·crt·key)
#     ./admin_issue_device_cert.sh --ca-cert <h100-ca.crt> --ca-key <h100-ca.key> --serial <시리얼> --ip <장비IP>
#  방식 B (권장): 장비가 만든 CSR 에 서명만 한다 → 개인키는 장비 밖으로 나가지 않음. payload/certs/ 에 crt, CA
#     ./admin_issue_device_cert.sh --ca-cert … --ca-key … --serial <시리얼> --ip <장비IP> --csr <device-시리얼.csr>
#
#  옵션: --days 365   --out <폴더, 기본 payload/certs>   --ca-serial <h100-ca.srl 경로, 기본 CA 인증서 옆>
#  인증서에는 SAN(IP, DNS:device-<시리얼>)이 들어간다. 끝나면 admin_make_sums.sh 를 다시 실행하세요.
#  값(개인키 내용)은 출력하지 않는다.
set -euo pipefail
KIT_DIR=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
CA_CERT=""; CA_KEY=""; SERIAL=""; IP=""; CSR=""; DAYS=365; OUT="$KIT_DIR/payload/certs"; CA_SRL=""
while [ $# -gt 0 ]; do case "$1" in
  --ca-cert) CA_CERT=$2; shift 2;; --ca-key) CA_KEY=$2; shift 2;; --serial) SERIAL=$2; shift 2;; --ip) IP=$2; shift 2;;
  --csr) CSR=$2; shift 2;; --days) DAYS=$2; shift 2;; --out) OUT=$2; shift 2;; --ca-serial) CA_SRL=$2; shift 2;;
  *) sed -n '2,12p' "$0"; exit 2;; esac; done
[ -f "$CA_CERT" ] && [ -f "$CA_KEY" ] || { echo "--ca-cert / --ca-key 파일을 확인하세요"; exit 1; }
printf '%s' "$SERIAL" | grep -Eq '^[0-9]{6,20}$' || { echo "--serial 은 숫자 6~20자"; exit 1; }
printf '%s' "$IP" | grep -Eq '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' || { echo "--ip 는 장비 IPv4 주소"; exit 1; }
[ -n "$CA_SRL" ] || CA_SRL="${CA_CERT%.*}.srl"
mkdir -p "$OUT"; TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
EXT="$TMP/ext.cnf"; cat > "$EXT" <<EOT
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=IP:$IP,DNS:device-$SERIAL
EOT
if [ -n "$CSR" ]; then
  [ -f "$CSR" ] || { echo "CSR 파일 없음: $CSR"; exit 1; }
  openssl req -in "$CSR" -noout -verify 2>/dev/null || { echo "CSR 서명 검증 실패"; exit 1; }
  CSR_USE="$CSR"; MODE="B(CSR 서명)"
else
  umask 077; openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$OUT/device-$SERIAL.key" 2>/dev/null
  openssl req -new -key "$OUT/device-$SERIAL.key" -subj "/CN=device-$SERIAL" -out "$TMP/dev.csr" 2>/dev/null
  CSR_USE="$TMP/dev.csr"; MODE="A(키+인증서 생성)"
fi
openssl x509 -req -in "$CSR_USE" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAserial "$CA_SRL" -CAcreateserial \
  -days "$DAYS" -sha256 -extfile "$EXT" -out "$OUT/device-$SERIAL.crt" 2>/dev/null || { echo "서명 실패 (CA 키 암호 확인)"; exit 1; }
cp "$CA_CERT" "$OUT/h100-ca.crt"
openssl verify -CAfile "$OUT/h100-ca.crt" "$OUT/device-$SERIAL.crt" >/dev/null || { echo "발급 결과 검증 실패"; exit 1; }
echo "발급 완료 — 방식 $MODE"
echo "  출력 폴더 : $OUT"
ls -1 "$OUT" | sed 's/^/    /'
echo "  만료일    : $(openssl x509 -in "$OUT/device-$SERIAL.crt" -noout -enddate | cut -d= -f2)"
echo "  SAN       : IP:$IP, DNS:device-$SERIAL"
echo "  CA 지문   : $(openssl x509 -in "$OUT/h100-ca.crt" -noout -fingerprint -sha256 | cut -d= -f2)"
echo "다음: ./admin_make_sums.sh 로 SHA256SUMS 를 다시 만든 뒤, 키트 폴더 전체를 장비로 복사하세요 (CA 개인키는 복사 금지)."
