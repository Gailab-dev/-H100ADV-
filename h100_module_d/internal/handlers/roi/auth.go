package roi

import (
	"crypto/hmac"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"net/http"
	"os"
	"strings"
	"time"
)

// 서버(module_c) -> 디바이스(module_d) 요청 인증.
// module_c 가 디바이스별 키(H100_HMAC_KEYS)로 HMAC-SHA256(serial || body) 를 계산해 헤더로 보낸다.
// 디바이스 -> 서버 업로드(fileReceive)와 같은 서명 규약(X-Device-Serial / X-Device-HMAC)이며,
// 이 디바이스의 키는 DEVICE_HMAC_KEY, 시리얼은 DEVICE_SERIAL 환경변수다.

const (
	headerSerial = "X-Device-Serial"
	headerHMAC   = "X-Device-HMAC"
	// 요청 본문의 ts 가 이 범위를 벗어나면 거부한다(오래된 요청 재전송 방지).
	maxClockSkew = 5 * time.Minute
)

// verifyHMAC 는 헤더의 시리얼·HMAC 이 이 디바이스의 것과 일치하는지 검증한다. 실패 사유는 응답에 키·HMAC 원문을 담지 않는다.
func verifyHMAC(r *http.Request, body []byte) (ok bool, status int, msg string) {
	serial := os.Getenv("DEVICE_SERIAL")
	key, err := hex.DecodeString(strings.TrimSpace(os.Getenv("DEVICE_HMAC_KEY")))
	if serial == "" || err != nil || len(key) != 32 {
		return false, http.StatusServiceUnavailable, "디바이스 인증 설정이 없습니다"
	}
	gotSerial := r.Header.Get(headerSerial)
	macHex := strings.TrimSpace(r.Header.Get(headerHMAC))
	if gotSerial == "" || macHex == "" {
		return false, http.StatusUnauthorized, "인증 헤더가 없습니다"
	}
	if subtle.ConstantTimeCompare([]byte(gotSerial), []byte(serial)) != 1 {
		return false, http.StatusUnauthorized, "인증에 실패했습니다"
	}
	want, err := hex.DecodeString(macHex)
	if err != nil {
		return false, http.StatusUnauthorized, "인증에 실패했습니다"
	}
	mac := hmac.New(sha256.New, key)
	mac.Write([]byte(serial))
	mac.Write(body)
	if subtle.ConstantTimeCompare(mac.Sum(nil), want) != 1 {
		return false, http.StatusUnauthorized, "인증에 실패했습니다"
	}
	return true, 0, ""
}

// checkFreshness 는 본문 ts(RFC3339)가 현재 시각과 크게 어긋나지 않는지 확인한다.
func checkFreshness(ts string, now time.Time) bool {
	t, err := time.Parse(time.RFC3339, ts)
	if err != nil {
		return false
	}
	d := now.Sub(t)
	if d < 0 {
		d = -d
	}
	return d <= maxClockSkew
}
