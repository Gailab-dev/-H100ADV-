package roi

import (
	"bytes"
	"context"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"strings"
	"time"

	"local.dev/h100_module_c/internal/auth"
)

// module_c -> module_d 타임아웃. Java(13초)·웹 팝업(15초)보다 짧아야 순서가 맞는다. 테스트에서 줄여 쓰므로 var.
var deviceTimeout = 12 * time.Second

const maxDeviceResult = 24 << 20 // 스냅샷 2장(base64) 응답 상한

type relayErrorKind int

const (
	relayOK relayErrorKind = iota
	relayNotConfigured
	relayTimeout
	relayUnreachable
)

type relayError struct {
	kind relayErrorKind
	err  error
}

func (e *relayError) Error() string { return e.err.Error() }

// deviceTLSConfig 는 디바이스 서버 인증서를 내부 CA(CA_CERT_FILE)로 검증한다. CA 가 없으면 연결하지 않는다(fail-closed).
// H100_DEVICE_TLS_HOSTNAME_CHECK=false 이면 호스트명(IP SAN) 검증만 생략하고 인증서 체인 검증은 유지한다
// (디바이스 인증서에 IP SAN 이 없는 현재 상황용 임시 설정 — 웹(Java)의 기존 임시 조치와 같은 수준).
func deviceTLSConfig() (*tls.Config, error) {
	caPath := os.Getenv("CA_CERT_FILE")
	if caPath == "" {
		return nil, errors.New("CA_CERT_FILE 미설정")
	}
	pem, err := os.ReadFile(caPath)
	if err != nil {
		return nil, errors.New("CA 인증서를 읽을 수 없음")
	}
	pool := x509.NewCertPool()
	if !pool.AppendCertsFromPEM(pem) {
		return nil, errors.New("CA 인증서 형식 오류")
	}
	cfg := &tls.Config{RootCAs: pool, MinVersion: tls.VersionTLS12}
	if strings.EqualFold(os.Getenv("H100_DEVICE_TLS_HOSTNAME_CHECK"), "false") {
		cfg.InsecureSkipVerify = true // 아래 VerifyConnection 이 체인을 직접 검증한다
		cfg.VerifyConnection = func(cs tls.ConnectionState) error {
			if len(cs.PeerCertificates) == 0 {
				return errors.New("서버 인증서 없음")
			}
			opts := x509.VerifyOptions{Roots: pool, Intermediates: x509.NewCertPool()}
			for _, c := range cs.PeerCertificates[1:] {
				opts.Intermediates.AddCert(c)
			}
			_, err := cs.PeerCertificates[0].Verify(opts)
			return err
		}
	}
	return cfg, nil
}

// callDevice 는 디바이스(module_d)의 path 로 서명된 POST 를 보내고 상태코드와 본문을 돌려준다.
func callDevice(ctx context.Context, hostPort, path, serial string, payload map[string]interface{}) (int, []byte, error) {
	cfg, err := deviceTLSConfig()
	if err != nil {
		return 0, nil, &relayError{relayNotConfigured, err}
	}
	payload["serial"] = serial
	payload["ts"] = time.Now().Format(time.RFC3339)
	body, err := json.Marshal(payload)
	if err != nil {
		return 0, nil, err
	}
	mac, ok := auth.Sign(serial, body)
	if !ok {
		return 0, nil, &relayError{relayNotConfigured, errors.New("디바이스 서명 키 미등록")}
	}
	ctx, cancel := context.WithTimeout(ctx, deviceTimeout)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, "https://"+hostPort+path, bytes.NewReader(body))
	if err != nil {
		return 0, nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Device-Serial", serial)
	req.Header.Set("X-Device-HMAC", mac)

	transport := &http.Transport{TLSClientConfig: cfg, DisableKeepAlives: true}
	defer transport.CloseIdleConnections()
	client := &http.Client{Transport: transport, CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	resp, err := client.Do(req)
	if err != nil {
		var ne net.Error
		if errors.Is(err, context.DeadlineExceeded) || (errors.As(err, &ne) && ne.Timeout()) {
			return 0, nil, &relayError{relayTimeout, err}
		}
		return 0, nil, &relayError{relayUnreachable, err}
	}
	defer resp.Body.Close()
	data, err := io.ReadAll(io.LimitReader(resp.Body, maxDeviceResult+1))
	if err != nil {
		var ne net.Error
		if errors.Is(err, context.DeadlineExceeded) || (errors.As(err, &ne) && ne.Timeout()) {
			return 0, nil, &relayError{relayTimeout, err}
		}
		return 0, nil, &relayError{relayUnreachable, err}
	}
	if len(data) > maxDeviceResult {
		return 0, nil, fmt.Errorf("디바이스 응답이 너무 큽니다")
	}
	return resp.StatusCode, data, nil
}
