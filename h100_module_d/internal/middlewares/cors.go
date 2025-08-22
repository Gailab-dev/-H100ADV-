package middlewares

import (
	"net/http"
)

// "/"로 요청 시 실행하는 함수
// CORS 미들웨어 적용 함수
func CorsMiddleware(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
                // CORS 헤더 설정
                w.Header().Set("Access-Control-Allow-Origin", "*")
                w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE")
                w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, Range, Origin, Accept, Access-Control-Allow-Origin")

                // 캐시 방지 헤더
            w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
	        w.Header().Set("Pragma", "no-cache")
	        w.Header().Set("Expires", "0")

                // OPTIONS 사전 요청 처리
                if r.Method == "OPTIONS" {
                        w.WriteHeader(http.StatusOK)
                        return
                }

                // 다음 핸들러 실행
                next.ServeHTTP(w, r)
        })
}

// 도메인별 handlerFunc을 CORS 처리하는 함수
// CORS 미들웨어 적용 함수
func WithCORS(h http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// CORS 헤더 설정
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, Range, Origin, Accept, Access-Control-Allow-Origin")

                // 캐시 방지 헤더
                w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
	        w.Header().Set("Pragma", "no-cache")
	        w.Header().Set("Expires", "0")

	        w.Write([]byte("Hello, no-cache response!"))

		// OPTIONS 사전 요청 처리
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

                // 다음 핸들러 실행
		h.ServeHTTP(w, r)
	}
}
