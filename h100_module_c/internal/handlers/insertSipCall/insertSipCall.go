// Package insertSipCall: SIP CALL 로그 수신 핸들러 (작업계획서 07 / DB설계서 v0.0.7 tbl_sip_call = AP_DB_0012)
//
// POST /insertSipCallLog  — 디바이스가 통화 종료 후 통화 로그를 보고 → tbl_sip_call INSERT
//
// 정책(작업계획서 §2-1, §7 / device-status(04) 패턴 재사용):
//   - 시리얼 유효성 검증(13자리 숫자) 실패 → logger [INVALID_SERIAL] + 400
//   - 신규 시리얼(DB 없음) → logger [NEW_DEVICE_SIP] 만, DB 자동등록 X → 200(조용히 무시)
//   - 기존 시리얼 → 매칭 디바이스별 INSERT (이벤트 INSERT 패턴 재사용, sc_dv_id 자동 채움)
//   - Phase 2 HMAC 은 본 영역 범위 외(별도) — /deviceStatus 와 동일하게 JSON 수신
//
// DB v0.0.7 정합(작업계획서 §9 게이트 결과 — 계획서 가정과 달라 DB 기준으로 정정):
//
//	sc_serial_number = varchar(15) (계획서 13 → DB 15), sc_start_date/sc_end_date(varchar20)·sc_has_audio 존재.
//	sc_has_audio 는 서버가 오디오 파일명 유무로 파생(1:있음/0:없음). sc_reg_date 는 Go time.Now().
package insertSipCall

import (
	"encoding/json"
	"fmt"
	"net/http"
	"regexp"
	"strings"
	"time"

	"go.uber.org/zap"

	"local.dev/h100_module_c/database"
	"local.dev/h100_module_c/logger"
)

// 디바이스가 보내는 SIP 통화 로그 본문
type SipCallReq struct {
	SerialNumber string `json:"serial_number"`
	ScStartDate  string `json:"sc_start_date"` // 통화 시작(문자열 yyyyMMddHHmmss, ev_date 패턴)
	ScEndDate    string `json:"sc_end_date"`   // 통화 종료(선택)
	ScDuration   int    `json:"sc_duration"`   // 통화 시간(초)
	ScStatus     int    `json:"sc_status"`     // 0:발신 1:응답 2:부재중 3:실패
	ScDirection  int    `json:"sc_direction"`  // 0:인바운드 1:아웃바운드
	ScAudioPath  string `json:"sc_audio_path"` // 음성 파일명(없으면 통화 부재중·실패)
}

// tbl_device 조회용 최소 매핑 (이벤트 INSERT 패턴 재사용)
type Tbl_Device struct {
	DvId           uint   `gorm:"primaryKey" json:"dv_id"`
	DvSerialNumber string `json:"dv_serial_number"`
}

func (Tbl_Device) TableName() string { return "tbl_device" }

// tbl_sip_call INSERT용 매핑 (DB설계서 v0.0.7 AP_DB_0012)
type Tbl_Sip_Call struct {
	ScId           uint      `gorm:"primaryKey;column:sc_id" json:"sc_id"`
	ScDvId         uint      `gorm:"column:sc_dv_id" json:"sc_dv_id"`
	ScSerialNumber string    `gorm:"column:sc_serial_number" json:"sc_serial_number"`
	ScStartDate    string    `gorm:"column:sc_start_date" json:"sc_start_date"`
	ScEndDate      string    `gorm:"column:sc_end_date" json:"sc_end_date"`
	ScDuration     int       `gorm:"column:sc_duration" json:"sc_duration"`
	ScStatus       int       `gorm:"column:sc_status" json:"sc_status"`
	ScDirection    int       `gorm:"column:sc_direction" json:"sc_direction"`
	ScAudioPath    string    `gorm:"column:sc_audio_path" json:"sc_audio_path"`
	ScHasAudio     int       `gorm:"column:sc_has_audio" json:"sc_has_audio"`
	ScRegDate      time.Time `gorm:"column:sc_reg_date" json:"sc_reg_date"`
}

func (Tbl_Sip_Call) TableName() string { return "tbl_sip_call" }

// 시리얼 규칙: 13자리 숫자 (작업계획서). DB sc_serial_number 는 varchar(15)
var serialRe = regexp.MustCompile(`^[0-9]{13}$`)

func clientIP(r *http.Request) string {
	ip := r.Header.Get("X-Forwarded-For")
	if ip == "" {
		ip = strings.Split(r.RemoteAddr, ":")[0]
	}
	return ip
}

// InsertSipCallHandler: POST /insertSipCallLog
func InsertSipCallHandler(w http.ResponseWriter, r *http.Request) {

	logger.Log.Info("[SIP_CALL_ENTRY] /insertSipCallLog 요청 수신",
        zap.String("method", r.Method),
		zap.String("client_ip", clientIP(r)))

	if r.Method != http.MethodPost {
		http.Error(w, "POST 요청만 허용됩니다.", http.StatusMethodNotAllowed)
		return
	}

	var req SipCallReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		logger.Log.Warn("[SIP_BAD_JSON] JSON 파싱 실패", zap.String("client_ip", clientIP(r)), zap.Error(err))
		http.Error(w, "JSON 파싱 오류", http.StatusBadRequest)
		return
	}

	// 1. 시리얼 유효성 검증
	if !serialRe.MatchString(req.SerialNumber) {
		logger.Log.Warn("[INVALID_SERIAL] 유효하지 않은 시리얼(SIP)",
			zap.String("serial", req.SerialNumber), zap.String("client_ip", clientIP(r)))
		http.Error(w, "Invalid serial", http.StatusBadRequest)
		return
	}

	// 2. 시리얼 → tbl_device 조회 (이벤트 INSERT 패턴 재사용)
	var devices []Tbl_Device
	result := database.DBConn.Where("dv_serial_number = ?", req.SerialNumber).Find(&devices)
	if result.Error != nil {
		logger.Log.Error("[SIP_DB] 디바이스 조회 실패", zap.String("serial", req.SerialNumber), zap.Error(result.Error))
		http.Error(w, "디바이스 조회 실패", http.StatusInternalServerError)
		return
	}

	// 3. 신규 시리얼(DB 없음) → 자동 등록 X, 로그만 (04 결정 정합)
	if len(devices) == 0 {
		logger.Log.Info("[NEW_DEVICE_SIP] 미등록 시리얼(무시)",
			zap.String("serial", req.SerialNumber), zap.String("client_ip", clientIP(r)))
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, `{"result":"ignored_new_device"}`)
		return
	}

	// 4. sc_has_audio 파생: 오디오 파일명 유무 (통화 부재중·실패는 보통 파일 없음)
	hasAudio := 0
	if strings.TrimSpace(req.ScAudioPath) != "" {
		hasAudio = 1
	}

	// 5. 매칭 디바이스별 INSERT
	inserted := 0
	var insertedIds []uint
	for _, device := range devices {
		sipCall := Tbl_Sip_Call{
			ScDvId:         device.DvId,
			ScSerialNumber: req.SerialNumber,
			ScStartDate:    req.ScStartDate,
			ScEndDate:      req.ScEndDate,
			ScDuration:     req.ScDuration,
			ScStatus:       req.ScStatus,
			ScDirection:    req.ScDirection,
			ScAudioPath:    req.ScAudioPath,
			ScHasAudio:     hasAudio,
			ScRegDate:      time.Now(),
		}
		if ins := database.DBConn.Create(&sipCall); ins.Error != nil {
			logger.Log.Error("[SIP_DB] INSERT 실패", zap.Uint("dv_id", device.DvId), zap.Error(ins.Error))
			continue
		}
		inserted++
		insertedIds = append(insertedIds, sipCall.ScId)
	}

	if inserted == 0 {
		http.Error(w, "모든 INSERT 실패", http.StatusInternalServerError)
		return
	}

	logger.Log.Info("[SIP_OK] SIP 통화 로그 저장",
		zap.String("serial", req.SerialNumber), zap.Int("inserted", inserted),
		zap.Int("status", req.ScStatus), zap.Int("direction", req.ScDirection), zap.Int("has_audio", hasAudio))

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success":        true,
		"inserted_count": inserted,
		"inserted_ids":   insertedIds,
	})
}
