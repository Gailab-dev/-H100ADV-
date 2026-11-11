package roi

import (
	"fmt"
	"net"
	"net/http"
	"strings"
	"time"

	"go.uber.org/zap"

	"local.dev/h100_module_c/logger"
)

// ROI 요청 추적 로그(2026-11-11, 계획서 WP-S1).
// ROI_get / ROI_snapshot / ROI_send 모든 요청에 한 줄 요약을 남긴다: 요청 종류, serial, 결과 상태·code, 소요 시간, 단계·부가 정보.
// 성공(2xx)은 Info, 클라이언트 오류(4xx)는 Warn, 서버 오류(5xx)는 Error. Bearer 토큰·HMAC 키·이미지 바이트·ROI 본문은 남기지 않는다.

type recorder struct {
	http.ResponseWriter
	status int
	code   string
	serial string
	extra  []string
}

func (r *recorder) WriteHeader(status int) {
	if r.status == 0 {
		r.status = status
	}
	r.ResponseWriter.WriteHeader(status)
}

func (r *recorder) Write(b []byte) (int, error) {
	if r.status == 0 {
		r.status = http.StatusOK
	}
	return r.ResponseWriter.Write(b)
}

// note 는 요약 로그에 덧붙일 "key=value" 정보를 기록한다. w 가 recorder 가 아니면 무시한다.
func note(w http.ResponseWriter, format string, args ...interface{}) {
	if r, ok := w.(*recorder); ok {
		r.extra = append(r.extra, fmt.Sprintf(format, args...))
	}
}

func setCode(w http.ResponseWriter, code string) {
	if r, ok := w.(*recorder); ok {
		r.code = code
	}
}

// setSerial 은 요청 본문을 읽은 뒤 요약 로그에 쓸 serial 을 기록한다(13자리 숫자만 — 아니면 "-").
func setSerial(w http.ResponseWriter, serial string) {
	if r, ok := w.(*recorder); ok && serialPattern.MatchString(serial) {
		r.serial = serial
	}
}

func withSummary(name string, h http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &recorder{ResponseWriter: w}
		defer func() {
			if p := recover(); p != nil {
				logger.Log.Error("["+name+"] 처리 중 패닉", zap.Any("panic", p))
				if rec.status == 0 {
					fail(rec, http.StatusInternalServerError, "INTERNAL", "내부 오류가 발생했습니다")
				}
			}
			logSummary(name, r, rec, time.Since(start))
		}()
		h(rec, r)
	}
}

func logSummary(name string, r *http.Request, rec *recorder, took time.Duration) {
	status := rec.status
	if status == 0 {
		status = http.StatusOK
	}
	code := rec.code
	if code == "" {
		code = "OK"
	}
	serial := rec.serial
	if serial == "" {
		serial = "-"
	}
	msg := fmt.Sprintf("[%s] 요청 처리 serial=%s remote=%s status=%d code=%s took=%dms", name, serial, remoteHost(r), status, code, took.Milliseconds())
	if len(rec.extra) > 0 {
		msg += " " + strings.Join(rec.extra, " ")
	}
	switch {
	case status >= 500:
		logger.Log.Error(msg)
	case status >= 400:
		logger.Log.Warn(msg)
	default:
		logger.Log.Info(msg)
	}
}

func remoteHost(r *http.Request) string {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return "-"
	}
	return host
}
