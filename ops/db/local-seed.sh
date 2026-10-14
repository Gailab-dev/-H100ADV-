#!/bin/sh
set -eu
case "$H100_DEMO_PASSWORD_HASH" in *[!A-Za-z0-9+/=]*|'') echo 'Invalid local password hash'; exit 1;; esac
MYSQL_PWD="$MARIADB_PASSWORD" mariadb -u "$MARIADB_USER" "$MARIADB_DATABASE" <<SQL
SET NAMES utf8mb4;
INSERT INTO tbl_user (u_login_id,u_login_pwd,u_name,u_email,u_phone,u_grade,u_region,u_req_date)
VALUES ('local_admin','$H100_DEMO_PASSWORD_HASH','로컬 검증 관리자','local@example.invalid','01000000000',0,'광주광역시',NOW());
INSERT INTO tbl_device (dv_name,dv_addr,dv_addr_detail,dv_ip,dv_serial_number,dv_lat,dv_lng,dv_status_pc,dv_status_cctv,dv_lens,dv_status_speaker,dv_status_sip,dv_status_updated) VALUES
('검증 장비 01','광주광역시 서구 내방로 111','검증 데이터','module-d:8443','2026101400001',35.1595,126.8526,1,1,1,1,1,NOW()),
('검증 장비 02','광주광역시 북구','검증 데이터','192.0.2.22:8443','2026101400002',35.1740,126.9120,1,0,1,1,1,NOW()),
('검증 장비 03','광주광역시 동구','검증 데이터','192.0.2.23:8443','2026101400003',35.1460,126.9230,1,1,1,1,1,DATE_SUB(NOW(), INTERVAL 1 HOUR));
INSERT INTO tbl_event_data (ev_dv_id,ev_serial_number,ev_dv_name,ev_dv_addr,ev_car_num,ev_cd,ev_action,ev_date) VALUES
(1,'2026101400001','검증 장비 01','광주광역시 서구','검증차량01',1,0,DATE_FORMAT(NOW(),'%Y%m%d%H%i%s')),
(2,'2026101400002','검증 장비 02','광주광역시 북구','검증차량02',5,1,DATE_FORMAT(NOW(),'%Y%m%d%H%i%s'));
INSERT INTO tbl_sip_call(sc_dv_id,sc_serial_number,sc_start_date,sc_end_date,sc_duration,sc_direction,sc_status) VALUES
(1,'2026101400001',DATE_SUB(NOW(),INTERVAL 2 MINUTE),NOW(),120,'inbound','completed');
INSERT INTO tbl_region(rg_name,rg_depth,rg_p_id,rg_org) VALUES ('광주광역시',1,0,1),('서구',2,1,2);
INSERT INTO tbl_statistics VALUES (DATE_FORMAT(NOW(),'%Y%m'),1,1),(DATE_FORMAT(NOW(),'%Y%m'),5,1);
SQL
echo 'Local verification fixtures created.'
