package video

import (
	"fmt"
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
        Result string `json:"result"`
}

/*var cmdManager = createCmdManager()*/

func VideoHandler(oCmdManager *CmdManager) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		ids5 := make([]string, 0, len(oCmdManager.store))
                for id := range oCmdManager.store {
                        ids5 = append(ids5, id)
                }

                logger.Log.Info(fmt.Sprintf("--555555---ids5 :", ids5))



		VideoFunction(w, r, oCmdManager)
	}
}


/**
 * CCTV 실시간 스트리밍 관련 핸들러
 * @param	type    스트리밍 요청 유형 (start: 스트리밍 시작, end: 스트리밍 종료)
 * @param       id      cmdManager의 id
 * @return      result  결과값
 */
func VideoFunction(res http.ResponseWriter, req *http.Request, oCmdManager *CmdManager) {
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
                        resVal := StartVideo(oCmdManager)
			logger.Log.Info(fmt.Sprintf("resVal : %s", resVal))
			response := Response{Result: resVal}
			/*json.NewEncoder(res).Encode(map[string]string{"result": resVal})*/
                        res.Header().Set("Content-Type", "application/json")

			if err := json.NewEncoder(res).Encode(response); err != nil {
				logger.Log.Error("failed to encode response: ", zap.Error(err))
			}

                        return
                } else if tType == "end" {
                        id, iOk := bData["id"] // cmdManager의 id
                        if !iOk {
                                logger.Log.Error("id 키가 존재하지 않습니다.", zap.Error(err))
                        } else {
				if strID, ok := id.(string); ok {
					resVal := EndVideo(strID, oCmdManager)
					logger.Log.Info(fmt.Sprintf("resVal : %s", resVal))
	                                response := Response{Result: resVal}
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
func StartVideo(oCmdManager *CmdManager) string{
        // HLS 디렉토리 준비
        err := os.MkdirAll(os.Getenv("HLS_DIR"), os.ModePerm)
        if err != nil {
                logger.Log.Error("HLS 디렉토리 생성 실패", zap.Error(err))
        }

        // 기존 HLS 파일들 삭제 (과거 세그먼트 방지)
        hlsDir := os.Getenv("HLS_DIR")
        files, _ := filepath.Glob(filepath.Join(hlsDir, "*.ts"))
        for _, f := range files {
                os.Remove(f)
        }
        os.Remove(filepath.Join(hlsDir, "index.m3u8"))

        // FFmpeg 명령어 구성
	cmd := exec.Command(
                os.Getenv("FFMPEG_PATH"),
                "-i", os.Getenv("RTSP_URL"),
                "-rtsp_transport", "tcp",        // UDP 대신 TCP 사용 (더 안정적)
                "-fflags", "+genpts",            // 타임스탬프 재생성
                "-avoid_negative_ts", "make_zero", // 음수 타임스탬프 방지
                "-err_detect", "ignore_err",     // 에러 무시하고 계속 진행
		"-c:v", "libx264",
                "-preset", "veryfast",
                "-profile:v", "main",
                "-level", "4.0",
                "-sc_threshold", "0",
                "-g", "30",  // GOP 크기를 줄임 (더 자주 키프레임)
                "-keyint_min", "30",
                "-force_key_frames", "expr:gte(t,n_forced*1)",  // 1초마다 키프레임
                "-sc_threshold", "0",
                "-c:a", "aac",
                "-b:a", "128k",
                "-ac", "2",
                "-f", "hls",
                "-hls_time", os.Getenv("SEGMENT_TIME"),
                "-hls_list_size", "3",  // 최대 3개 세그먼트만 유지
                "-hls_flags", "delete_segments+independent_segments",  // 플래그 개선
                "-hls_start_number_source", "datetime",  // 세그먼트 번호를 시간 기반으로
                filepath.Join(os.Getenv("HLS_DIR"), "index.m3u8"),
        )

        logger.Log.Info("FFmpeg 시작...")

	// FFmpeg 실행
	// oCmdManager = &CmdManager{}
	if oCmdManager.store == nil {
		oCmdManager.store = make(map[string]*exec.Cmd)
	}

	return cmdStart(cmd, oCmdManager)
}

/**
 * CCTV 실시간 스트리밍 종료
 * @param       id     cmdManager의 id
 * @return      error  프로세스 종료 결과
 */
func EndVideo(id string, oCmdManager *CmdManager) string{
        // 종료 신호 대기
        logger.Log.Info("end 신호 수신. FFmpeg 종료 중...")
	/*cmdManager := &CmdManager{}*/
        return cmdStop(id, oCmdManager)
}
