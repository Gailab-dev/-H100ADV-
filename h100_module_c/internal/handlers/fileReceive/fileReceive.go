package fileReceive

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
    "time"

	"go.uber.org/zap"

	"local.dev/h100_module_c/logger"
)

/**
 * 단일 파일 수신 함수
 * @param	file    수신 file
 */
func FileReceive(res http.ResponseWriter, req *http.Request) {
	// 최대 업로드 크기 제한 (50MB)
    req.ParseMultipartForm(50 << 20)
    timestamp := time.Now().Format("2006-01-02 15:04:05")



    // 폼 필드 이름 출력
    if req.MultipartForm != nil {
        for fieldName := range req.MultipartForm.Value {
            fmt.Println("Field name:", fieldName)
        }
        for fieldName := range req.MultipartForm.File {
            fmt.Println("File field name:", fieldName)
        }
    }
    
    // "file"은 클라이언트에서 전송한 폼 필드 이름
    file, handler, err := req.FormFile("file")
    if err != nil {
        logger.Log.Error("파일 수신 실패", zap.Error(err))
        http.Error(res, fmt.Sprintf("파일 수신 실패: %v", err), http.StatusBadRequest)
        return
    }
    defer file.Close()
    
    sFileName := handler.Filename
    saveDir := os.Getenv("FILE_UPLOAD_PATH")
    os.MkdirAll(saveDir, os.ModePerm)

    // 저장할 전체 경로
    savePath := filepath.Join(saveDir, handler.Filename)

    // 파일 생성
    dst, err := os.Create(savePath)
    if err != nil {
        logger.Log.Error("파일 저장 실패", zap.Error(err))
        http.Error(res, fmt.Sprintf("파일 저장 실패: %v", err), http.StatusInternalServerError)
        return
    }
    defer dst.Close()

    // 파일 내용 복사
    _, err = io.Copy(dst, file)
    if err != nil {
        logger.Log.Error("파일 저장 중 오류 발생", zap.Error(err))
        http.Error(res, fmt.Sprintf("파일 저장 중 오류 발생: %v", err), http.StatusInternalServerError)
        return
    }
    logger.Log.Info(fmt.Sprintf("[파일 수신] 시간: %s | 파일명: %s bytes\n", timestamp, sFileName))
    // 응답
    fmt.Fprintf(res, "OK")
}

