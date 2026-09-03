package fileSend

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha256"
	"crypto/tls"
	"crypto/x509"
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
	"sync"
	"time"

	"go.uber.org/zap"

	"local.dev/h100_module_d/logger"
)

type Response struct {
        Result string `json:"result"`
}

// (22번: InsecureSkipVerify 제거) 21번에서 구축한 내부 CA(h100-ca.crt) 인증서 풀.
// FileSender 가 파일 전송마다(스케줄러 루프 포함) 호출되므로 sync.Once 로 1회만 로드해 캐시한다.
var (
	caCertPool     *x509.CertPool
	caCertPoolOnce sync.Once
	caCertPoolErr  error
)

// loadCACertPool: CA_CERT_FILE(env) 의 내부 CA 인증서를 읽어 x509.CertPool 을 구성한다.
// 실패 시(파일 없음·PEM 파싱 실패 등) InsecureSkipVerify 로 되돌아가지 않고 에러를 반환한다(fail-closed).
func loadCACertPool() (*x509.CertPool, error) {
	caCertPoolOnce.Do(func() {
		caCertPath := os.Getenv("CA_CERT_FILE")
		if caCertPath == "" {
			caCertPoolErr = fmt.Errorf("CA_CERT_FILE 환경변수가 설정되지 않았습니다")
			return
		}
		caCert, err := os.ReadFile(caCertPath)
		if err != nil {
			caCertPoolErr = fmt.Errorf("CA 인증서 파일 읽기 실패(%s): %w", caCertPath, err)
			return
		}
		pool := x509.NewCertPool()
		if ok := pool.AppendCertsFromPEM(caCert); !ok {
			caCertPoolErr = fmt.Errorf("CA 인증서 파싱 실패(PEM 형식 확인 필요): %s", caCertPath)
			return
		}
		caCertPool = pool
	})
	return caCertPool, caCertPoolErr
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
			// (23번) 디바이스 담당자와 합의된 실제 폴더 구조: FILE_PATH/image (구 output_images 아님)
        	filePath = filepath.Join(os.Getenv("FILE_PATH"), "image/")
			resVal = FileSender(filePath, tFileName.(string), fmt.Sprintf("https://%s/imageFileReceive", os.Getenv("CLOUD_RECEIVE_IP")))
        } else if tType == "video" {
			// (23번) 디바이스 담당자와 합의된 실제 폴더 구조: FILE_PATH/video (구 output_videos 아님)
			filePath = filepath.Join(os.Getenv("FILE_PATH"), "video/")
			resVal = FileSender(filePath, tFileName.(string), fmt.Sprintf("https://%s/videoFileReceive", os.Getenv("CLOUD_RECEIVE_IP")))
		} else if tType == "audio" {
			// (2026-07-22 신규) SIP 통화 녹음(wav) 전송.
			//   녹음 폴더는 module_d 실행 경로(FILE_PATH) 밖에 있으므로 전용 env(AUDIO_PATH)로 지정한다.
			//   예) AUDIO_PATH=/home/gailab/H100_system/0924_3/sip_test/recordings
			//   (23번) 미설정 시 폴백 폴더명은 디바이스 담당자와 합의된 FILE_PATH/voice (구 recordings 아님)
			filePath = os.Getenv("AUDIO_PATH")
			if filePath == "" {
				filePath = filepath.Join(os.Getenv("FILE_PATH"), "voice/")
			}
			resVal = FileSender(filePath, tFileName.(string), fmt.Sprintf("https://%s/audioFileReceive", os.Getenv("CLOUD_RECEIVE_IP")))
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

	// ===== [S] TLS 서버 인증서 검증 (22번: InsecureSkipVerify 제거) ===== //
	// 21번에서 구축한 내부 CA(h100-ca.crt)를 신뢰 루트로 module_c 서버 인증서를 검증한다.
	// CA 인증서 로드 실패 시 InsecureSkipVerify 로 되돌아가지 않고 전송을 중단한다(fail-closed).
	pool, poolErr := loadCACertPool()
	if poolErr != nil {
		logger.Log.Error("CA 인증서 로드 실패 — 전송 중단", zap.Error(poolErr))
		return false
	}

	client := &http.Client{
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{RootCAs: pool},
		},
	}
	// ===== [E] TLS 서버 인증서 검증 ===== //
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

			// (23번) 디바이스 담당자와 합의된 실제 폴더 구조: image / video (구 output_images/output_videos 아님)
			if name == "image" || name == "video" {
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

						if name == "image" {
							logger.Log.Info(fmt.Sprintf("파일 전송 스케줄러 결과 : ", FileSender(filepath.Join(videoFilePath, "image/"), entry2.Name(), fmt.Sprintf("https://%s/imageFileReceive", cloudReceiveIp))))
						} else if name == "video" {
							logger.Log.Info(fmt.Sprintf("파일 전송 스케줄러 결과 : ", FileSender(filepath.Join(videoFilePath, "video/"), entry2.Name(), fmt.Sprintf("https://%s/videoFileReceive", cloudReceiveIp))))
						}
					}
				}
			}
		}
	}
}
