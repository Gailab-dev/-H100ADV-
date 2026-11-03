package video

import (
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"local.dev/h100_module_d/logger"
)

// ===== 실시간 영상 단일 스트림 · 단일 시청자 관리 (38번 WP-1) =====
//
//  - ffmpeg 는 한 번에 하나만 둔다(같은 HLS_DIR/index.m3u8 에 쓰므로 여러 개면 서로 덮어쓴다).
//  - 시청자는 1명. 같은 viewerId 의 start 는 인계(ffmpeg 재시작 없음), 다른 viewerId 는 409 VIEWER_BUSY.
//  - end 는 현재 시청자만 유효. end 후 종료 유예 동안 같은 시청자(또는 새 시청자)가 start 하면 종료를 취소하고 이어 쓴다.
//  - 브라우저 비정상 종료·네트워크 단절로 end 가 오지 않아도, 유휴 타임아웃 동안 .m3u8/.ts 요청이나 하트비트가
//    없으면 점유를 풀고 ffmpeg 를 종료한다.
//  - 모든 상태(현재 스트림, 시청자, 활동 시각, ffmpeg 핸들)는 mu 로 보호한다. 활동 시각만 요청 경로의
//    락 경합을 피하려고 atomic 으로 둔다.

// 코드 기본값. 아래 환경변수가 없거나 잘못되면 이 값을 쓴다(기존 장비의 .env 에 새 키가 없어도 동작해야 한다).
const (
	defaultIdleTimeoutSec = 20   // VIEWER_IDLE_TIMEOUT_SEC : 요청·하트비트 없을 때 점유 해제까지(초)
	defaultEndGraceSec    = 15   // STREAM_END_GRACE_SEC    : end 후 ffmpeg 종료까지 유예(초, 0=즉시)
	defaultStartCheckMs   = 1500 // FFMPEG_START_CHECK_MS : 시작 직후 이 시간 안에 죽으면 start 실패(밀리초, 0=검사 안 함)
	defaultStopWaitSec    = 5    // FFMPEG_STOP_WAIT_SEC    : Kill 후 종료 확인 대기(초)
	defaultStatsLogSec    = 10   // FFMPEG_STATS_LOG_SEC    : ffmpeg 진행 상태(fps/speed/dup/drop) 로그 간격(초, 0=끔)

	anonymousViewer = "(anonymous)" // viewerId 를 보내지 않는 구형 호출자
)

// Config: 시청자·ffmpeg 수명 관련 설정값.
type Config struct {
	IdleTimeout   time.Duration
	EndGrace      time.Duration
	StartCheck    time.Duration
	StopWait      time.Duration
	StatsLogEvery time.Duration
}

func envInt(key string, def int, min int) int {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return def
	}
	n, err := strconv.Atoi(v)
	if err != nil || n < min {
		logger.Log.Warn(fmt.Sprintf("%s 값이 잘못되어 기본값(%d)을 사용합니다", key, def))
		return def
	}
	return n
}

// LoadConfig: .env(godotenv.Load 이후)에서 설정을 읽는다.
func LoadConfig() Config {
	return Config{
		IdleTimeout:   time.Duration(envInt("VIEWER_IDLE_TIMEOUT_SEC", defaultIdleTimeoutSec, 1)) * time.Second,
		EndGrace:      time.Duration(envInt("STREAM_END_GRACE_SEC", defaultEndGraceSec, 0)) * time.Second,
		StartCheck:    time.Duration(envInt("FFMPEG_START_CHECK_MS", defaultStartCheckMs, 0)) * time.Millisecond,
		StopWait:      time.Duration(envInt("FFMPEG_STOP_WAIT_SEC", defaultStopWaitSec, 1)) * time.Second,
		StatsLogEvery: time.Duration(envInt("FFMPEG_STATS_LOG_SEC", defaultStatsLogSec, 0)) * time.Second,
	}
}

// apiError: 핸들러가 그대로 HTTP 응답으로 바꿀 수 있는 실패.
type apiError struct {
	Status  int
	Code    string
	Message string
}

// stream: 현재 떠 있는 ffmpeg 한 개와 그 시청자 정보.
type stream struct {
	id          string // 브라우저가 end 때 되돌려 보내는 토큰(기존 start 응답 result)
	viewer      string // 현재 시청자. "" 이면 end 로 해제되어 종료 유예 중
	cmd         *exec.Cmd
	logw        *ffLogWriter
	startedAt   time.Time
	viewerSince time.Time
	endAt       time.Time // 종료 예정 시각(유예 중일 때만 값이 있음)
	stopping    bool
	stopReason  string
	done        chan struct{} // cmd.Wait 가 반환(프로세스 회수 완료)하면 닫힘
	exitErr     error         // done 이 닫힌 뒤에만 읽는다
}

// CmdManager: 단일 스트림 상태 보관소.
type CmdManager struct {
	mu     sync.Mutex
	cfg    Config
	cur    *stream
	active int // 아직 회수되지 않은 ffmpeg 프로세스 수(누수 확인용)

	lastActivity atomic.Int64 // 마지막 .m3u8/.ts 요청·하트비트 시각(UnixNano)
	watchOnce    sync.Once
}

/**
 * CmdManager 생성자 — godotenv.Load 이후에 호출해야 .env 값이 반영된다.
 * @return	CmdManager  CmdManager 구조체
 */
func CreateCmdManager() *CmdManager {
	m := &CmdManager{cfg: LoadConfig()}
	m.lastActivity.Store(time.Now().UnixNano())
	logger.Log.Info("영상 설정",
		zap.Duration("idleTimeout", m.cfg.IdleTimeout), zap.Duration("endGrace", m.cfg.EndGrace),
		zap.Duration("startCheck", m.cfg.StartCheck), zap.Duration("stopWait", m.cfg.StopWait),
		zap.Duration("statsLogEvery", m.cfg.StatsLogEvery))
	return m
}

// Touch: HLS 파일(.m3u8/.ts) 요청이 있었음을 기록한다(유휴 판단용).
func (m *CmdManager) Touch() {
	m.lastActivity.Store(time.Now().UnixNano())
}

// ActivityMiddleware: HLS 파일 서버 앞에 두어 .m3u8/.ts 요청을 활동으로 기록한다.
// 응답 자체에는 관여하지 않으므로 영상 전송을 끊거나 지연시키지 않는다.
func (m *CmdManager) ActivityMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		p := r.URL.Path
		if strings.HasSuffix(p, ".m3u8") || strings.HasSuffix(p, ".ts") {
			m.Touch()
		}
		next.ServeHTTP(w, r)
	})
}

// StartWatchdog: 유휴 타임아웃·end 유예 만료를 감시하는 고루틴을 1회 시작한다.
func (m *CmdManager) StartWatchdog() {
	m.watchOnce.Do(func() {
		go func() {
			t := time.NewTicker(time.Second)
			defer t.Stop()
			for range t.C {
				m.checkTimers()
			}
		}()
	})
}

func (m *CmdManager) checkTimers() {
	now := time.Now()
	m.mu.Lock()
	s := m.cur
	if s == nil || s.stopping {
		m.mu.Unlock()
		return
	}
	var reason string
	if s.viewer == "" {
		if !s.endAt.IsZero() && !now.Before(s.endAt) {
			reason = "end 유예 만료(재시청 요청 없음)"
		}
	} else {
		idle := now.Sub(time.Unix(0, m.lastActivity.Load()))
		if idle >= m.cfg.IdleTimeout {
			reason = fmt.Sprintf("유휴 타임아웃(%.0f초간 .m3u8/.ts 요청·하트비트 없음)", idle.Seconds())
			logger.Log.Warn("시청자 해제(유휴 타임아웃)", zap.String("viewer", s.viewer), zap.String("stream", s.id))
			s.viewer = ""
		}
	}
	if reason == "" {
		m.mu.Unlock()
		return
	}
	s.stopping = true
	s.stopReason = reason
	m.mu.Unlock()
	m.killAndWait(s)
}

// StartResult: start 성공 결과.
type StartResult struct {
	ID       string
	Takeover bool // true 이면 기존 스트림을 이어 받음(ffmpeg 를 새로 시작하지 않음)
}

// Start: 시청 시작 요청. 같은 시청자는 인계, 다른 시청자는 VIEWER_BUSY(409).
func (m *CmdManager) Start(viewer, requestID string) (*StartResult, *apiError) {
	viewer = strings.TrimSpace(viewer)
	if viewer == "" {
		viewer = anonymousViewer
	}
	for attempt := 0; attempt < 3; attempt++ {
		res, wait, err := m.tryStart(viewer, requestID)
		if wait == nil {
			return res, err
		}
		// 이전 ffmpeg 가 종료되는 중이면 회수를 기다린 뒤 다시 판단한다.
		select {
		case <-wait:
		case <-time.After(m.cfg.StopWait + time.Second):
			logger.Log.Error("이전 ffmpeg 종료 확인 시간 초과 — start 거부", zap.String("viewer", viewer))
			return nil, &apiError{http.StatusInternalServerError, "FFMPEG_FAILED", "이전 ffmpeg 가 아직 종료되지 않았습니다"}
		}
	}
	return nil, &apiError{http.StatusInternalServerError, "FFMPEG_FAILED", "이전 ffmpeg 종료를 확인하지 못했습니다"}
}

func (m *CmdManager) tryStart(viewer, requestID string) (*StartResult, <-chan struct{}, *apiError) {
	m.mu.Lock()
	defer m.mu.Unlock()

	if s := m.cur; s != nil {
		select {
		case <-s.done:
			// 이미 종료된 프로세스(정리 고루틴이 아직 목록에서 못 뺀 순간)
			m.cur = nil
		default:
			if s.stopping {
				return nil, s.done, nil
			}
			switch {
			case s.viewer == "":
				// end 후 종료 유예 중 — 종료를 취소하고 이어 쓴다(새 시청자도 같은 카메라 스트림이므로 재시작 불필요)
				s.viewer, s.viewerSince, s.endAt = viewer, time.Now(), time.Time{}
				m.Touch()
				logger.Log.Info("시청자 등록(종료 유예 중 인계)", zap.String("viewer", viewer), zap.String("stream", s.id), zap.String("requestId", requestID))
				return &StartResult{ID: s.id, Takeover: true}, nil, nil
			case s.viewer == viewer:
				m.Touch()
				logger.Log.Info("시청자 인계(같은 사용자 재시청)", zap.String("viewer", viewer), zap.String("stream", s.id), zap.String("requestId", requestID))
				return &StartResult{ID: s.id, Takeover: true}, nil, nil
			default:
				logger.Log.Warn("시청 거부(다른 사용자가 시청 중)",
					zap.String("viewer", viewer), zap.String("holder", s.viewer), zap.String("stream", s.id),
					zap.Duration("heldFor", time.Since(s.viewerSince)), zap.String("requestId", requestID))
				return nil, nil, &apiError{http.StatusConflict, "VIEWER_BUSY", "다른 사용자가 시청 중입니다"}
			}
		}
	}

	// 스트림 없음 — 새 ffmpeg 를 시작한다. 기존 HLS 파일 삭제는 여기서(실제로 새로 시작할 때)만 한다.
	s, err := m.launchLocked(viewer, requestID)
	if err != nil {
		return nil, nil, err
	}
	return &StartResult{ID: s.id}, nil, nil
}

// launchLocked: mu 를 잡은 상태에서 ffmpeg 를 띄우고, 시작 직후 실패하면 apiError 로 돌려준다.
func (m *CmdManager) launchLocked(viewer, requestID string) (*stream, *apiError) {
	hlsDir := os.Getenv("HLS_DIR")
	if err := os.MkdirAll(hlsDir, os.ModePerm); err != nil {
		logger.Log.Error("HLS 디렉토리 생성 실패", zap.Error(err))
	}
	// 기존 HLS 파일들 삭제 (과거 세그먼트 방지)
	files, _ := filepath.Glob(filepath.Join(hlsDir, "*.ts"))
	for _, f := range files {
		os.Remove(f)
	}
	os.Remove(filepath.Join(hlsDir, "index.m3u8"))

	id := uuid.NewString()
	cmd := buildFFmpegCmd()
	logw := newFFLogWriter(id, m.cfg.StatsLogEvery)
	cmd.Stdout = nil
	cmd.Stderr = logw

	if err := cmd.Start(); err != nil {
		logger.Log.Error("ffmpeg 시작 실패", zap.String("viewer", viewer), zap.String("requestId", requestID), zap.Error(err))
		return nil, &apiError{http.StatusInternalServerError, "FFMPEG_FAILED", "ffmpeg 를 시작하지 못했습니다"}
	}

	now := time.Now()
	s := &stream{id: id, viewer: viewer, cmd: cmd, logw: logw, startedAt: now, viewerSince: now, done: make(chan struct{})}
	m.cur = s
	m.active++
	m.Touch()
	logger.Log.Info("ffmpeg 시작", zap.String("viewer", viewer), zap.String("stream", id), zap.Int("pid", cmd.Process.Pid),
		zap.Int("activeFFmpeg", m.active), zap.String("requestId", requestID))

	go m.reap(s)

	// 시작 직후 실패 판정 — 이전에는 Start() 성공만 보고 가짜 성공 응답을 냈다.
	if m.cfg.StartCheck > 0 {
		select {
		case <-s.done:
			// 정리 고루틴(reap)은 mu 를 기다리는 중이므로 목록에서 직접 뺀다(active 감소는 reap 가 한다).
			m.cur = nil
			logger.Log.Error("ffmpeg 시작 직후 종료 — start 실패 처리",
				zap.String("viewer", viewer), zap.String("stream", id), zap.Error(s.exitErr))
			m.logTailLocked(s)
			return nil, &apiError{http.StatusInternalServerError, "FFMPEG_FAILED",
				fmt.Sprintf("ffmpeg 가 시작 직후 종료되었습니다(%s). 장비 로그를 확인하세요", exitText(s.exitErr))}
		case <-time.After(m.cfg.StartCheck):
		}
	}
	logger.Log.Info("시청자 등록", zap.String("viewer", viewer), zap.String("stream", id), zap.String("requestId", requestID))
	return s, nil
}

func (m *CmdManager) logTailLocked(s *stream) {
	if _, _, tail := s.logw.snapshot(); len(tail) > 0 {
		logger.Log.Error("ffmpeg 마지막 출력", zap.String("stream", s.id), zap.Strings("lines", tail))
	}
}

func exitText(err error) string {
	if err == nil {
		return "exit code 0"
	}
	return err.Error()
}

// reap: ffmpeg 종료를 기다려 회수하고 상태에서 제거한다(프로세스 맵 정리·좀비 방지).
func (m *CmdManager) reap(s *stream) {
	err := s.cmd.Wait()
	s.exitErr = err
	close(s.done)

	m.mu.Lock()
	m.active--
	if m.cur == s {
		m.cur = nil
	}
	active := m.active
	reason, stopping, viewer := s.stopReason, s.stopping, s.viewer
	m.mu.Unlock()

	last, hasStats, _ := s.logw.snapshot()
	fields := []zap.Field{
		zap.String("stream", s.id), zap.Duration("duration", time.Since(s.startedAt).Round(time.Second)),
		zap.Int("activeFFmpeg", active), zap.String("exit", exitText(err)),
	}
	if hasStats {
		fields = append(fields, last.fields()...)
	}
	if stopping {
		logger.Log.Info("ffmpeg 종료(요청에 의한 종료): "+reason, fields...)
	} else {
		// 스스로 종료 — RTSP 끊김 등. 시청자가 남아 있으면 점유도 함께 풀린다(자동 재시작은 이번 범위 아님).
		logger.Log.Error("ffmpeg 종료(비정상: ffmpeg 가 스스로 종료)", append(fields, zap.String("viewer", viewer))...)
	}
}

// killAndWait: Kill 후 프로세스 회수를 기다려 확인한다.
func (m *CmdManager) killAndWait(s *stream) {
	if s.cmd.Process != nil {
		if err := s.cmd.Process.Kill(); err != nil {
			// 이미 종료된 경우가 대부분. 회수 여부는 아래 done 으로 확인한다.
			logger.Log.Info("ffmpeg Kill 응답", zap.String("stream", s.id), zap.Error(err))
		}
	}
	select {
	case <-s.done:
	case <-time.After(m.cfg.StopWait):
		logger.Log.Error("ffmpeg 종료 확인 시간 초과(프로세스가 남아 있을 수 있음)", zap.String("stream", s.id), zap.Duration("waited", m.cfg.StopWait))
	}
}

// EndResult: end 처리 결과.
type EndResult struct {
	Code string // END_SCHEDULED / ENDED / NOT_VIEWER / NO_STREAM
	OK   bool
	ID   string
}

// End: 시청 종료 요청. 현재 시청자의 end 만 유효하다.
//
//	viewer 가 있으면 현재 시청자와 같아야 하고(id 가 있으면 스트림 id 도 같아야 함),
//	viewer 가 없는 구형 호출자는 스트림 id 가 같을 때만 유효하다.
func (m *CmdManager) End(viewer, id, requestID string) EndResult {
	viewer = strings.TrimSpace(viewer)
	id = strings.TrimSpace(id)

	m.mu.Lock()
	s := m.cur
	if s == nil || s.stopping {
		m.mu.Unlock()
		logger.Log.Info("end 무시(진행 중인 스트림 없음)", zap.String("viewer", viewer), zap.String("requestId", requestID))
		return EndResult{Code: "NO_STREAM"}
	}

	valid := false
	switch {
	case s.viewer == "":
		valid = false // 이미 해제된 스트림(유예 중) — 같은 요청이 한 번 더 온 경우
	case viewer != "":
		valid = viewer == s.viewer && (id == "" || id == s.id)
	default:
		valid = id != "" && id == s.id && s.viewer == anonymousViewer
	}
	if !valid {
		holder := s.viewer
		m.mu.Unlock()
		logger.Log.Warn("end 거부(현재 시청자가 아님)", zap.String("viewer", viewer), zap.String("holder", holder), zap.String("requestId", requestID))
		return EndResult{Code: "NOT_VIEWER"}
	}

	logger.Log.Info("시청자 해제(end)", zap.String("viewer", s.viewer), zap.String("stream", s.id),
		zap.Duration("watched", time.Since(s.viewerSince).Round(time.Second)), zap.Duration("endGrace", m.cfg.EndGrace), zap.String("requestId", requestID))
	s.viewer = ""
	if m.cfg.EndGrace > 0 {
		s.endAt = time.Now().Add(m.cfg.EndGrace)
		sid := s.id
		m.mu.Unlock()
		return EndResult{Code: "END_SCHEDULED", OK: true, ID: sid}
	}
	s.stopping = true
	s.stopReason = "end 요청(유예 없음)"
	sid := s.id
	m.mu.Unlock()
	m.killAndWait(s)
	return EndResult{Code: "ENDED", OK: true, ID: sid}
}

// Heartbeat: 시청 중임을 알리는 신호(탭이 숨겨져 .m3u8/.ts 요청이 멈춘 동안 점유를 유지하려는 호출자용).
// 현재 시청자의 신호만 유효하다.
func (m *CmdManager) Heartbeat(viewer, id string) bool {
	viewer = strings.TrimSpace(viewer)
	id = strings.TrimSpace(id)
	m.mu.Lock()
	defer m.mu.Unlock()
	s := m.cur
	if s == nil || s.stopping || s.viewer == "" {
		return false
	}
	if viewer != "" && viewer != s.viewer {
		return false
	}
	if id != "" && id != s.id {
		return false
	}
	if viewer == "" && id == "" {
		return false
	}
	m.Touch()
	return true
}
