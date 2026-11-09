package roi

import (
	"fmt"
	"net"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"time"

	"go.uber.org/zap"

	"local.dev/h100_module_d/logger"
)

// ROI 요청 추적용 로그(2026-11-09 패치).
//   - 모든 ROI 요청(ROI_get / ROI_receive / ROI_snapshot)에 한 줄 요약을 남긴다:
//     요청 종류, 요청자 시리얼(헤더), 상태·결과 code, 소요 시간, 단계별 부가 정보.
//   - 성공(2xx)은 Info, 클라이언트 오류(4xx)는 Warn, 서버 오류(5xx)는 Error 로 남기고 정확한 사유(code·단계)를 적는다.
//   - HMAC 키·토큰·이미지 바이트·ROI 좌표 전체는 남기지 않는다(도형 개수, 해시 앞 8자리 정도만).

// recorder 는 응답 상태와 결과 code 를 가로채 한 줄 요약 로그에 쓴다.
type recorder struct {
	http.ResponseWriter
	status int
	code   string
	extra  []string // "key=value" 형태의 부가 정보(비밀 아님)
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

// note 는 요약 로그에 덧붙일 정보를 기록한다. w 가 recorder 가 아니면 무시한다.
func note(w http.ResponseWriter, format string, args ...interface{}) {
	if r, ok := w.(*recorder); ok {
		r.extra = append(r.extra, fmt.Sprintf(format, args...))
	}
}

// setCode 는 실패/성공 결과 code 를 기록한다. w 가 recorder 가 아니면 무시한다.
func setCode(w http.ResponseWriter, code string) {
	if r, ok := w.(*recorder); ok {
		r.code = code
	}
}

// withSummary 는 handler 를 감싸 요청마다 한 줄 요약 로그를 남긴다.
func withSummary(name string, h http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &recorder{ResponseWriter: w}
		defer func() {
			if p := recover(); p != nil {
				logger.Log.Error(fmt.Sprintf("[%s] 처리 중 패닉 serial=%s", name, headerSerialForLog(r)), zap.Any("panic", p))
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
	msg := fmt.Sprintf("[%s] 요청 처리 serial=%s remote=%s status=%d code=%s took=%dms", name, headerSerialForLog(r), remoteHost(r), status, code, took.Milliseconds())
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

// headerSerialForLog 는 X-Device-Serial 헤더를 로그용으로 정리한다(영숫자·.-_ 만, 최대 32자 — 로그 줄 위조 방지).
func headerSerialForLog(r *http.Request) string {
	s := r.Header.Get(headerSerial)
	if s == "" {
		return "-"
	}
	var b strings.Builder
	for _, c := range s {
		if (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c == '.' || c == '-' || c == '_' {
			b.WriteRune(c)
		} else {
			b.WriteRune('?')
		}
		if b.Len() >= 32 {
			break
		}
	}
	return b.String()
}

func remoteHost(r *http.Request) string {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return "-"
	}
	return host
}

// LogStartupConfig 는 ROI 관련 설정의 설정 여부·경로·파일 존재 여부를 기동 시 한 번 Info 로 남긴다(2026-11-09).
// 값 자체가 비밀인 항목(HMAC 키)은 "설정됨/없음" 만 적고, 스냅샷 URL 은 호스트·포트만 적는다.
// 서비스가 .env 를 읽는 방식이라 `systemctl cat` 으로는 환경변수가 보이지 않으므로, 이 로그로 실제 적용값을 확인한다.
func LogStartupConfig() {
	cwd, _ := os.Getwd()
	logger.Log.Info(fmt.Sprintf("[ROI_config] 작업 폴더=%s pid=%d", cwd, os.Getpid()))

	serialSet := os.Getenv("DEVICE_SERIAL") != ""
	_, hmacErr := hmacKeyFromEnv()
	logger.Log.Info(fmt.Sprintf("[ROI_config] DEVICE_SERIAL=%s DEVICE_HMAC_KEY=%s", setOrNot(serialSet), hmacState(hmacErr)))

	if writeNormalized() {
		logger.Log.Info("[ROI_config] ROI_WRITE_NORMALIZED=기본(정본 형식 점 배열로 기록)")
	} else {
		logger.Log.Warn("[ROI_config] ROI_WRITE_NORMALIZED=false — 입력 원문을 그대로 기록합니다(전환기 설정, 웹이 정본 형식으로 바뀌면 제거)")
	}

	if p := os.Getenv("ROI_FILE_PATH"); p == "" {
		logger.Log.Warn("[ROI_config] ROI_FILE_PATH 미설정 — ROI_get/ROI_receive 는 NOT_CONFIGURED(503) 로 응답합니다")
	} else {
		logger.Log.Info(fmt.Sprintf("[ROI_config] ROI_FILE_PATH=%s %s", p, fileState(p)))
	}

	switch u, d := os.Getenv("ROI_SNAPSHOT_URL"), os.Getenv("ROI_SNAPSHOT_DIR"); {
	case u != "":
		logger.Log.Info(fmt.Sprintf("[ROI_config] ROI_SNAPSHOT_URL=%s (URL 이 DIR 보다 우선)", urlHostForLog(u)))
		if d != "" {
			logger.Log.Info(fmt.Sprintf("[ROI_config] ROI_SNAPSHOT_DIR=%s (URL 이 설정되어 사용되지 않음)", d))
		}
	case d != "":
		logger.Log.Info(fmt.Sprintf("[ROI_config] ROI_SNAPSHOT_DIR=%s", d))
		for _, cam := range cameras {
			logger.Log.Info(fmt.Sprintf("[ROI_config]   %s 스냅샷: %s", cam, snapshotFileState(d, cam)))
		}
	default:
		logger.Log.Warn("[ROI_config] ROI_SNAPSHOT_URL / ROI_SNAPSHOT_DIR 모두 미설정 — ROI_snapshot 은 NOT_CONFIGURED(503) 로 응답합니다")
	}
}

func setOrNot(b bool) string {
	if b {
		return "설정됨"
	}
	return "없음"
}

func hmacState(err error) string {
	if err == nil {
		return "설정됨(형식 정상)"
	}
	return "없음 또는 형식 오류(64자리 16진수 필요)"
}

func fileState(p string) string {
	st, err := os.Stat(p)
	switch {
	case err == nil:
		return fmt.Sprintf("(존재, %d bytes, 권한 %v)", st.Size(), st.Mode().Perm())
	case os.IsNotExist(err):
		return "(파일 없음 — ROI_get 은 exists=false 로 응답)"
	default:
		return "(확인 실패: " + err.Error() + ")"
	}
}

func snapshotFileState(dir, cam string) string {
	for _, ext := range snapshotExts {
		p := filepath.Join(dir, cam+ext)
		if st, err := os.Stat(p); err == nil {
			return fmt.Sprintf("%s%s 존재 (%d bytes)", cam, ext, st.Size())
		}
	}
	return fmt.Sprintf("%s.png/%s.jpg 없음", cam, cam)
}

// urlHostForLog 는 스냅샷 URL 의 호스트:포트만 돌려준다(경로·쿼리·계정 정보는 남기지 않는다).
func urlHostForLog(raw string) string {
	u, err := url.Parse(raw)
	if err != nil || u.Host == "" {
		return "(올바르지 않은 URL)"
	}
	return u.Scheme + "://" + u.Host
}
