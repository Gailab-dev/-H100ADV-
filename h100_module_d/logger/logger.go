package logger

import (
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"gopkg.in/natefinch/lumberjack.v2"
)

var Log *zap.Logger

const (
	logDir = "logs" // 서비스 WorkingDirectory 기준 상대 경로(예: ~/H100/system/h100_module_d/logs)
	// 날짜가 바뀐 뒤 이 일수보다 오래된 일별 로그 파일(log-YYYY-MM-DD*.log)은 지운다.
	keepDays = 30
)

// kst 는 로그 파일 날짜 경계(자정 교체) 기준 시간대. 장비 TZ 가 UTC 여도 한국 시간 날짜로 파일이 나뉘게 한다.
var kst = loadKST()

func loadKST() *time.Location {
	if loc, err := time.LoadLocation("Asia/Seoul"); err == nil {
		return loc
	}
	return time.FixedZone("KST", 9*60*60)
}

// dailyWriter 는 쓸 때마다 날짜를 확인해 날짜가 바뀌면 새 일별 파일(logs/log-YYYY-MM-DD.log)로 바꿔 쓴다.
// (2026-11-09) 예전에는 프로세스 시작일의 파일명을 한 번만 정해, 며칠 동안 켜져 있으면 오늘자 파일이 생기지 않고
// 시작일 파일에만 계속 쌓였다. 파일 크기 교체(lumberjack, 10MB)는 날짜 파일 안에서 그대로 동작한다.
// 파일을 열거나 쓰지 못하면 호출한 쪽에 오류를 돌려주지 않고 stderr 로 알린다(콘솔 출력은 별도 코어가 stdout 으로 계속 남긴다).
type dailyWriter struct {
	mu        sync.Mutex
	dir       string
	now       func() time.Time
	day       string
	w         *lumberjack.Logger
	lastWarn  time.Time
	lastPrune string
}

func newDailyWriter(dir string) *dailyWriter {
	return &dailyWriter{dir: dir, now: time.Now}
}

func (d *dailyWriter) pathFor(day string) string {
	return filepath.Join(d.dir, fmt.Sprintf("log-%s.log", day))
}

func (d *dailyWriter) Write(p []byte) (int, error) {
	d.mu.Lock()
	defer d.mu.Unlock()
	t := d.now().In(kst)
	day := t.Format("2006-01-02")
	if d.w == nil || day != d.day {
		if d.w != nil {
			d.w.Close()
		}
		d.w = &lumberjack.Logger{
			Filename:   d.pathFor(day),
			MaxSize:    10, // MB 단위(날짜 파일 안에서의 크기 교체)
			MaxBackups: 5,
			MaxAge:     30,
			Compress:   false,
		}
		d.day = day
		if d.lastPrune != day {
			d.lastPrune = day
			pruneOld(d.dir, t, keepDays)
		}
	}
	n, err := d.w.Write(p)
	if err != nil {
		// 파일에 못 쓰면 stderr 로 알린다(분당 1회). 로그 내용 자체는 콘솔 코어가 stdout 으로 남긴다.
		if now := d.now(); now.Sub(d.lastWarn) > time.Minute {
			d.lastWarn = now
			fmt.Fprintf(os.Stderr, "[logger] 로그 파일 쓰기 실패 file=%s err=%v — 콘솔(stdout) 출력만 남습니다\n", d.pathFor(day), err)
		}
		return len(p), nil
	}
	return n, nil
}

func (d *dailyWriter) Sync() error { return nil }

// pruneOld 는 dir 의 일별 로그 파일(log-YYYY-MM-DD.log 와 lumberjack 백업 log-YYYY-MM-DD-<시각>.log) 중
// 파일명 날짜가 keep 일보다 오래된 것을 지운다. 이름이 형식에 맞지 않는 파일은 건드리지 않는다.
func pruneOld(dir string, now time.Time, keep int) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return
	}
	cutoff := now.AddDate(0, 0, -keep).Format("2006-01-02")
	for _, e := range entries {
		name := e.Name()
		if e.IsDir() || len(name) < len("log-2006-01-02.log") || name[:4] != "log-" || filepath.Ext(name) != ".log" {
			continue
		}
		day := name[4:14]
		if _, err := time.Parse("2006-01-02", day); err != nil {
			continue
		}
		if day < cutoff {
			os.Remove(filepath.Join(dir, name))
		}
	}
}

func InitLogger() {
	fileWriter := zapcore.AddSync(newDailyWriter(logDir))

	// 로그 레벨 설정 (INFO)
	level := zap.NewAtomicLevelAt(zapcore.InfoLevel)

	// 인코더 설정: 콘솔(stdout → journald/systemd.log)은 색상, 로그 파일은 색상 코드 없이(grep 이 쉽도록)
	encoderConfig := zapcore.EncoderConfig{
		TimeKey:       "time",
		LevelKey:      "level",
		NameKey:       "logger",
		CallerKey:     "caller",
		MessageKey:    "msg",
		StacktraceKey: "stacktrace",
		EncodeLevel:   zapcore.CapitalColorLevelEncoder, // INFO, ERROR 등
		EncodeTime:    zapcore.ISO8601TimeEncoder,       // 2025-07-07T12:34:56
		EncodeCaller:  zapcore.ShortCallerEncoder,
	}
	fileEncoderConfig := encoderConfig
	fileEncoderConfig.EncodeLevel = zapcore.CapitalLevelEncoder

	consoleEncoder := zapcore.NewConsoleEncoder(encoderConfig)
	fileEncoder := zapcore.NewConsoleEncoder(fileEncoderConfig)
	consoleWriter := zapcore.Lock(os.Stdout)

	// 파일 + 콘솔을 동시에 출력하도록 구성
	core := zapcore.NewTee(
		zapcore.NewCore(fileEncoder, fileWriter, level),
		zapcore.NewCore(consoleEncoder, consoleWriter, level),
	)

	// 전체 Logger 구성
	Log = zap.New(core, zap.AddCaller(), zap.AddStacktrace(zapcore.ErrorLevel))

	cwd, _ := os.Getwd()
	Log.Info(fmt.Sprintf("로거 시작 pid=%d 작업폴더=%s 로그폴더=%s (날짜별 파일 log-YYYY-MM-DD.log, KST 자정 교체, %d일 보관)",
		os.Getpid(), cwd, filepath.Join(cwd, logDir), keepDays))
}
