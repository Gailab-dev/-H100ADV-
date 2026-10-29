package roi

import (
	"bytes"
	"crypto/rand"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/jpeg"
	"image/png"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"go.uber.org/zap"

	"local.dev/h100_module_c/logger"
)

const (
	snapshotWidth  = 1920
	snapshotHeight = 1080
)

type serialRequest struct {
	Serial string `json:"serial"`
}

type snapshotRequest struct {
	Serial  string `json:"serial"`
	Account string `json:"account"`
}

type sendRequest struct {
	Serial   string `json:"serial"`
	BaseHash string `json:"baseHash"`
	RoisText string `json:"roisText"`
}

// relayFailure 는 중계 실패를 웹이 구분할 수 있는 코드로 응답한다. 디바이스 주소·오류 원문은 노출하지 않는다.
func relayFailure(w http.ResponseWriter, name string, err error) {
	var re *relayError
	if errors.As(err, &re) {
		switch re.kind {
		case relayTimeout:
			logger.Log.Warn("[" + name + "] 디바이스 응답 시간 초과")
			fail(w, http.StatusGatewayTimeout, "TIMEOUT", "장비 응답 시간이 초과되었습니다")
			return
		case relayUnreachable:
			logger.Log.Warn("["+name+"] 디바이스 연결 실패", zap.Error(re.err))
			fail(w, http.StatusServiceUnavailable, "UNREACHABLE", "장비와 통신할 수 없습니다")
			return
		case relayNotConfigured:
			logger.Log.Error("["+name+"] 중계 설정 오류", zap.Error(re.err))
			fail(w, http.StatusServiceUnavailable, "NOT_CONFIGURED", "장비 연동 설정이 올바르지 않습니다")
			return
		}
	}
	logger.Log.Error("["+name+"] 중계 실패", zap.Error(err))
	fail(w, http.StatusBadGateway, "DEVICE_ERROR", "장비가 요청을 처리하지 못했습니다")
}

// passThrough 는 디바이스가 의미 있는 코드(400/409/422/503 등)로 답한 경우 본문을 그대로 전달하고,
// 인증 실패·서버 오류 같은 나머지는 일반 오류로 바꾼다.
func passThrough(w http.ResponseWriter, name string, status int, body []byte) {
	switch status {
	case http.StatusOK, http.StatusBadRequest, http.StatusConflict, http.StatusUnprocessableEntity:
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		w.Header().Set("Cache-Control", "no-store")
		w.WriteHeader(status)
		w.Write(body)
	default:
		logger.Log.Warn(fmt.Sprintf("[%s] 디바이스 응답 코드 %d", name, status))
		fail(w, http.StatusBadGateway, "DEVICE_ERROR", "장비가 요청을 처리하지 못했습니다")
	}
}

// Get 은 ROI_get — 디바이스의 현재 ROI 파일 내용과 해시.
func Get(w http.ResponseWriter, r *http.Request) {
	var req serialRequest
	if !decodeRequest(w, r, &req) {
		return
	}
	host, ok := resolveDevice(w, req.Serial)
	if !ok {
		return
	}
	status, body, err := callDevice(r.Context(), host, "/ROI_get", req.Serial, map[string]interface{}{})
	if err != nil {
		relayFailure(w, "ROI_get", err)
		return
	}
	passThrough(w, "ROI_get", status, body)
}

// Send 는 ROI_send — baseHash 와 함께 새 ROI 를 디바이스에 적용한다.
func Send(w http.ResponseWriter, r *http.Request) {
	var req sendRequest
	if !decodeRequest(w, r, &req) {
		return
	}
	if req.RoisText == "" {
		fail(w, http.StatusBadRequest, "BAD_REQUEST", "ROI 내용이 없습니다")
		return
	}
	host, ok := resolveDevice(w, req.Serial)
	if !ok {
		return
	}
	status, body, err := callDevice(r.Context(), host, "/ROI_receive", req.Serial,
		map[string]interface{}{"baseHash": req.BaseHash, "roisText": req.RoisText})
	if err != nil {
		relayFailure(w, "ROI_send", err)
		return
	}
	passThrough(w, "ROI_send", status, body)
}

// Snapshot 은 ROI_snapshot — Cam1/Cam2 스냅샷을 받아 서버 임시 폴더(roi/snapshot/{계정}/{serial}/)에 저장한다.
// 같은 계정·장비의 이전 파일은 덮어쓴다. 두 장 모두 PNG 또는 JPEG·1920x1080 으로 확인된 뒤에만 저장한다.
// 저장 형식은 항상 JPEG(.jpg)다 — PNG 로 받으면 JPEG 로 변환한다(Java·정리 스케줄러가 .jpg/JPEG 를 전제로 하므로).
func Snapshot(w http.ResponseWriter, r *http.Request) {
	var req snapshotRequest
	if !decodeRequest(w, r, &req) {
		return
	}
	account, err := encodeAccount(req.Account)
	if err != nil {
		fail(w, http.StatusBadRequest, "BAD_ACCOUNT", "계정 정보가 올바르지 않습니다")
		return
	}
	base := os.Getenv("FILE_UPLOAD_PATH")
	if base == "" {
		fail(w, http.StatusServiceUnavailable, "NOT_CONFIGURED", "미디어 저장 경로가 설정되지 않았습니다")
		return
	}
	host, ok := resolveDevice(w, req.Serial)
	if !ok {
		return
	}
	status, body, err := callDevice(r.Context(), host, "/ROI_snapshot", req.Serial, map[string]interface{}{})
	if err != nil {
		relayFailure(w, "ROI_snapshot", err)
		return
	}
	if status != http.StatusOK {
		passThrough(w, "ROI_snapshot", status, body)
		return
	}
	var payload map[string]json.RawMessage
	images := map[string][]byte{}
	if json.Unmarshal(body, &payload) != nil {
		fail(w, http.StatusBadGateway, "DEVICE_ERROR", "장비 응답을 해석할 수 없습니다")
		return
	}
	for _, cam := range []string{"Cam1", "Cam2"} {
		var b64 string
		if json.Unmarshal(payload[cam], &b64) != nil {
			fail(w, http.StatusBadGateway, "DEVICE_ERROR", "장비 응답을 해석할 수 없습니다")
			return
		}
		raw, decErr := base64.StdEncoding.DecodeString(b64)
		if decErr != nil {
			fail(w, http.StatusBadGateway, "DEVICE_ERROR", "장비 응답을 해석할 수 없습니다")
			return
		}
		jpg, sizeErr, decErr := normalizeSnapshot(raw)
		if decErr != nil {
			logger.Log.Warn("[ROI_snapshot] "+cam+" 스냅샷 해석 실패", zap.Error(decErr))
			fail(w, http.StatusBadGateway, "SNAPSHOT_INVALID", cam+" 스냅샷이 올바른 PNG/JPEG 가 아닙니다")
			return
		}
		if sizeErr {
			fail(w, http.StatusBadGateway, "SNAPSHOT_SIZE", fmt.Sprintf("%s 스냅샷 크기가 %dx%d 가 아닙니다", cam, snapshotWidth, snapshotHeight))
			return
		}
		images[cam] = jpg
	}
	dir := filepath.Join(base, "roi", "snapshot", account, req.Serial)
	if err := os.MkdirAll(dir, 0o750); err != nil {
		logger.Log.Error("[ROI_snapshot] 폴더 생성 실패", zap.Error(err))
		fail(w, http.StatusInternalServerError, "STORE_FAILED", "스냅샷을 저장할 수 없습니다")
		return
	}
	for _, cam := range []string{"Cam1", "Cam2"} {
		if err := writeAtomic(filepath.Join(dir, cam+".jpg"), images[cam]); err != nil {
			logger.Log.Error("[ROI_snapshot] 저장 실패", zap.Error(err))
			fail(w, http.StatusInternalServerError, "STORE_FAILED", "스냅샷을 저장할 수 없습니다")
			return
		}
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"ok": true, "width": snapshotWidth, "height": snapshotHeight, "takenAt": time.Now().Format(time.RFC3339),
	})
}

var (
	jpegMagic = []byte{0xFF, 0xD8, 0xFF}
	pngMagic  = []byte{0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A}
)

// snapshotJPEGQuality 는 PNG → JPEG 변환 품질. ROI 를 그릴 때 배경으로만 쓰이므로 육안 차이가 없는 수준이면 충분하다.
const snapshotJPEGQuality = 92

// normalizeSnapshot 은 디바이스가 보낸 이미지(PNG 또는 JPEG)를 저장용 JPEG 로 정리한다.
// 헤더로 형식·크기를 먼저 확인하고(크기가 다르면 sizeMismatch=true, 전체 디코딩은 하지 않는다),
// JPEG 는 원본을 그대로, PNG 는 JPEG 로 변환해 돌려준다. 형식이 PNG/JPEG 가 아니면 err.
func normalizeSnapshot(raw []byte) (out []byte, sizeMismatch bool, err error) {
	switch {
	case bytes.HasPrefix(raw, jpegMagic):
		cfg, e := jpeg.DecodeConfig(bytes.NewReader(raw))
		if e != nil {
			return nil, false, e
		}
		if cfg.Width != snapshotWidth || cfg.Height != snapshotHeight {
			return nil, true, nil
		}
		return raw, false, nil
	case bytes.HasPrefix(raw, pngMagic):
		cfg, e := png.DecodeConfig(bytes.NewReader(raw))
		if e != nil {
			return nil, false, e
		}
		if cfg.Width != snapshotWidth || cfg.Height != snapshotHeight {
			return nil, true, nil
		}
		img, e := png.Decode(bytes.NewReader(raw))
		if e != nil {
			return nil, false, e
		}
		// JPEG 는 투명도가 없으므로 흰 바탕 위에 합성한다.
		rgba := image.NewRGBA(img.Bounds())
		draw.Draw(rgba, rgba.Bounds(), image.NewUniform(color.White), image.Point{}, draw.Src)
		draw.Draw(rgba, rgba.Bounds(), img, img.Bounds().Min, draw.Over)
		var buf bytes.Buffer
		if e := jpeg.Encode(&buf, rgba, &jpeg.Options{Quality: snapshotJPEGQuality}); e != nil {
			return nil, false, e
		}
		return buf.Bytes(), false, nil
	default:
		return nil, false, errors.New("PNG/JPEG 형식이 아닙니다")
	}
}

// writeAtomic 은 임시 파일에 쓰고 fsync 후 rename 한다(읽는 쪽이 반쯤 쓰인 파일을 보지 않도록).
func writeAtomic(path string, data []byte) error {
	suffix := make([]byte, 6)
	if _, err := rand.Read(suffix); err != nil {
		return err
	}
	tmp := filepath.Join(filepath.Dir(path), "."+filepath.Base(path)+".tmp-"+hex.EncodeToString(suffix))
	f, err := os.OpenFile(tmp, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o640)
	if err != nil {
		return err
	}
	if _, err := f.Write(data); err != nil {
		f.Close()
		os.Remove(tmp)
		return err
	}
	if err := f.Sync(); err != nil {
		f.Close()
		os.Remove(tmp)
		return err
	}
	if err := f.Close(); err != nil {
		os.Remove(tmp)
		return err
	}
	if err := os.Rename(tmp, path); err != nil {
		os.Remove(tmp)
		return err
	}
	return nil
}
