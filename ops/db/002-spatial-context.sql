-- Additive spatial configuration; existing events and device coordinates are preserved.
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
