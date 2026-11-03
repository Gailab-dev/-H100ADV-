package video

import (
	"net/url"
	"os"
	"regexp"
	"strings"
	"sync"
	"time"

	"go.uber.org/zap"

	"local.dev/h100_module_d/logger"
)

// ffmpeg 표준 에러 처리(38번 WP-1 6번).
//
//  - 이전에는 ffmpeg 의 stderr 를 그대로 os.Stderr 로 흘려 module_d.log 에 남겼다. ffmpeg 는 시작 시
//    입력 주소(rtsp://계정:비밀번호@...)를 그대로 출력할 수 있으므로, 모든 줄에서 비밀을 가린 뒤에만 기록한다.
//  - 진행 상태 줄(frame= fps= ... speed= dup= drop=)은 모두 남기지 않고 일정 간격으로 요약해 남긴다
//    (측정 절차 WP-M M-2: speed < 1.0x 지속 / drop 증가 여부 확인용).

var (
	// scheme://userinfo@ 형태의 자격 증명 일반 마스킹
	reURLUserInfo = regexp.MustCompile(`([A-Za-z][A-Za-z0-9+.\-]*://)[^/\s@'"]+@`)

	reFrame   = regexp.MustCompile(`frame=\s*(\d+)`)
	reFPS     = regexp.MustCompile(`fps=\s*([0-9.]+)`)
	reSpeed   = regexp.MustCompile(`speed=\s*([0-9.]+)x`)
	reDup     = regexp.MustCompile(`dup=\s*(\d+)`)
	reDrop    = regexp.MustCompile(`drop=\s*(\d+)`)
	reBitrate = regexp.MustCompile(`bitrate=\s*(\S+)`)
)

// redactSecrets: 로그에 남기기 전에 RTSP 계정·비밀번호를 가린다.
func redactSecrets(s string) string {
	s = reURLUserInfo.ReplaceAllString(s, "${1}***@")
	// .env 의 RTSP_URL 에서 계정/비밀번호를 뽑아 문자열 그대로 나타나는 곳도 가린다.
	if raw := os.Getenv("RTSP_URL"); raw != "" {
		if u, err := url.Parse(raw); err == nil && u.User != nil {
			if name := u.User.Username(); len(name) >= 3 {
				s = strings.ReplaceAll(s, name, "***")
			}
			if pw, ok := u.User.Password(); ok && len(pw) >= 3 {
				s = strings.ReplaceAll(s, pw, "***")
				s = strings.ReplaceAll(s, url.QueryEscape(pw), "***")
			}
		}
	}
	return s
}

// ffStats: ffmpeg 진행 상태의 마지막 값.
type ffStats struct {
	Frame, FPS, Speed, Dup, Drop, Bitrate string
}

func (s ffStats) fields() []zap.Field {
	return []zap.Field{
		zap.String("frame", s.Frame), zap.String("fps", s.FPS), zap.String("speed", s.Speed),
		zap.String("dup", s.Dup), zap.String("drop", s.Drop), zap.String("bitrate", s.Bitrate),
	}
}

// ffLogWriter: cmd.Stderr 로 연결하는 io.Writer. '\r' 또는 '\n' 으로 줄을 나눠 처리한다.
type ffLogWriter struct {
	streamID string
	every    time.Duration // 진행 상태 요약 로그 간격(0 이면 남기지 않음)

	mu       sync.Mutex
	buf      []byte
	last     ffStats
	hasStats bool
	lastLog  time.Time
	infoCnt  int      // 일반 줄 기록 수(상한 적용)
	warnCnt  int      // 오류성 줄 기록 수(상한 적용)
	tail     []string // 최근 일반 줄(종료 진단용, 비밀 제거본)
}

const (
	ffMaxInfoLines = 60  // 실행 1회당 남길 일반 줄(배너·스트림 정보)
	ffMaxWarnLines = 200 // 실행 1회당 남길 오류성 줄
	ffTailLines    = 8
	ffMaxPartial   = 64 << 10
)

func newFFLogWriter(streamID string, every time.Duration) *ffLogWriter {
	return &ffLogWriter{streamID: streamID, every: every}
}

func (w *ffLogWriter) Write(p []byte) (int, error) {
	w.mu.Lock()
	defer w.mu.Unlock()
	w.buf = append(w.buf, p...)
	for {
		i := -1
		for k, c := range w.buf {
			if c == '\r' || c == '\n' {
				i = k
				break
			}
		}
		if i < 0 {
			if len(w.buf) > ffMaxPartial {
				w.buf = w.buf[:0] // 줄바꿈 없는 비정상 출력은 버린다
			}
			break
		}
		line := strings.TrimSpace(string(w.buf[:i]))
		w.buf = w.buf[i+1:]
		if line != "" {
			w.handleLine(line)
		}
	}
	return len(p), nil
}

func (w *ffLogWriter) handleLine(line string) {
	if strings.Contains(line, "fps=") && strings.Contains(line, "speed=") {
		st := ffStats{
			Frame: find1(reFrame, line), FPS: find1(reFPS, line), Speed: find1(reSpeed, line),
			Dup: find1(reDup, line), Drop: find1(reDrop, line), Bitrate: find1(reBitrate, line),
		}
		w.last, w.hasStats = st, true
		if w.every > 0 && time.Since(w.lastLog) >= w.every {
			w.lastLog = time.Now()
			logger.Log.Info("ffmpeg 진행 상태", append([]zap.Field{zap.String("stream", w.streamID)}, st.fields()...)...)
		}
		return
	}

	safe := redactSecrets(line)
	w.tail = append(w.tail, safe)
	if len(w.tail) > ffTailLines {
		w.tail = w.tail[len(w.tail)-ffTailLines:]
	}
	lower := strings.ToLower(safe)
	if strings.Contains(lower, "error") || strings.Contains(lower, "fail") || strings.Contains(lower, "invalid") ||
		strings.Contains(lower, "timed out") || strings.Contains(lower, "timeout") || strings.Contains(lower, "refused") ||
		strings.Contains(lower, "unauthorized") || strings.Contains(lower, "not found") {
		if w.warnCnt < ffMaxWarnLines {
			w.warnCnt++
			logger.Log.Warn("ffmpeg: "+safe, zap.String("stream", w.streamID))
		}
		return
	}
	if w.infoCnt < ffMaxInfoLines {
		w.infoCnt++
		logger.Log.Info("ffmpeg: "+safe, zap.String("stream", w.streamID))
	}
}

// snapshot: 마지막 진행 상태와 최근 줄을 복사해 돌려준다.
func (w *ffLogWriter) snapshot() (ffStats, bool, []string) {
	w.mu.Lock()
	defer w.mu.Unlock()
	tail := make([]string, len(w.tail))
	copy(tail, w.tail)
	return w.last, w.hasStats, tail
}

func find1(re *regexp.Regexp, s string) string {
	m := re.FindStringSubmatch(s)
	if len(m) < 2 {
		return "-"
	}
	return m[1]
}
