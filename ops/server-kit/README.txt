H100 서버 배포 키트 v5.3 (2026-11-03)  — git 관리본: 저장소 ops/server-kit/

이 폴더는 신 서버(개발서버)에서 H100 컨테이너(db/module-c/web)를 준비·기동·검증·갱신하는 스크립트 모음이다.
docker 이미지에는 들어가지 않는다(.dockerignore 와 docker/Dockerfile.module-c.dockerignore 로 빌드 컨텍스트에서 제외).
장비(module_d) 설치 키트는 ops/device-kit/ 이며 별개다.

구성
  migration/   실행 스크립트(서버의 /opt/h100/migration/ 로 설치)
  docker/      Dockerfile.module-c, Dockerfile.module-c.dockerignore, Dockerfile.web  (서버의 /opt/h100/docker/)
  conf/        migration.conf.example, env-templates.md                                 (서버의 /opt/h100/conf/)
  H100_개발서버_이전_런북_2026-10-23.md   절차서

※ docker/compose.yml 은 git 에 아직 없다. 서버에서 직접 수정된 이력(compose.yml.bak-20261027-tz, .bak-20261028)이 있어
  서버 현재본이 최신이다. 서버본을 확인·비밀 점검한 뒤 이 폴더에 추가한다(작업결과서 40 참고).

git 에 없는 것(올리지 않는다): migration.conf, /etc/h100/*(env·database.yml·tls), 인증서·키·토큰, DB 덤프,
  *.bak-*, .env.bak-*, deploy-history.log, 로그, WAR, tar 산출물.  (.gitignore 에 패턴 있음)
  이 키트에는 비밀값이 없다. /etc/h100/* 는 conf/env-templates.md 를 보고 직접 채운다.

스크립트 역할(이름 변경: 40-up→h100-deploy, 50-verify→h100-verify, 90-rollback→h100-rollback, 신규 h100-update)
  h100-update.sh    소스 반영 표준 진입점. 이미지 빌드 → 컨테이너 교체 → 검증. --rollback-to <태그>, --status. DB 유지.
  10-build-images.sh  이미지 빌드(h100-update.sh 가 호출). 단독은 최초 설치·리허설용
  h100-deploy.sh    컨테이너 준비/기동. 이미지를 빌드하지 않는다(이미 있는 이미지로 기동·교체만)
  h100-verify.sh    반영 후 검증(읽기 전용, --cutover)
  h100-rollback.sh  컨테이너 정지(데이터·이미지 보존). 이전 이미지로 되돌리기는 h100-update.sh --rollback-to
  그 외(00-preflight, 20-db-restore, 25-db-migrate, 30-media-sync, 35-web-env, 45-fw-docker-user, 55-event-scheduler,
        60-hmac-test, 65-ops-check, 70-cleanup-list 등)는 초기 이전·특정 조건용

소스 변경 반영(매번) — 항상 전체(module-c + web)로 한다
  1. gailab-si(sudo 없이): cd /opt/h100/repo && git status --short(깨끗해야 함) && git fetch origin
        && git log --oneline HEAD..origin/main && git pull --ff-only
  2. 관리자 PC 에서 같은 커밋으로 mvn package → WAR 를 서버로 복사 (서버 git pull 만으로는 web 이 바뀌지 않는다)
  3. DB 스키마 변경이 있으면 백업 후 25-db-migrate.sh  (h100-update.sh 는 DB 를 바꾸지 않는다)
  4. sudo /opt/h100/migration/h100-update.sh --war <WAR 경로>
  5. 검증 통과 확인(필요하면 --status). 반영 커밋·태그·시각·결과를 일일 노트에 기록(비밀 제외)
  실패 시: 빌드 실패는 .env 가 자동 복원되고 기존 컨테이너는 그대로다. 교체·검증 실패는 자동 롤백하지 않고
          되돌리기 명령(sudo ./h100-update.sh --rollback-to <이전태그>)을 출력한다.

키트 파일을 서버에 반영하는 방법(제안 — 확정 전)
  gailab-si 가 pull 한 뒤 root 가 diff 를 확인하고 /opt/h100/migration, /opt/h100/docker, /opt/h100/conf 로 복사한다.
  /opt/h100/migration 을 저장소로 심볼릭 링크하지 않는다(pull 이 곧바로 root 실행 스크립트를 바꾸게 됨).
  migration.conf 같은 서버 고유 파일은 건드리지 않는다. 이름 바꾼 스크립트는 mv 가 아니라 새 이름 파일을 추가하고
  옛 이름은 며칠 두었다가 정리한다.

버전·갱신 규칙
  v5.3  2026-11-03  git 편입. 스크립트 이름 변경 3건, h100-update.sh 추가, 65-ops-check/70-cleanup-list 편입,
                    docker/Dockerfile.module-c.dockerignore 추가, 안내 문구의 옛 이름 정리.
  v5.2  2026-10-27  web 이미지 폰트 패키지, db/module-c/web TZ=Asia/Seoul, /imgFile Context, 25-db-migrate.sh,
                    legacy-snapshot.sh(구 서버용), web 컨텍스트 경로 WEB_CONTEXT(기본 gov-disabled-web-adv),
                    web 헬스체크 bash, conf/Catalina/localhost 생성, 35-web-env.sh
  키트를 바꾸면 위에 버전·변경 내용을 한 줄 추가한다.
