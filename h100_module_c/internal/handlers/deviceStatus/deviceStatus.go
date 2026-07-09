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
}

func (Tbl_Device) TableName() string {
	return "tbl_device"
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
