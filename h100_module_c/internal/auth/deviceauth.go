// Package auth: 디바이스 -> 서버 파일 업로드의 디바이스 인증(시리얼 + HMAC) 담당.
//
// [Phase 2 배경]
//   - 디바이스(module_d/fileSend)가 .enc 파일을 multipart 로 POST 하면 본 서버(module_c/fileReceive)가 수신·저장한다.
//   - 기존에는 인증이 전혀 없어 누구나 파일을 밀어넣을 수 있었고, 전송 TLS 도 InsecureSkipVerify 라 MITM 에 취약했다.
//   - 따라서 디바이스별 대칭키 기반 HMAC-SHA256 으로 (1) 디바이스 식별 (2) 본문 무결성 을 검증한다.
//
// 보안 정책: 키 원문·HMAC 원문은 로그/응답에 절대 출력하지 않는다. 시리얼은 마스킹해서만 남긴다.
package auth

import (
	"crypto/hmac"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"sync"

	"go.uber.org/zap"

	"local.dev/h100_module_c/logger"
)

// 디바이스별 HMAC 키 저장소 (시리얼 -> 32바이트 키). 시작 시 1회 로드 후 읽기 전용으로 사용.
var (
	deviceKeys map[string][]byte
	loadOnce   sync.Once
)

// LoadKeys 는 환경변수 H100_HMAC_KEYS 의 JSON 을 파싱해 시리얼->키 맵을 메모리에 적재한다.
//
// 형식: {"DEV-2026-001":"<64자 hex>","DEV-2026-002":"<64자 hex>",...}
// sync.Once 로 최초 호출 시 1회만 수행된다(이후 호출은 무시). main 에서 미리 호출하거나,
// 첫 요청 시 lazy 로 호출되어도 동작한다.
func LoadKeys() {
	loadOnce.Do(func() {
		deviceKeys = make(map[string][]byte)

		raw := strings.TrimSpace(os.Getenv("H100_HMAC_KEYS"))
		if raw == "" {
			// 키 미설정이어도 서버 기동은 막지 않는다. 단, 모든 디바이스 인증은 실패한다.
			logger.Log.Warn("[보안] 환경변수 H100_HMAC_KEYS 미설정 — 모든 디바이스 HMAC 검증이 실패합니다.")
			return
		}

		var m map[string]string
		if err := json.Unmarshal([]byte(raw), &m); err != nil {
			// 키 값이 메시지에 섞이지 않도록 err 만 zap 으로 남긴다(파싱 에러엔 키 원문 미포함).
			logger.Log.Error("[보안] H100_HMAC_KEYS JSON 파싱 실패", zap.Error(err))
			return
		}

		for serial, hexKey := range m {
			kb, err := hex.DecodeString(strings.TrimSpace(hexKey))
			if err != nil || len(kb) != 32 {
				// 잘못된 키는 스킵(시리얼만 마스킹해서 남김, 키 원문 미출력)
				logger.Log.Warn(fmt.Sprintf("[보안] 잘못된 디바이스 키 스킵 - serial(masked): %s (64자 hex 필요)", MaskSerial(serial)))
				continue
			}
			deviceKeys[serial] = kb
		}
		logger.Log.Info(fmt.Sprintf("디바이스 HMAC 키 로드 완료 - 등록 디바이스 수: %d", len(deviceKeys)))
	})
}

// Verify 는 업로드 요청의 디바이스 인증을 수행한다.
//
//	serial : X-Device-Serial 헤더
//	macHex : X-Device-HMAC 헤더 (hex)
//	body   : 수신한 파일 원본 바이트 (IV || 암호문). 복호화 전 바이트 그대로.
//
// HMAC 입력 = serial 바이트 || body  (시리얼 스왑 공격 방지를 위해 시리얼을 MAC 에 바인딩)
// 반환: (검증성공여부, 실패사유). 실패사유는 호출측 로그/응답용이며 키·HMAC 원문은 포함하지 않는다.
func Verify(serial, macHex string, body []byte) (bool, string) {
	LoadKeys()

	// 1. 헤더 누락 검사
	if strings.TrimSpace(serial) == "" || strings.TrimSpace(macHex) == "" {
		return false, "헤더 누락(X-Device-Serial / X-Device-HMAC)"
	}

	// 2. 시리얼로 키 조회 (등록되지 않은 디바이스 차단)
	key, ok := deviceKeys[serial]
	if !ok {
		return false, "등록되지 않은 디바이스"
	}

	// 3. 수신 HMAC hex 디코딩
	want, err := hex.DecodeString(strings.TrimSpace(macHex))
	if err != nil {
		return false, "HMAC hex 형식 오류"
	}

	// 4. 서버측 HMAC 계산 후 상수시간 비교(타이밍 공격 방지)
	mac := hmac.New(sha256.New, key)
	mac.Write([]byte(serial))
	mac.Write(body)
	got := mac.Sum(nil)
	if subtle.ConstantTimeCompare(got, want) != 1 {
		return false, "HMAC 불일치(위조 의심)"
	}

	return true, ""
}

// MaskSerial 은 로그 출력용으로 시리얼을 마스킹한다. 앞 8자만 노출하고 이후는 *** 로 가린다.
// 예) "DEV-2026-001" -> "DEV-2026***"
func MaskSerial(s string) string {
	if strings.TrimSpace(s) == "" {
		return "(none)"
	}
	keep := 8
	if keep > len(s) {
		keep = len(s)
	}
	return s[:keep] + "***"
}
