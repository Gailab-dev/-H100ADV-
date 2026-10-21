package auth

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
)

// Sign 은 서버(module_c) -> 디바이스(module_d) 요청 서명을 만든다(34번 ROI 중계).
// Verify 와 같은 규약: HMAC-SHA256(디바이스 키, serial || body) 의 hex.
// 키는 H100_HMAC_KEYS 에서 시리얼로 찾는다. 등록되지 않은 디바이스는 서명할 수 없다(ok=false).
func Sign(serial string, body []byte) (macHex string, ok bool) {
	LoadKeys()
	key, found := deviceKeys[serial]
	if !found {
		return "", false
	}
	mac := hmac.New(sha256.New, key)
	mac.Write([]byte(serial))
	mac.Write(body)
	return hex.EncodeToString(mac.Sum(nil)), true
}
