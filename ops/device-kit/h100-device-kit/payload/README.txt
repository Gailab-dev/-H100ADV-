이 폴더(payload)에 패치 파일을 넣고, 관리자 PC 에서 ../admin_make_sums.sh 로 SHA256SUMS 를 만든 뒤 키트 전체를 장비로 복사합니다.

  h100_module_d                       module_d 바이너리 (linux/arm64)         — 1번·2번·3번(--cert-only 제외)
  certs/h100-ca.crt                   내부 CA 공개 인증서                       — 1번 필수, 3번 선택
  certs/device-<시리얼>.crt           장비 인증서                               — 1번·3번
  certs/device-<시리얼>.key           장비 개인키 (복사·붙여넣기 금지)           — 1번·3번(--use-local-key 면 불필요)
  SHA256SUMS                          위 파일들의 해시                          — 항상 필요

※ 2번(바이너리 패치)은 h100_module_d 와 SHA256SUMS 만 있으면 됩니다. certs/ 는 비워 두거나 지워도 됩니다.
※ 개인키 사본은 장비 설치·교체가 끝나면 삭제하세요 (--wipe-payload-key 옵션 또는 shred -u).
※ CA 개인키(h100-ca.key)는 절대 이 폴더나 장비에 두지 않습니다.
