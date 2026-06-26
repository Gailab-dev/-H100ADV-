package fileReceive

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"go.uber.org/zap"

	"local.dev/h100_module_c/database"
	"local.dev/h100_module_c/internal/auth"
	"local.dev/h100_module_c/logger"
)

/**
 * 단일 파일 수신 함수
 *
 * [Phase 2 변경] 저장 전에 디바이스 인증(X-Device-Serial + X-Device-HMAC)을 검증한다.
 *  - 검증을 위해 파일 바이트를 메모리에 적재한 뒤(<=50MB) HMAC 을 계산/비교하고, 통과 시에만 디스크에 저장한다.
 *  - 검증 실패 시 401 Unauthorized 로 응답하고 파일을 저장하지 않는다.
 *  - 보안: 시리얼은 마스킹 로그만 남기고, 키·HMAC 원문은 로그에 남기지 않는다.
 *
 * @param	stype   파일 유형 (image / video)
 * @return  검증·저장 성공 여부
 */
func FileReceive(res http.ResponseWriter, req *http.Request, stype string) bool {
	// 최대 업로드 크기 제한 (50MB)
	req.ParseMultipartForm(50 << 20)
	timestamp := time.Now().Format("2006-01-02 15:04:05")

	// "file"은 클라이언트에서 전송한 폼 필드 이름
	file, handler, err := req.FormFile("file")
	if err != nil {
		logger.Log.Error("파일 수신 실패", zap.Error(err))
		http.Error(res, fmt.Sprintf("파일 수신 실패: %v", err), http.StatusBadRequest)
		return false
	}
	defer file.Close()

	// HMAC 검증과 저장 모두에 사용하기 위해 파일 바이트를 메모리에 적재
	fileBytes, err := io.ReadAll(file)
	if err != nil {
		logger.Log.Error("파일 읽기 실패", zap.Error(err))
		http.Error(res, "파일 읽기 실패", http.StatusInternalServerError)
		return false
	}

	// ===== [S] 디바이스 인증 (시리얼 + HMAC 검증) ===== //
	serial := req.Header.Get("X-Device-Serial")
	macHex := req.Header.Get("X-Device-HMAC")
	if ok, reason := auth.Verify(serial, macHex, fileBytes); !ok {
		// 보안: 시리얼은 마스킹, 키/HMAC 원문은 로그 금지
		logger.Log.Warn(fmt.Sprintf("[디바이스 인증 실패] 사유: %s | serial(masked): %s", reason, auth.MaskSerial(serial)))
		http.Error(res, "Unauthorized: "+reason, http.StatusUnauthorized)
		return false
	}
	logger.Log.Info(fmt.Sprintf("[디바이스 인증 성공] serial(masked): %s", auth.MaskSerial(serial)))
	// ===== [E] 디바이스 인증 ===== //

	sFileName := handler.Filename
	saveDir := ""

	if stype == "image" {
		saveDir = filepath.Join(os.Getenv("FILE_UPLOAD_PATH"), "output_images_enc")
	} else if stype == "video" {
		saveDir = filepath.Join(os.Getenv("FILE_UPLOAD_PATH"), "output_videos_enc")
	}

	os.MkdirAll(saveDir, os.ModePerm)

	// 저장할 전체 경로
	savePath := filepath.Join(saveDir, handler.Filename)

	// 검증 통과한 바이트를 그대로 저장
	if err := os.WriteFile(savePath, fileBytes, 0o644); err != nil {
		logger.Log.Error("파일 저장 실패", zap.Error(err))
		http.Error(res, fmt.Sprintf("파일 저장 실패: %v", err), http.StatusInternalServerError)
		return false
	}

	logger.Log.Info(fmt.Sprintf("[파일 수신] 시간: %s | 파일명: %s | 사이즈:%d bytes\n", timestamp, sFileName, handler.Size))
	if info, statErr := os.Stat(savePath); statErr == nil {
		logger.Log.Info(fmt.Sprintf("[[[[파일 사이즈 ]]]] %d bytes\n", info.Size()))
	}

	return true
}

/**
 * 이미지 단일 파일 수신 함수
 * @param	file    수신 file
 */
func ImageFileReceive(res http.ResponseWriter, req *http.Request) {
	resVal := FileReceive(res, req, "image")
	if !resVal {
		// FileReceive 가 이미 상태코드/메시지(401/400/500)를 기록함 — 중복 출력 방지
		return
	}

	file, handler, err := req.FormFile("file")
	if err != nil {
		return
	}
	defer file.Close()

	sFileName := handler.Filename

	database.DBConn.Exec("UPDATE tbl_event_data SET ev_has_img = 1 WHERE ev_img_path = ?", sFileName)
	logger.Log.Info(fmt.Sprintf("UPDATE tbl_event_data SET ev_has_img = 1 WHERE ev_img_path = %s", sFileName))

	fmt.Fprintf(res, "OK")
}

/**
 * 영상 단일 파일 수신 함수
 * @param	file    수신 file
 */
func VideoFileReceive(res http.ResponseWriter, req *http.Request) {
	resVal := FileReceive(res, req, "video")
	if !resVal {
		// FileReceive 가 이미 상태코드/메시지(401/400/500)를 기록함 — 중복 출력 방지
		return
	}

	file, handler, err := req.FormFile("file")
	if err != nil {
		return
	}
	defer file.Close()

	sFileName := handler.Filename

	database.DBConn.Exec("UPDATE tbl_event_data SET ev_has_mov = 1 WHERE ev_mov_path = ?", sFileName)

	fmt.Fprintf(res, "OK")
}

/**
 * 단일 파일 수신 함수
 * @param	file    수신 file
 */
func OneFileReceive(res http.ResponseWriter, req *http.Request) {
	if FileReceive(res, req, "image") {
		fmt.Fprintf(res, "OK")
	}
}
