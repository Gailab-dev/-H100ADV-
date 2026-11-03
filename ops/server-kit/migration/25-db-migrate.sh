#!/usr/bin/env bash
# HEAD 코드가 쓰는 신규 테이블 5개를 h100-db(able_park)에 추가 (기존 데이터 변경·삭제 없음, 재실행 가능)
#   tbl_roi_history, tbl_roi_snapshot, tbl_detection_capture, tbl_device_geofence, tbl_event_vehicle_pose
# 제외(의도적): evt_roi_history_purge 이벤트(컷오버 후 별도), u_grade=25 장비관리자 지정(추후)
# 사용: sudo ./25-db-migrate.sh            # 점검만 (읽기 전용)
#       sudo ./25-db-migrate.sh --apply    # 백업 → 적용 → 검증
# 주의: 컷오버 때 20-db-restore.sh --mode final 이 able_park 을 DROP 후 덤프로 교체하므로,
#       구 DB 에 없는 테이블(지오펜스·캡처·차량위치)은 사라진다 → 최종 복원 직후 이 스크립트를 다시 실행할 것.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"
need_root
APPLY=0
while [ $# -gt 0 ]; do case "$1" in --apply) APPLY=1; shift;; --yes) ASSUME_YES=1; shift;; *) echo "알 수 없는 옵션 $1"; exit 2;; esac; done

load_db_env || { summary; exit 1; }
docker inspect -f '{{.State.Health.Status}}' h100-db 2>/dev/null | grep -q healthy && ok "h100-db healthy" || { bad "h100-db 가 healthy 가 아님"; summary; exit 1; }

NEW_TABLES="tbl_roi_history tbl_roi_snapshot tbl_detection_capture tbl_device_geofence tbl_event_vehicle_pose"

# 1) 컬럼 점검: 6행이어야 함
COLS=$(dbx -N -e "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='able_park' AND ((TABLE_NAME='tbl_device' AND COLUMN_NAME IN ('dv_lat','dv_lng','dv_addr_detail')) OR (TABLE_NAME='tbl_event_data' AND COLUMN_NAME IN ('ev_is_deleted','ev_deleted_at','ev_deleted_by')))" </dev/null)
[ "$COLS" = "6" ] && ok "기존 테이블 필수 컬럼 6/6 존재" || bad "필수 컬럼 ${COLS:-?}/6 — 저장소SQL파일_보관 3절(소프트 삭제 컬럼) 적용 필요, 여기서 중단"
[ "$COLS" = "6" ] || { summary; exit 1; }

# 2) 현재 상태
for t in $NEW_TABLES; do
  n=$(dbx -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='able_park' AND table_name='$t'" </dev/null)
  [ "$n" = "1" ] && info "$t: 이미 있음" || info "$t: 없음"
done

if [ "$APPLY" -ne 1 ]; then info "점검만 수행했습니다. 적용하려면 --apply"; summary; exit $?; fi

confirm "able_park 에 신규 테이블 5개를 추가합니다(IF NOT EXISTS)." || { say "중단"; exit 1; }

# 3) 백업
BK="$WORK/pre-migrate-able_park.sql.gz"
docker exec -e MYSQL_PWD h100-db mariadb-dump -uroot --single-transaction --routines --triggers --events --databases able_park </dev/null | gzip > "$BK" \
  && [ -s "$BK" ] && ok "적용 전 백업 $BK" || { bad "백업 실패 — 중단"; summary; exit 1; }
chmod 600 "$BK"

# 4) 적용
dbx able_park >>"$LOG" 2>&1 <<'SQL' && ok "CREATE TABLE IF NOT EXISTS 5개 실행" || { bad "적용 실패 (로그 참조)"; summary; exit 1; }
CREATE TABLE IF NOT EXISTS tbl_roi_history (
    rh_id int NOT NULL AUTO_INCREMENT COMMENT 'ROI 이력 ID',
    rh_dv_id int NOT NULL COMMENT '장치 ID (tbl_device.dv_id)',
    rh_action varchar(10) NOT NULL COMMENT 'CREATE/UPDATE/ROLLBACK/SYNC',
    rh_roi_json text NOT NULL COMMENT 'ROI JSON 원문',
    rh_meta_json text NULL COMMENT '웹 전용 부가정보(도형 이름 등)',
    rh_roi_hash char(64) NOT NULL COMMENT 'rh_roi_json SHA-256',
    rh_base_hash char(64) NULL COMMENT '편집 시작 시점 디바이스 해시',
    rh_status varchar(10) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING/SUCCESS/FAIL',
    rh_fail_code int NULL COMMENT '실패 코드(409, 400, 503 등)',
    rh_fail_msg varchar(200) NULL COMMENT '실패 메시지',
    rh_u_name varchar(40) NOT NULL COMMENT '요청자 이름 (SYNC는 SYSTEM)',
    rh_req_date datetime NOT NULL DEFAULT now() COMMENT '요청 시각',
    rh_resp_date datetime NULL COMMENT '디바이스 응답 시각',
    PRIMARY KEY (rh_id),
    KEY ix_rh_dv_status (rh_dv_id, rh_status, rh_id),
    KEY ix_rh_req_date (rh_req_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='ROI 설정 적용 이력';

CREATE TABLE IF NOT EXISTS tbl_roi_snapshot (
    rs_id int NOT NULL AUTO_INCREMENT COMMENT '스냅샷 ID',
    rs_rh_id int NOT NULL COMMENT 'ROI 이력 ID (tbl_roi_history.rh_id)',
    rs_camera varchar(4) NOT NULL COMMENT '카메라 구분 (Cam1 / Cam2)',
    rs_file_path varchar(300) NOT NULL COMMENT '이미지 파일 경로 (공유 미디어 기준 상대 경로)',
    rs_width int NOT NULL COMMENT '이미지 너비(px)',
    rs_height int NOT NULL COMMENT '이미지 높이(px)',
    rs_taken_date datetime NOT NULL DEFAULT now() COMMENT '스냅샷 수신 시각',
    PRIMARY KEY (rs_id),
    UNIQUE KEY ux_rs_rh_camera (rs_rh_id, rs_camera)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='ROI 적용 시점의 카메라별 기준 스냅샷';

CREATE TABLE IF NOT EXISTS tbl_detection_capture (
    request_id CHAR(36) NOT NULL PRIMARY KEY,
    serial VARCHAR(30) NOT NULL,
    event_id INT UNSIGNED NOT NULL DEFAULT 0,
    file_name VARCHAR(160) NOT NULL,
    file_bytes INT UNSIGNED NOT NULL,
    sha256 CHAR(64) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX capture_event(event_id)
) CHARACTER SET utf8mb4;

CREATE TABLE IF NOT EXISTS tbl_device_geofence (
    dv_id INT NOT NULL PRIMARY KEY,
    boundary_json TEXT NOT NULL,
    updated_by INT NOT NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4;

CREATE TABLE IF NOT EXISTS tbl_event_vehicle_pose (
    ev_id INT NOT NULL PRIMARY KEY,
    vehicle_lat DECIMAL(12,8) NOT NULL,
    vehicle_lng DECIMAL(12,8) NOT NULL,
    heading DECIMAL(6,2) NOT NULL,
    updated_by INT NOT NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4;
SQL

# 5) 검증
for t in $NEW_TABLES; do
  n=$(dbx -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='able_park' AND table_name='$t'" </dev/null)
  [ "$n" = "1" ] && ok "$t 존재" || bad "$t 없음"
done
T=$(dbx -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='able_park'" </dev/null)
info "able_park 테이블 수: $T (기대: 13 + 신규 중 새로 만든 것)"

# 6) 앱 계정 권한이 able_park.* 로 부여되어 있는지 (신규 테이블 자동 포함)
for u in h100_web h100_module_c; do
  g=$(dbx -N -e "SHOW GRANTS FOR '$u'@'172.31.100.%'" </dev/null 2>/dev/null | grep -c 'ON `able_park`\.\*')
  [ "${g:-0}" -ge 1 ] && ok "$u: able_park.* 권한 (신규 테이블 포함)" || bad "$u: able_park.* 권한 없음 — 테이블 단위 부여인지 확인"
done
# 이벤트 상태(변경 없음 확인용)
dbx -N -e "SELECT event_name, status FROM information_schema.events WHERE event_schema='able_park'" </dev/null | sed 's/^/[INFO] event: /' | tee -a "$LOG"
info "evt_roi_history_purge 는 컷오버 후 별도 생성, u_grade=25 지정은 추후"
summary
