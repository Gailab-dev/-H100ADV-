# H100 서버 키트 안내 (v5.3)

신 서버/개발서버(GAILAB-SI)에서 H100(module-c + web + DB)을 **빌드·배포·검증·롤백**하는 스크립트 모음입니다.
위치: 저장소 `ops/server-kit/` → 서버 설치 경로 `/opt/h100/` (`migration/` = 스크립트, `docker/` = Dockerfile·compose.yml). 이 폴더는 Docker 이미지에 들어가지 않습니다(`.dockerignore`).

## 1. 어떤 파일이 무슨 일을 하나

| 파일 | 역할 | 언제 쓰나 |
|---|---|---|
| `h100-update.sh` | **소스에서 이미지 빌드(module-c·web) → 컨테이너 교체 → 검증**, 이전 태그로 롤백, 상태 조회 | 소스 반영(일상), 문제 시 되돌리기 |
| `h100-deploy.sh` | 컨테이너 **준비·기동·정지** (이미지는 빌드하지 않음) | 최초 설치, 전체 정지/원복 |
| `h100-verify.sh` | 읽기 전용 **검증**(`--ops` 추가 시 운영 점검) | 반영 직후(자동 실행), 정기 점검 |
| `h100-web-env.sh` | `/etc/h100/web.env` 생성·키 추가(`--set`)·목록(`--list`) | 최초 설치, web 환경키(날씨 키 등) 추가 |
| `lib.sh` | 공통 함수(직접 실행 금지) | 위 스크립트들이 자동으로 읽음 |
| `../docker/` | `Dockerfile.module-c`(Go 빌드), `Dockerfile.web`(Maven 빌드 → Tomcat), `Dockerfile.web-war`(예비: 미리 만든 WAR), `*.dockerignore`(빌드 제외 목록), `compose.yml`(서버 구성 백업본) | 이미지 빌드가 사용. 직접 실행하지 않음 |
| `h100-legacy-snapshot.sh` | **구 서버(192.168.0.15) 전용** 설정 사본 생성 | 구 서버에서 1회성. 이 키트와 별개 |

## 2. 상황별 사용법 (모두 `sudo`, `/opt/h100/migration` 에서)

**소스 반영 (일상 업무)** — 관리자 PC 에서 WAR 를 만들어 올릴 필요가 없습니다.
```
# ① gailab-si 로:  cd /opt/h100/repo && git pull --ff-only
sudo ./h100-update.sh            # 계획 확인 후 yes → 소스 빌드(module-c·web) → 컨테이너 교체 → 검증 자동
```
- module-c(Go)와 web(Maven→WAR→Tomcat) 모두 **Docker 안에서 소스로 빌드**합니다. 서버가 Maven 저장소·Docker Hub 에 접근할 수 있어야 하고, 첫 빌드는 의존성을 내려받느라 수 분 걸립니다(이후 캐시).
- 이미지 태그는 git 커밋 SHA(예: `45db37c8`)로 붙고, 같은 태그가 있으면 시각을 덧붙여 기존 이미지를 지키며, 반영 이력은 `/opt/h100/docker/deploy-history.log` 에 남습니다.
- 빌드가 실패하면 `.env`·기존 컨테이너는 바뀌지 않습니다(빌드 로그: `/root/h100-migration/<시각>/build-*.log`). DB 는 이 스크립트가 건드리지 않으므로 **DB 스키마 변경이 있으면 먼저 별도로 반영(백업 후)** 하세요.
- 소스에 구 서버 값(192.168.0.15, /home/dsic)이 하드코딩돼 있으면 web 빌드 중에 실패합니다(G0).
- (예비) Maven 빌드가 막힌 환경에서는 `--war FILE` 로 미리 만든 WAR 를 쓸 수 있습니다.

**문제가 생겼을 때**
```
sudo ./h100-update.sh --status                    # 현재 태그·보유 이미지·최근 이력
sudo ./h100-update.sh --rollback-to <이전태그>    # 이미지만 이전 버전으로 되돌림(DB 유지)
sudo ./h100-deploy.sh --stop                      # 컨테이너 전체 정지(데이터·이미지 보존). 옵션: --restore-host-service --remove-fw --purge-db
```

**점검**
```
sudo ./h100-verify.sh            # 컨테이너·포트·TLS·무서명 거절·web·DB·로그
sudo ./h100-verify.sh --ops      # + 재부팅 복구, 8189 허용 목록, 백업·로그·디스크   (--cutover: event_scheduler ON 기대)
```

**web 환경키 추가 (예: 날씨 키)** — 값은 화면에 보이지 않게 입력하고 다른 키는 유지합니다.
```
sudo ./h100-web-env.sh --set H100_WEATHER_KEY
sudo ./h100-web-env.sh --list                     # 키 이름만 확인
# web.env 는 컨테이너 생성 때 읽히므로 변경 후 web 재생성 필요(명령은 스크립트가 안내)
```

**최초 설치(요약)**: `h100-deploy.sh --prepare` → `/etc/h100/*.env`·`tls/` 채움(`conf/env-templates.md`) → `h100-web-env.sh` → `h100-update.sh --build-only` → `h100-deploy.sh --db-only` → DB 복원(런북, 서버의 이관용 스크립트) → `h100-deploy.sh --all` → `h100-verify.sh`

## 3. 키트 자체를 서버에 갱신하는 법
```
cd /opt/h100/repo/ops/server-kit        # gailab-si 로 git pull 한 뒤
sudo install -m 755 -o root -g root migration/h100-*.sh migration/lib.sh /opt/h100/migration/
sudo install -m 644 -o root -g root docker/Dockerfile.* /opt/h100/docker/    # Dockerfile 만. compose.yml 은 서버 파일이 기준(아래 참고)
```
root 로 실행되는 스크립트를 일반 사용자가 쓸 수 있는 저장소 경로에서 직접 돌리지 말고, 위처럼 root 가 복사해 쓰는 것을 원칙으로 합니다. `compose.yml` 은 서버(`/opt/h100/docker/compose.yml`)에 이미 있으면 `h100-update.sh` 가 **덮어쓰지 않고** 키트본과 다를 때 경고만 합니다(서버에서 고친 설정 보호). 서버 파일을 바꿨다면 개발 PC 의 `ops/server-kit/docker/compose.yml` 에도 같은 내용을 커밋해 두세요(`diff -u /opt/h100/docker/compose.yml docker/compose.yml` 로 일치 확인). 서버에 남아 있는 이관용 스크립트(`00-preflight`, `20-db-restore`, `25-db-migrate`, `30-media-sync`, `45-fw-docker-user`, `55-event-scheduler`, `60-hmac-test`, `70-cleanup-list` 등)는 git 에는 없지만 같은 폴더에서 그대로 동작합니다.

## 4. 공통 원칙과 기록 위치
- 비밀값(비밀번호·키)은 `/etc/h100/*.env` 에만 둡니다. 스크립트는 값을 출력·로그에 남기지 않으며, git/문서에도 기록하지 않습니다.
- 위험한 단계는 확인 입력(`yes`) 또는 `--yes` 가 필요합니다. 실행 로그·결과: `/root/h100-migration/<실행시각>/` (스크립트별 `.log`, `RESULT_*.txt`, 빌드 로그 `build-*.log`).
- 이전 이미지는 롤백용이므로 최근 3개 태그는 지우지 마세요.
- module-c·web 모두 `git pull` 후 `h100-update.sh` 한 번이면 반영됩니다. module_d(디바이스)는 이 키트와 무관(디바이스에 별도 설치).

## 5. 이름 변경·통합 내역 (2026-11-03)
| 구 이름 | 현재 |
|---|---|
| `10-build-images.sh` | `h100-update.sh` 에 통합 (`--build-only` 로 빌드만 가능). web 은 WAR 업로드 없이 소스 빌드 |
| `40-up.sh`, `h100-rollback.sh`(구 `90-rollback.sh`) | `h100-deploy.sh` 에 통합 (`--stop` 이 구 rollback) |
| `50-verify.sh`, `65-ops-check.sh` | `h100-verify.sh` 에 통합 (`--ops`) |
| `35-web-env.sh` | `h100-web-env.sh` (`--set`/`--list` 추가, `--force` 시 다른 키 보존) |
| `legacy-snapshot.sh` | `h100-legacy-snapshot.sh` |
