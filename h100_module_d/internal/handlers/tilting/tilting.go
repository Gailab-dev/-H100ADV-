// Package tilting: 카메라 조종(화각·줌) 명령 수신 핸들러
//
// POST /tilting  — 웹(Java DeviceListController) → module_c 경유 없이 디바이스로 직접 전달
//
// (15번 4-4) 현재 단계 범위:
//   - 어떤 명령 문자열이 들어왔는지 로그로 남기는 것까지가 이 파일의 책임
//   - 실제 카메라 구동(PTZ 제어)은 디바이스 담당자 개발 영역 → 아래 TODO 지점에 연결
//
// 수신 본문 예시 (deviceList.jsp sendCommand 가 만드는 형태 그대로):
//
//	{"type":"U","id":"<tokenId>","deviceId":"12"}
//
// type 값: U(위) · D(아래) · L(왼쪽) · R(오른쪽) · H(중앙 복귀) · zoomIn · zoomOut
package tilting

import (
	"encoding/json"
	"io"
	"net/http"
	"strings"

	"go.uber.org/zap"

	"local.dev/h100_module_d/logger"
)

const maxBody = 1 << 20 // 1MB

// 웹이 보내는 조종 명령 본문
type TiltingReq struct {
	Type     string `json:"type"`
	Id       string `json:"id"`       // 스트리밍 tokenId (조종 자체에는 사용하지 않음)
	DeviceId string `json:"deviceId"` // 웹 DB 상의 dv_id
}

// 허용 명령 — 이 목록에 없는 값은 로그를 남기되 구동 대상으로 넘기지 않는다.
var allowedCmd = map[string]string{
	"U":       "화각 위",
	"D":       "화각 아래",
	"L":       "화각 왼쪽",
	"R":       "화각 오른쪽",
	"H":       "중앙 복귀(HOME)",
	"zoomIn":  "줌 인",
	"zoomOut": "줌 아웃",
}

func clientIP(r *http.Request) string {
	ip := r.Header.Get("X-Forwarded-For")
	if ip == "" {
		ip = strings.Split(r.RemoteAddr, ":")[0]
	}
	return ip
}

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
		logger.Log.Warn("[TILT_READ_FAIL] 본문 읽기 실패",
			zap.String("client_ip", clientIP(req)), zap.Error(err))
		http.Error(res, "failed to read body", http.StatusBadRequest)
		return
	}

	// 원문 우선 기록 — 파싱에 실패해도 '무엇이 들어왔는지'는 남아야 담당자가 추적할 수 있다.
	logger.Log.Info("[TILT_RAW] 조종 명령 수신(원문)",
		zap.String("client_ip", clientIP(req)),
		zap.String("body", string(raw)))

	var cmd TiltingReq
	if err := json.Unmarshal(raw, &cmd); err != nil {
		logger.Log.Warn("[TILT_BAD_JSON] JSON 파싱 실패",
			zap.String("client_ip", clientIP(req)),
			zap.String("body", string(raw)), zap.Error(err))
		http.Error(res, "invalid json", http.StatusBadRequest)
		return
	}

	desc, ok := allowedCmd[cmd.Type]
	if !ok {
		// 미지원 명령도 400 으로 되돌려 웹에서 오탐을 바로 알 수 있게 한다.
		logger.Log.Warn("[TILT_UNKNOWN_CMD] 지원하지 않는 명령",
			zap.String("type", cmd.Type),
			zap.String("device_id", cmd.DeviceId),
			zap.String("client_ip", clientIP(req)))
		http.Error(res, "unsupported command", http.StatusBadRequest)
		return
	}

	// 담당자가 로그만 보고 바로 판별할 수 있도록 명령·의미·디바이스를 분리해 기록
	logger.Log.Info("[TILT_CMD] 카메라 조종 명령",
		zap.String("type", cmd.Type),
		zap.String("desc", desc),
		zap.String("device_id", cmd.DeviceId),
		zap.String("client_ip", clientIP(req)))

	// TODO(디바이스 담당자): 여기서 실제 카메라 PTZ 구동을 호출한다.
	//   cmd.Type 값(U·D·L·R·H·zoomIn·zoomOut)을 카메라 제어 SDK/시리얼 명령으로 매핑.
	//   현재는 수신 확인 및 로그 기록까지만 수행한다.

	// 항상 JSON 한 번만 응답 (헤더/상태 중복 금지)
	res.Header().Set("Content-Type", "application/json; charset=utf-8")
	res.Header().Set("Cache-Control", "no-store")
	_ = json.NewEncoder(res).Encode(map[string]any{
		"ok":        true,
		"type":      cmd.Type,
		"desc":      desc,
		"device_id": cmd.DeviceId,
		"executed":  false, // 실제 카메라 구동 미구현 상태임을 명시
	})
}
