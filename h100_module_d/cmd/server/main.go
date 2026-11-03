package main

import (
	"net/http"
	"os"
	"time"

	"github.com/joho/godotenv"
	"github.com/robfig/cron/v3"
	"go.uber.org/zap"

	"local.dev/h100_module_d/internal/handlers/detection"
	"local.dev/h100_module_d/internal/handlers/fileSend"
	"local.dev/h100_module_d/internal/handlers/roi"
	"local.dev/h100_module_d/internal/handlers/tilting"
	"local.dev/h100_module_d/internal/handlers/video"
	"local.dev/h100_module_d/internal/middlewares"
	"local.dev/h100_module_d/logger"
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

	// 영상 상태 관리자: .env 의 시청자 타임아웃·유예 값을 읽어야 하므로 .env 로딩 뒤에 만든다.
	oCmdManager := video.CreateCmdManager()
	oCmdManager.StartWatchdog() // 유휴 타임아웃·end 유예 만료 감시

	// ===== [S] 스케줄러 설정 ====== //
	// FILE_SEND_SCHEDULER_ENABLED=false 이면 장비 주도 전송 스케줄러를 등록하지 않는다(서버 주도 백업 전환용).
	// 미설정이면 기존처럼 켜짐(이 경우 FILE_SEND_SCH_TIME 이 올바르지 않으면 기동 실패 — 기존 동작 유지).
	if fileSend.SchedulerEnabled() {
		log.Info("스케줄러 설정")
		// 날짜 경계·실행 시각 해석을 KST 로 고정한다(장비 TZ 가 UTC 여도 동일하게 동작).
		c := cron.New(cron.WithSeconds(), cron.WithLocation(fileSend.KST()))
		// 초 분 시 일 월 요일
		_, schErr := c.AddFunc(os.Getenv("FILE_SEND_SCH_TIME"), func() {
			// _, schErr := c.AddFunc("0 42 13 * * *", func() {
			log.Info("스케줄러 실행")
			fileSend.FileSendScheduler()
		})
		if schErr != nil {
			log.Fatal("Invalid file schedule", zap.Error(schErr))
		}
		c.Start()
	} else {
		log.Info("FileSendScheduler 비활성(FILE_SEND_SCHEDULER_ENABLED=false) — 서버 주도 /fileSend 요청만 처리")
	}
	// ===== [E] 스케줄러 설정 ====== //

	// ===== [S] SSL 적용 ====== //
	/*
				domain := "geyeparking.shop" // 가비아에서 구입한 도메인

		        m := &autocert.Manager{
				// 인증서 캐시(필수). 없으면 재부팅 때마다 재발급 시도 → 레이트리밋 위험
				Cache:      autocert.DirCache("/var/lib/autocert"),
				HostPolicy: autocert.HostWhitelist(domain, "www."+domain), // www 서브도메인 포함
				Prompt:     autocert.AcceptTOS, // Let's Encrypt 서비스 약관 자동 동의
			}

		        // HTTP-01 챌린지용 80 포트 핸들러(이 경로는 꼭 열려야 함)
			go func() {
				httpSrv := &http.Server{
					Addr:    ":80",
					Handler: m.HTTPHandler(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
						// 그 외 경로는 HTTPS 리다이렉트
						target := "https://" + r.Host + r.URL.RequestURI()
						http.Redirect(w, r, target, http.StatusPermanentRedirect)
					})),
				}
				if err := httpSrv.ListenAndServe(); err != nil {
					log.Fatal("HTTP 서버 시작 실패", zap.Error(err))
				}
			}()

	*/
	mux := http.NewServeMux()
	mux.HandleFunc("/detection/trigger", detection.Handler)
	// 34번: 웹 ROI 설정 — 서버(module_c)가 HMAC 서명해 중계한 요청만 처리한다
	mux.HandleFunc("/ROI_get", roi.GetHandler)
	mux.HandleFunc("/ROI_snapshot", roi.SnapshotHandler)
	mux.HandleFunc("/ROI_receive", roi.ReceiveHandler)
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status":"ok"}`))
	})

	// 실제 HTTPS 서버
	/*
		httpsSrv := &http.Server{
			// Addr:    ":8443",
			Addr:    ":"+os.Getenv("PORT"),
			Handler: mux,
			TLSConfig: &tls.Config{
				MinVersion:     tls.VersionTLS12,
				GetCertificate: m.GetCertificate, // ★ 인증서 자동 로드/갱신
			},
		}
	*/
	// ===== [E] SSL 적용 ====== //

	// ===== [S] 서버 설정 ====== //
	mux.HandleFunc("/video", middlewares.WithCORS(video.VideoHandler(oCmdManager)))
	mux.HandleFunc("/fileSend", middlewares.WithCORS(fileSend.FileSendHandler))
	mux.HandleFunc("/tilting", middlewares.WithCORS(tilting.TiltingCmdHandler))

	// HLS 파일 제공을 위한 HTTP 서버설정
	fileServer := http.FileServer(http.Dir(os.Getenv("HLS_DIR")))

	// FileServer에 CORS 미들웨어 적용 + .m3u8/.ts 요청을 시청 활동으로 기록(유휴 타임아웃 판단용)
	mux.Handle("/", middlewares.CorsMiddleware(oCmdManager.ActivityMiddleware(fileServer)))

	log.Info("video App Start!")

	// Start custom port server for development/testing
	// sErr := http.ListenAndServe(fmt.Sprintf(":%s", os.Getenv("PORT")), nil)
	// sErr := http.ListenAndServeTLS(":"+os.Getenv("PORT"), os.Getenv("TLS_CERT_FILE"), os.Getenv("TLS_KEY_FILE"), mux)

	// Start HTTPS server with Let's Encrypt
	// 38번: Read/Write/Idle 전체 타임아웃은 영상(.ts)·/fileSend 처럼 오래 걸리는 응답을 끊을 수 있어 두지 않고,
	//   헤더를 보내지 않고 버티는 연결만 막는 ReadHeaderTimeout 만 둔다.
	srv := &http.Server{
		Addr:              ":" + os.Getenv("PORT"),
		Handler:           mux,
		ReadHeaderTimeout: 10 * time.Second,
	}
	sErr := srv.ListenAndServeTLS(os.Getenv("TLS_CERT_FILE"), os.Getenv("TLS_KEY_FILE"))

	if sErr != nil {
		log.Fatal("HTTPS server failed", zap.Error(sErr))
	}
	// ===== [E] 서버 설정 ====== //
}
