package logger

import (
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"gopkg.in/natefinch/lumberjack.v2"
	"os"
	"time"
	"fmt"
)

var Log *zap.Logger

func InitLogger() {
	today := time.Now().Format("2006-01-02")	// 날짜 포맷
	filename := fmt.Sprintf("logs/log-%s.log", today)	// 로그 파일 경로

	// 로그 파일 설정
	fileWriter := zapcore.AddSync(&lumberjack.Logger{
		Filename:   filename, // 저장할 로그 파일 경로
		MaxSize:    10,       // MB 단위
		MaxBackups: 5,        // 최대 백업 파일 수
		MaxAge:     30,       // 일(day) 단위
		Compress:   false,     // gzip 압축 여부
	})

	// 로그 레벨 설정 (INFO)
	level := zap.NewAtomicLevelAt(zapcore.InfoLevel)

	// 인코더 설정 (JSON 또는 콘솔용 선택 가능)
	encoderConfig := zapcore.EncoderConfig{
		TimeKey:        "time",
		LevelKey:       "level",
		NameKey:        "logger",
		CallerKey:      "caller",
		MessageKey:     "msg",
		StacktraceKey:  "stacktrace",
		EncodeLevel:    zapcore.CapitalColorLevelEncoder, // INFO, ERROR 등
		EncodeTime:     zapcore.ISO8601TimeEncoder,       // 2025-07-07T12:34:56
		EncodeCaller:   zapcore.ShortCallerEncoder,
	}

	// 콘솔 출력
	consoleEncoder := zapcore.NewConsoleEncoder(encoderConfig)
	consoleWriter := zapcore.Lock(os.Stdout)

	// 파일 + 콘솔을 동시에 출력하도록 구성
	core := zapcore.NewTee(
		zapcore.NewCore(consoleEncoder, fileWriter, level),
		zapcore.NewCore(consoleEncoder, consoleWriter, level),
	)

	// 전체 Logger 구성
	Log = zap.New(core, zap.AddCaller(), zap.AddStacktrace(zapcore.ErrorLevel))
}
