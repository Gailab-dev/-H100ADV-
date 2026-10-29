# H100 엣지(Jetson) 설치·패치 키트 사용 매뉴얼

- 대상: 디바이스 담당자(엣지 작업), 서버 담당자(효성)
- 작성: 2026-10-29 / 기준 문서: 「G.Eye.Parking H100 엣지 저장경로 안내」(2026-10-28, 조석빈)
- 이 키트가 하는 일: 엣지의 **module_d 설치·패치를 같은 방식으로 반복**하게 하고, **인증서 키가 복사 중 바뀌거나 사라지지 않도록** 해시로 확인한다.
- 비밀값(키·토큰·RTSP 계정)은 이 문서에도, 화면·로그에도 쓰지 않는다.

---

## 1. 어떤 스크립트를 쓰나 (한눈에)

| 상황 | 스크립트 | 바뀌는 것 | 바뀌지 않는 것 |
|---|---|---|---|
| **① 새 엣지에 처음 설치** (인증서 키 배포 포함) | `1_install_first.sh` | 폴더, 바이너리, 인증서·개인키, `.env`, systemd 서비스 | — |
| **② 이미 설치된 엣지에 두 번째 이후 패치** | `2_patch_binary.sh` | **바이너리 1개만** | 인증서, `.env`, logs, hls |
| **③ 패치하면서 인증서까지 교체** (또는 인증서만) | `3_patch_with_cert.sh` | 바이너리(선택) + CA·장비 인증서·개인키 | `.env`(경로 동일), logs, hls |

세 스크립트 공통 사용법

```
./<스크립트> check      # 점검만 (아무것도 바꾸지 않음) ← 항상 먼저
./<스크립트> apply      # 실행 (계획을 보여주고 yes 를 입력해야 진행, 실패하면 자동 복구)
./<스크립트> rollback   # 직전 백업으로 되돌리기 (2번·3번)
```

경로만 바꿀 때는 2번 스크립트에 `--paths-only` 를 쓴다(§4).

공통 옵션: `--dry-run`(계획만 출력), `--yes`(확인 질문 생략), `--no-sums`(SHA256 검증 생략, 비권장)

**원칙: 패치 때 인증서 파일은 건드리지 않는다.** 2번 스크립트는 교체 전·후로 `ssl/`·`.env` 의 SHA256 을 비교해 달라지면 자동으로 되돌린다.

---

## 2. 키트 구성

```
h100-device-kit/
├─ h100-device.conf          ★ 경로·이름 변수 (경로를 바꿀 때 이 파일만 수정)
├─ lib.sh                    공통 함수 (수정하지 않음)
├─ 1_install_first.sh        최초 설치
├─ 2_patch_binary.sh         바이너리만 패치
├─ 3_patch_with_cert.sh      패치 + 인증서 교체
├─ admin_make_sums.sh        [관리자 PC] payload 해시 목록(SHA256SUMS) 생성
├─ admin_issue_device_cert.sh[관리자 PC] 장비 인증서 발급
├─ MANUAL.md                 이 문서
└─ payload/                  패치 파일을 넣는 곳
   ├─ h100_module_d              module_d 바이너리 (linux/arm64)
   ├─ certs/h100-ca.crt          내부 CA 공개 인증서
   ├─ certs/device-<시리얼>.crt  장비 인증서
   ├─ certs/device-<시리얼>.key  장비 개인키 (복사·붙여넣기 금지)
   └─ SHA256SUMS                 위 파일들의 해시
```

| payload 파일 | 1번 | 2번 | 3번 |
|---|---|---|---|
| `h100_module_d` | 필수 | 필수 | 필수 (`--cert-only` 면 불필요) |
| `certs/h100-ca.crt` | 필수 | 불필요 | 선택 (없으면 현재 CA 사용) |
| `certs/device-<시리얼>.crt` | 필수 | 불필요 | 필수 |
| `certs/device-<시리얼>.key` | 필수 | 불필요 | 필수 (`--use-local-key` 면 불필요) |
| `SHA256SUMS` | 필수 | 필수 | 필수 |

---

## 3. 경로 계약표 (디바이스 담당자와 서버 담당자가 같이 보는 표)

기준: 엣지 Jetson, 코드 폴더 `~/H100/system`, 기존 `recorded` 폴더는 `output` 으로 이름 변경(하위 구조 동일). 아래 표의 `~` 는 서비스 계정(`gailab`)의 홈 `/home/gailab` 이다.

| 항목 | 경로 | 설정 파일 변수 (`h100-device.conf`) | module_d `.env` 키 | 비고 |
|---|---|---|---|---|
| 위반 이벤트 이미지 | `~/H100/output/image` | `IMAGE_DIR` | `FILE_PATH`(=`output`) 아래 `image` | 폴더명 `image` 는 module_d 소스에 고정 |
| 위반 이벤트 영상 | `~/H100/output/video` | `VIDEO_DIR` | `FILE_PATH` 아래 `video` | 폴더명 `video` 는 소스에 고정 |
| 상시 녹화 영상 | `~/H100/output/video/always` | `VIDEO_ALWAYS_DIR` | (없음) | Python 이 사용. module_d 는 하위 폴더를 전송하지 않음 |
| SIP 통화 녹음(음성) | `~/H100/output/voice` | `VOICE_DIR` | `AUDIO_PATH` | 이름 변경 가능(.env 로 지정) |
| 산출물 최상위 | `~/H100/output` | `OUTPUT_DIR` | `FILE_PATH` | 예전 이름 `recorded` |
| rois.json | `~/H100/system/rois.json` | `ROIS_JSON` | `ROI_FILE_PATH` | 코드 폴더 바로 안 |
| ROI 그리기용 스냅샷 | `~/H100/output/roi_snapshot` | `ROI_SNAPSHOT_DIR` | `ROI_SNAPSHOT_DIR` | 구현 예정. 아래 §9 확인 필요 |
| module_d 실행 폴더 | `~/H100/system/h100_module_d` | `MODULE_D_DIR` | — | 바이너리·`.env`·`ssl/`·`logs/`·`hls/` |
| 인증서 폴더 | `~/H100/system/h100_module_d/ssl` | `SSL_DIR` | `TLS_CERT_FILE`·`TLS_KEY_FILE`·`CA_CERT_FILE` | 키 파일 권한 600 |
| HLS 폴더 | `~/H100/system/h100_module_d/hls` | `HLS_DIR` | `HLS_DIR` | |
| 키트 백업·기록 | `~/.h100-device/` | `KIT_STATE_DIR` | — | 백업·로그·인증서 CSR 대기 키 (권한 700) |
| 인증서 기준 해시 | `~/module_d_ssl.sha256` | `SSL_BASELINE` | — | 인증서 변경 여부 확인용 |

서버(module_c)는 위 엣지 경로를 알 필요가 없다. 서버와 엣지의 약속은 **파일명 규칙 + 종류 문자열(image/video/audio) + 엔드포인트 + 인증(HMAC/TLS)** 뿐이다.

---

## 4. 저장 경로를 수정해야 할 때 (디바이스 담당자용)

경로는 **`h100-device.conf` 한 곳**에서만 바꾼다. 스크립트 본문은 고치지 않는다. 파일 안에 `[A]`~`[H]` 구역과 `←←←` 표시, 주석이 있다.

**수정 절차**

1. 경로 안내서(조석빈 문서)를 먼저 갱신한다.
2. `h100-device.conf` 에서 해당 변수를 수정한다.
   - 상위 폴더가 바뀌면 `[A]` 의 `H100_HOME` / `SYSTEM_DIR` / `OUTPUT_DIR`
   - 음성 폴더만 바뀌면 `[B]` 의 `VOICE_DIR`
   - rois.json 이나 스냅샷 폴더가 바뀌면 `[C]` 의 `ROIS_JSON` / `ROI_SNAPSHOT_DIR`
3. 점검: `./2_patch_binary.sh check` — `.env` 경로와 설정 파일이 다르면 `[WARN] … ≠ 설정 파일` 로 알려준다.
4. 반영:
   - 경로만 바뀌었으면 `./2_patch_binary.sh apply --paths-only` (바이너리·payload 없이 `.env` 경로만 맞추고 재시작)
   - 바이너리 패치와 함께면 `./2_patch_binary.sh apply --sync-paths`
   - `.env` 의 `FILE_PATH`, `AUDIO_PATH`, `ROI_FILE_PATH`, `ROI_SNAPSHOT_DIR` **4개 경로 키만** 바뀐다. 비밀값은 건드리지 않는다.
   - 없는 폴더는 만들어 준다. 변경 전 `.env` 는 백업된다.
5. 서버 담당자(효성)에게 알리고, 이 매뉴얼 §3 표와 안내서를 같이 수정한다.

**꼭 지킬 것**

- `image`, `video` 폴더 이름은 module_d 소스에 고정되어 있다. 바꾸려면 module_d 소스를 고쳐 다시 빌드해야 하므로, `h100-device.conf` 에서 `IMAGE_DIR`/`VIDEO_DIR` 을 `OUTPUT_DIR/image`, `OUTPUT_DIR/video` 가 아닌 값으로 두면 스크립트가 시작하지 않는다.
- `recorded` → `output` 이름 변경은 **Python 쪽 개명과 module_d `.env` 의 `FILE_PATH` 변경을 같은 점검창에서** 한다. 사이에 module_d 가 옛 경로를 보면 파일 전송이 실패한다.
- 폴더를 옮긴 뒤에는 module_d 를 재시작해야 새 경로가 적용된다(`--paths-only`·`--sync-paths` 는 재시작까지 한다).
- 경로를 바꿨다면 반드시 `check` 를 다시 돌려 통과를 확인한다.

---

## 5. 시나리오 ① 최초 설치 (`1_install_first.sh`)

### 5-1. 관리자 PC 에서 준비 (Windows 는 Git Bash 또는 WSL)

1. 장비 시리얼과 IP 를 확인한다. (시리얼: 장비에서 `cat /proc/device-tree/serial-number`)
2. 장비 인증서를 만든다 (CA 개인키는 관리자 PC 에서만 쓰고 장비·서버·키트에 복사하지 않는다).
   ```
   ./admin_issue_device_cert.sh --ca-cert <h100-ca.crt 경로> --ca-key <h100-ca.key 경로> --serial <시리얼> --ip <장비IP>
   ```
   → `payload/certs/` 에 `h100-ca.crt`, `device-<시리얼>.crt`, `device-<시리얼>.key` 가 생긴다. SAN 에 장비 IP 가 들어간다.
3. module_d 바이너리를 `payload/h100_module_d` 로 둔다 (linux/arm64).
4. 해시 목록을 만든다: `./admin_make_sums.sh` → `payload/SHA256SUMS`
   - Git Bash 가 없으면 PowerShell 로 만들 수 있다 (줄바꿈 CRLF·대문자 해시도 스크립트가 읽는다).
     ```powershell
     cd payload
     Get-ChildItem -Recurse -File | Where-Object { $_.Name -notin 'SHA256SUMS','README.txt' } |
       ForEach-Object { $rel = (Resolve-Path -Relative $_.FullName) -replace '^\.\\','' -replace '\\','/'
                        "{0}  {1}" -f (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower(), $rel } |
       Set-Content -Encoding ascii SHA256SUMS
     ```
5. `h100-device.conf` 의 `CLOUD_RECEIVE_IP` 를 **`IP:포트`** 로 채운다 (예 `192.168.0.115:8189`, 포트 8189 포함).

### 5-2. 장비로 복사

- 키트 폴더 **전체**를 파일 그대로 복사한다 (`scp -r h100-device-kit gailab@<장비IP>:~/` 또는 USB).
- **개인키·인증서를 메모장·채팅·터미널에 붙여넣지 않는다.** 줄바꿈·공백이 바뀌어 키가 깨진다. 해시 검증이 이를 잡아내지만, 처음부터 파일 복사만 쓴다.

### 5-3. 서버에서 먼저 등록 (서버 담당자, §6)

허용 목록에 장비 IP 등록 + HMAC 키 등록. 이게 안 되어 있으면 설치는 되지만 서버 연결 점검이 `[WARN]` 으로 나온다.

### 5-4. 장비에서 실행

```
cd ~/h100-device-kit
chmod +x *.sh
./1_install_first.sh check
./1_install_first.sh apply --hmac-key-file <HMAC키파일> --wipe-payload-key
```

- HMAC 키 파일은 64자 hex 한 줄짜리 파일이다(권한 600). 파일 옵션을 생략하면 숨김 입력으로 받는다. RTSP 주소도 같다(`--rtsp-file`).
- `check` 에서 `[FAIL]` 이 없어야 `apply` 가 진행된다. `[WARN]` 은 읽고 판단한다.
- `apply` 는 계획을 보여주고 `yes` 를 입력해야 진행한다.

**설치가 하는 일**: 폴더 생성(`output/{image,video,video/always,voice,roi_snapshot}`, `ssl`, `logs`, `hls`) → 바이너리 설치(root:root 755) → CA·인증서·개인키 배포(개인키 600) → `.env` 생성(600) → systemd 서비스 등록·시작 → `/healthz`·인증서 일치 점검 → 인증서 기준 해시 저장.

**설치 후**: payload 의 개인키 사본을 지운다 (`--wipe-payload-key` 로 자동 삭제되지 않았다면 `shred -u payload/certs/device-<시리얼>.key`).

이미 설치된 장비에서 1번을 실행하면 `[FAIL] 이미 설치된 장비입니다` 로 멈춘다(실수로 덮어쓰기 방지). 정말 다시 설치해야 하면 `--reinstall` 을 쓴다 — 기존 파일은 전부 `~/.h100-device/backup/` 에 백업된다.

---

## 6. 서버 쪽 작업 (서버 담당자, 신 개발서버 192.168.0.115)

장비를 새로 추가하거나 인증서를 바꿀 때 서버에서 하는 일이다. 키 값은 화면·노트에 쓰지 않는다.

| 작업 | 언제 | 방법 |
|---|---|---|
| 8189 허용 목록에 장비 IP 추가 | 새 장비 추가 | `/etc/h100/device-allow.list` 에 IP 한 줄 추가 → `sudo /opt/h100/migration/45-fw-docker-user.sh --apply` |
| HMAC 키 등록 | 새 장비 추가 | `/etc/h100/module-c.env` 의 `H100_HMAC_KEYS` 에 `시리얼:키` 항목 추가 → compose 로 `module-c` 재생성(`/opt/h100/docker/compose.yml`, 프로젝트 `h100`) |
| 장비 HMAC 키 만들기 | 새 장비 추가 | `openssl rand -hex 32` (64자 hex). 같은 값이 장비 `.env` 의 `DEVICE_HMAC_KEY` 와 서버 `H100_HMAC_KEYS` 에 들어간다 |
| 서버의 CA 파일 | CA 를 바꿀 때만 | 서버가 새 CA 를 신뢰하도록 먼저 교체한 뒤 장비에 `--allow-ca-change` |
| 인증서 호스트명 검사 | 새 인증서에 IP SAN 이 포함되면 | 서버의 `H100_DEVICE_TLS_HOSTNAME_CHECK` 를 `true` 로 되돌릴 수 있음(모든 장비에 IP SAN 이 들어간 뒤) |

---

## 7. 시나리오 ② 두 번째 이후 패치 (`2_patch_binary.sh`)

인증서·`.env` 를 건드리지 않고 **바이너리만** 교체한다.

1. 관리자 PC: 새 바이너리를 `payload/h100_module_d` 로 교체 → `./admin_make_sums.sh`
2. 키트의 `payload/` 를 장비로 파일 복사 (`certs/` 는 없어도 된다)
3. 장비에서
   ```
   cd ~/h100-device-kit
   ./2_patch_binary.sh check
   ./2_patch_binary.sh apply          # 경로 변경이 있을 때만:  apply --sync-paths
   ```

`apply` 가 하는 일: 서비스 정지(수 초) → 현재 바이너리 백업 → 새 바이너리 교체(소유·권한 유지) → 서비스 시작 → `/healthz` 200 확인 → `ssl/`·`.env` 해시가 교체 전과 같은지 확인.
어느 단계든 실패하면 **자동으로 이전 바이너리로 복구**하고 서비스를 다시 올린다.

영상(HLS)과 파일 전송이 서비스 정지 동안 잠시 끊기므로, 파일 일괄 전송 시각(`FILE_SEND_SCH_TIME`)을 피하고 점검창에 한다.

---

## 8. 시나리오 ③ 패치 + 인증서 교체 (`3_patch_with_cert.sh`)

인증서 세트(CA·장비 인증서·개인키)를 **통째로 백업**하고, 새 세트를 **검증한 뒤에만** 교체한다.
검증 항목: 인증서·키 형식, **인증서와 키가 한 쌍인지**, CA 로 체인 검증, 만료일(30일 이상), IP SAN, **CA 지문이 현재와 같은지**.

### 방식 A — 관리자 PC 에서 키+인증서를 함께 만들어 복사 (기존 방식)

1. 관리자 PC: `admin_issue_device_cert.sh`(§5-1 2번)로 3개 파일 생성, 새 바이너리가 있으면 `payload/h100_module_d` 교체, `./admin_make_sums.sh`
2. 장비로 `payload/` 파일 복사
3. 장비에서
   ```
   ./3_patch_with_cert.sh check
   ./3_patch_with_cert.sh apply --wipe-payload-key
   ```
   (인증서만 바꾸려면 `--cert-only`)

### 방식 B — 장비가 개인키를 만들고 CSR 만 가져간다 (권장: 개인키가 장비 밖으로 안 나감)

1. 장비: `./3_patch_with_cert.sh gen-csr --ip <장비IP>` → `~/.h100-device/csr/device-<시리얼>.csr` 생성(운영 중인 파일은 건드리지 않음)
2. `.csr` 파일만 관리자 PC 로 복사 (공개 정보)
3. 관리자 PC: `./admin_issue_device_cert.sh --ca-cert … --ca-key … --serial <시리얼> --ip <장비IP> --csr device-<시리얼>.csr` → `payload/certs/` 에 `.crt`, `h100-ca.crt` 생성 → `./admin_make_sums.sh`
4. 장비로 `payload/` 복사 후
   ```
   ./3_patch_with_cert.sh apply --use-local-key        # 인증서만:  --cert-only 추가
   ```

### 3번 `apply` 의 동작

서비스 정지 → 바이너리·CA·인증서·개인키 백업(`~/.h100-device/backup/`, 700) → 새 파일 교체(개인키 600) → 서비스 시작 → **서비스가 실제로 내보내는 인증서가 새 파일과 같은지** 확인 → 서버 연결 확인 → 인증서 기준 해시 갱신.
실패하면 자동으로 백업을 복원한다. 되돌리려면 `./3_patch_with_cert.sh rollback`.

**CA 가 바뀌는 경우**: 기본적으로 `[FAIL] CA 인증서가 현재와 다름` 으로 멈춘다(다른 CA 파일을 잘못 넣는 사고 방지). 의도한 교체라면 서버가 새 CA 를 먼저 신뢰하도록 설정한 뒤 `--allow-ca-change` 를 쓴다.

**CA 지문 고정(권장)**: `openssl x509 -in <h100-ca.crt> -noout -fingerprint -sha256` 로 지문을 확인해 `h100-device.conf` 의 `CA_FINGERPRINT_SHA256` 에 적어 두면, 다른 CA 파일이 들어오면 모든 점검에서 실패한다.

---

## 9. 롤백

| 상황 | 방법 |
|---|---|
| 2번 패치 후 문제 | `./2_patch_binary.sh rollback` (가장 최근 백업) 또는 `rollback ~/.h100-device/backup/<폴더>` |
| 3번 패치 후 문제 | `./3_patch_with_cert.sh rollback` (바이너리와 인증서 세트를 함께 복원, 개인키 권한·소유까지 원래대로) |
| 최초 설치 후 문제 | 서비스 정지(`sudo systemctl stop h100_module_d`) 후 원인 확인, 다시 설치할 때는 `--reinstall` |

백업은 최신 5개만 보관한다(`KEEP_BACKUPS`). 백업에는 개인키 사본이 들어 있어 폴더 권한이 700 이다.

---

## 10. 점검 결과 읽는 법 / 자주 나는 문제

출력은 `[ OK ]` / `[WARN]` / `[FAIL]` 로 나온다. `[FAIL]` 이 하나라도 있으면 `apply` 는 진행하지 않는다. 모든 실행 기록은 `~/.h100-device/logs/` 에 남는다(비밀값 없음).

| 증상 | 원인 | 조치 |
|---|---|---|
| `패치 파일 SHA256 불일치` | 복사 중 손상, 파일을 나중에 바꾸고 `admin_make_sums.sh` 를 다시 안 함 | 관리자 PC 에서 `admin_make_sums.sh` 재실행 후 `payload/` 를 파일째 다시 복사 |
| `인증서와 개인키가 서로 짝이 아님` | 다른 장비의 키, 키 파일 손상, 붙여넣기 | 같은 발급에서 나온 `.crt`/`.key` 를 다시 복사 |
| `장비 인증서가 이 CA 로 검증되지 않음` | 다른 CA 로 발급 | 올바른 CA 로 다시 발급 |
| `CLOUD_RECEIVE_IP 에 :포트 없음` | 포트(8189) 누락 | `IP:8189` 형식 (모듈이 파일을 이 주소로 보냄) |
| `FILE_SEND_SCH_TIME 이 6칸이 아님` | cron 형식 오류 | `"초 분 시 일 월 요일"` 6칸. 새 바이너리는 형식 오류면 시작하지 않는다 |
| `서버 … 에 연결 불가(curl 7/28)` | 서버 8189 허용 목록에 장비 IP 없음, 네트워크 | 서버 담당자에게 허용 목록 등록 요청(§6) |
| `서버 인증서 검증 실패(curl 60)` | 장비의 CA 파일이 서버 CA 와 다름 | CA 지문 비교 |
| `NTP 동기화 아님` | 장비 시각 어긋남 | 서버와 5분 넘게 어긋나면 ROI·촬영 요청 인증이 거부됨. 시각 동기화 |
| `이미 설치된 장비입니다` | 1번을 설치된 장비에 실행 | 2번/3번을 사용 |
| `.env … ≠ 설정 파일` | 경로 안내가 바뀌었는데 `.env` 는 그대로 | §4 절차 (`--paths-only`) |
| `폴더에 쓸 수 없음` | 폴더 소유자가 서비스 계정이 아님 | `sudo chown gailab:gailab <폴더>` |
| `/healthz 응답 404` | 구 버전 바이너리가 실행 중 | 정상(구 버전에는 `/healthz` 가 없음). 새 바이너리로 교체되면 200 |

---

## 11. 보안 원칙

- 개인키·HMAC 키·토큰·RTSP 계정은 화면·로그·문서·메신저에 올리지 않는다. 키트는 이름과 길이·형식만 확인한다.
- 인증서·키는 **파일 그대로 복사**한다(붙여넣기 금지). 복사 후 해시로 검증한다.
- CA 개인키(`h100-ca.key`)는 관리자 PC 에서만 사용한다. 장비·서버·키트·payload 에 두지 않는다.
- payload 의 개인키 사본은 설치·교체가 끝나면 삭제한다(`--wipe-payload-key`, `shred -u`).
- 개인키 권한은 600, 소유자는 서비스 계정. `ssl/` 폴더는 700.
- 백업 폴더(`~/.h100-device/`)에는 키 사본이 있으므로 권한 700 을 유지한다.
- 이 키트의 패치 스크립트는 `.env` 의 서버 주소(`CLOUD_RECEIVE_IP`)를 바꾸지 않는다. 서버 주소 전환은 별도 절차로 한다.

---

## 12. 확인이 필요한 항목 (디바이스 담당자)

경로 안내서만으로는 정해지지 않은 부분이다. 답을 받으면 이 표를 갱신한다.

| # | 질문 | 현재 가정 |
|---|---|---|
| 1 | ROI 스냅샷 **파일명 규칙과 형식** — module_d 는 `ROI_SNAPSHOT_DIR/<카메라명>.jpg` (JPEG)를 읽는다 | 구현 예정이라 폴더만 만들어 둠. 파일명·형식이 다르면 module_d 수정이 필요 |
| 2 | 상시 녹화(`video/always`)는 module_d 가 전송하지 않아도 되는가 | module_d 는 `video` 바로 아래 파일만 전송하고 하위 폴더는 건너뜀 |
| 3 | `rois.json` 을 Python 이 어떻게 다시 읽는가(주기 읽기 / 변경 감지 / 재시작) | 서버가 ROI 를 저장하면 module_d 가 임시파일→교체로 쓴다 |
| 4 | `recorded` → `output` 개명 시점 | 개명과 `.env` 경로 변경을 같은 점검창에서 |
| 5 | 장비 시각(NTP) 동기화 여부 | 서버와 ±5분 이내 |

---

## 13. 변경 이력

| 날짜 | 내용 |
|---|---|
| 2026-10-29 | 최초 작성: 최초 설치 / 바이너리 패치 / 패치+인증서 교체 스크립트, 경로 계약표(저장경로 안내 2026-10-28 반영) |
