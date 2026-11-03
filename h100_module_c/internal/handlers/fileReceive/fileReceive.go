package fileReceive

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"go.uber.org/zap"

	"local.dev/h100_module_c/database"
	"local.dev/h100_module_c/internal/auth"
	"local.dev/h100_module_c/logger"
)

// 파일 수신 요청 본문 상한 기본값(MB). .env 의 FILE_RECEIVE_MAX_MB 로 조정한다(코드 기본값 사용 가능).
//
//	HMAC 검증을 위해 파일 전체를 메모리에 올리므로 무제한으로 둘 수 없다.
const defaultMaxReceiveMB = 512

// 수신 영수증 JSON(39번 WP-3). 성공 시 200 + ok:true, 실패 시 비-200 + ok:false.
// 송신 측(module_d FileSender)은 HTTP 200 && ok==true && bytes==보낸 바이트 일 때만 성공으로 본다.
type receipt struct {
	OK    bool   `json:"ok"`
	File  string `json:"file"`
	Bytes int64  `json:"bytes"`
	Kind  string `json:"kind"`
	// 참고용: DB 플래그 갱신 결과(updated / unchanged / no_row / skipped). 송신 측은 무시해도 된다.
	Flag string `json:"flag,omitempty"`
}

type failure struct {
	OK   bool   `json:"ok"`
	Code string `json:"code"`
	Msg  string `json:"msg"`
}

// receiveError: 저장 도중 발생한 실패를 상태코드·사유코드와 함께 호출측으로 전달한다.
type receiveError struct {
	status int
	code   string
	msg    string
}

func writeJSON(res http.ResponseWriter, status int, v interface{}) {
	res.Header().Set("Content-Type", "application/json")
	res.WriteHeader(status)
	if err := json.NewEncoder(res).Encode(v); err != nil {
		logger.Log.Error("응답 인코딩 실패", zap.Error(err))
	}
}

func writeFail(res http.ResponseWriter, e *receiveError) {
	writeJSON(res, e.status, failure{OK: false, Code: e.code, Msg: e.msg})
}

// maxReceiveBytes: 요청 본문 상한(바이트). FILE_RECEIVE_MAX_MB 가 없거나 잘못되면 기본값.
func maxReceiveBytes() int64 {
	mb := int64(defaultMaxReceiveMB)
	if v := strings.TrimSpace(os.Getenv("FILE_RECEIVE_MAX_MB")); v != "" {
		if n, err := strconv.ParseInt(v, 10, 64); err == nil && n > 0 {
			mb = n
		}
	}
	return mb << 20
}

// sanitizeFileName: 업로드 파일명에서 경로 성분을 제거하고 안전하지 않은 이름은 거부한다.
func sanitizeFileName(name string) (string, bool) {
	name = strings.ReplaceAll(name, "\\", "/")
	name = filepath.Base(name)
	if name == "" || name == "." || name == ".." || name == "/" || strings.ContainsRune(name, 0) {
		return "", false
	}
	return name, true
}

// saveDirFor: 파일 유형별 저장 폴더. 알 수 없는 유형은 ok=false.
func saveDirFor(stype string) (string, bool) {
	switch stype {
	case "image":
		return filepath.Join(os.Getenv("FILE_UPLOAD_PATH"), "output_images_enc"), true
	case "video":
		return filepath.Join(os.Getenv("FILE_UPLOAD_PATH"), "output_videos_enc"), true
	case "audio":
		// (2026-07-22) SIP 통화 녹음(wav) 수신. 이미지·영상과 달리 '평문'으로 운용하기로 결정되어
		//   암호화 디렉토리(_enc)가 아닌 output_audios 에 그대로 저장한다.
		//   → 웹(Java)의 audio.dec.path 와 동일 경로이므로 별도 복호화 없이 바로 재생된다.
		return filepath.Join(os.Getenv("FILE_UPLOAD_PATH"), "output_audios"), true
	}
	return "", false
}

// readUploadPart: multipart 본문에서 "file" 파트를 스트리밍으로 찾아 파일명과 바이트를 읽는다.
// (ParseMultipartForm 은 상한 이상을 임시 파일로 흘려 디스크를 쓰므로 MultipartReader 를 직접 쓴다.)
func readUploadPart(req *http.Request) (string, []byte, *receiveError) {
	mr, err := req.MultipartReader()
	if err != nil {
		return "", nil, &receiveError{http.StatusBadRequest, "BAD_FORM", fmt.Sprintf("multipart 본문이 아닙니다: %v", err)}
	}
	for {
		part, err := mr.NextPart()
		if err == io.EOF {
			return "", nil, &receiveError{http.StatusBadRequest, "BAD_FORM", "file 폼 필드가 없습니다"}
		}
		if err != nil {
			return "", nil, bodyReadError(err)
		}
		if part.FormName() != "file" || part.FileName() == "" {
			part.Close()
			continue
		}
		data, rdErr := io.ReadAll(part)
		name := part.FileName()
		part.Close()
		if rdErr != nil {
			return "", nil, bodyReadError(rdErr)
		}
		return name, data, nil
	}
}

func bodyReadError(err error) *receiveError {
	var tooBig *http.MaxBytesError
	if errors.As(err, &tooBig) {
		return &receiveError{http.StatusRequestEntityTooLarge, "TOO_LARGE", "요청 본문이 허용 크기를 초과했습니다"}
	}
	return &receiveError{http.StatusBadRequest, "BAD_FORM", fmt.Sprintf("파일 수신 실패: %v", err)}
}

// saveAtomic: 같은 폴더의 임시 파일에 쓰고 fsync 후 rename 한다(부분 파일이 최종 이름으로 노출되지 않게).
func saveAtomic(dir, name string, data []byte) error {
	if err := os.MkdirAll(dir, os.ModePerm); err != nil {
		return fmt.Errorf("저장 폴더 생성 실패: %w", err)
	}
	tmp, err := os.CreateTemp(dir, ".recv-*.tmp")
	if err != nil {
		return fmt.Errorf("임시 파일 생성 실패: %w", err)
	}
	tmpPath := tmp.Name()
	cleanup := func() { os.Remove(tmpPath) }

	n, wErr := tmp.Write(data)
	if wErr == nil && n != len(data) {
		wErr = io.ErrShortWrite
	}
	if wErr == nil {
		wErr = tmp.Sync()
	}
	cErr := tmp.Close()
	if wErr != nil {
		cleanup()
		return fmt.Errorf("임시 파일 쓰기 실패: %w", wErr)
	}
	if cErr != nil {
		cleanup()
		return fmt.Errorf("임시 파일 닫기 실패: %w", cErr)
	}
	if err := os.Chmod(tmpPath, 0o644); err != nil {
		cleanup()
		return fmt.Errorf("파일 권한 설정 실패: %w", err)
	}
	final := filepath.Join(dir, name)
	if err := os.Rename(tmpPath, final); err != nil {
		cleanup()
		return fmt.Errorf("파일 이름 확정 실패: %w", err)
	}
	if info, err := os.Stat(final); err != nil || info.Size() != int64(len(data)) {
		return fmt.Errorf("저장 후 크기 확인 실패")
	}
	return nil
}

/**
 * 단일 파일 수신 함수 — 인증·크기 상한·원자적 저장까지만 수행한다(DB 갱신은 호출측).
 *
 * [Phase 2 변경] 저장 전에 디바이스 인증(X-Device-Serial + X-Device-HMAC)을 검증한다.
 *  - 검증을 위해 파일 바이트를 메모리에 적재한 뒤 HMAC 을 계산/비교하고, 통과 시에만 디스크에 저장한다.
 *  - 검증 실패 시 401 Unauthorized 로 응답하고 파일을 저장하지 않는다.
 *  - 보안: 시리얼은 마스킹 로그만 남기고, 키·HMAC 원문은 로그에 남기지 않는다.
 *
 * [39번 WP-3] 요청 본문 상한(MaxBytesReader), 임시 파일+rename 원자적 저장, 실패 시 JSON 응답.
 *  성공 시 응답은 쓰지 않고 (저장된 파일명, 저장 바이트)를 돌려준다 — 영수증은 호출측이 DB 갱신 뒤 작성한다.
 *
 * @param	stype   파일 유형 (image / video / audio)
 * @return  저장된 파일명, 저장 바이트, 실패 시 *receiveError
 */
func receiveAndSave(res http.ResponseWriter, req *http.Request, stype string) (string, int64, *receiveError) {
	if req.Method != http.MethodPost {
		return "", 0, &receiveError{http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "POST 만 허용됩니다"}
	}
	saveDir, ok := saveDirFor(stype)
	if !ok {
		// 알 수 없는 유형은 저장하지 않음(빈 saveDir 로 인한 엉뚱한 위치 저장 방지)
		logger.Log.Error(fmt.Sprintf("지원하지 않는 파일 유형: %s", stype))
		return "", 0, &receiveError{http.StatusBadRequest, "BAD_KIND", "지원하지 않는 파일 유형"}
	}

	// 요청 본문 상한(파일 + multipart 오버헤드 여유 1MB)
	req.Body = http.MaxBytesReader(res, req.Body, maxReceiveBytes()+(1<<20))
	timestamp := time.Now().Format("2006-01-02 15:04:05")

	rawName, fileBytes, rErr := readUploadPart(req)
	if rErr != nil {
		logger.Log.Error("파일 수신 실패", zap.String("code", rErr.code), zap.String("msg", rErr.msg))
		return "", 0, rErr
	}

	// ===== [S] 디바이스 인증 (시리얼 + HMAC 검증) ===== //
	serial := req.Header.Get("X-Device-Serial")
	macHex := req.Header.Get("X-Device-HMAC")
	if ok, reason := auth.Verify(serial, macHex, fileBytes); !ok {
		// 보안: 시리얼은 마스킹, 키/HMAC 원문은 로그 금지
		logger.Log.Warn(fmt.Sprintf("[디바이스 인증 실패] 사유: %s | serial(masked): %s", reason, auth.MaskSerial(serial)))
		return "", 0, &receiveError{http.StatusUnauthorized, "UNAUTHORIZED", "Unauthorized: " + reason}
	}
	logger.Log.Info(fmt.Sprintf("[디바이스 인증 성공] serial(masked): %s", auth.MaskSerial(serial)))
	// ===== [E] 디바이스 인증 ===== //

	name, nameOK := sanitizeFileName(rawName)
	if !nameOK {
		logger.Log.Warn("허용되지 않는 업로드 파일명")
		return "", 0, &receiveError{http.StatusBadRequest, "BAD_FILENAME", "허용되지 않는 파일명"}
	}

	// 검증 통과한 바이트를 그대로 저장(임시 파일 + rename)
	if err := saveAtomic(saveDir, name, fileBytes); err != nil {
		logger.Log.Error("파일 저장 실패", zap.Error(err))
		return "", 0, &receiveError{http.StatusInternalServerError, "SAVE_FAILED", "파일 저장 실패"}
	}

	logger.Log.Info(fmt.Sprintf("[파일 수신] 시간: %s | 종류: %s | 파일명: %s | 사이즈:%d bytes", timestamp, stype, name, len(fileBytes)))
	return name, int64(len(fileBytes)), nil
}

// markFlag: UPDATE <table> SET <setCol> = 1 WHERE <keyCol> = ? 를 수행하고 결과를 구분한다.
//
//	updated   : 행이 갱신됨
//	unchanged : 대상 행은 있으나 이미 1(재전송 등) — DSN 에 clientFoundRows 가 없어 영향 행 수가 0 으로 나오므로 COUNT 로 구분
//	no_row    : 대상 행 자체가 없음(이벤트 행이 아직 없거나 다른 파일명)
//
// DB 오류는 error 로 반환한다. table/컬럼명은 호출측 상수만 쓴다(사용자 입력 아님).
func markFlag(table, setCol, keyCol, value string) (string, error) {
	if database.DBConn == nil {
		return "", errors.New("DB 연결이 초기화되지 않았습니다")
	}
	tx := database.DBConn.Exec(fmt.Sprintf("UPDATE %s SET %s = 1 WHERE %s = ?", table, setCol, keyCol), value)
	if tx.Error != nil {
		return "", tx.Error
	}
	if tx.RowsAffected > 0 {
		return "updated", nil
	}
	var cnt int64
	if err := database.DBConn.Table(table).Where(keyCol+" = ?", value).Count(&cnt).Error; err != nil {
		return "", err
	}
	if cnt > 0 {
		return "unchanged", nil
	}
	return "no_row", nil
}

// finish: 저장 결과 + DB 플래그 갱신 결과를 영수증/실패 JSON 으로 응답한다.
func finish(res http.ResponseWriter, stype, name string, size int64, flag string, dbErr error) {
	if dbErr != nil {
		// 파일은 이미 원자적으로 저장되어 있다. 송신 측이 재시도해도 같은 이름으로 덮어쓰므로 안전하다.
		logger.Log.Error(fmt.Sprintf("DB 플래그 갱신 실패(파일은 저장됨): kind=%s file=%s", stype, name), zap.Error(dbErr))
		writeFail(res, &receiveError{http.StatusInternalServerError, "DB_UPDATE_FAILED", "파일은 저장되었으나 DB 갱신에 실패했습니다"})
		return
	}
	if flag == "no_row" {
		logger.Log.Warn(fmt.Sprintf("DB 플래그 대상 행 없음(파일은 저장됨): kind=%s file=%s", stype, name))
	}
	writeJSON(res, http.StatusOK, receipt{OK: true, File: name, Bytes: size, Kind: stype, Flag: flag})
}

/**
 * 이미지 단일 파일 수신 함수
 *
 * 현재 동작(수신 즉시 ev_has_img = 1)은 유지하되 오류·영향 행 수를 확인한다.
 * 이미지 2(ev_img_path2)는 ev_has_img2 컬럼이 없어, ev_img_path 로 행을 못 찾으면 ev_img_path2 로 찾아
 * 같은 ev_has_img 플래그를 갱신한다(= "이미지가 도착했다" 의미 유지).
 * @param	file    수신 file
 */
func ImageFileReceive(res http.ResponseWriter, req *http.Request) {
	name, size, rErr := receiveAndSave(res, req, "image")
	if rErr != nil {
		writeFail(res, rErr)
		return
	}

	flag, err := markFlag("tbl_event_data", "ev_has_img", "ev_img_path", name)
	if err == nil && flag == "no_row" {
		flag, err = markFlag("tbl_event_data", "ev_has_img", "ev_img_path2", name)
	}
	if err == nil {
		logger.Log.Info(fmt.Sprintf("tbl_event_data ev_has_img 갱신 결과: %s (file=%s)", flag, name))
	}
	finish(res, "image", name, size, flag, err)
}

/**
 * 영상 단일 파일 수신 함수
 * @param	file    수신 file
 */
func VideoFileReceive(res http.ResponseWriter, req *http.Request) {
	name, size, rErr := receiveAndSave(res, req, "video")
	if rErr != nil {
		writeFail(res, rErr)
		return
	}

	flag, err := markFlag("tbl_event_data", "ev_has_mov", "ev_mov_path", name)
	if err == nil {
		logger.Log.Info(fmt.Sprintf("tbl_event_data ev_has_mov 갱신 결과: %s (file=%s)", flag, name))
	}
	finish(res, "video", name, size, flag, err)
}

/**
 * (2026-07-22 신규) SIP 통화 녹음(wav) 단일 파일 수신 함수
 *  - 저장 위치: FILE_UPLOAD_PATH/output_audios (평문)
 *  - 파일명은 tbl_sip_call.sc_audio_path 와 동일해야 웹에서 재생 가능
 *  - 이미지·영상과 동일하게 HMAC 디바이스 인증 필수(receiveAndSave 내부에서 검증)
 * @param	file    수신 file
 */
func AudioFileReceive(res http.ResponseWriter, req *http.Request) {
	name, size, rErr := receiveAndSave(res, req, "audio")
	if rErr != nil {
		writeFail(res, rErr)
		return
	}

	// 파일이 실제로 도착했으므로 음성 보유 플래그를 확정(로그 INSERT 시 파일명 유무로만 파생돼 있었음)
	flag, err := markFlag("tbl_sip_call", "sc_has_audio", "sc_audio_path", name)
	if err == nil {
		logger.Log.Info(fmt.Sprintf("tbl_sip_call sc_has_audio 갱신 결과: %s (file=%s)", flag, name))
	}
	finish(res, "audio", name, size, flag, err)
}

/**
 * 단일 파일 수신 함수 (/fileReceive, 이미지로 저장만 하고 DB 는 갱신하지 않는다)
 * @param	file    수신 file
 */
func OneFileReceive(res http.ResponseWriter, req *http.Request) {
	name, size, rErr := receiveAndSave(res, req, "image")
	if rErr != nil {
		writeFail(res, rErr)
		return
	}
	finish(res, "image", name, size, "skipped", nil)
}
