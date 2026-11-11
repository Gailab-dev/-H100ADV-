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
	"math"
	"net/http"
	"os"
	"path/filepath"
	"strings"
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
		if status != http.StatusOK {
			var dev struct {
				Code string `json:"code"`
			}
			json.Unmarshal(body, &dev)
			setCode(w, safeCode(dev.Code))
		}
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		w.Header().Set("Cache-Control", "no-store")
		w.WriteHeader(status)
		w.Write(body)
	default:
		logger.Log.Warn(fmt.Sprintf("[%s] 디바이스 응답 코드 %d", name, status))
		note(w, "deviceStatus=%d", status)
		fail(w, http.StatusBadGateway, "DEVICE_ERROR", "장비가 요청을 처리하지 못했습니다")
	}
}

// getHandler 는 ROI_get — 디바이스의 현재 ROI 파일 내용과 해시.
func getHandler(w http.ResponseWriter, r *http.Request) {
	var req serialRequest
	if !decodeRequest(w, r, &req) {
		return
	}
	setSerial(w, req.Serial)
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

// sendHandler 는 ROI_send — baseHash 와 함께 새 ROI 를 디바이스에 적용한다.
func sendHandler(w http.ResponseWriter, r *http.Request) {
	var req sendRequest
	if !decodeRequest(w, r, &req) {
		return
	}
	setSerial(w, req.Serial)
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

// Get / Send / Snapshot 은 요청마다 한 줄 요약 로그를 남긴다(summary.go).
var (
	Get      http.HandlerFunc = withSummary("ROI_get", getHandler)
	Send     http.HandlerFunc = withSummary("ROI_send", sendHandler)
	Snapshot http.HandlerFunc = withSummary("ROI_snapshot", snapshotHandler)
)

// snapshotCodeMessages 는 장비(module_d)가 돌려주는 스냅샷 실패 code 와 화면에 보일 고정 문구다.
// 장비의 메시지·경로·내부 오류 원문은 전달하지 않고 code 만 받아 이 문구로 바꾼다.
var snapshotCodeMessages = map[string]string{
	"SNAPSHOT_NOT_FOUND":    "장비에 스냅샷 파일이 없습니다",
	"SNAPSHOT_TOO_LARGE":    "장비의 스냅샷 파일이 너무 큽니다",
	"SNAPSHOT_FORMAT":       "장비의 스냅샷이 PNG 또는 JPEG 형식이 아닙니다",
	"SNAPSHOT_SOURCE_ERROR": "장비가 스냅샷을 읽지 못했습니다",
}

// snapshotDeviceFailure 는 장비가 200 이 아닌 상태로 답했을 때 처리한다.
// 장비의 SNAPSHOT_* 502 와 스냅샷 소스 미설정(503 NOT_CONFIGURED)은 원인을 구분할 수 있게 code 를 살려 전달하고,
// 그 밖(인증 실패 등)은 기존처럼 passThrough 규칙을 따른다.
func snapshotDeviceFailure(w http.ResponseWriter, status int, body []byte) {
	var dev struct {
		Code string `json:"code"`
	}
	json.Unmarshal(body, &dev)
	note(w, "stage=device_status deviceStatus=%d deviceCode=%s", status, safeCode(dev.Code))
	if status == http.StatusBadGateway {
		if msg, ok := snapshotCodeMessages[dev.Code]; ok {
			fail(w, http.StatusBadGateway, dev.Code, msg)
			return
		}
	}
	if status == http.StatusServiceUnavailable && dev.Code == "NOT_CONFIGURED" {
		fail(w, http.StatusServiceUnavailable, "SNAPSHOT_NOT_CONFIGURED", "장비에 스냅샷 소스가 설정되어 있지 않습니다")
		return
	}
	passThrough(w, "ROI_snapshot", status, body)
}

// safeCode 는 로그에 남길 code 를 영숫자·_ 로 제한한다(장비 응답이 로그 줄을 위조하지 못하게).
func safeCode(code string) string {
	var b strings.Builder
	for _, c := range code {
		if (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_' {
			b.WriteRune(c)
		}
		if b.Len() >= 40 {
			break
		}
	}
	if b.Len() == 0 {
		return "-"
	}
	return b.String()
}

// Snapshot 은 ROI_snapshot — Cam1/Cam2 스냅샷을 받아 서버 임시 폴더(roi/snapshot/{계정}/{serial}/)에 저장한다.
// 같은 계정·장비의 이전 파일은 덮어쓴다. 두 장 모두 디코딩 가능한 PNG 또는 JPEG 로 확인된 뒤에만 저장한다.
// 크기가 1920x1080 이 아니어도 거부하지 않는다(2026-11-11): 실제 크기와 일치 여부(sizeMatches, aspectMatches)를 응답에 담아
// 화면이 경고로 알리게 한다. 저장 형식은 항상 JPEG(.jpg)다 — PNG 로 받으면 JPEG 로 변환한다(Java·정리 스케줄러 전제).
func snapshotHandler(w http.ResponseWriter, r *http.Request) {
	var req snapshotRequest
	if !decodeRequest(w, r, &req) {
		return
	}
	setSerial(w, req.Serial)
	account, err := encodeAccount(req.Account)
	if err != nil {
		note(w, "stage=request reason=bad_account")
		fail(w, http.StatusBadRequest, "BAD_ACCOUNT", "계정 정보가 올바르지 않습니다")
		return
	}
	base := os.Getenv("FILE_UPLOAD_PATH")
	if base == "" {
		note(w, "stage=config reason=FILE_UPLOAD_PATH_unset")
		fail(w, http.StatusServiceUnavailable, "NOT_CONFIGURED", "미디어 저장 경로가 설정되지 않았습니다")
		return
	}
	host, ok := resolveDevice(w, req.Serial)
	if !ok {
		return
	}
	status, body, err := callDevice(r.Context(), host, "/ROI_snapshot", req.Serial, map[string]interface{}{})
	if err != nil {
		note(w, "stage=device_call")
		relayFailure(w, "ROI_snapshot", err)
		return
	}
	note(w, "deviceStatus=%d deviceBytes=%d", status, len(body))
	if status != http.StatusOK {
		snapshotDeviceFailure(w, status, body)
		return
	}
	var payload map[string]json.RawMessage
	if json.Unmarshal(body, &payload) != nil {
		note(w, "stage=device_response reason=json_parse")
		fail(w, http.StatusBadGateway, "DEVICE_ERROR", "장비 응답을 해석할 수 없습니다")
		return
	}
	images := map[string][]byte{}
	infos := map[string]snapshotInfo{}
	for _, cam := range []string{"Cam1", "Cam2"} {
		var b64 string
		if json.Unmarshal(payload[cam], &b64) != nil {
			note(w, "stage=device_response reason=%s_missing_or_not_string", cam)
			fail(w, http.StatusBadGateway, "DEVICE_ERROR", "장비 응답을 해석할 수 없습니다")
			return
		}
		raw, decErr := base64.StdEncoding.DecodeString(b64)
		if decErr != nil {
			note(w, "stage=device_response reason=%s_base64", cam)
			fail(w, http.StatusBadGateway, "DEVICE_ERROR", "장비 응답을 해석할 수 없습니다")
			return
		}
		jpg, info, snapErr := normalizeSnapshot(raw)
		if snapErr != nil {
			note(w, "camera=%s stage=normalize rawBytes=%d reason=%s", cam, len(raw), snapErr.reason)
			logger.Log.Warn("[ROI_snapshot] "+cam+" 스냅샷 처리 실패 code="+snapErr.code, zap.Error(snapErr.cause))
			if snapErr.code == "SNAPSHOT_TOO_LARGE" {
				fail(w, http.StatusBadGateway, snapErr.code, cam+" 스냅샷 해상도가 너무 큽니다")
			} else {
				fail(w, http.StatusBadGateway, "SNAPSHOT_INVALID", cam+" 스냅샷이 올바른 PNG/JPEG 가 아닙니다")
			}
			return
		}
		note(w, "%s=%dx%d/%s/%dB", cam, info.Width, info.Height, info.Format, info.Bytes)
		images[cam] = jpg
		infos[cam] = info
	}
	sizeOK := infos["Cam1"].sizeMatches() && infos["Cam2"].sizeMatches()
	aspectOK := infos["Cam1"].aspectMatches() && infos["Cam2"].aspectMatches()
	if !sizeOK {
		note(w, "sizeMatches=false aspectMatches=%t", aspectOK)
	}
	dir := filepath.Join(base, "roi", "snapshot", account, req.Serial)
	if err := os.MkdirAll(dir, 0o750); err != nil {
		note(w, "stage=store reason=mkdir")
		logger.Log.Error("[ROI_snapshot] 폴더 생성 실패", zap.Error(err))
		fail(w, http.StatusInternalServerError, "STORE_FAILED", "스냅샷을 저장할 수 없습니다")
		return
	}
	for _, cam := range []string{"Cam1", "Cam2"} {
		if err := writeAtomic(filepath.Join(dir, cam+".jpg"), images[cam]); err != nil {
			note(w, "stage=store reason=write camera=%s", cam)
			logger.Log.Error("[ROI_snapshot] 저장 실패", zap.Error(err))
			fail(w, http.StatusInternalServerError, "STORE_FAILED", "스냅샷을 저장할 수 없습니다")
			return
		}
	}
	cams := map[string]interface{}{}
	for cam, in := range infos {
		cams[cam] = map[string]interface{}{"width": in.Width, "height": in.Height, "format": in.Format}
	}
	// width/height 는 ROI 논리 좌표계(1920x1080)다. 실제 이미지 크기는 cams 에 있다.
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"ok": true, "width": snapshotWidth, "height": snapshotHeight, "takenAt": time.Now().Format(time.RFC3339),
		"sizeMatches": sizeOK, "aspectMatches": aspectOK, "cams": cams,
	})
}

var (
	jpegMagic = []byte{0xFF, 0xD8, 0xFF}
	pngMagic  = []byte{0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A}
)

// snapshotJPEGQuality 는 PNG → JPEG 변환 품질. ROI 를 그릴 때 배경으로만 쓰이므로 육안 차이가 없는 수준이면 충분하다.
const snapshotJPEGQuality = 92

// 디코딩 전에 헤더(DecodeConfig)로 확인하는 해상도 상한. 작은 PNG 가 거대한 해상도로 메모리를 소모하지 못하게 한다.
const (
	maxSnapshotSide   = 8192
	maxSnapshotPixels = 36_000_000
)

// snapshotInfo 는 장비가 보낸 이미지의 실제 크기·형식·원본 바이트 수.
type snapshotInfo struct {
	Width, Height int
	Format        string // png | jpeg
	Bytes         int
}

// sizeMatches 는 ROI 논리 좌표계(1920x1080)와 크기가 같은지.
func (i snapshotInfo) sizeMatches() bool {
	return i.Width == snapshotWidth && i.Height == snapshotHeight
}

// aspectMatches 는 가로세로 비율이 16:9 에 1% 이내로 가까운지(다르면 ROI 좌표가 어긋나 보일 수 있다).
func (i snapshotInfo) aspectMatches() bool {
	if i.Width <= 0 || i.Height <= 0 {
		return false
	}
	ratio := float64(i.Width) / float64(i.Height)
	want := float64(snapshotWidth) / float64(snapshotHeight)
	return math.Abs(ratio-want) <= want*0.01
}

// snapshotProblem 는 스냅샷 처리 실패 사유(code)와 내부 원인(로그 전용).
type snapshotProblem struct {
	code   string // SNAPSHOT_INVALID | SNAPSHOT_TOO_LARGE
	reason string // 로그용 짧은 사유
	cause  error
}

// normalizeSnapshot 은 디바이스가 보낸 이미지(PNG 또는 JPEG)를 저장용 JPEG 로 정리한다.
// 헤더로 형식·크기를 먼저 확인하고(해상도 상한 초과는 SNAPSHOT_TOO_LARGE), JPEG 는 원본을 그대로, PNG 는 JPEG 로 변환한다.
// 크기가 1920x1080 이 아니어도 실패시키지 않고 info 로 돌려준다. 디코딩할 수 없거나 PNG/JPEG 가 아니면 SNAPSHOT_INVALID.
func normalizeSnapshot(raw []byte) (out []byte, info snapshotInfo, prob *snapshotProblem) {
	info.Bytes = len(raw)
	var cfg image.Config
	var e error
	switch {
	case bytes.HasPrefix(raw, jpegMagic):
		info.Format = "jpeg"
		cfg, e = jpeg.DecodeConfig(bytes.NewReader(raw))
	case bytes.HasPrefix(raw, pngMagic):
		info.Format = "png"
		cfg, e = png.DecodeConfig(bytes.NewReader(raw))
	default:
		return nil, info, &snapshotProblem{"SNAPSHOT_INVALID", "not_png_or_jpeg", errors.New("PNG/JPEG 형식이 아닙니다")}
	}
	if e != nil {
		return nil, info, &snapshotProblem{"SNAPSHOT_INVALID", "decode_config_failed", e}
	}
	info.Width, info.Height = cfg.Width, cfg.Height
	if cfg.Width <= 0 || cfg.Height <= 0 {
		return nil, info, &snapshotProblem{"SNAPSHOT_INVALID", "empty_dimensions", errors.New("이미지 크기가 0 입니다")}
	}
	if cfg.Width > maxSnapshotSide || cfg.Height > maxSnapshotSide || cfg.Width*cfg.Height > maxSnapshotPixels {
		return nil, info, &snapshotProblem{"SNAPSHOT_TOO_LARGE", "dimensions_over_limit", fmt.Errorf("해상도 %dx%d 가 상한을 넘습니다", cfg.Width, cfg.Height)}
	}
	if info.Format == "jpeg" {
		return raw, info, nil
	}
	img, e := png.Decode(bytes.NewReader(raw))
	if e != nil {
		return nil, info, &snapshotProblem{"SNAPSHOT_INVALID", "png_decode_failed", e}
	}
	// JPEG 는 투명도가 없으므로 흰 바탕 위에 합성한다.
	rgba := image.NewRGBA(img.Bounds())
	draw.Draw(rgba, rgba.Bounds(), image.NewUniform(color.White), image.Point{}, draw.Src)
	draw.Draw(rgba, rgba.Bounds(), img, img.Bounds().Min, draw.Over)
	var buf bytes.Buffer
	if e := jpeg.Encode(&buf, rgba, &jpeg.Options{Quality: snapshotJPEGQuality}); e != nil {
		return nil, info, &snapshotProblem{"SNAPSHOT_INVALID", "jpeg_encode_failed", e}
	}
	return buf.Bytes(), info, nil
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
