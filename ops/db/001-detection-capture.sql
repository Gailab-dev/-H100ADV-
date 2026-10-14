-- Additive migration. Apply to an existing H100 database before using the capture trigger.
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
