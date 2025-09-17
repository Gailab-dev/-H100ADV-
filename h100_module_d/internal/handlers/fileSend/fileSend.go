package fileSend

import (
	"bytes"
	"crypto/tls"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"time"
	"encoding/json"
	"strconv"

	"go.uber.org/zap"

	"local.dev/h100_module_d/logger"
)

type Response struct {
        Result string `json:"result"`
}

/**
 * 파일 전송 핸들러 
 * @param       type    	파일 요청 유형 (image: 이미지, video: 영상)
 * @param       fileName	파일명
 * @param       id      	cmdManager의 id
 * @return      result  결과값
 */
func FileSendHandler(res http.ResponseWriter, req *http.Request) {
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

        tType, tOk := bData["type"] // 파일 요청 유형
		if !tOk {
                logger.Log.Error("type 키가 존재하지 않습니다.", zap.Error(err))
				return
        }

		tFileName, tOk := bData["fileName"] // 파일 요청 유형
        if !tOk {
                logger.Log.Error("fileName 키가 존재하지 않습니다.", zap.Error(err))
				return
        }

		filePath := ""
		resVal := false
	
        if tType == "image" {
        	filePath = filepath.Join(os.Getenv("FILE_PATH"), "output_images/")
			resVal = FileSender(filePath, tFileName.(string), fmt.Sprintf("http://%s/imageFileReceive", os.Getenv("CLOUD_RECEIVE_IP")))
        } else if tType == "video" {
			filePath = filepath.Join(os.Getenv("FILE_PATH"), "output_videos/")
			resVal = FileSender(filePath, tFileName.(string), fmt.Sprintf("http://%s/videoFileReceive", os.Getenv("CLOUD_RECEIVE_IP")))
		} else {
			http.Error(res, "Invalid body content", http.StatusBadRequest)
		}

		logger.Log.Info(fmt.Sprintf("resVal : ", strconv.FormatBool(resVal)))
		response := Response{Result: strconv.FormatBool(resVal)}
		res.Header().Set("Content-Type", "application/json")

		if err := json.NewEncoder(res).Encode(response); err != nil {
			logger.Log.Error("failed to encode response: ", zap.Error(err))
		}

		return
}

/**
 * 단일 파일 전송 함수
 * @param	sFilePath    파일 경로
 * @param	sFileName    파일명
 * @param	sendUrl      수신 url
 */
func FileSender(sFilePath string, sFileName string, sendUrl string) bool {
	filePath := filepath.Join(sFilePath, sFileName)
	file, fErr := os.Open(filePath)
	if fErr != nil {
		logger.Log.Error(fmt.Sprintf("파일 열기 실패: %s", filePath), zap.Error(fErr))
		defer file.Close()
		return false
	} else {
		defer file.Close()
	}

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	fileInfo, _ := file.Stat()
	filesize := fileInfo.Size()
	timestamp := time.Now().Format("2006-01-02 15:04:05")

	part, pErr := writer.CreateFormFile("file", sFileName)
	if pErr != nil {
		logger.Log.Error("FormFile 생성 실패", zap.Error(pErr))
		return false
	}
	io.Copy(part, file)

	writer.Close()

	logger.Log.Info(fmt.Sprintf("[송신] 시간: %s | 파일명: %s | 크기: %d bytes\n", timestamp, sFileName, filesize))
	req, rErr := http.NewRequest("POST", sendUrl, body)
	if rErr != nil {
		logger.Log.Error("POST 요청 생성 실패", zap.Error(rErr))
		return false
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())

	client := &http.Client{
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		},
	}
	resp, reErr := client.Do(req)
	if reErr != nil {
		logger.Log.Error("클라이언트 요청 생성 실패", zap.Error(reErr))
		return false
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)
	logger.Log.Info(fmt.Sprintf("서버 응답: %s", string(respBody)))

	return true
}

/**
 * 파일 전송 스케줄러 함수
 * @param	type    스트리밍 요청 유형 (start: 스트리밍 시작, end: 스트리밍 종료)
 * @param       id      cmdManager의 id
 * @return      result  결과값
 */
func FileSendScheduler() {
	videoFilePath := os.Getenv("FILE_PATH") // 송신할 파일이 있는 폴더 경로
	cloudReceiveIp := os.Getenv("CLOUD_RECEIVE_IP") // 클라우드 수신 모듈 IP

	logger.Log.Info("파일 보내기 시작")
	logger.Log.Info(fmt.Sprintf("videoFilePath : %s", videoFilePath))
	files, err := os.ReadDir(videoFilePath)
	if err != nil {
		logger.Log.Error("디렉토리 열기 실패", zap.Error(err))
	}

	for _, entry := range files {
		if !entry.IsDir() {
			continue // 하위 파일은 무시
		} else {
			name := entry.Name()

			if name == "output_images" || name == "output_videos" {
				files, err := os.ReadDir(filepath.Join(videoFilePath, name))
				
				if err != nil {
					logger.Log.Info(fmt.Sprintf("하위 디렉토리 이름: %s", filepath.Join(videoFilePath, name)))
					logger.Log.Error("하위 디렉토리 열기 실패", zap.Error(err))
				}

				for _, entry2 := range files {
					if entry2.IsDir() {
						continue // 하위 파일은 무시
					} else {
						if name == "output_images" {
							logger.Log.Info(fmt.Sprintf("파일 전송 스케줄러 결과 : ", FileSender(filepath.Join(videoFilePath, "output_images/"), entry2.Name(), fmt.Sprintf("http://%s/imageFileReceive", cloudReceiveIp))))
						} else if name == "output_videos" {
							logger.Log.Info(fmt.Sprintf("파일 전송 스케줄러 결과 : ", FileSender(filepath.Join(videoFilePath, "output_videos/"), entry2.Name(), fmt.Sprintf("http://%s/videoFileReceive", cloudReceiveIp))))
						}
					}
				}
			}
		}
	}
}
