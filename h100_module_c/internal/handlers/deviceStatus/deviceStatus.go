// Package deviceStatus: 디바이스 Heartbeat(상태) 수신 핸들러 (작업계획서 04 / DB설계서 v0.0.7)
//
// POST /deviceStatus  — 디바이스가 주기적으로 5가지 상태를 보고 → tbl_device UPDATE
//
// 정책(작업계획서 §1, §7):
//   - 시리얼 유효성 검증(13자리 숫자) 실패 → logger + 400
//   - 신규 시리얼(DB 없음) → logger 만, DB 자동등록 X → 200(조용히 무시)
//   - 기존 시리얼 → 상태 5종 + dv_status_updated UPDATE
//   - Phase 2 HMAC 은 본 영역 범위 외(별도)
//
// 상태 컬럼(DB v0.0.7 tbl_device): dv_status_pc / dv_status_cctv / dv_lens / dv_status_speaker / dv_status_sip
//
//	※ dv_status_display 는 DB v0.0.7 에 없음(전광판 단방향 불가로 제외) → 수신/반영하지 않음
package deviceStatus

import (
	"encoding/json"
	"fmt"
	"net/http"
	"regexp"
	"strings"
	"time"

	"go.uber.org/zap"
	"gorm.io/gorm"

	"local.dev/h100_module_c/database"
	"local.dev/h100_module_c/logger"
)

// 디바이스가 보내는 상태 본문 (0:이상 / 1:정상, 누락 시 0)
type StatusReq struct {
	SerialNumber    string `json:"serial_number"`
	DvStatusPc      int    `json:"dv_status_pc"`
	DvStatusCctv    int    `json:"dv_status_cctv"`
	DvLens          int    `json:"dv_lens"`
	DvStatusSpeaker int    `json:"dv_status_speaker"`
	DvStatusSip     int    `json:"dv_status_sip"`
}

// 존재 확인용 최소 매핑
type Tbl_Device struct {
	DvId           uint   `gorm:"primaryKey"`
	DvSerialNumber string
	// (15번 4-5) 이상 로그 감지를 위해 '이전 상태값' 도 함께 조회한다.
	DvName          string `gorm:"column:dv_name"`
	DvStatusPc      int    `gorm:"column:dv_status_pc"`
	DvStatusCctv    int    `gorm:"column:dv_status_cctv"`
	DvLens          int    `gorm:"column:dv_lens"`
	DvStatusSpeaker int    `gorm:"column:dv_status_speaker"`
	DvStatusSip     int    `gorm:"column:dv_status_sip"`
}

func (Tbl_Device) TableName() string {
	return "tbl_device"
}

// (15번 4-5 신설) 디바이스 상태 변경 이력
type Tbl_Device_Error_Log struct {
	DelId         uint      `gorm:"primaryKey;column:del_id"`
	DelDvId       uint      `gorm:"column:del_dv_id"`
	DelStatusType string    `gorm:"column:del_status_type"`
	DelOldValue   int       `gorm:"column:del_old_value"`
	DelNewValue   int       `gorm:"column:del_new_value"`
	DelRegDate    time.Time `gorm:"column:del_reg_date"`
}

func (Tbl_Device_Error_Log) TableName() string { return "tbl_device_error_log" }

// (15번 4-2 신설) 헤더 알림
type Tbl_Notification struct {
	NotiId       uint      `gorm:"primaryKey;column:noti_id"`
	NotiType     string    `gorm:"column:noti_type"`
	NotiDvId     uint      `gorm:"column:noti_dv_id"`
	NotiSerial   string    `gorm:"column:noti_serial"`
	NotiTargetId int       `gorm:"column:noti_target_id"`
	NotiTitle    string    `gorm:"column:noti_title"`
	NotiIsRead   int       `gorm:"column:noti_is_read"`
	NotiRegDate  time.Time `gorm:"column:noti_reg_date"`
}

func (Tbl_Notification) TableName() string { return "tbl_notification_log" }

/**
 * (15번 4-5) 상태 5종 중 '값이 바뀐 항목'만 이상 로그로 남기고,
 * 새로 이상이 된 항목(정상 1 → 그 외)은 헤더 알림도 함께 생성한다.
 *  - 매 heartbeat 마다가 아니라 '변경 시점'에만 INSERT (계획서 §8 주의영역)
 *  - 로그/알림 INSERT 실패가 heartbeat 본 처리를 막지 않도록 오류는 로그만 남긴다.
 */
func recordStatusChanges(old Tbl_Device, req StatusReq) {
	type change struct {
		name string
		o    int
		n    int
	}
	changes := []change{
		{"pc", old.DvStatusPc, req.DvStatusPc},
		{"cctv", old.DvStatusCctv, req.DvStatusCctv},
		{"lens", old.DvLens, req.DvLens},
		{"speaker", old.DvStatusSpeaker, req.DvStatusSpeaker},
		{"sip", old.DvStatusSip, req.DvStatusSip},
	}

	for _, c := range changes {
		if c.o == c.n {
			continue // 변경 없음 → 기록하지 않음
		}

		errorLog := Tbl_Device_Error_Log{
			DelDvId:       old.DvId,
			DelStatusType: c.name,
			DelOldValue:   c.o,
			DelNewValue:   c.n,
			DelRegDate:    time.Now(),
		}
		if ins := database.DBConn.Create(&errorLog); ins.Error != nil {
			logger.Log.Error("[ERR_LOG_DB] 이상 로그 INSERT 실패",
				zap.String("type", c.name), zap.Error(ins.Error))
			continue
		}

		// 정상(1) 이 아닌 값으로 바뀐 경우에만 알림 생성 (정상 복구는 알림 X)
		if c.n != 1 {
			noti := Tbl_Notification{
				NotiType:     "device_error",
				NotiDvId:     old.DvId,
				NotiSerial:   req.SerialNumber,
				NotiTargetId: int(errorLog.DelId),
				NotiTitle:    fmt.Sprintf("디바이스 이상 - %s (%s)", old.DvName, c.name),
				NotiIsRead:   0,
				NotiRegDate:  time.Now(),
			}
			if ins := database.DBConn.Create(&noti); ins.Error != nil {
				logger.Log.Error("[NOTI_DB] 이상 알림 INSERT 실패", zap.Error(ins.Error))
			}
		}

		logger.Log.Info("[ERR_LOG] 디바이스 상태 변경 기록",
			zap.Uint("dv_id", old.DvId), zap.String("type", c.name),
			zap.Int("old", c.o), zap.Int("new", c.n))
	}
}

// 시리얼 규칙: 13자리 숫자 (작업계획서). DB dv_serial_number 는 varchar(15)
var serialRe = regexp.MustCompile(`^[0-9]{13}$`)

func clientIP(r *http.Request) string {
	ip := r.Header.Get("X-Forwarded-For")
	if ip == "" {
		ip = strings.Split(r.RemoteAddr, ":")[0]
	}
	return ip
}

// DeviceStatusHandler: POST /deviceStatus
func DeviceStatusHandler(w http.ResponseWriter, r *http.Request) {

	logger.Log.Info("[DEVICE_STATUS_ENTRY] /deviceStatus 요청 수신",
        zap.String("method", r.Method),
		zap.String("client_ip", clientIP(r)))

	if r.Method != http.MethodPost {
		http.Error(w, "POST 요청만 허용됩니다.", http.StatusMethodNotAllowed)
		return
	}

	var req StatusReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		logger.Log.Warn("[STATUS_BAD_JSON] JSON 파싱 실패", zap.String("client_ip", clientIP(r)), zap.Error(err))
		http.Error(w, "JSON 파싱 오류", http.StatusBadRequest)
		return
	}

	// 1. 시리얼 유효성 검증
	if !serialRe.MatchString(req.SerialNumber) {
		logger.Log.Warn("[INVALID_SERIAL] 유효하지 않은 시리얼",
			zap.String("serial", req.SerialNumber), zap.String("client_ip", clientIP(r)))
		http.Error(w, "Invalid serial", http.StatusBadRequest)
		return
	}

	// 2. DB 조회 (존재 확인)
	var device Tbl_Device
	result := database.DBConn.Where("dv_serial_number = ?", req.SerialNumber).First(&device)
	if result.Error == gorm.ErrRecordNotFound {
		// 신규 시리얼 → 자동 등록 X, 로그만 (보안 정책)
		logger.Log.Info("[NEW_DEVICE] 미등록 시리얼(무시)",
			zap.String("serial", req.SerialNumber), zap.String("client_ip", clientIP(r)))
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, `{"result":"ignored_new_device"}`)
		return
	}
	if result.Error != nil {
		logger.Log.Error("[STATUS_DB] 디바이스 조회 실패", zap.String("serial", req.SerialNumber), zap.Error(result.Error))
		http.Error(w, "DB 조회 실패", http.StatusInternalServerError)
		return
	}

	// (15번 4-5) UPDATE 전에 '이전 값 ↔ 새 값' 을 비교해 변경분만 이상 로그·알림으로 남긴다.
	//   UPDATE 이후에는 이전 값을 알 수 없으므로 반드시 이 위치여야 한다.
	recordStatusChanges(device, req)

	// 3. 기존 디바이스 → 상태 5종 + 갱신시각 UPDATE
	// map 사용: 값 0(이상)도 누락 없이 반영(GORM zero-value 생략 회피), 지정 컬럼만 갱신
	upd := database.DBConn.Model(&Tbl_Device{}).
		Where("dv_serial_number = ?", req.SerialNumber).
		Updates(map[string]interface{}{
			"dv_status_pc":      req.DvStatusPc,
			"dv_status_cctv":    req.DvStatusCctv,
			"dv_lens":           req.DvLens,
			"dv_status_speaker": req.DvStatusSpeaker,
			"dv_status_sip":     req.DvStatusSip,
			"dv_status_updated": time.Now(),
		})
	if upd.Error != nil {
		logger.Log.Error("[STATUS_DB] 상태 UPDATE 실패", zap.String("serial", req.SerialNumber), zap.Error(upd.Error))
		http.Error(w, "상태 갱신 실패", http.StatusInternalServerError)
		return
	}

	logger.Log.Info("[STATUS_OK] 상태 갱신",
		zap.String("serial", req.SerialNumber),
		zap.Int("pc", req.DvStatusPc), zap.Int("cctv", req.DvStatusCctv), zap.Int("lens", req.DvLens),
		zap.Int("speaker", req.DvStatusSpeaker), zap.Int("sip", req.DvStatusSip))

	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, `{"result":"ok"}`)
}
