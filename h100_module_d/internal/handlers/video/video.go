package video

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"

	"go.uber.org/zap"

	"local.dev/h100_module_d/logger"
)

// Response: /video 응답. 성공 start 는 기존처럼 {"result":"<스트림 id>"} 이며(Spring 이 result 를 end 토큰으로 사용),
// 실패는 {"result":"false","code":"...","message":"..."} 이다(38번 WP-1, 공통 지시서 4.1).
type Response struct {
	Result  string `json:"result"`
	Code    string `json:"code,omitempty"`
	Message string `json:"message,omitempty"`
}

// 요청 본문 상한. start/end 본문은 수백 바이트이므로 충분히 작게 둔다.
const maxVideoBody = 64 << 10

func VideoHandler(oCmdManager *CmdManager) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		VideoFunction(w, r, oCmdManager)
	}
}

func writeResponse(res http.ResponseWriter, status int, v Response) {
	res.Header().Set("Content-Type", "application/json")
	res.WriteHeader(status)
	if err := json.NewEncoder(res).Encode(v); err != nil {
		logger.Log.Error("failed to encode response: ", zap.Error(err))
	}
}

// strField: JSON 값(문자열 또는 숫자)을 문자열로 꺼낸다. 없으면 "".
func strField(m map[string]interface{}, key string) string {
	v, ok := m[key]
	if !ok || v == nil {
		return ""
	}
	if s, ok := v.(string); ok {
		return s
	}
	return fmt.Sprint(v)
}

/**
 * CCTV 실시간 스트리밍 관련 핸들러
 * @param type       스트리밍 요청 유형 (start: 스트리밍 시작, end: 스트리밍 종료, heartbeat: 시청 유지 신호)
 * @param id         start 응답으로 받은 스트림 id (end 시 필수는 아님: viewerId 로도 판정)
 * @param viewerId   시청자 식별자(로그인 u_id). Spring 이 항상 보낸다
 * @param requestId  요청 단위 식별자(로그 추적용, 선택)
 * @return result    결과값
 *
 * 응답 규칙(38번 / 공통 지시서 4.1)
 *   start 성공(인계 포함)            200 {"result":"<id>"}
 *   start, 다른 시청자가 점유 중      409 {"result":"false","code":"VIEWER_BUSY",...}
 *   start, ffmpeg 시작 직후 실패      500 {"result":"false","code":"FFMPEG_FAILED",...}
 *   end, 현재 시청자가 아님           200 {"result":"false","code":"NOT_VIEWER"}
 */
func VideoFunction(res http.ResponseWriter, req *http.Request, oCmdManager *CmdManager) {
	if req.Method != http.MethodPost {
		http.Error(res, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	bodyBytes, err := io.ReadAll(http.MaxBytesReader(res, req.Body, maxVideoBody)) // body 값
	if err != nil {
		http.Error(res, "Failed to read request body", http.StatusBadRequest)
		return
	}
	defer req.Body.Close()

	var bData map[string]interface{} // json 파싱한 body 값
	if err := json.Unmarshal(bodyBytes, &bData); err != nil {
		http.Error(res, "JSON 파싱 실패", http.StatusBadRequest)
		return
	}

	tType := strField(bData, "type") // 스트리밍 요청 유형
	viewerID := strField(bData, "viewerId")
	requestID := strField(bData, "requestId")
	id := strField(bData, "id") // cmdManager의 id

	switch tType {
	case "start":
		result, aErr := oCmdManager.Start(viewerID, requestID)
		if aErr != nil {
			writeResponse(res, aErr.Status, Response{Result: "false", Code: aErr.Code, Message: aErr.Message})
			return
		}
		code := "STARTED"
		if result.Takeover {
			code = "TAKEOVER"
		}
		writeResponse(res, http.StatusOK, Response{Result: result.ID, Code: code})

	case "end":
		er := oCmdManager.End(viewerID, id, requestID)
		if er.OK {
			writeResponse(res, http.StatusOK, Response{Result: "true", Code: er.Code})
		} else {
			writeResponse(res, http.StatusOK, Response{Result: "false", Code: er.Code})
		}

	case "heartbeat":
		if oCmdManager.Heartbeat(viewerID, id) {
			writeResponse(res, http.StatusOK, Response{Result: "true", Code: "OK"})
		} else {
			writeResponse(res, http.StatusOK, Response{Result: "false", Code: "NOT_VIEWER"})
		}

	case "":
		logger.Log.Error("type 키가 존재하지 않습니다.")
		writeResponse(res, http.StatusBadRequest, Response{Result: "false", Code: "BAD_REQUEST", Message: "type 이 필요합니다"})

	default:
		http.Error(res, "Invalid body content", http.StatusBadRequest)
	}
}

/**
 * FFmpeg 명령어 구성 — 인코딩·비트레이트·세그먼트 설정은 측정(WP-M) 전이므로 변경하지 않는다.
 * RTSP 주소(계정 포함)는 이 함수 밖으로 로그에 남기지 않는다.
 */
func buildFFmpegCmd() *exec.Cmd {
	return exec.Command(
		os.Getenv("FFMPEG_PATH"),
		// ===== 입력(demuxer) 옵션 — 반드시 -i 앞에 와야 함 =====
		// (긴급복구 2026-07-21) 기존에는 아래 옵션들이 -i 뒤에 있어 ffmpeg 이 출력 옵션으로 해석,
		//   "Option rtsp_transport not found." 로 즉시 종료 → index.m3u8 미생성(브라우저 404) 원인.
		"-rtsp_transport", "tcp", // UDP 대신 TCP 사용 (더 안정적)
		"-fflags", "+genpts", // 타임스탬프 재생성
		"-err_detect", "ignore_err", // 에러 무시하고 계속 진행
		"-i", os.Getenv("RTSP_URL"),
		// ===== 이하 출력 옵션 =====
		"-avoid_negative_ts", "make_zero", // 음수 타임스탬프 방지
		"-c:v", "libx264",
		"-preset", "veryfast",
		"-profile:v", "main",
		"-level", "4.0",
		"-sc_threshold", "0",
		"-g", "30", // GOP 크기를 줄임 (더 자주 키프레임)
		"-keyint_min", "30",
		"-force_key_frames", "expr:gte(t,n_forced*1)", // 1초마다 키프레임
		"-sc_threshold", "0",
		"-c:a", "aac",
		"-b:a", "128k",
		"-ac", "2",
		"-f", "hls",
		"-hls_time", os.Getenv("SEGMENT_TIME"),
		"-hls_list_size", "3", // 최대 3개 세그먼트만 유지
		"-hls_flags", "delete_segments+independent_segments", // 플래그 개선
		"-hls_start_number_source", "datetime", // 세그먼트 번호를 시간 기반으로
		filepath.Join(os.Getenv("HLS_DIR"), "index.m3u8"),
	)
}
