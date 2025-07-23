package main

import (
	"fmt"
	"net/http"
	"os"

	"github.com/joho/godotenv"
	"go.uber.org/zap"

	"local.dev/h100_module_c/database"
	"local.dev/h100_module_c/insertEvent"
	"local.dev/h100_module_c/internal/handlers/fileReceive"
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
                log.Error(".env 파일을 불러올 수 없습니다", zap.Error(eErr))
	}
        // ===== [E] .env 파일 로딩 ====== //
        
        // ===== [S] 서버 설정 ====== //
        http.HandleFunc("/fileReceive", middlewares.WithCORS(fileReceive.FileReceive))
        
        sErr := http.ListenAndServe(fmt.Sprintf(":%s", os.Getenv("PORT")), nil)
        
        if sErr != nil {
                log.Error("HTTP 서버 오류", zap.Error(sErr))
        }
        // ===== [E] 서버 설정 ====== //
        // ===== [S] mariaDB 설정 및 이벤트 정보 insert ====== //
        database.Init()
        defer database.Close()
        
        http.HandleFunc("/insertEventData",insertEvent.InsertEventData())
        http.ListenAndServe(":8080",nil)
        // ===== [E] mariaDB 설정 및 이벤트 정보 insert ====== //
        
}
        