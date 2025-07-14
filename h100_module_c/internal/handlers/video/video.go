package video

import (
	"os/exec"
	"net/http"
        "encoding/json"
        "io"
	"os"
	"path/filepath"

        "go.uber.org/zap"

        "local.dev/h100_module_d/logger"
)

type Response struct {
        result string
}

var cmdManager = createCmdManager()

/**
 * CCTV 실시간 스트리밍 관련 핸들러
 * @param	type    스트리밍 요청 유형 (start: 스트리밍 시작, end: 스트리밍 종료)
 * @param       id      cmdManager의 id
 * @return      result  결과값
 */
func VideoHandler(res http.ResponseWriter, req *http.Request) {
        if req.Method != http.MethodPost {
                http.Error(res, "Method not allowed", http.StatusMethodNotAllowed)
                return
        }

        bodyBytes, err := io.ReadAll(req.Body) // body 값
        if err != nil {
                http.Error(res, "Failed to read request body", http.StatusInternalServerError)
                return
        }
        defer req.Body.Close()

        var bData map[string]interface{} // json 파싱한 body 값
        if err := json.Unmarshal(bodyBytes, &bData); err != nil {
                http.Error(res, "JSON 파싱 실패", http.StatusBadRequest)
                return
        }

        tType, tOk := bData["type"] // 스트리밍 요청 유형
        if !tOk {
                logger.Log.Error("type 키가 존재하지 않습니다.", zap.Error(err))
        } else {
                if tType == "start" {
                        resVal := StartVideo()
                        response := Response{result: resVal}
                        res.Header().Set("Content-Type", "application/json")
                        json.NewEncoder(res).Encode(response)
                        return
                } else if tType == "end" {
                        id, iOk := bData["id"] // cmdManager의 id
                        if !iOk {
                                logger.Log.Error("id 키가 존재하지 않습니다.", zap.Error(err))
                        } else {
				if strID, ok := id.(string); ok {
					resVal := EndVideo(strID)
	                                response := Response{result: resVal}
        	                        res.Header().Set("Content-Type", "application/json")
                	                json.NewEncoder(res).Encode(response)
				} else {
                                        logger.Log.Error("id 키가 string형이 아닙니다.", zap.Error(err))
				}
                                
				return
                        }
                } else {
                        http.Error(res, "Invalid body content", http.StatusBadRequest)
                }
        }

}

/**
 * CCTV 실시간 스트리밍 시작
 * @return      id  cmdManager의 id
 */
func StartVideo() string{
        // HLS 디렉토리 준비
        err := os.MkdirAll(os.Getenv("HLS_DIR"), os.ModePerm)
        if err != nil {
                logger.Log.Error("HLS 디렉토리 생성 실패", zap.Error(err))
        }

        // FFmpeg 명령어 구성
	cmd := exec.Command(
                os.Getenv("FFMPEG_PATH"),
                "-i", os.Getenv("RTSP_URL"),
                "-c:v", "libx264",
                "-preset", "veryfast",
                "-g", "50",
                "-sc_threshold", "0",
                "-f", "hls",
                "-hls_time", os.Getenv("SEGMENT_TIME"),
                "-hls_list_size", "3",
                "-hls_flags", "delete_segments+omit_endlist",
                filepath.Join(os.Getenv("HLS_DIR"), "index.m3u8"),
        )

        logger.Log.Info("FFmpeg 시작...")

	// FFmpeg 실행
	cmdManager := &CmdManager{}
	if cmdManager.store == nil {
		cmdManager.store = make(map[string]*exec.Cmd)
	}

	return cmdManager.cmdStart(cmd)
}

/**
 * CCTV 실시간 스트리밍 종료
 * @param       id     cmdManager의 id
 * @return      error  프로세스 종료 결과
 */
func EndVideo(id string) string{
        // 종료 신호 대기
        logger.Log.Info("end 신호 수신. FFmpeg 종료 중...")
	cmdManager := &CmdManager{}
        return cmdManager.cmdStop(id)
}
