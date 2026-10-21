// roi_cleaner 는 ROI 스냅샷 파일을 정리하는 cron 용 실행 파일이다(34번 작업계획서 §8).
//
//	roi_cleaner --mode temp     --max-age 1h              # 임시 스냅샷(편집 중 파일) 정리, 10분마다
//	roi_cleaner --mode baseline --max-age 1h              # DB 에 없는 기준 스냅샷 폴더 정리, 하루 1회(evt_roi_history_purge 이후)
//	공통: --dry-run (삭제 없이 대상만 출력), --base (미디어 기준 폴더, 기본 FILE_UPLOAD_PATH)
//
// baseline 모드의 --max-age 는 "갓 만들어진 폴더를 지우지 않는 유예 시간"이다. DB 는 database.Init 이 읽는
// 설정(H100_DB_* 환경변수 또는 ./config/database.yml)을 쓰며, SELECT 만 하므로 읽기 전용 계정을 권장한다.
package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/joho/godotenv"

	"local.dev/h100_module_c/database"
	"local.dev/h100_module_c/internal/roicleaner"
)

type snapshotRow struct {
	RsFilePath string `gorm:"column:rs_file_path"`
}

func main() {
	mode := flag.String("mode", "", "temp | baseline")
	maxAge := flag.Duration("max-age", time.Hour, "temp: 이보다 오래된 파일 삭제 / baseline: 이보다 오래된 고아 폴더만 삭제")
	dryRun := flag.Bool("dry-run", false, "삭제하지 않고 대상만 출력")
	baseFlag := flag.String("base", "", "미디어 기준 폴더(기본: 환경변수 FILE_UPLOAD_PATH)")
	flag.Parse()

	_ = godotenv.Load() // 없어도 된다(프로세스 환경변수 사용)
	base := *baseFlag
	if base == "" {
		base = os.Getenv("FILE_UPLOAD_PATH")
	}
	if base == "" || !filepath.IsAbs(base) {
		fmt.Fprintln(os.Stderr, "미디어 기준 폴더(--base 또는 FILE_UPLOAD_PATH)가 절대경로로 필요합니다")
		os.Exit(2)
	}
	if *maxAge <= 0 {
		fmt.Fprintln(os.Stderr, "--max-age 는 0 보다 커야 합니다")
		os.Exit(2)
	}

	var res roicleaner.Result
	var err error
	switch *mode {
	case "temp":
		res, err = roicleaner.CleanTemp(base, *maxAge, time.Now(), *dryRun)
	case "baseline":
		database.Init()
		defer database.Close()
		var rows []snapshotRow
		if qErr := database.DBConn.Table("tbl_roi_snapshot").Select("rs_file_path").Find(&rows).Error; qErr != nil {
			fmt.Fprintln(os.Stderr, "기준 스냅샷 목록 조회 실패")
			os.Exit(1)
		}
		paths := make([]string, 0, len(rows))
		for _, r := range rows {
			paths = append(paths, r.RsFilePath)
		}
		res, err = roicleaner.CleanBaseline(base, roicleaner.ReferencedFromPaths(paths), *maxAge, time.Now(), *dryRun)
	default:
		fmt.Fprintln(os.Stderr, "--mode 는 temp 또는 baseline 이어야 합니다")
		os.Exit(2)
	}
	prefix := ""
	if *dryRun {
		prefix = "[dry-run] "
	}
	fmt.Printf("%sroi_cleaner mode=%s %s\n", prefix, *mode, res)
	if err != nil {
		fmt.Fprintln(os.Stderr, "정리 중 오류:", err)
		os.Exit(1)
	}
}
