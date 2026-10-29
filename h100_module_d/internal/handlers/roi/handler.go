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
	"time"
	"unicode/utf8"

	"go.uber.org/zap"

	"local.dev/h100_module_d/logger"
)

const (
	maxRequestBody  = 1 << 20 // 요청 본문 1MB (ROI JSON 은 보통 수 KB)
	maxRoiTextBytes = 512 << 10
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
		fail(w, status, "UNAUTHORIZED", msg)
		return false
	}
	if err := json.Unmarshal(body, into); err != nil {
		fail(w, http.StatusBadRequest, "BAD_REQUEST", "요청 형식이 올바르지 않습니다")
		return false
	}
	var env envelope
	json.Unmarshal(body, &env)
	if env.Serial != os.Getenv("DEVICE_SERIAL") {
		fail(w, http.StatusUnauthorized, "UNAUTHORIZED", "인증에 실패했습니다")
		return false
	}
	if !checkFreshness(env.TS, time.Now()) {
		fail(w, http.StatusBadRequest, "STALE", "요청 시각이 올바르지 않습니다")
		return false
	}
	return true
}

func roiPath(w http.ResponseWriter) (string, bool) {
	p := os.Getenv("ROI_FILE_PATH")
	if p == "" {
		fail(w, http.StatusServiceUnavailable, "NOT_CONFIGURED", "ROI 파일 경로가 설정되지 않았습니다")
		return "", false
	}
	return p, true
}

// GetHandler 는 ROI_get.
func GetHandler(w http.ResponseWriter, r *http.Request) {
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
		logger.Log.Error("[ROI_get] 파일 읽기 실패", zap.Error(err))
		fail(w, http.StatusInternalServerError, "READ_FAILED", "ROI 파일을 읽을 수 없습니다")
		return
	}
	if len(data) > maxRoiTextBytes || !utf8.Valid(data) {
		fail(w, http.StatusUnprocessableEntity, "BAD_FILE", "ROI 파일 내용을 해석할 수 없습니다")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"ok": true, "exists": exists, "roisText": string(data), "hash": hash})
}

// ReceiveHandler 는 ROI_receive.
func ReceiveHandler(w http.ResponseWriter, r *http.Request) {
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
		fail(w, http.StatusBadRequest, "INVALID", "ROI 내용이 올바르지 않습니다")
		return
	}
	problems, err := ValidateText(text)
	if err != nil {
		fail(w, http.StatusBadRequest, "INVALID", err.Error())
		return
	}
	if len(problems) > 0 {
		detail := make([]string, 0, len(problems))
		for _, p := range problems {
			detail = append(detail, p.String())
		}
		writeJSON(w, http.StatusBadRequest, apiError{Code: "INVALID", Msg: "ROI 검증에 실패했습니다", Detail: detail})
		return
	}
	newHash, conflict, current, err := saveReplacing(path, req.BaseHash, text)
	if err != nil {
		logger.Log.Error("[ROI_receive] 저장 실패", zap.Error(err))
		fail(w, http.StatusInternalServerError, "WRITE_FAILED", "ROI 파일을 저장할 수 없습니다")
		return
	}
	if conflict {
		writeJSON(w, http.StatusConflict, apiError{Code: "CONFLICT", Msg: "다른 곳에서 먼저 수정되었습니다", Current: current})
		return
	}
	logger.Log.Info(fmt.Sprintf("[ROI_receive] 저장 완료 bytes=%d hash=%s", len(text), newHash))
	writeJSON(w, http.StatusOK, map[string]interface{}{"ok": true, "hash": newHash})
}

// SnapshotHandler 는 ROI_snapshot. 스냅샷 소스는 ROI_SNAPSHOT_URL(로컬 Python 등) 또는 ROI_SNAPSHOT_DIR(Cam1.png/Cam2.png, 없으면 .jpg).
func SnapshotHandler(w http.ResponseWriter, r *http.Request) {
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
			logger.Log.Error("[ROI_snapshot] 스냅샷 획득 실패 camera="+cam, zap.Error(err))
			if err == errSnapshotNotConfigured {
				fail(w, http.StatusServiceUnavailable, "NOT_CONFIGURED", "스냅샷 소스가 설정되지 않았습니다")
			} else {
				fail(w, http.StatusBadGateway, "SNAPSHOT_FAILED", "카메라 스냅샷을 가져오지 못했습니다")
			}
			return
		}
		out[cam] = base64.StdEncoding.EncodeToString(img)
	}
	writeJSON(w, http.StatusOK, out)
}

type snapshotError string

func (e snapshotError) Error() string { return string(e) }

const errSnapshotNotConfigured = snapshotError("snapshot source not configured")

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
			return nil, fmt.Errorf("ROI_SNAPSHOT_URL 이 올바르지 않습니다")
		}
		q := u.Query()
		q.Set("camera", camera)
		u.RawQuery = q.Encode()
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, u.String(), nil)
		if err != nil {
			return nil, err
		}
		client := &http.Client{Timeout: snapshotTimeout, CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
		resp, err := client.Do(req)
		if err != nil {
			return nil, fmt.Errorf("스냅샷 소스 호출 실패")
		}
		defer resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			return nil, fmt.Errorf("스냅샷 소스 응답 코드 %d", resp.StatusCode)
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
// 권한 오류 등 "없음"이 아닌 오류는 다음 확장자로 넘어가지 않고 그대로 반환한다.
func openSnapshotFile(dir, camera string) (*os.File, error) {
	for _, ext := range snapshotExts {
		f, err := os.Open(filepath.Join(dir, camera+ext))
		if err == nil {
			return f, nil
		}
		if !errors.Is(err, fs.ErrNotExist) {
			return nil, err
		}
	}
	return nil, fmt.Errorf("스냅샷 파일이 없습니다 (%s.png, %s.jpg)", camera, camera)
}

// readImage 는 크기 상한 안에서 읽고 PNG 또는 JPEG 매직 바이트인지 확인한다(그 외 형식은 거부).
func readImage(r io.Reader) ([]byte, error) {
	data, err := io.ReadAll(io.LimitReader(r, maxSnapshot+1))
	if err != nil {
		return nil, err
	}
	if len(data) > maxSnapshot {
		return nil, fmt.Errorf("스냅샷이 너무 큽니다")
	}
	if !bytes.HasPrefix(data, pngMagic) && !bytes.HasPrefix(data, jpegMagic) {
		return nil, fmt.Errorf("PNG/JPEG 가 아닙니다")
	}
	return data, nil
}
