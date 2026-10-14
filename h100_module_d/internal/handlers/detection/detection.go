// Package detection captures a camera frame on an authenticated operator request.
// This is a manual capture trigger; it does not run an AI detector.
package detection

import (
	"bytes"
	"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"crypto/tls"
	"crypto/x509"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"regexp"
	"strings"
	"time"
)

var requestIDPattern = regexp.MustCompile(`^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$`)
var captureSlot = make(chan struct{}, 1)

const maxImage = 8 << 20

type Request struct {
	RequestID string `json:"request_id"`
	Serial    string `json:"serial"`
}
type Capture struct {
	RequestID  string `json:"request_id"`
	Serial     string `json:"serial"`
	CapturedAt string `json:"captured_at"`
	Image      []byte `json:"image"`
}

// boundedBuffer prevents an unexpected camera stream from consuming unlimited memory.
type boundedBuffer struct{ bytes.Buffer }

func (b *boundedBuffer) Write(p []byte) (int, error) {
	if b.Len()+len(p) > maxImage {
		return 0, fmt.Errorf("capture exceeds size limit")
	}
	return b.Buffer.Write(p)
}

func encryptImage(image, key []byte) ([]byte, error) {
	if len(key) != 32 {
		return nil, fmt.Errorf("AES-256 key required")
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}
	padding := aes.BlockSize - len(image)%aes.BlockSize
	plain := append(append([]byte{}, image...), bytes.Repeat([]byte{byte(padding)}, padding)...)
	result := make([]byte, aes.BlockSize+len(plain))
	if _, err = rand.Read(result[:aes.BlockSize]); err != nil {
		return nil, err
	}
	cipher.NewCBCEncrypter(block, result[:aes.BlockSize]).CryptBlocks(result[aes.BlockSize:], plain)
	return result, nil
}

func Handler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", 405)
		return
	}
	token := os.Getenv("H100_TRIGGER_TOKEN")
	if token == "" || subtle.ConstantTimeCompare([]byte(r.Header.Get("Authorization")), []byte("Bearer "+token)) != 1 {
		http.Error(w, "Unauthorized", 401)
		return
	}
	var request Request
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 2048)).Decode(&request); err != nil || !requestIDPattern.MatchString(request.RequestID) || request.Serial != os.Getenv("DEVICE_SERIAL") || request.Serial == "" {
		http.Error(w, "Invalid capture request", 400)
		return
	}
	select {
	case captureSlot <- struct{}{}:
		defer func() { <-captureSlot }()
	default:
		http.Error(w, "Camera capture already in progress", 409)
		return
	}
	rtsp, err := url.Parse(os.Getenv("RTSP_URL"))
	if err != nil || (rtsp.Scheme != "rtsp" && rtsp.Scheme != "rtsps") || rtsp.Host == "" {
		http.Error(w, "Camera is not configured", 503)
		return
	}
	key, err := hex.DecodeString(os.Getenv("H100_AES_KEY"))
	if err != nil || len(key) != 32 {
		http.Error(w, "Capture encryption is not configured", 503)
		return
	}
	hmacKey, err := hex.DecodeString(os.Getenv("DEVICE_HMAC_KEY"))
	if err != nil || len(hmacKey) != 32 {
		http.Error(w, "Device authentication is not configured", 503)
		return
	}
	ca, err := os.ReadFile(os.Getenv("CA_CERT_FILE"))
	if err != nil {
		http.Error(w, "Cloud trust is not configured", 503)
		return
	}
	pool := x509.NewCertPool()
	if !pool.AppendCertsFromPEM(ca) {
		http.Error(w, "Cloud trust is invalid", 503)
		return
	}
	ctx, cancel := context.WithTimeout(r.Context(), 15*time.Second)
	defer cancel()
	ffmpeg := os.Getenv("FFMPEG_PATH")
	if ffmpeg == "" {
		ffmpeg = "ffmpeg"
	}
	cmd := exec.CommandContext(ctx, ffmpeg, "-nostdin", "-hide_banner", "-loglevel", "error", "-rtsp_transport", "tcp", "-i", rtsp.String(), "-frames:v", "1", "-an", "-f", "image2pipe", "-vcodec", "png", "pipe:1")
	var frame boundedBuffer
	cmd.Stdout = &frame
	// Do not log FFmpeg arguments/stderr: RTSP URLs may contain camera credentials.
	if err := cmd.Run(); err != nil || !bytes.HasPrefix(frame.Bytes(), []byte("\x89PNG\r\n\x1a\n")) {
		http.Error(w, "Camera capture failed", 502)
		return
	}
	encrypted, err := encryptImage(frame.Bytes(), key)
	if err != nil {
		http.Error(w, "Capture encryption failed", 500)
		return
	}
	body, err := json.Marshal(Capture{request.RequestID, request.Serial, time.Now().Format(time.RFC3339), encrypted})
	if err != nil {
		http.Error(w, "Capture encoding failed", 500)
		return
	}
	mac := hmac.New(sha256.New, hmacKey)
	mac.Write([]byte(request.Serial))
	mac.Write(body)
	target := "https://" + os.Getenv("CLOUD_RECEIVE_IP") + "/detectionCapture"
	outgoing, err := http.NewRequestWithContext(r.Context(), http.MethodPost, target, bytes.NewReader(body))
	if err != nil {
		http.Error(w, "Cloud address is invalid", 503)
		return
	}
	outgoing.Header.Set("Content-Type", "application/json")
	outgoing.Header.Set("X-Device-Serial", request.Serial)
	outgoing.Header.Set("X-Device-HMAC", hex.EncodeToString(mac.Sum(nil)))
	transport := &http.Transport{TLSClientConfig: &tls.Config{RootCAs: pool, MinVersion: tls.VersionTLS12}}
	defer transport.CloseIdleConnections()
	client := &http.Client{Timeout: 15 * time.Second, Transport: transport, CheckRedirect: func(_ *http.Request, _ []*http.Request) error { return http.ErrUseLastResponse }}
	response, err := client.Do(outgoing)
	if err != nil {
		http.Error(w, "Cloud upload failed", 502)
		return
	}
	defer response.Body.Close()
	data, err := io.ReadAll(io.LimitReader(response.Body, 4097))
	var receipt struct {
		OK        bool   `json:"ok"`
		RequestID string `json:"request_id"`
		EventID   uint   `json:"event_id"`
		File      string `json:"file"`
		Bytes     int    `json:"bytes"`
	}
	// A retry can return the first successful capture's size; the cloud request ID is authoritative.
	if err != nil || len(data) > 4096 || response.StatusCode != 200 || json.Unmarshal(data, &receipt) != nil || !receipt.OK || receipt.RequestID != request.RequestID || receipt.EventID == 0 || receipt.Bytes <= 16 || !strings.HasSuffix(receipt.File, ".png.enc") {
		http.Error(w, "Cloud did not confirm storage", 502)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(data)
}
