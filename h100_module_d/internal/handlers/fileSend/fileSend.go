package fileSend

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha256"
	"crypto/tls"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

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
			resVal = FileSender(filePath, tFileName.(string), fmt.Sprintf("https://%s/imageFileReceive", os.Getenv("CLOUD_RECEIVE_IP")))
        } else if tType == "video" {
			filePath = filepath.Join(os.Getenv("FILE_PATH"), "output_videos/")
			resVal = FileSender(filePath, tFileName.(string), fmt.Sprintf("https://%s/videoFileReceive", os.Getenv("CLOUD_RECEIVE_IP")))
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
		return false
	}
	defer file.Close()

	// HMAC 계산과 전송 본문 작성 모두에 사용하기 위해 파일 바이트를 메모리에 적재
	fileBytes, rdErr := io.ReadAll(file)
	if rdErr != nil {
		logger.Log.Error(fmt.Sprintf("파일 읽기 실패: %s", filePath), zap.Error(rdErr))
		return false
	}

	// ===== [S] 디바이스 인증 헤더 생성 (Phase 2) ===== //
	// 환경변수 DEVICE_SERIAL(디바이스 시리얼), DEVICE_HMAC_KEY(64자 hex=32바이트)에서 로드.
	// HMAC = HMAC-SHA256(키, serial || fileBytes) 의 hex. 서버(module_c)가 동일하게 계산·비교한다.
	serial := os.Getenv("DEVICE_SERIAL")
	macHex, hErr := computeDeviceHMAC(os.Getenv("DEVICE_HMAC_KEY"), serial, fileBytes)
	if hErr != nil {
		// 보안: 키 원문은 로그에 남기지 않음
		logger.Log.Error("HMAC 생성 실패 — 환경변수 DEVICE_SERIAL / DEVICE_HMAC_KEY 확인 필요", zap.Error(hErr))
		return false
	}
	// ===== [E] 디바이스 인증 헤더 생성 ===== //

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	filesize := int64(len(fileBytes))
	timestamp := time.Now().Format("2006-01-02 15:04:05")

	part, pErr := writer.CreateFormFile("file", sFileName)
	if pErr != nil {
		logger.Log.Error("FormFile 생성 실패", zap.Error(pErr))
		return false
	}
	if _, wErr := part.Write(fileBytes); wErr != nil {
		logger.Log.Error("multipart 본문 작성 실패", zap.Error(wErr))
		return false
	}

	writer.Close()

	logger.Log.Info(fmt.Sprintf("[송신] 시간: %s | 파일명: %s | 크기: %d bytes\n", timestamp, sFileName, filesize))
	req, rErr := http.NewRequest("POST", sendUrl, body)
	if rErr != nil {
		logger.Log.Error("POST 요청 생성 실패", zap.Error(rErr))
		return false
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())
	// 디바이스 인증 헤더 부착
	req.Header.Set("X-Device-Serial", serial)
	req.Header.Set("X-Device-HMAC", macHex)

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
 * 디바이스 인증용 HMAC 생성 함수
 * HMAC-SHA256(key, serial || body) 의 hex 문자열을 반환한다.
 *
 * @param	keyHex	디바이스 HMAC 키(64자 hex = 32바이트).
 * @param	serial	디바이스 시리얼
 * @param	body	전송 파일 원본 바이트(IV || 암호문)
 * @return	HMAC hex, 오류
 */
func computeDeviceHMAC(keyHex string, serial string, body []byte) (string, error) {
	keyHex = strings.TrimSpace(keyHex)
	if keyHex == "" || strings.TrimSpace(serial) == "" {
		return "", fmt.Errorf("DEVICE_SERIAL 또는 DEVICE_HMAC_KEY 미설정")
	}
	key, err := hex.DecodeString(keyHex)
	if err != nil || len(key) != 32 {
		return "", fmt.Errorf("DEVICE_HMAC_KEY 형식 오류(64자 hex 필요)")
	}
	mac := hmac.New(sha256.New, key)
	mac.Write([]byte(serial)) // 시리얼 바인딩(스왑 방지)
	mac.Write(body)
	return hex.EncodeToString(mac.Sum(nil)), nil
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
						// 어제 날짜 계산
						yesterday := time.Now().AddDate(0, 0, -1)
						yesterdayStart := time.Date(yesterday.Year(), yesterday.Month(), yesterday.Day(), 0, 0, 0, 0, yesterday.Location())
						yesterdayEnd := time.Date(yesterday.Year(), yesterday.Month(), yesterday.Day(), 23, 59, 59, 999999999, yesterday.Location())

						// 파일 정보 가져오기
						fileInfo, err := entry2.Info()
						if err != nil {
							logger.Log.Error(fmt.Sprintf("파일 정보 가져오기 실패: %s", entry2.Name()), zap.Error(err))
							continue
						}

						// 파일 수정 시간이 어제인지 확인
						modTime := fileInfo.ModTime()
						if modTime.Before(yesterdayStart) || modTime.After(yesterdayEnd) {
							logger.Log.Info(fmt.Sprintf("어제 날짜가 아닌 파일 건너뜀: %s (수정 시간: %s)", entry2.Name(), modTime.Format("2006-01-02 15:04:05")))
							continue
						}

						if name == "output_images" {
							logger.Log.Info(fmt.Sprintf("파일 전송 스케줄러 결과 : ", FileSender(filepath.Join(videoFilePath, "output_images/"), entry2.Name(), fmt.Sprintf("https://%s/imageFileReceive", cloudReceiveIp))))
						} else if name == "output_videos" {
							logger.Log.Info(fmt.Sprintf("파일 전송 스케줄러 결과 : ", FileSender(filepath.Join(videoFilePath, "output_videos/"), entry2.Name(), fmt.Sprintf("https://%s/videoFileReceive", cloudReceiveIp))))
						}
					}
				}
			}
		}
	}
}
