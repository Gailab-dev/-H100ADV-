package main

import (
	"net/http"
	"os"

	"github.com/joho/godotenv"
	"go.uber.org/zap"

	"local.dev/h100_module_c/database"
	"local.dev/h100_module_c/insertEvent"
	"local.dev/h100_module_c/internal/handlers/detection"
	"local.dev/h100_module_c/internal/handlers/deviceStatus"
	"local.dev/h100_module_c/internal/handlers/fileReceive"
	"local.dev/h100_module_c/internal/handlers/insertSipCall"
	"local.dev/h100_module_c/internal/handlers/sipCallTrigger"
	"local.dev/h100_module_c/internal/middlewares"
	"local.dev/h100_module_c/logger"
)

func main() {
	// ===== [S] logger 적용 ====== //
	logger.InitLogger()
	log := logger.Log
	defer log.Sync() // 로그 flush
	// ===== [E] logger 적용 ====== //
	// ===== [S] .env 파일 로딩 ====== //
	eErr := godotenv.Load()
	if eErr != nil {
		log.Info("Using process environment; optional .env file is unavailable")
	}
	// ===== [E] .env 파일 로딩 ====== //
	// ===== [S] mariadb 설정 ====== //
	database.Init()
	defer database.Close()
	// ===== [E] mariadb 설정 ====== //

	// ===== [S] SSL 적용 ====== //
	mux := http.NewServeMux()
	mux.HandleFunc("/detectionCapture", detection.Handler)
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		db, err := database.DBConn.DB()
		if err != nil || db.PingContext(r.Context()) != nil {
			http.Error(w, "Database unavailable", http.StatusServiceUnavailable)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status":"ok"}`))
	})
	// ===== [E] SSL 적용 ====== //

	// ===== [S] 핸들러 등록 ====== //
	mux.HandleFunc("/fileReceive", middlewares.WithCORS(fileReceive.OneFileReceive))
	mux.HandleFunc("/imageFileReceive", middlewares.WithCORS(fileReceive.ImageFileReceive))
	mux.HandleFunc("/videoFileReceive", middlewares.WithCORS(fileReceive.VideoFileReceive))
	mux.HandleFunc("/audioFileReceive", middlewares.WithCORS(fileReceive.AudioFileReceive)) // 2026-07-22: SIP 통화 녹음(wav) 수신
	mux.HandleFunc("/insertEventData", insertEvent.InsertEventData())
	mux.HandleFunc("/deviceStatus", middlewares.WithCORS(deviceStatus.DeviceStatusHandler))       // 작업계획서 04: 디바이스 상태 Heartbeat 수신
	mux.HandleFunc("/insertSipCallLog", middlewares.WithCORS(insertSipCall.InsertSipCallHandler)) // 작업계획서 07: SIP CALL 로그 수신
	mux.HandleFunc("/sipCallTrigger", middlewares.WithCORS(sipCallTrigger.SipCallTriggerHandler)) // 작업계획서 15: 응급콜 실시간 알림 트리거
	log.Info("[BUILD_CHECK] 핸들러 등록 완료")
	// ===== [E] 핸들러 등록 ====== //

	// ===== [S] 서버 설정 ====== //
	sErr := http.ListenAndServeTLS(":"+os.Getenv("PORT"), os.Getenv("TLS_CERT_FILE"), os.Getenv("TLS_KEY_FILE"), mux)

	if sErr != nil {
		log.Fatal("HTTPS server failed", zap.Error(sErr))
	}
	// ===== [E] 서버 설정 ====== //

}
