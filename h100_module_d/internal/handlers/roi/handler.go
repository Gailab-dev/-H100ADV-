// Package roi 는 서버(module_c)가 중계한 ROI 조회·스냅샷·적용 요청을 처리한다(34번 작업계획서).
//
//	ROI_get      현재 ROI 파일 내용 + SHA-256 해시
//	ROI_snapshot Cam1/Cam2 스냅샷 각 1장(PNG 또는 JPEG)
//	ROI_receive  baseHash 가 현재 파일 해시와 같을 때만 검증 후 파일 교체(아니면 409)
//
// 인증: X-Device-Serial + X-Device-HMAC(auth.go). 파일 경로·스냅샷 소스는 모두 환경설정으로 받는다.
package roi

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"time"
	"unicode/utf8"

	"go.uber.org/zap"

	"local.dev/h100_module_d/logger"
)

const (
	maxRequestBody  = 1 << 20 // 요청 본문 1MB (ROI JSON 은 보통 수 KB)
	maxRoiTextBytes = 512 << 10
	// 스냅샷 1장 상한. 해상도 제한은 두지 않는다(PNG 1~2MB 는 여유 있게 통과).
	// 응답은 두 장을 base64(약 4/3 배)로 담아 module_c 로 가는데 module_c 의 장비 응답 상한(maxDeviceResult)이 24MB 라,
	// 2 × 8MB × 4/3 ≈ 21.4MB 가 그 안에 들어오는 최대치다. 이 값을 올리면 module_c 상한도 함께 올려야 한다.
	maxSnapshot     = 8 << 20
	snapshotTimeout = 10 * time.Second
)

var snapshotSlot = make(chan struct{}, 1)

type envelope struct {
	Serial string `json:"serial"`
	TS     string `json:"ts"`
}

type receiveRequest struct {
	envelope
	BaseHash string `json:"baseHash"`
	RoisText string `json:"roisText"`
}

type apiError struct {
	OK      bool     `json:"ok"`
	Code    string   `json:"code"`
	Msg     string   `json:"msg"`
	Detail  []string `json:"problems,omitempty"`
	Current string   `json:"currentHash,omitempty"`
}

func writeJSON(w http.ResponseWriter, status int, v interface{}) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func fail(w http.ResponseWriter, status int, code, msg string) {
	setCode(w, code)
	writeJSON(w, status, apiError{Code: code, Msg: msg})
}

// preamble 은 메서드·본문 크기·HMAC·시리얼·ts 를 공통 검증하고 본문 바이트를 돌려준다. 실패 시 응답까지 마친 뒤 ok=false.
func preamble(w http.ResponseWriter, r *http.Request, into interface{}) (ok bool) {
	if r.Method != http.MethodPost {
		fail(w, http.StatusMethodNotAllowed, "METHOD", "POST 만 허용됩니다")
		return false
	}
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, maxRequestBody))
	if err != nil {
		fail(w, http.StatusRequestEntityTooLarge, "TOO_LARGE", "요청이 너무 큽니다")
		return false
	}
	if good, status, msg := verifyHMAC(r, body); !good {
		note(w, "stage=auth reason=%s", authReason(status))
		fail(w, status, "UNAUTHORIZED", msg)
		return false
	}
	if err := json.Unmarshal(body, into); err != nil {
		note(w, "stage=parse")
		fail(w, http.StatusBadRequest, "BAD_REQUEST", "요청 형식이 올바르지 않습니다")
		return false
	}
	var env envelope
	json.Unmarshal(body, &env)
	if env.Serial != os.Getenv("DEVICE_SERIAL") {
		note(w, "stage=auth reason=serial_mismatch")
		fail(w, http.StatusUnauthorized, "UNAUTHORIZED", "인증에 실패했습니다")
		return false
	}
	if !checkFreshness(env.TS, time.Now()) {
		note(w, "stage=freshness")
		fail(w, http.StatusBadRequest, "STALE", "요청 시각이 올바르지 않습니다")
		return false
	}
	return true
}

// authReason 은 HMAC 검증 실패 상태를 로그용 사유로 바꾼다(키·서명 값은 남기지 않는다).
func authReason(status int) string {
	if status == http.StatusServiceUnavailable {
		return "device_auth_not_configured"
	}
	return "bad_or_missing_signature"
}

func roiPath(w http.ResponseWriter) (string, bool) {
	p := os.Getenv("ROI_FILE_PATH")
	if p == "" {
		fail(w, http.StatusServiceUnavailable, "NOT_CONFIGURED", "ROI 파일 경로가 설정되지 않았습니다")
		return "", false
	}
	return p, true
}

// GetHandler 는 ROI_get. 모든 요청에 한 줄 요약 로그를 남긴다(log.go).
var GetHandler http.HandlerFunc = withSummary("ROI_get", getHandler)

// ReceiveHandler 는 ROI_receive.
var ReceiveHandler http.HandlerFunc = withSummary("ROI_receive", receiveHandler)

// SnapshotHandler 는 ROI_snapshot. 스냅샷 소스는 ROI_SNAPSHOT_URL(로컬 Python 등) 또는 ROI_SNAPSHOT_DIR(Cam1.png/Cam2.png, 없으면 .jpg).
var SnapshotHandler http.HandlerFunc = withSummary("ROI_snapshot", snapshotHandler)

func getHandler(w http.ResponseWriter, r *http.Request) {
	var req envelope
	if !preamble(w, r, &req) {
		return
	}
	path, ok := roiPath(w)
	if !ok {
		return
	}
	data, hash, exists, err := readCurrent(path)
	if err != nil {
		note(w, "stage=read")
		logger.Log.Error("[ROI_get] 파일 읽기 실패", zap.Error(err))
		fail(w, http.StatusInternalServerError, "READ_FAILED", "ROI 파일을 읽을 수 없습니다")
		return
	}
	if len(data) > maxRoiTextBytes || !utf8.Valid(data) {
		note(w, "stage=file_content bytes=%d", len(data))
		fail(w, http.StatusUnprocessableEntity, "BAD_FILE", "ROI 파일 내용을 해석할 수 없습니다")
		return
	}
	note(w, "exists=%t bytes=%d hash=%s", exists, len(data), hash8(hash))
	writeJSON(w, http.StatusOK, map[string]interface{}{"ok": true, "exists": exists, "roisText": string(data), "hash": hash})
}

func receiveHandler(w http.ResponseWriter, r *http.Request) {
	var req receiveRequest
	if !preamble(w, r, &req) {
		return
	}
	path, ok := roiPath(w)
	if !ok {
		return
	}
	text := []byte(req.RoisText)
	if len(text) == 0 || len(text) > maxRoiTextBytes || !utf8.Valid(text) {
		note(w, "stage=validate reason=empty_or_too_large_or_not_utf8 bytes=%d", len(text))
		fail(w, http.StatusBadRequest, "INVALID", "ROI 내용이 올바르지 않습니다")
		return
	}
	// 점 배열(정본)·객체 두 형식 모두 받고, 검증을 통과하면 정본 형식으로 직렬화한 바이트를 파일에 쓴다.
	normalized, problems, err := ParseAndValidate(text)
	if err != nil {
		note(w, "stage=validate reason=%s", err.Error())
		fail(w, http.StatusBadRequest, "INVALID", err.Error())
		return
	}
	if len(problems) > 0 {
		detail := make([]string, 0, len(problems))
		for _, p := range problems {
			detail = append(detail, p.String())
		}
		note(w, "stage=validate problems=%s", strings.Join(detail, ","))
		setCode(w, "INVALID")
		writeJSON(w, http.StatusBadRequest, apiError{Code: "INVALID", Msg: "ROI 검증에 실패했습니다", Detail: detail})
		return
	}
	newHash, conflict, current, err := saveReplacing(path, req.BaseHash, normalized)
	if err != nil {
		note(w, "stage=write")
		logger.Log.Error("[ROI_receive] 저장 실패", zap.Error(err))
		fail(w, http.StatusInternalServerError, "WRITE_FAILED", "ROI 파일을 저장할 수 없습니다")
		return
	}
	if conflict {
		note(w, "stage=conflict base=%s current=%s", hash8(req.BaseHash), hash8(current))
		setCode(w, "CONFLICT")
		writeJSON(w, http.StatusConflict, apiError{Code: "CONFLICT", Msg: "다른 곳에서 먼저 수정되었습니다", Current: current})
		return
	}
	// 저장한 바이트(정본 형식)의 해시를 돌려준다. 다음 ROI_get 의 해시와 같다.
	note(w, "saved bytes=%d inputBytes=%d hash=%s", len(normalized), len(text), hash8(newHash))
	writeJSON(w, http.StatusOK, map[string]interface{}{"ok": true, "hash": newHash})
}

// hash8 은 로그용 해시 앞 8자리.
func hash8(h string) string {
	if h == "" {
		return "-"
	}
	if len(h) > 8 {
		return h[:8]
	}
	return h
}

func snapshotHandler(w http.ResponseWriter, r *http.Request) {
	var req envelope
	if !preamble(w, r, &req) {
		return
	}
	select {
	case snapshotSlot <- struct{}{}:
		defer func() { <-snapshotSlot }()
	default:
		fail(w, http.StatusConflict, "BUSY", "스냅샷 요청이 이미 진행 중입니다")
		return
	}
	ctx, cancel := context.WithTimeout(r.Context(), snapshotTimeout)
	defer cancel()

	out := map[string]interface{}{"ok": true}
	for _, cam := range cameras {
		img, err := fetchSnapshot(ctx, cam)
		if err != nil {
			code, status := snapshotFailure(err)
			note(w, "camera=%s stage=snapshot", cam)
			logger.Log.Error("[ROI_snapshot] 스냅샷 획득 실패 camera="+cam+" code="+code, zap.Error(err))
			fail(w, status, code, snapshotMessage(code))
			return
		}
		note(w, "%s=%dbytes", cam, len(img))
		out[cam] = base64.StdEncoding.EncodeToString(img)
	}
	writeJSON(w, http.StatusOK, out)
}

// 스냅샷 실패 사유 code(2026-11-09). 응답은 502(설정 없음만 503)이고 code 로 원인을 구분한다.
// 응답 메시지에는 경로·내부 오류 원문을 싣지 않는다(원인은 장비 로그에만 남는다).
const (
	codeNotConfigured = "NOT_CONFIGURED"        // ROI_SNAPSHOT_URL/DIR 모두 미설정
	codeNotFound      = "SNAPSHOT_NOT_FOUND"    // 스냅샷 파일 없음(또는 소스가 404)
	codeTooLarge      = "SNAPSHOT_TOO_LARGE"    // 1장 상한(maxSnapshot) 초과
	codeFormat        = "SNAPSHOT_FORMAT"       // PNG/JPEG 가 아님(빈 파일 포함)
	codeSource        = "SNAPSHOT_SOURCE_ERROR" // URL 호출 실패·권한 오류·읽기 오류 등
)

// snapshotErr 는 사유 code 와 내부 원인(로그 전용)을 담는다.
type snapshotErr struct {
	code  string
	cause error
}

func (e *snapshotErr) Error() string { return e.code + ": " + e.cause.Error() }
func (e *snapshotErr) Unwrap() error { return e.cause }

func newSnapshotErr(code string, format string, args ...interface{}) *snapshotErr {
	return &snapshotErr{code: code, cause: fmt.Errorf(format, args...)}
}

var errSnapshotNotConfigured = &snapshotErr{code: codeNotConfigured, cause: errors.New("snapshot source not configured")}

// snapshotFailure 는 fetchSnapshot 오류를 응답 code·HTTP 상태로 바꾼다. 분류되지 않은 오류는 SNAPSHOT_SOURCE_ERROR.
func snapshotFailure(err error) (code string, status int) {
	var se *snapshotErr
	if errors.As(err, &se) {
		code = se.code
	} else {
		code = codeSource
	}
	if code == codeNotConfigured {
		return code, http.StatusServiceUnavailable
	}
	return code, http.StatusBadGateway
}

func snapshotMessage(code string) string {
	switch code {
	case codeNotConfigured:
		return "스냅샷 소스가 설정되지 않았습니다"
	case codeNotFound:
		return "스냅샷 파일이 없습니다"
	case codeTooLarge:
		return "스냅샷 파일이 너무 큽니다"
	case codeFormat:
		return "스냅샷이 PNG 또는 JPEG 형식이 아닙니다"
	default:
		return "스냅샷을 가져오지 못했습니다"
	}
}

var (
	jpegMagic = []byte{0xFF, 0xD8, 0xFF}
	pngMagic  = []byte{0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A}
)

// snapshotExts 는 ROI_SNAPSHOT_DIR 에서 카메라별 파일을 찾는 확장자 순서(PNG 우선, 없을 때만 JPG).
var snapshotExts = []string{".png", ".jpg"}

func fetchSnapshot(ctx context.Context, camera string) ([]byte, error) {
	if base := os.Getenv("ROI_SNAPSHOT_URL"); base != "" {
		u, err := url.Parse(base)
		if err != nil || (u.Scheme != "http" && u.Scheme != "https") || u.Host == "" {
			return nil, newSnapshotErr(codeSource, "ROI_SNAPSHOT_URL 이 올바르지 않습니다")
		}
		q := u.Query()
		q.Set("camera", camera)
		u.RawQuery = q.Encode()
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, u.String(), nil)
		if err != nil {
			return nil, &snapshotErr{code: codeSource, cause: err}
		}
		client := &http.Client{Timeout: snapshotTimeout, CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
		resp, err := client.Do(req)
		if err != nil {
			return nil, &snapshotErr{code: codeSource, cause: fmt.Errorf("스냅샷 소스 호출 실패: %w", err)}
		}
		defer resp.Body.Close()
		switch {
		case resp.StatusCode == http.StatusNotFound:
			return nil, newSnapshotErr(codeNotFound, "스냅샷 소스 응답 코드 404")
		case resp.StatusCode != http.StatusOK:
			return nil, newSnapshotErr(codeSource, "스냅샷 소스 응답 코드 %d", resp.StatusCode)
		}
		return readImage(resp.Body)
	}
	if dir := os.Getenv("ROI_SNAPSHOT_DIR"); dir != "" {
		f, err := openSnapshotFile(dir, camera)
		if err != nil {
			return nil, err
		}
		defer f.Close()
		return readImage(f)
	}
	return nil, errSnapshotNotConfigured
}

// openSnapshotFile 은 <camera>.png 를 먼저 열고, 파일이 없을 때만 <camera>.jpg 를 연다.
// 권한 오류 등 "없음"이 아닌 오류는 다음 확장자로 넘어가지 않고 SNAPSHOT_SOURCE_ERROR 로 반환한다.
func openSnapshotFile(dir, camera string) (*os.File, error) {
	for _, ext := range snapshotExts {
		f, err := os.Open(filepath.Join(dir, camera+ext))
		if err == nil {
			return f, nil
		}
		if !errors.Is(err, fs.ErrNotExist) {
			return nil, &snapshotErr{code: codeSource, cause: err}
		}
	}
	return nil, newSnapshotErr(codeNotFound, "스냅샷 파일이 없습니다 (%s.png, %s.jpg)", camera, camera)
}

// readImage 는 크기 상한 안에서 읽고 PNG 또는 JPEG 매직 바이트인지 확인한다(그 외 형식은 거부). 해상도는 검사하지 않는다.
func readImage(r io.Reader) ([]byte, error) {
	data, err := io.ReadAll(io.LimitReader(r, maxSnapshot+1))
	if err != nil {
		return nil, &snapshotErr{code: codeSource, cause: err}
	}
	if len(data) > maxSnapshot {
		return nil, newSnapshotErr(codeTooLarge, "스냅샷이 너무 큽니다 (상한 %d bytes)", maxSnapshot)
	}
	if !bytes.HasPrefix(data, pngMagic) && !bytes.HasPrefix(data, jpegMagic) {
		return nil, newSnapshotErr(codeFormat, "PNG/JPEG 가 아닙니다 (%d bytes)", len(data))
	}
	return data, nil
}
