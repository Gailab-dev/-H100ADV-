package video

import (
	"fmt"
	"os/exec"
	"sync"
	"os"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"local.dev/h100_module_d/logger"
)

// CmdManager 구조체
type CmdManager struct {
        store   map[string]*exec.Cmd
        mu      sync.Mutex
}

/**
 * CmdManager 생성자
 * @return	CmdManager  CmdManager 구조체
 */
func createCmdManager() *CmdManager {
	return &CmdManager{
		store: make(map[string]*exec.Cmd),
	}
}

/**
 * CmdManager 생성하는 함수
 * 클라이언트 요청마다 cmd를 별도로 생성하기 위함 
 * @receiver	cmdManager  CmdManager 구조체
 * @param		cmd		    커맨드
 * @return      id			cmdManager의 id
 */
func (cmdManager *CmdManager) cmdStart(cmd *exec.Cmd) string {
	id := uuid.NewString()
	cmdManager.mu.Lock() // cmdManager 동시 접근 금지
	cmdManager.store[id] = cmd
	cmdManager.mu.Unlock()  // cmdManager 동시 접근 금지 해제

	// 비동기 처리(고루틴)
	go func() {
		// 표준 출력/에러 연결 (디버깅용)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr

		err := cmd.Start()
		if err != nil{
			logger.Log.Error(fmt.Sprintf("명령어 실행 실패: %s", id), zap.Error(err))
		} else {
			logger.Log.Info("명령어 실행 성공!")
		}

		cmdManager.mu.Lock()
		delete(cmdManager.store, id) // 프로세스 누수 방지를 위해 생성 함수에서 delete 코드 추가
		cmdManager.mu.Unlock()
	}()

	return id
}

/**
 * CmdManager 프로세스 종료하는 함수
 * @receiver    cmdManager  CmdManager 구조체
 * @param       id          cmdManager의 id
 * @return      error
 */
func (cmdManager *CmdManager) cmdStop(id string) string {
	cmdManager.mu.Lock()
	cmd, ok := cmdManager.store[id]
	cmdManager.mu.Unlock()
	if !ok {
		return fmt.Sprintf("프로세스 ID 미존재: %s", id)
	}
	
	cmd.Process.Kill()
	return fmt.Sprintf("프로세스 종료 완료: %s", id)
}
