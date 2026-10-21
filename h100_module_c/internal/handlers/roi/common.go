// Package roi 는 웹(Java)이 요청한 ROI 조회·스냅샷·적용을 디바이스(module_d)에 중계한다(34번 작업계획서).
//
//	Java --Bearer(H100_ROI_TOKEN)--> module_c --HMAC(디바이스 키)--> module_d
//
//	ROI_get      디바이스의 현재 ROI 파일 내용 + 해시
//	ROI_snapshot Cam1/Cam2 스냅샷을 받아 서버 임시 폴더에 저장
//	ROI_send     baseHash 와 함께 새 ROI 를 디바이스에 적용(낙관적 잠금, 충돌 시 409)
//
// module_c 는 ROI 내용을 해석하지 않는다(검증은 웹과 디바이스가 한다). 디바이스 주소는 요청이 아니라
// 등록된 디바이스(tbl_device)에서만 가져온다.
package roi

import (
	"crypto/subtle"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"
	"regexp"
	"strings"

	"go.uber.org/zap"

	"local.dev/h100_module_c/database"
	"local.dev/h100_module_c/insertEvent"
	"local.dev/h100_module_c/logger"
)

const maxRequestBody = 1 << 20

var (
	serialPattern = regexp.MustCompile(`^[0-9]{13}$`)
	hostPattern   = regexp.MustCompile(`^[A-Za-z0-9.-]+(:[0-9]{1,5})?$`)
)

// lookupDeviceHost 는 시리얼로 등록된 디바이스의 "host[:port]" 를 돌려준다. 테스트에서 교체한다.
var lookupDeviceHost = func(serial string) (string, error) {
	var device insertEvent.Tbl_Device
	if err := database.DBConn.First(&device, "dv_serial_number = ?", serial).Error; err != nil {
		return "", err
	}
	return device.DvIp, nil
}

type apiError struct {
	OK          bool     `json:"ok"`
	Code        string   `json:"code"`
	Msg         string   `json:"msg"`
	Problems    []string `json:"problems,omitempty"`
	CurrentHash string   `json:"currentHash,omitempty"`
}

func writeJSON(w http.ResponseWriter, status int, v interface{}) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func fail(w http.ResponseWriter, status int, code, msg string) {
	writeJSON(w, status, apiError{Code: code, Msg: msg})
}

// authorize 는 웹 -> module_c 내부 호출의 Bearer 토큰을 검증한다. 토큰이 설정되지 않으면 모든 요청을 거부한다(fail-closed).
func authorize(w http.ResponseWriter, r *http.Request) bool {
	token := os.Getenv("H100_ROI_TOKEN")
	if token == "" {
		fail(w, http.StatusServiceUnavailable, "NOT_CONFIGURED", "ROI 연동 설정이 없습니다")
		return false
	}
	if subtle.ConstantTimeCompare([]byte(r.Header.Get("Authorization")), []byte("Bearer "+token)) != 1 {
		fail(w, http.StatusUnauthorized, "UNAUTHORIZED", "인증에 실패했습니다")
		return false
	}
	return true
}

// decodeRequest 는 POST·인증·본문 크기·JSON 파싱을 공통 처리한다.
func decodeRequest(w http.ResponseWriter, r *http.Request, into interface{}) bool {
	if r.Method != http.MethodPost {
		fail(w, http.StatusMethodNotAllowed, "METHOD", "POST 만 허용됩니다")
		return false
	}
	if !authorize(w, r) {
		return false
	}
	dec := json.NewDecoder(http.MaxBytesReader(w, r.Body, maxRequestBody))
	if err := dec.Decode(into); err != nil {
		fail(w, http.StatusBadRequest, "BAD_REQUEST", "요청 형식이 올바르지 않습니다")
		return false
	}
	return true
}

// resolveDevice 는 시리얼을 검증하고 등록된 디바이스 주소(host:port)를 돌려준다.
func resolveDevice(w http.ResponseWriter, serial string) (string, bool) {
	if !serialPattern.MatchString(serial) {
		fail(w, http.StatusBadRequest, "BAD_SERIAL", "장비 시리얼이 올바르지 않습니다")
		return "", false
	}
	host, err := lookupDeviceHost(serial)
	if err != nil {
		logger.Log.Warn("[ROI] 등록된 디바이스 조회 실패", zap.Error(err))
		fail(w, http.StatusNotFound, "NO_DEVICE", "등록된 장비를 찾을 수 없습니다")
		return "", false
	}
	host = strings.TrimSpace(host)
	if !hostPattern.MatchString(host) {
		fail(w, http.StatusUnprocessableEntity, "BAD_DEVICE_ADDR", "장비 주소를 확인하십시오")
		return "", false
	}
	if !strings.Contains(host, ":") {
		host += ":8087"
	}
	return host, true
}

// encodeAccount 는 계정명을 폴더명으로 안전하게 바꾼다. 허용 문자(영문·숫자·_·-) 외에는 %XX(UTF-8 바이트, 대문자 hex)로
// 인코딩해 경로 이탈(.., /)이 불가능하다. Java(RoiPaths)와 규칙이 같아야 한다.
func encodeAccount(account string) (string, error) {
	if account == "" || len(account) > 64 {
		return "", errors.New("계정명이 올바르지 않습니다")
	}
	var b strings.Builder
	for _, c := range []byte(account) {
		if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' || c == '-' {
			b.WriteByte(c)
		} else {
			fmt.Fprintf(&b, "%%%02X", c)
		}
	}
	return b.String(), nil
}
