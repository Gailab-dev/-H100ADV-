-- Local verification schema derived from Java mappers and Go models.
-- This is NOT an authoritative production migration or production DB dump.
SET NAMES utf8mb4;
CREATE TABLE tbl_user (
 u_id INT AUTO_INCREMENT PRIMARY KEY, u_org_id INT DEFAULT 1,
 u_login_id VARCHAR(100) NOT NULL UNIQUE, u_login_pwd VARCHAR(200) NOT NULL,
 u_name VARCHAR(100), u_email VARCHAR(200), u_phone VARCHAR(50), u_grade INT DEFAULT 0,
 u_region VARCHAR(200), u_pwd_changed INT DEFAULT 1, u_pwd_changed_dt DATETIME DEFAULT CURRENT_TIMESTAMP,
 u_login_fail_count INT DEFAULT 0, u_account_locked CHAR(1) DEFAULT 'N', u_lock_time DATETIME,
 u_req_user INT, u_mod_user INT, u_req_date DATETIME, u_mod_date DATETIME
) CHARACTER SET utf8mb4;
CREATE TABLE tbl_device (
 dv_id INT AUTO_INCREMENT PRIMARY KEY, dv_org_id INT DEFAULT 1, dv_name VARCHAR(200),
 dv_addr VARCHAR(300), dv_addr_detail VARCHAR(200), dv_ip VARCHAR(200), dv_serial_number VARCHAR(30) UNIQUE,
 dv_lat DECIMAL(12,8), dv_lng DECIMAL(12,8), dv_status INT DEFAULT 1,
 dv_status_pc INT DEFAULT 0, dv_status_cctv INT DEFAULT 0, dv_lens INT DEFAULT 0,
 dv_status_speaker INT DEFAULT 0, dv_status_sip INT DEFAULT 0, dv_status_updated DATETIME,
 dv_reg_user INT, dv_mod_user INT, dv_reg_date DATETIME DEFAULT CURRENT_TIMESTAMP, dv_mod_date DATETIME
) CHARACTER SET utf8mb4;
CREATE TABLE tbl_event_data (
 ev_id INT AUTO_INCREMENT PRIMARY KEY, ev_dv_id INT, ev_serial_number VARCHAR(30),
 ev_dv_ip VARCHAR(200), ev_dv_name VARCHAR(200), ev_dv_addr VARCHAR(300), ev_car_num VARCHAR(50),
 ev_cd INT, ev_action INT DEFAULT 0, ev_date VARCHAR(20), ev_el_id INT,
 ev_mov_path VARCHAR(500), ev_img_path VARCHAR(500), ev_img_path2 VARCHAR(500),
 ev_has_img INT DEFAULT 0, ev_has_mov INT DEFAULT 0, ev_reg_date DATETIME DEFAULT CURRENT_TIMESTAMP,
 ev_is_deleted INT DEFAULT 0, ev_deleted_at DATETIME, ev_deleted_by INT,
 INDEX event_date(ev_date), INDEX event_device(ev_dv_id)
) CHARACTER SET utf8mb4;
CREATE TABLE tbl_sip_call (
 sc_id INT AUTO_INCREMENT PRIMARY KEY, sc_dv_id INT, sc_serial_number VARCHAR(30),
 sc_start_date DATETIME, sc_end_date DATETIME, sc_duration INT DEFAULT 0, sc_direction VARCHAR(20),
 sc_status VARCHAR(20), sc_has_audio INT DEFAULT 0, sc_audio_path VARCHAR(500), sc_reg_date DATETIME DEFAULT CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4;
CREATE TABLE tbl_notification_log (
 noti_id INT AUTO_INCREMENT PRIMARY KEY, noti_type VARCHAR(40), noti_dv_id INT, noti_serial VARCHAR(30),
 noti_target_id INT, noti_title VARCHAR(300), noti_is_read INT DEFAULT 0,
 noti_read_date DATETIME, noti_reg_date DATETIME DEFAULT CURRENT_TIMESTAMP,
 INDEX unread(noti_is_read, noti_reg_date)
) CHARACTER SET utf8mb4;
CREATE TABLE tbl_device_error_log (
 del_id INT AUTO_INCREMENT PRIMARY KEY, del_dv_id INT, del_status_type VARCHAR(50),
 del_old_value INT, del_new_value INT, del_reg_date DATETIME DEFAULT CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4;
CREATE TABLE tbl_region (
 rg_id INT AUTO_INCREMENT PRIMARY KEY, rg_name VARCHAR(100), rg_depth INT, rg_p_id INT,
 rg_org INT, rg_reg_user INT, rg_mod_user INT, rg_reg_date DATETIME, rg_mod_date DATETIME
) CHARACTER SET utf8mb4;
CREATE TABLE tbl_statistics (st_date VARCHAR(6), st_cd INT, st_cnt INT, PRIMARY KEY(st_date, st_cd));
