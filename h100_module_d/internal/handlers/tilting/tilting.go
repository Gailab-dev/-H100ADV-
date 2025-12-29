package tilting

import (
	"encoding/json"
	"io"
	"log"
	"net/http"
)

const maxBody = 1 << 20 // 1MB

func TiltingCmdHandler(res http.ResponseWriter, req *http.Request) {
	
		// (옵션) 프리플라이트 직접 처리 – CORS 미들웨어가 이미 처리하면 불필요
	if req.Method == http.MethodOptions {
		res.WriteHeader(http.StatusNoContent)
		return
	}

	if req.Method != http.MethodPost {
		http.Error(res, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// 본문 크기 제한 & 읽기
	req.Body = http.MaxBytesReader(res, req.Body, maxBody)
	defer req.Body.Close()

	raw, err := io.ReadAll(req.Body)
	if err != nil {
		http.Error(res, "failed to read body", http.StatusBadRequest)
		return
	}

	// JSON 유효성 체크(필요 없으면 이 블록은 생략 가능)
	var js any
	if err := json.Unmarshal(raw, &js); err != nil {
		// JSON이 아니어도 그냥 찍고 싶다면 아래 로그만 남기고 200 OK로 응답해도 됨
		log.Printf("[/tilting] invalid JSON from %s: %s", req.RemoteAddr, string(raw))
		http.Error(res, "invalid json", http.StatusBadRequest)
		return
	}

	// 받은 JSON 그대로 로그 출력
	log.Printf("[/tilting] from %s: %s", req.RemoteAddr, string(raw))

	// 항상 JSON 한 번만 응답 (헤더/상태 중복 금지)
	res.Header().Set("Content-Type", "application/json; charset=utf-8")
	res.Header().Set("Cache-Control", "no-store")
	_ = json.NewEncoder(res).Encode(map[string]any{
		"ok":   true,
		"echo": js, // 받은 JSON을 그대로 되돌려주고 싶다면
	})
	
	return
}