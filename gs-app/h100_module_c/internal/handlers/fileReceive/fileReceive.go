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
	"local.dev/h100_module_c/logger"
)

/**
 * 단일 파일 수신 함수
 * @param	file    수신 file
 */
func FileReceive(res http.ResponseWriter, req *http.Request, stype string) bool {
	// 최대 업로드 크기 제한 (50MB)
    req.ParseMultipartForm(50 << 20)
    timestamp := time.Now().Format("2006-01-02 15:04:05")

    // 폼 필드 이름 출력
    if req.MultipartForm != nil {
        for fieldName := range req.MultipartForm.Value {
            logger.Log.Info(fmt.Sprintf("Field name: %s", fieldName))
        }
        for fieldName := range req.MultipartForm.File {
            logger.Log.Info(fmt.Sprintf("File field name: %s", fieldName))
        }
    }
    
    // "file"은 클라이언트에서 전송한 폼 필드 이름
    file, handler, err := req.FormFile("file")
    if err != nil {
        logger.Log.Error("파일 수신 실패", zap.Error(err))
        http.Error(res, fmt.Sprintf("파일 수신 실패: %v", err), http.StatusBadRequest)
        return false
    }
    defer file.Close()
    
    sFileName := handler.Filename
    saveDir := ""

    if(stype == "image") {
        saveDir = filepath.Join(os.Getenv("FILE_UPLOAD_PATH"), "output_images")
    } else if (stype == "video") {
        saveDir = filepath.Join(os.Getenv("FILE_UPLOAD_PATH"), "output_videos")
    }
    
    os.MkdirAll(saveDir, os.ModePerm)

    // 저장할 전체 경로l
    savePath := filepath.Join(saveDir, handler.Filename)

    // 파일 생성
    dst, err := os.Create(savePath)
    if err != nil {
        logger.Log.Error("파일 저장 실패", zap.Error(err))
        http.Error(res, fmt.Sprintf("파일 저장 실패: %v", err), http.StatusInternalServerError)
        return false
    }
    defer dst.Close()

    // 파일 내용 복사
    _, err = io.Copy(dst, file)
    if err != nil {
        logger.Log.Error("파일 저장 중 오류 발생", zap.Error(err))
        http.Error(res, fmt.Sprintf("파일 저장 중 오류 발생: %v", err), http.StatusInternalServerError)
        return false
    }
    
    logger.Log.Info(fmt.Sprintf("[파일 수신] 시간: %s | 파일명: %s bytes\n", timestamp, sFileName))
    return true
}

/**
 * 이미지 단일 파일 수신 함수
 * @param	file    수신 file
 */
func ImageFileReceive(res http.ResponseWriter, req *http.Request) {
    resVal := FileReceive(res, req, "image")

    file, handler, err := req.FormFile("file")
    if err != nil {return}
    defer file.Close()
    
    sFileName := handler.Filename

    if (resVal){
        //_, err := database.DBConn.Exec("UPDATE tbl_event_data SET ev_has_img = 1 WHERE ev_img_path = ?", fieldName)
        database.DBConn.Exec("UPDATE tbl_event_data SET ev_has_img = 1 WHERE ev_img_path = ?", sFileName)
        logger.Log.Info(fmt.Sprintf("UPDATE tbl_event_data SET ev_has_img = 1 WHERE ev_img_path = %s", sFileName))
        
        /*
        if err != nil {
            logger.Log.Error("이미지 단일 파일 수신 함수 : db 업데이트 중 에러 발생, ", zap.Error(err)) 
            fmt.Fprintf(res, "error")
            return
        }
        */
        
        fmt.Fprintf(res, "OK")
    } else {
        fmt.Fprintf(res, "error")
    }
}


/**
 * 영상 단일 파일 수신 함수
 * @param	file    수신 file
 */
func VideoFileReceive(res http.ResponseWriter, req *http.Request) {
    resVal := FileReceive(res, req, "video")

    file, handler, err := req.FormFile("file")
    if err != nil {return}
    defer file.Close()
    
    sFileName := handler.Filename

    if (resVal){
        database.DBConn.Exec("UPDATE tbl_event_data SET ev_has_mov = 1 WHERE ev_mov_path = ?", sFileName)
            
        /*
        if err != nil {
            logger.Log.Error("영상 단일 파일 수신 함수 : db 업데이트 중 에러 발생, ", zap.Error(err)) 
            fmt.Fprintf(res, "error")
            return
        }
        */

        fmt.Fprintf(res, "OK")
    } else {
        fmt.Fprintf(res, "error")
    }
}


/**
 * 단일 파일 수신 함수
 * @param	file    수신 file
 */
func OneFileReceive(res http.ResponseWriter, req *http.Request) {
	resVal := FileReceive(res, req, "image")

    if (!resVal) {// 응답
        fmt.Fprintf(res, "OK")
    }
}

