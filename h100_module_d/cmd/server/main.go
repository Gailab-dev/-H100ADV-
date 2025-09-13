package main

import (
        "crypto/tls"
        "net/http"
        "os"
       // "fmt"

        "github.com/robfig/cron/v3"
        "github.com/joho/godotenv"
        "go.uber.org/zap"
        "golang.org/x/crypto/acme/autocert"

	"local.dev/h100_module_d/internal/middlewares"
        "local.dev/h100_module_d/internal/handlers/video"
        "local.dev/h100_module_d/internal/handlers/fileSend"
        "local.dev/h100_module_d/logger"
)

var oCmdManager = video.CreateCmdManager()

func main() {
        // ===== [S] logger 적용 ====== //
        logger.InitLogger()
	log := logger.Log
        defer log.Sync() // 로그 flush
        // ===== [E] logger 적용 ====== //
        
        // ===== [S] .env 파일 로딩 ====== //
	eErr := godotenv.Load()
	if eErr != nil {
                log.Error(".env 파일을 불러올 수 없습니다", zap.Error(eErr))
	}
        // ===== [E] .env 파일 로딩 ====== //
        
        // ===== [S] 스케줄러 설정 ====== //
        log.Info("스케줄러 설정")
        c := cron.New(cron.WithSeconds())
	// 초 분 시 일 월 요일
	_, schErr := c.AddFunc(os.Getenv("FILE_SEND_SCH_TIME"), func() {
                // _, schErr := c.AddFunc("0 42 13 * * *", func() {
                log.Info("스케줄러 실행")
                fileSend.FileSendScheduler()
        })
        if schErr != nil {
                log.Error("스케줄러 등록 실패", zap.Error(eErr))
        }
        c.Start()
        // ===== [E] 스케줄러 설정 ====== //

        // ===== [S] SSL 적용 ====== //
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

        mux := http.NewServeMux()

	// 실제 HTTPS 서버
	httpsSrv := &http.Server{
		Addr:    ":443",
		// Addr:    ":"+os.Getenv("PORT"),
		Handler: mux,
		TLSConfig: &tls.Config{
			MinVersion:     tls.VersionTLS12,
			GetCertificate: m.GetCertificate, // ★ 인증서 자동 로드/갱신
		},
	}
        // ===== [E] SSL 적용 ====== //
        
        // ===== [S] 서버 설정 ====== //
        mux.HandleFunc("/video", middlewares.WithCORS(video.VideoHandler(oCmdManager)))
        mux.HandleFunc("/fileSend", middlewares.WithCORS(fileSend.FileSendHandler))

        // HLS 파일 제공을 위한 HTTP 서버설정
        fileServer := http.FileServer(http.Dir(os.Getenv("HLS_DIR")))
        
        // FileServer에 CORS 미들웨어 적용
        mux.Handle("/", middlewares.CorsMiddleware(fileServer))
        
        log.Info("video App Start!")

        // Start custom port server for development/testing
        // sErr := http.ListenAndServe(fmt.Sprintf(":%s", os.Getenv("PORT")), nil)
        // sErr := http.ListenAndServeTLS(":"+os.Getenv("PORT"), os.Getenv("TLS_CERT_FILE"), os.Getenv("TLS_KEY_FILE"), mux)
        
        // Start HTTPS server with Let's Encrypt
        if err := httpsSrv.ListenAndServeTLS("", ""); err != nil {
                log.Fatal("HTTPS 서버 시작 실패", zap.Error(err))
        }
        // ===== [E] 서버 설정 ====== //
}
        
