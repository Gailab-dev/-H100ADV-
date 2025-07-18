package fileSend

import (
	"bytes"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"go.uber.org/zap"

	"local.dev/h100_module_d/logger"
)

/**
 * 단일 파일 전송 함수
 * @param	sFilePath    파일 경로
 * @param	sFileName    파일명
 * @param	sendUrl      수신 url
 */
func FileSender(sFilePath string, sFileName string, sendUrl string) {
	filePath := filepath.Join(sFilePath, sFileName)
	file, fErr := os.Open(filePath)
	if fErr != nil {
		logger.Log.Error(fmt.Sprintf("파일 열기 실패: %s", filePath), zap.Error(fErr))
		return
	}
	defer file.Close()

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	fileInfo, _ := file.Stat()
	filesize := fileInfo.Size()
	timestamp := time.Now().Format("2006-01-02 15:04:05")

	part, pErr := writer.CreateFormFile("file", sFileName)
	if pErr != nil {
		logger.Log.Error("FormFile 생성 실패", zap.Error(pErr))
		return
	}
	io.Copy(part, file)

	writer.Close()

	logger.Log.Info(fmt.Sprintf("[송신] 시간: %s | 파일명: %s | 크기: %d bytes\n", timestamp, sFileName, filesize))
	req, rErr := http.NewRequest("POST", sendUrl, body)
	if rErr != nil {
		logger.Log.Error("POST 요청 생성 실패", zap.Error(rErr))
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())

	client := &http.Client{}
	resp, reErr := client.Do(req)
	if reErr != nil {
		logger.Log.Error("클라이언트 요청 생성 실패", zap.Error(reErr))
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)
	logger.Log.Info(fmt.Sprintf("서버 응답: %s", string(respBody)))
}

/**
 * 파일 전송 스케줄러 함수
 * @param	type    스트리밍 요청 유형 (start: 스트리밍 시작, end: 스트리밍 종료)
 * @param       id      cmdManager의 id
 * @return      result  결과값
 */
func FileSendScheduler() {
	videoFilePath := os.Getenv("VIDEO_FILE_PATH") // 송신할 파일이 있는 폴더 경로
	cloudReceiveIp := os.Getenv("CLOUD_RECEIVE_IP") // 클라우드 수신 모듈 IP

	logger.Log.Info("파일 보내기 시작")
	logger.Log.Info(fmt.Sprintf("videoFilePath : %s", videoFilePath))
	files, err := os.ReadDir(videoFilePath)
	if err != nil {
		logger.Log.Error("디렉토리 열기 실패", zap.Error(err))
	}

	for _, entry := range files {
		if entry.IsDir() {
			continue // 하위 폴더는 무시
		}

		FileSender(videoFilePath, entry.Name(), fmt.Sprintf("http://%s/fileReceive", cloudReceiveIp))
	}
}
