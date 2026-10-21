package roi

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"sync"
)

// ROI 파일 저장소. 디바이스의 ROI 파일이 기준(진실)이다.
// 새 파일을 만들지 않고 기존 파일의 내용을 교체하며, 교체 직전 내용을 <경로>.bak 한 개로 보관한다.
// 한 프로세스 안의 동시 요청은 fileMu 로 직렬화한다(다른 프로세스가 직접 고치는 경우는 해시 비교로 감지).

var fileMu sync.Mutex

func sha256Hex(b []byte) string {
	sum := sha256.Sum256(b)
	return hex.EncodeToString(sum[:])
}

// readCurrent 는 현재 ROI 파일 내용과 해시를 돌려준다. 파일이 없으면 exists=false, 해시는 빈 문자열.
func readCurrent(path string) (data []byte, hash string, exists bool, err error) {
	data, err = os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil, "", false, nil
	}
	if err != nil {
		return nil, "", false, err
	}
	return data, sha256Hex(data), true, nil
}

// writeFileAtomic 은 같은 디렉터리의 임시 파일에 쓰고 fsync 한 뒤 rename 으로 교체한다.
// 읽는 쪽(Python)은 항상 완전한 옛 파일 또는 완전한 새 파일만 보게 된다.
func writeFileAtomic(path string, data []byte, mode os.FileMode) error {
	dir := filepath.Dir(path)
	suffix := make([]byte, 6)
	if _, err := rand.Read(suffix); err != nil {
		return err
	}
	tmp := filepath.Join(dir, fmt.Sprintf(".%s.tmp-%d-%s", filepath.Base(path), os.Getpid(), hex.EncodeToString(suffix)))
	f, err := os.OpenFile(tmp, os.O_WRONLY|os.O_CREATE|os.O_EXCL, mode)
	if err != nil {
		return err
	}
	cleanup := func() { os.Remove(tmp) }
	if _, err := f.Write(data); err != nil {
		f.Close()
		cleanup()
		return err
	}
	if err := f.Sync(); err != nil {
		f.Close()
		cleanup()
		return err
	}
	if err := f.Close(); err != nil {
		cleanup()
		return err
	}
	if err := os.Rename(tmp, path); err != nil {
		cleanup()
		return err
	}
	syncDir(dir)
	return nil
}

// syncDir 은 rename 결과를 디스크에 반영한다(Windows 는 디렉터리 fsync 를 지원하지 않아 건너뜀).
func syncDir(dir string) {
	if runtime.GOOS == "windows" {
		return
	}
	if d, err := os.Open(dir); err == nil {
		d.Sync()
		d.Close()
	}
}

// saveReplacing 은 현재 파일 해시가 baseHash 와 같을 때만 새 내용으로 교체한다.
// 반환: 저장한 바이트의 해시, 충돌 시 conflict=true 와 현재 해시.
func saveReplacing(path, baseHash string, next []byte) (newHash string, conflict bool, currentHash string, err error) {
	fileMu.Lock()
	defer fileMu.Unlock()

	cur, curHash, exists, err := readCurrent(path)
	if err != nil {
		return "", false, "", err
	}
	if curHash != baseHash {
		return "", true, curHash, nil
	}
	mode := os.FileMode(0o640)
	if exists {
		if st, statErr := os.Stat(path); statErr == nil {
			mode = st.Mode().Perm()
		}
		// 이전 내용 .bak 1개 보관(교체 중에도 원본 파일은 항상 존재해야 하므로 복사 후 rename 방식)
		if err := writeFileAtomic(path+".bak", cur, mode); err != nil {
			return "", false, "", fmt.Errorf("백업 저장 실패: %w", err)
		}
	}
	if err := writeFileAtomic(path, next, mode); err != nil {
		return "", false, "", err
	}
	return sha256Hex(next), false, "", nil
}
