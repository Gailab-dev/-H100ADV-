// Package detection persists an authenticated camera capture and its event receipt.
package detection

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"time"

	"gorm.io/gorm"
	"local.dev/h100_module_c/database"
	"local.dev/h100_module_c/insertEvent"
	"local.dev/h100_module_c/internal/auth"
)

var requestIDPattern = regexp.MustCompile(`^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$`)

type Capture struct {
	RequestID  string `json:"request_id"`
	Serial     string `json:"serial"`
	CapturedAt string `json:"captured_at"`
	Image      []byte `json:"image"`
}
type Receipt struct {
	RequestID string `gorm:"column:request_id;primaryKey" json:"request_id"`
	Serial    string `gorm:"column:serial" json:"-"`
	EventID   uint   `gorm:"column:event_id" json:"event_id"`
	File      string `gorm:"column:file_name" json:"file"`
	Bytes     int    `gorm:"column:file_bytes" json:"bytes"`
	SHA256    string `gorm:"column:sha256" json:"sha256"`
}

func (Receipt) TableName() string { return "tbl_detection_capture" }
func respond(w http.ResponseWriter, receipt Receipt) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(struct {
		OK bool `json:"ok"`
		Receipt
	}{true, receipt})
}
func receiptFileValid(base string, receipt Receipt) bool {
	image, err := os.ReadFile(filepath.Join(base, receipt.File))
	if err != nil || len(image) != receipt.Bytes {
		return false
	}
	sum := sha256.Sum256(image)
	return hex.EncodeToString(sum[:]) == receipt.SHA256
}

func Handler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", 405)
		return
	}
	raw, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 12<<20))
	if err != nil {
		http.Error(w, "Capture too large", 413)
		return
	}
	serial := r.Header.Get("X-Device-Serial")
	if ok, _ := auth.Verify(serial, r.Header.Get("X-Device-HMAC"), raw); !ok {
		http.Error(w, "Unauthorized", 401)
		return
	}
	var capture Capture
	if json.Unmarshal(raw, &capture) != nil || capture.Serial != serial || !requestIDPattern.MatchString(capture.RequestID) || len(capture.Image) < 32 || len(capture.Image) > (8<<20)+32 || len(capture.Image)%16 != 0 {
		http.Error(w, "Invalid capture", 400)
		return
	}
	captured, err := time.Parse(time.RFC3339, capture.CapturedAt)
	if err != nil {
		http.Error(w, "Invalid capture time", 400)
		return
	}
	base := filepath.Join(os.Getenv("FILE_UPLOAD_PATH"), "output_images_enc")
	var previous Receipt
	found := database.DBConn.First(&previous, "request_id = ?", capture.RequestID)
	if found.Error == nil {
		if previous.Serial != serial {
			http.Error(w, "Request identity conflict", 409)
			return
		}
		if !receiptFileValid(base, previous) {
			http.Error(w, "Stored capture is unavailable", 500)
			return
		}
		respond(w, previous)
		return
	}
	if found.Error != gorm.ErrRecordNotFound {
		http.Error(w, "Capture database unavailable", 503)
		return
	}
	if time.Since(captured) > 5*time.Minute || time.Until(captured) > time.Minute {
		http.Error(w, "Capture time outside accepted window", 400)
		return
	}
	sum := sha256.Sum256(capture.Image)
	receipt := Receipt{RequestID: capture.RequestID, Serial: serial, File: captured.Format("20060102150405") + "_" + capture.RequestID + ".png.enc", Bytes: len(capture.Image), SHA256: hex.EncodeToString(sum[:])}
	if err := os.MkdirAll(base, 0750); err != nil {
		http.Error(w, "Capture storage unavailable", 500)
		return
	}
	finalPath := filepath.Join(base, receipt.File)
	ownedFile := false
	err = database.DBConn.Transaction(func(tx *gorm.DB) error {
		// The primary key serializes retries across concurrent C processes.
		if err := tx.Create(&receipt).Error; err != nil {
			return err
		}
		var device insertEvent.Tbl_Device
		if err := tx.First(&device, "dv_serial_number = ?", serial).Error; err != nil {
			return err
		}
		event := map[string]interface{}{
			"ev_dv_id": device.DvId, "ev_serial_number": serial, "ev_dv_ip": device.DvIp,
			"ev_dv_name": device.DvName, "ev_dv_addr": device.DvAddr, "ev_cd": 4, "ev_action": 0,
			"ev_car_num": "", "ev_img_path": receipt.File, "ev_img_path2": "", "ev_mov_path": "",
			"ev_date": captured.In(time.Local).Format("20060102150405"), "ev_reg_date": time.Now(), "ev_has_img": 1, "ev_has_mov": 0,
		}
		if err := tx.Table("tbl_event_data").Create(event).Error; err != nil {
			return err
		}
		if err := tx.Raw("SELECT LAST_INSERT_ID()").Scan(&receipt.EventID).Error; err != nil || receipt.EventID == 0 {
			return fmt.Errorf("event creation failed")
		}
		note := insertEvent.Tbl_Notification{NotiType: "event", NotiDvId: device.DvId, NotiSerial: serial, NotiTargetId: int(receipt.EventID), NotiTitle: "수동 이상탐지 캡처 - " + device.DvName, NotiRegDate: time.Now()}
		if err := tx.Create(&note).Error; err != nil {
			return err
		}
		file, err := os.OpenFile(finalPath, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0640)
		if err != nil {
			return err
		}
		ownedFile = true
		_, writeErr := file.Write(capture.Image)
		syncErr := file.Sync()
		closeErr := file.Close()
		if writeErr != nil {
			return writeErr
		}
		if syncErr != nil {
			return syncErr
		}
		if closeErr != nil {
			return closeErr
		}
		return tx.Model(&receipt).Update("event_id", receipt.EventID).Error
	})
	if err != nil {
		// A concurrent retry or uncertain commit may have completed successfully.
		var committed Receipt
		checkErr := database.DBConn.First(&committed, "request_id = ?", capture.RequestID).Error
		if checkErr == nil && committed.Serial == serial && receiptFileValid(base, committed) {
			respond(w, committed)
			return
		}
		// Preserve the file when a database outage makes the commit outcome unknown.
		if ownedFile && checkErr == gorm.ErrRecordNotFound {
			os.Remove(finalPath)
		}
		http.Error(w, "Capture storage transaction failed", 500)
		return
	}
	if !receiptFileValid(base, receipt) {
		http.Error(w, "Capture verification failed", 500)
		return
	}
	respond(w, receipt)
}
