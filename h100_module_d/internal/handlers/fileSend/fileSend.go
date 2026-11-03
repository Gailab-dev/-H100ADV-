package fileSend

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha256"
	"crypto/tls"
	"crypto/x509"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"hash"
	"io"
	"io/fs"
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

// 전송 결과 코드(39번 WP-4, 공통 지시서 4.2). /fileSend 응답의 code 와 동일하다.
const (
	CodeOK             = "OK"
	CodeNoFile         = "NO_FILE"         // 장비에 해당 파일이 없음(서버가 MISSING 으로 기록할 수 있게 오류와 구분)
	CodeServerRejected = "SERVER_REJECTED" // 서버가 받았으나 실패/영수증 불일치(상태코드·ok·바이트)
	CodeSendFailed     = "SEND_FAILED"     // 네트워크·TLS·타임아웃·로컬 오류 등 전송 자체 실패
)

// 환경변수 기본값. 새 키가 .env 에 없어도(기존 장비) 기존 동작이 유지되도록 코드에 기본값을 둔다.
const (
	defaultSendTimeoutSec      = 120 // FILE_SEND_TIMEOUT_SEC           : /fileSend(수동·PULL) 전송 1건의 전체 제한(초)
	defaultSchedulerTimeoutSec = 600 // FILE_SEND_SCHEDULER_TIMEOUT_SEC : 스케줄러 전송 1건의 전체 제한(초, 대용량 영상 고려)
)

// kst: 날짜 경계 계산용 한국 표준시. tzdata 가 없는 장비에서는 고정 오프셋으로 대체한다.
var kst = loadKST()

func loadKST() *time.Location {
	if loc, err := time.LoadLocation("Asia/Seoul"); err == nil {
		return loc
	}
	return time.FixedZone("KST", 9*3600)
}

// KST: 날짜 경계·cron 에서 공통으로 쓰는 한국 표준시.
func KST() *time.Location { return kst }

// SchedulerEnabled: 기존 FileSendScheduler 사용 여부(FILE_SEND_SCHEDULER_ENABLED, 코드 기본값 true = 기존 동작).
// 서버 주도 백업으로 전환할 때 false 로 두면 장비 스케줄러가 꺼져 이중 전송이 생기지 않는다.
func SchedulerEnabled() bool {
	v := strings.ToLower(strings.TrimSpace(os.Getenv("FILE_SEND_SCHEDULER_ENABLED")))
	switch v {
	case "false", "0", "off", "no", "n":
		return false
	}
	return true
}

func envSeconds(key string, def int) time.Duration {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return time.Duration(def) * time.Second
	}
	n, err := strconv.Atoi(v)
	if err != nil || n <= 0 {
		logger.Log.Warn(fmt.Sprintf("%s 값이 잘못되어 기본값(%d초)을 사용합니다", key, def))
		return time.Duration(def) * time.Second
	}
	return time.Duration(n) * time.Second
}

// Response: /fileSend 응답. 기존 {"result":"true"|"false"} 를 유지하고 code·bytes 를 덧붙인다.
type Response struct {
	Result string `json:"result"`
	Code   string `json:"code,omitempty"`
	Bytes  *int64 `json:"bytes,omitempty"` // 성공 시 서버가 영수증으로 확인한 저장 바이트
}

// SendResult: FileSender 의 결과.
type SendResult struct {
	OK     bool
	Code   string
	Bytes  int64 // 성공 시 전송(=서버 저장) 바이트
	Detail string
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

// cleanFileName: fileName 은 폴더 구분자 없는 파일 이름(base name)만 허용한다(경로 탐색 방지).
func cleanFileName(name string) (string, bool) {
	if name == "" || name == "." || name == ".." {
		return "", false
	}
	if strings.ContainsAny(name, "/\\\x00") || strings.Contains(name, "..") {
		return "", false
	}
	if filepath.Base(name) != name || filepath.IsAbs(name) || filepath.VolumeName(name) != "" {
		return "", false
	}
	return name, true
}

func writeResponse(res http.ResponseWriter, status int, v Response) {
	res.Header().Set("Content-Type", "application/json")
	res.WriteHeader(status)
	if err := json.NewEncoder(res).Encode(v); err != nil {
		logger.Log.Error("failed to encode response: ", zap.Error(err))
	}
}

/**
 * 파일 전송 핸들러
 * @param       type    	파일 요청 유형 (image: 이미지, video: 영상, audio: 음성)
 * @param       fileName	파일명 (폴더 구분자 없는 이름만 허용)
 * @return      result  결과값 {"result":"true|false","code":"OK|NO_FILE|SERVER_REJECTED|SEND_FAILED","bytes":N}
 */
func FileSendHandler(res http.ResponseWriter, req *http.Request) {
	if req.Method != http.MethodPost {
		http.Error(res, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	bodyBytes, err := io.ReadAll(http.MaxBytesReader(res, req.Body, 64<<10)) // body 값
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

	tType, _ := bData["type"].(string) // 파일 요청 유형
	if tType == "" {
		logger.Log.Error("type 키가 존재하지 않습니다.")
		writeResponse(res, http.StatusBadRequest, Response{Result: "false", Code: "BAD_REQUEST"})
		return
	}

	rawName, _ := bData["fileName"].(string) // 파일명
	if rawName == "" {
		logger.Log.Error("fileName 키가 존재하지 않습니다.")
		writeResponse(res, http.StatusBadRequest, Response{Result: "false", Code: "BAD_REQUEST"})
		return
	}
	fileName, nameOK := cleanFileName(rawName)
	if !nameOK {
		// 경로 탐색 시도 차단. 이름 자체는 로그에 길이만 남겨 로그 오염을 막는다.
		logger.Log.Warn(fmt.Sprintf("허용되지 않는 fileName 요청 거부(type=%s, len=%d)", tType, len(rawName)))
		writeResponse(res, http.StatusBadRequest, Response{Result: "false", Code: "BAD_FILENAME"})
		return
	}

	var dir, endpoint string
	switch tType {
	case "image":
		// (23번) 디바이스 담당자와 합의된 실제 폴더 구조: FILE_PATH/image (구 output_images 아님)
		dir, endpoint = filepath.Join(os.Getenv("FILE_PATH"), "image/"), "imageFileReceive"
	case "video":
		// (23번) 디바이스 담당자와 합의된 실제 폴더 구조: FILE_PATH/video (구 output_videos 아님)
		dir, endpoint = filepath.Join(os.Getenv("FILE_PATH"), "video/"), "videoFileReceive"
	case "audio":
		// (2026-07-22 신규) SIP 통화 녹음(wav) 전송.
		//   녹음 폴더는 module_d 실행 경로(FILE_PATH) 밖에 있으므로 전용 env(AUDIO_PATH)로 지정한다.
		//   예) AUDIO_PATH=/home/gailab/H100_system/0924_3/sip_test/recordings
		//   (23번) 미설정 시 폴백 폴더명은 디바이스 담당자와 합의된 FILE_PATH/voice (구 recordings 아님)
		dir = os.Getenv("AUDIO_PATH")
		if dir == "" {
			dir = filepath.Join(os.Getenv("FILE_PATH"), "voice/")
		}
		endpoint = "audioFileReceive"
	default:
		http.Error(res, "Invalid body content", http.StatusBadRequest)
		return
	}

	sendUrl := fmt.Sprintf("https://%s/%s", os.Getenv("CLOUD_RECEIVE_IP"), endpoint)
	result := FileSender(dir, fileName, sendUrl, envSeconds("FILE_SEND_TIMEOUT_SEC", defaultSendTimeoutSec))

	resp := Response{Result: strconv.FormatBool(result.OK), Code: result.Code}
	if result.OK {
		b := result.Bytes
		resp.Bytes = &b
	}
	logger.Log.Info(fmt.Sprintf("[/fileSend] type=%s file=%s 결과=%s code=%s", tType, fileName, resp.Result, result.Code))
	writeResponse(res, http.StatusOK, resp)
}

// serverReceipt: module_c 수신 영수증(공통 지시서 4.2).
type serverReceipt struct {
	OK    bool   `json:"ok"`
	File  string `json:"file"`
	Bytes int64  `json:"bytes"`
	Kind  string `json:"kind"`
	Code  string `json:"code"`
	Msg   string `json:"msg"`
}

/**
 * 단일 파일 전송 함수
 *
 * 성공 조건: 서버 응답이 HTTP 200 이고, 영수증 JSON 의 ok==true 이며, 서버가 저장한 바이트가 보낸 바이트와 같을 때만.
 * 파일은 메모리에 통째로 올리지 않고 두 번 읽는다(1회: HMAC 계산, 2회: 스트리밍 업로드).
 * Content-Length 를 정확히 계산해 보내므로 서버 측은 기존과 동일하게 일반 요청으로 받는다.
 *
 * @param	sFilePath    파일 경로(폴더)
 * @param	sFileName    파일명(base name)
 * @param	sendUrl      수신 url
 * @param	timeout      요청 1건 전체 제한 시간
 */
func FileSender(sFilePath string, sFileName string, sendUrl string, timeout time.Duration) SendResult {
	started := time.Now()
	fail := func(code, detail string, err error) SendResult {
		fields := []zap.Field{zap.String("file", sFileName), zap.String("code", code), zap.String("detail", detail),
			zap.Duration("elapsed", time.Since(started).Round(time.Millisecond))}
		if err != nil {
			fields = append(fields, zap.Error(err))
		}
		logger.Log.Error("[송신 실패]", fields...)
		return SendResult{Code: code, Detail: detail}
	}

	name, ok := cleanFileName(sFileName)
	if !ok {
		return fail(CodeSendFailed, "허용되지 않는 파일명", nil)
	}
	filePath := filepath.Join(sFilePath, name)
	file, fErr := os.Open(filePath)
	if fErr != nil {
		if errors.Is(fErr, fs.ErrNotExist) {
			return fail(CodeNoFile, "장비에 파일이 없음", fErr)
		}
		return fail(CodeSendFailed, "파일 열기 실패", fErr)
	}
	defer file.Close()
	if info, sErr := file.Stat(); sErr == nil && info.IsDir() {
		return fail(CodeNoFile, "파일이 아니라 폴더임", nil)
	}

	// ===== [S] 디바이스 인증 헤더 생성 (Phase 2) ===== //
	// 환경변수 DEVICE_SERIAL(디바이스 시리얼), DEVICE_HMAC_KEY(64자 hex=32바이트)에서 로드.
	// HMAC = HMAC-SHA256(키, serial || fileBytes) 의 hex. 서버(module_c)가 동일하게 계산·비교한다.
	serial := os.Getenv("DEVICE_SERIAL")
	mac, hErr := newDeviceMAC(os.Getenv("DEVICE_HMAC_KEY"), serial)
	if hErr != nil {
		// 보안: 키 원문은 로그에 남기지 않음
		return fail(CodeSendFailed, "HMAC 설정 오류 — 환경변수 DEVICE_SERIAL / DEVICE_HMAC_KEY 확인 필요", hErr)
	}
	size, cpErr := io.Copy(mac, file)
	if cpErr != nil {
		return fail(CodeSendFailed, "파일 읽기 실패", cpErr)
	}
	macHex := hex.EncodeToString(mac.Sum(nil))
	if _, sErr := file.Seek(0, io.SeekStart); sErr != nil {
		return fail(CodeSendFailed, "파일 되감기 실패", sErr)
	}
	// ===== [E] 디바이스 인증 헤더 생성 ===== //

	// multipart 머리말·꼬리말을 미리 만들어 Content-Length 를 정확히 계산한다.
	var framing bytes.Buffer
	writer := multipart.NewWriter(&framing)
	if _, pErr := writer.CreateFormFile("file", name); pErr != nil {
		return fail(CodeSendFailed, "FormFile 생성 실패", pErr)
	}
	prefixLen := framing.Len()
	if cErr := writer.Close(); cErr != nil {
		return fail(CodeSendFailed, "multipart 마무리 실패", cErr)
	}
	prefix := append([]byte(nil), framing.Bytes()[:prefixLen]...)
	suffix := append([]byte(nil), framing.Bytes()[prefixLen:]...)

	timestamp := time.Now().Format("2006-01-02 15:04:05")
	logger.Log.Info(fmt.Sprintf("[송신] 시간: %s | 파일명: %s | 크기: %d bytes", timestamp, name, size))

	body := io.MultiReader(bytes.NewReader(prefix), io.LimitReader(file, size), bytes.NewReader(suffix))
	req, rErr := http.NewRequest("POST", sendUrl, body)
	if rErr != nil {
		return fail(CodeSendFailed, "POST 요청 생성 실패", rErr)
	}
	req.ContentLength = int64(len(prefix)) + size + int64(len(suffix))
	req.Header.Set("Content-Type", writer.FormDataContentType())
	// 디바이스 인증 헤더 부착
	req.Header.Set("X-Device-Serial", serial)
	req.Header.Set("X-Device-HMAC", macHex)

	// ===== [S] TLS 서버 인증서 검증 (22번: InsecureSkipVerify 제거) ===== //
	// 21번에서 구축한 내부 CA(h100-ca.crt)를 신뢰 루트로 module_c 서버 인증서를 검증한다.
	// CA 인증서 로드 실패 시 InsecureSkipVerify 로 되돌아가지 않고 전송을 중단한다(fail-closed).
	pool, poolErr := loadCACertPool()
	if poolErr != nil {
		return fail(CodeSendFailed, "CA 인증서 로드 실패 — 전송 중단", poolErr)
	}

	transport := &http.Transport{TLSClientConfig: &tls.Config{RootCAs: pool}}
	defer transport.CloseIdleConnections()
	client := &http.Client{Transport: transport, Timeout: timeout}
	// ===== [E] TLS 서버 인증서 검증 ===== //

	resp, reErr := client.Do(req)
	if reErr != nil {
		return fail(CodeSendFailed, "서버 요청 실패(연결·TLS·타임아웃)", reErr)
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 64<<10))
	preview := string(respBody)
	if len(preview) > 200 {
		preview = preview[:200]
	}
	logger.Log.Info(fmt.Sprintf("서버 응답: status=%d body=%s", resp.StatusCode, preview))

	if resp.StatusCode != http.StatusOK {
		return fail(CodeServerRejected, fmt.Sprintf("서버 상태코드 %d", resp.StatusCode), nil)
	}
	var rc serverReceipt
	if err := json.Unmarshal(respBody, &rc); err != nil {
		return fail(CodeServerRejected, "서버 영수증 JSON 해석 실패(구버전 서버 응답일 수 있음)", err)
	}
	if !rc.OK {
		return fail(CodeServerRejected, "서버가 실패로 응답: "+rc.Code, nil)
	}
	if rc.Bytes != size {
		return fail(CodeServerRejected, fmt.Sprintf("저장 바이트 불일치(보낸 %d / 서버 %d)", size, rc.Bytes), nil)
	}

	logger.Log.Info(fmt.Sprintf("[송신 성공] 파일명: %s | %d bytes | 소요 %s", name, size, time.Since(started).Round(time.Millisecond)))
	return SendResult{OK: true, Code: CodeOK, Bytes: size}
}

/**
 * 디바이스 인증용 HMAC 객체 생성 함수
 * HMAC-SHA256(key, serial || body) 를 계산할 hash 를 만들고 serial 을 먼저 기록해 돌려준다.
 * 호출측은 파일 바이트를 이어서 Write 한 뒤 Sum 하면 된다.
 *
 * @param	keyHex	디바이스 HMAC 키(64자 hex = 32바이트).
 * @param	serial	디바이스 시리얼
 * @return	hash, 오류
 */
func newDeviceMAC(keyHex string, serial string) (hash.Hash, error) {
	keyHex = strings.TrimSpace(keyHex)
	if keyHex == "" || strings.TrimSpace(serial) == "" {
		return nil, fmt.Errorf("DEVICE_SERIAL 또는 DEVICE_HMAC_KEY 미설정")
	}
	key, err := hex.DecodeString(keyHex)
	if err != nil || len(key) != 32 {
		return nil, fmt.Errorf("DEVICE_HMAC_KEY 형식 오류(64자 hex 필요)")
	}
	mac := hmac.New(sha256.New, key)
	mac.Write([]byte(serial)) // 시리얼 바인딩(스왑 방지)
	return mac, nil
}

/**
 * 파일 전송 스케줄러 함수 (장비 주도 전송 — FILE_SEND_SCHEDULER_ENABLED=false 이면 등록되지 않는다)
 * 대상: FILE_PATH/image, FILE_PATH/video 직속 파일 중 수정시각(mtime)이 '어제(KST)'인 것.
 */
func FileSendScheduler() {
	videoFilePath := os.Getenv("FILE_PATH")         // 송신할 파일이 있는 폴더 경로
	cloudReceiveIp := os.Getenv("CLOUD_RECEIVE_IP") // 클라우드 수신 모듈 IP
	timeout := envSeconds("FILE_SEND_SCHEDULER_TIMEOUT_SEC", defaultSchedulerTimeoutSec)

	// 어제(KST) 범위는 1회만 계산한다(실행 중 자정을 넘겨도 기준이 흔들리지 않게).
	now := time.Now().In(kst)
	yesterdayStart := time.Date(now.Year(), now.Month(), now.Day()-1, 0, 0, 0, 0, kst)
	yesterdayEnd := yesterdayStart.AddDate(0, 0, 1).Add(-time.Nanosecond)

	logger.Log.Info(fmt.Sprintf("파일 보내기 시작 — 대상 날짜(KST): %s, videoFilePath: %s", yesterdayStart.Format("2006-01-02"), videoFilePath))
	files, err := os.ReadDir(videoFilePath)
	if err != nil {
		logger.Log.Error("디렉토리 열기 실패", zap.Error(err))
		return
	}

	total, okCnt, failCnt := 0, 0, 0
	failByCode := map[string]int{}

	for _, entry := range files {
		if !entry.IsDir() {
			continue // 하위 파일은 무시
		}
		name := entry.Name()

		// (23번) 디바이스 담당자와 합의된 실제 폴더 구조: image / video (구 output_images/output_videos 아님)
		if name != "image" && name != "video" {
			continue
		}
		dir := filepath.Join(videoFilePath, name)
		subFiles, err := os.ReadDir(dir)
		if err != nil {
			logger.Log.Error(fmt.Sprintf("하위 디렉토리 열기 실패: %s", dir), zap.Error(err))
			continue
		}
		endpoint := "imageFileReceive"
		if name == "video" {
			endpoint = "videoFileReceive"
		}
		sendUrl := fmt.Sprintf("https://%s/%s", cloudReceiveIp, endpoint)

		for _, entry2 := range subFiles {
			if entry2.IsDir() {
				continue // 하위 폴더는 무시
			}

			// 파일 정보 가져오기
			fileInfo, err := entry2.Info()
			if err != nil {
				logger.Log.Error(fmt.Sprintf("파일 정보 가져오기 실패: %s", entry2.Name()), zap.Error(err))
				continue
			}

			// 파일 수정 시간이 어제(KST)인지 확인
			modTime := fileInfo.ModTime().In(kst)
			if modTime.Before(yesterdayStart) || modTime.After(yesterdayEnd) {
				continue
			}

			total++
			result := FileSender(dir, entry2.Name(), sendUrl, timeout)
			logger.Log.Info(fmt.Sprintf("파일 전송 스케줄러 결과 : %v (kind=%s file=%s code=%s)", result.OK, name, entry2.Name(), result.Code))
			if result.OK {
				okCnt++
			} else {
				failCnt++
				failByCode[result.Code]++
			}
		}
	}

	logger.Log.Info(fmt.Sprintf("파일 보내기 종료 — 대상 %d건 / 성공 %d건 / 실패 %d건 %v", total, okCnt, failCnt, failByCode))
}
