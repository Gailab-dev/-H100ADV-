// Package roicleaner 는 ROI 스냅샷 파일 정리 로직이다(34번 작업계획서 §8). cmd/roi_cleaner 가 cron 으로 실행한다.
//
//	temp     : <base>/roi/snapshot/{계정}/{serial}/Cam{1,2}.jpg 중 수정시각이 maxAge 보다 오래된 것(및 남은 .tmp- 파일) 삭제,
//	           비어 버린 serial·계정 폴더 정리
//	baseline : <base>/roi/baseline/{serial}/{rh_id}/ 폴더 중 DB(tbl_roi_snapshot)에 없는 고아 폴더 삭제.
//	           Java 는 "파일 복사 -> DB INSERT" 순서라 방금 만든 폴더를 지우지 않도록, 수정시각이 grace 보다 오래된 것만 지운다.
//
// 안전장치: 항상 <base>/roi/ 아래만 다루고, 심볼릭 링크는 따라가지 않으며, 예상한 이름 규칙(13자리 serial, 숫자 rh_id,
// Cam1.jpg/Cam2.jpg)이 아닌 것은 건드리지 않는다. dryRun 이면 아무것도 지우지 않고 대상만 센다.
package roicleaner

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

var (
	serialDir = regexp.MustCompile(`^[0-9]{13}$`)
	rhIDDir   = regexp.MustCompile(`^[0-9]+$`)
	camFile   = regexp.MustCompile(`^Cam[12]\.jpg$`)
	tmpFile   = regexp.MustCompile(`^\..+\.tmp-[0-9a-f]+$`)
)

// Result 는 정리 결과 요약.
type Result struct {
	FilesDeleted int
	DirsDeleted  int
	Skipped      int // 규칙에 맞지 않아 건드리지 않은 항목
}

func (r Result) String() string {
	return fmt.Sprintf("files=%d dirs=%d skipped=%d", r.FilesDeleted, r.DirsDeleted, r.Skipped)
}

type remover struct {
	dryRun bool
	res    *Result
}

func (r remover) file(path string) error {
	r.res.FilesDeleted++
	if r.dryRun {
		return nil
	}
	return os.Remove(path)
}

func (r remover) dir(path string) error {
	r.res.DirsDeleted++
	if r.dryRun {
		return nil
	}
	return os.Remove(path) // 비어 있을 때만 지워진다
}

func (r remover) tree(path string) error {
	r.res.DirsDeleted++
	if r.dryRun {
		return nil
	}
	return os.RemoveAll(path)
}

func isRegular(e os.DirEntry) bool {
	info, err := e.Info()
	return err == nil && info.Mode().IsRegular()
}

func isRealDir(e os.DirEntry) bool {
	info, err := e.Info()
	return err == nil && info.Mode().IsDir() && info.Mode()&os.ModeSymlink == 0
}

// CleanTemp 는 임시 스냅샷을 정리한다.
func CleanTemp(base string, maxAge time.Duration, now time.Time, dryRun bool) (Result, error) {
	var res Result
	rm := remover{dryRun, &res}
	root := filepath.Join(base, "roi", "snapshot")
	accounts, err := os.ReadDir(root)
	if os.IsNotExist(err) {
		return res, nil
	}
	if err != nil {
		return res, err
	}
	for _, acc := range accounts {
		if !isRealDir(acc) {
			res.Skipped++
			continue
		}
		accPath := filepath.Join(root, acc.Name())
		serials, err := os.ReadDir(accPath)
		if err != nil {
			return res, err
		}
		remaining := 0
		for _, s := range serials {
			if !isRealDir(s) || !serialDir.MatchString(s.Name()) {
				res.Skipped++
				remaining++
				continue
			}
			sPath := filepath.Join(accPath, s.Name())
			files, err := os.ReadDir(sPath)
			if err != nil {
				return res, err
			}
			left := 0
			for _, f := range files {
				if !isRegular(f) || !(camFile.MatchString(f.Name()) || tmpFile.MatchString(f.Name())) {
					res.Skipped++
					left++
					continue
				}
				info, err := f.Info()
				if err != nil {
					return res, err
				}
				if now.Sub(info.ModTime()) <= maxAge {
					left++
					continue
				}
				if err := rm.file(filepath.Join(sPath, f.Name())); err != nil {
					return res, err
				}
			}
			if left == 0 {
				if err := rm.dir(sPath); err != nil {
					return res, err
				}
			} else {
				remaining++
			}
		}
		if remaining == 0 {
			if err := rm.dir(accPath); err != nil {
				return res, err
			}
		}
	}
	return res, nil
}

// CleanBaseline 은 DB 에 기록이 없는 기준 스냅샷 폴더를 정리한다.
// referenced 는 "serial/rh_id" 형태(예: "2026102000001/15")의 집합 — tbl_roi_snapshot.rs_file_path 에서 뽑는다.
func CleanBaseline(base string, referenced map[string]bool, grace time.Duration, now time.Time, dryRun bool) (Result, error) {
	var res Result
	rm := remover{dryRun, &res}
	root := filepath.Join(base, "roi", "baseline")
	serials, err := os.ReadDir(root)
	if os.IsNotExist(err) {
		return res, nil
	}
	if err != nil {
		return res, err
	}
	for _, s := range serials {
		if !isRealDir(s) || !serialDir.MatchString(s.Name()) {
			res.Skipped++
			continue
		}
		sPath := filepath.Join(root, s.Name())
		ids, err := os.ReadDir(sPath)
		if err != nil {
			return res, err
		}
		left := 0
		for _, id := range ids {
			if !isRealDir(id) || !rhIDDir.MatchString(id.Name()) {
				res.Skipped++
				left++
				continue
			}
			if referenced[s.Name()+"/"+id.Name()] {
				left++
				continue
			}
			info, err := id.Info()
			if err != nil {
				return res, err
			}
			if now.Sub(info.ModTime()) <= grace {
				left++ // 막 만들어져 DB 기록이 아직일 수 있음
				continue
			}
			if err := rm.tree(filepath.Join(sPath, id.Name())); err != nil {
				return res, err
			}
		}
		if left == 0 {
			if err := rm.dir(sPath); err != nil {
				return res, err
			}
		}
	}
	return res, nil
}

// ReferencedFromPaths 는 rs_file_path 목록("roi/baseline/{serial}/{rh_id}/Cam1.jpg")에서 "serial/rh_id" 집합을 만든다.
func ReferencedFromPaths(paths []string) map[string]bool {
	out := make(map[string]bool)
	for _, p := range paths {
		parts := strings.Split(filepath.ToSlash(p), "/")
		// roi / baseline / serial / rh_id / CamN.jpg
		if len(parts) == 5 && parts[0] == "roi" && parts[1] == "baseline" && serialDir.MatchString(parts[2]) && rhIDDir.MatchString(parts[3]) {
			out[parts[2]+"/"+parts[3]] = true
		}
	}
	return out
}
