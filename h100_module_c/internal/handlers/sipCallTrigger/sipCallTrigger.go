// (15번 4-3 신설) SIP 응급콜 '실시간' 트리거 수신.
//
//	디바이스가 응급콜 버튼으로 전화를 거는 즉시 호출한다(통화 종료 후 남기는 /insertSipCallLog 와 별개).
//	여기서는 tbl_notification 에만 INSERT 하고, 통화 로그(tbl_sip_call)는 기존 API 가 담당한다.
//	인증: /deviceStatus·/insertSipCallLog 와 동일하게 JSON 수신(HMAC 은 파일 업로드 계열만 적용).
package sipCallTrigger

import (
	"encoding/json"
	"net/http"
	"regexp"
	"strings"
	"time"

	"go.uber.org/zap"

	"local.dev/h100_module_c/database"
	"local.dev/h100_module_c/logger"
)

type SipCallTriggerReq struct {
	SerialNumber string `json:"serial_number"`
	EventType    string `json:"event_type"`  // "call_start" | "call_end"
	OccurredAt   string `json:"occurred_at"` // 선택(로그용)
}

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

func (Tbl_Notification) TableName() string { return "tbl_notification" }

type Tbl_Device struct {
	DvId           uint   `gorm:"primaryKey"`
	DvSerialNumber string `gorm:"column:dv_serial_number"`
	DvName         string `gorm:"column:dv_name"`
}

func (Tbl_Device) TableName() string { return "tbl_device" }

// 시리얼 규칙: 13자리 숫자 (다른 핸들러와 동일)
var serialRe = regexp.MustCompile(`^[0-9]{13}$`)

func clientIP(r *http.Request) string {
	ip := r.Header.Get("X-Forwarded-For")
	if ip == "" {
		ip = strings.Split(r.RemoteAddr, ":")[0]
	}
	return ip
}

func SipCallTriggerHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "POST 요청만 허용됩니다.", http.StatusMethodNotAllowed)
		return
	}

	var req SipCallTriggerReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		logger.Log.Warn("[SIP_TRIGGER_BAD_JSON]", zap.Error(err))
		http.Error(w, "JSON 파싱 오류", http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	if !serialRe.MatchString(req.SerialNumber) {
		logger.Log.Warn("[SIP_TRIGGER_INVALID_SERIAL]",
			zap.String("client_ip", clientIP(r)))
		http.Error(w, "Invalid serial", http.StatusBadRequest)
		return
	}

	// 미등록 시리얼은 자동 등록하지 않고 무시(다른 핸들러와 동일한 보안 정책)
	var device Tbl_Device
	if result := database.DBConn.Where("dv_serial_number = ?", req.SerialNumber).First(&device); result.Error != nil {
		logger.Log.Info("[SIP_TRIGGER_NEW_DEVICE] 미등록 시리얼(무시)",
			zap.String("client_ip", clientIP(r)))
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]interface{}{"result": "ignored_new_device"})
		return
	}

	// 통화 '시작' 만 알림 대상 (종료는 기존 /insertSipCallLog 가 사후 로그로 남김)
	if req.EventType != "call_start" {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]interface{}{"result": "ignored_event_type"})
		return
	}

	noti := Tbl_Notification{
		NotiType:    "sip_call",
		NotiDvId:    device.DvId,
		NotiSerial:  req.SerialNumber,
		NotiTitle:   "응급콜 발생 - " + device.DvName,
		NotiIsRead:  0,
		NotiRegDate: time.Now(),
	}
	if ins := database.DBConn.Create(&noti); ins.Error != nil {
		logger.Log.Error("[SIP_TRIGGER_DB] 알림 INSERT 실패", zap.Error(ins.Error))
		http.Error(w, "INSERT 실패", http.StatusInternalServerError)
		return
	}

	logger.Log.Info("[SIP_TRIGGER_OK] 응급콜 알림 생성",
		zap.Uint("dv_id", device.DvId), zap.Uint("noti_id", noti.NotiId))

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success":         true,
		"notification_id": noti.NotiId,
	})
}
