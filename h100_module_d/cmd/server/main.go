package main

import (
        "net/http"
        "os"
        "fmt"

        "github.com/robfig/cron/v3"
        "github.com/joho/godotenv"
        "go.uber.org/zap"

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
        
        // ===== [S] 서버 설정 ====== //
        http.HandleFunc("/video", middlewares.WithCORS(video.VideoHandler(oCmdManager)))
        http.HandleFunc("/fileSend", middlewares.WithCORS(fileSend.FileSendHandler))
        // HLS 파일 제공을 위한 HTTP 서버설정
        fileServer := http.FileServer(http.Dir(os.Getenv("HLS_DIR")))
        
        // FileServer에 CORS 미들웨어 적용
        http.Handle("/", middlewares.CorsMiddleware(fileServer))
        
        log.Info("video App Start!")
        
        sErr := http.ListenAndServe(fmt.Sprintf(":%s", os.Getenv("PORT")), nil)
        
        if sErr != nil {
                log.Error("HTTP 서버 오류", zap.Error(sErr))
        }
        // ===== [E] 서버 설정 ====== //
}
        
