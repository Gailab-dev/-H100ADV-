# /etc/h100 설정 파일 템플릿 (값은 직접 채움 — 이 문서/저장소/Obsidian 에 값 기록 금지)

권한 규칙: 디렉터리 `/etc/h100` 750 root:h100, 각 `*.env`·`database.yml` 640 root:h100 (컨테이너 UID 3100 이 읽기만).
TLS 개인키 `server.key.pem` 640 root:h100. **CA 개인키는 두지 않는다(관리자 PC 전용).**

## /etc/h100/db.env  (MariaDB 컨테이너 + 복원 스크립트용)
```
MARIADB_ROOT_PASSWORD=<채움>
MARIADB_ROOT_HOST=localhost
DB_PASS_MODULE_C=<채움>      # 계정 h100_module_c (able_park DML)
DB_PASS_WEB=<채움>           # 계정 h100_web (able_park DML)
```

## /etc/h100/module-c.env
```
PORT=8189                       # 콜론 없이 숫자만 (코드가 ":"+PORT 로 사용 — VM 검증 2026-10-26)
H100_HMAC_KEYS={"<시리얼>":"<64자 hex>","<시리얼2>":"<64자 hex>"}
#   - 한 줄 JSON, **따옴표로 감싸지 않는다**, 키는 정확히 64자 hex. 형식이 틀린 항목은 조용히 건너뛰고 기동 로그에 "N개 로드"만 남음
#   - 키는 첫 인증 요청 때 한 번 로드된다(변경 후엔 컨테이너 재생성: docker compose up -d --force-recreate module-c)
#   - 구 서버 .env 의 값을 그대로 옮긴다. 테스트용 임의 키를 운영에 쓰지 않는다
# FILE_UPLOAD_PATH / TLS_* / CA_CERT_FILE 은 compose.yml 이 컨테이너 경로로 주입(덮어씀)
```

## /etc/h100/database.yml  (module_c 가 /app/config/database.yml 로 읽음)
```
database:
  Host: "db"
  Port: "3306"
  User: "h100_module_c"
  Password: "<DB_PASS_MODULE_C 와 동일>"
  Name: "able_park"
```
※ **최상위 `database:` 아래로 들여쓰기(중첩)** 해야 한다. 평평한(flat) 형식이면 연결 정보가 비어 기동 실패한다(VM 검증 2026-10-26).

## /etc/h100/web.env  (Java — B-02/B-01 외부화(T2) 완료 후 유효)
```
H100_DB_URL=jdbc:mariadb://db:3306/able_park?<기존 쿼리스트링>
H100_DB_USER=h100_web
H100_DB_PASSWORD=<DB_PASS_WEB 와 동일>
H100_AES_KEY=<기존 값>
```

## /etc/h100/tls/
```
server.cert.pem   # h100-ca 서명, SAN 에 SERVER_CERT_IP 포함
server.key.pem    # 640 root:h100
h100-ca.crt       # 공개 인증서
```

## /etc/h100/device-allow.list  (선택)
```
192.168.0.233
```
