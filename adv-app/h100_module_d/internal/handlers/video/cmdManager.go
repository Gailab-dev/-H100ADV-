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
func CreateCmdManager() *CmdManager {
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
func cmdStart(cmd *exec.Cmd, oCmdManager *CmdManager) string {
/*func (manager *CmdManager) cmdStart(cmd *exec.Cmd, cmdManager *CmdManager) string {*/
	id := uuid.NewString()
	oCmdManager.mu.Lock() // cmdManager 동시 접근 금지
	oCmdManager.store[id] = cmd

	ids := make([]string, 0, len(oCmdManager.store))
        for id := range oCmdManager.store {
                ids = append(ids, id)
        }

        logger.Log.Info(fmt.Sprintf("--1111111---ids :", ids))

	oCmdManager.mu.Unlock()  // cmdManager 동시 접근 금지 해제

	ids2 := make([]string, 0, len(oCmdManager.store))
	for id := range oCmdManager.store {
                ids2 = append(ids2, id)
        }

        logger.Log.Info(fmt.Sprintf("--222222---ids2 :", ids2))

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

		ids3 := make([]string, 0, len(oCmdManager.store))
                for id := range oCmdManager.store {
                        ids3 = append(ids3, id)
                }

                logger.Log.Info(fmt.Sprintf("--333333---ids3 :", ids3))

		/*
		cmdManager.mu.Lock()
		delete(cmdManager.store, id) // 프로세스 누수 방지를 위해 생성 함수에서 delete 코드 추가
		cmdManager.mu.Unlock()

		ids4 := make([]string, 0, len(cmdManager.store))
                for id := range cmdManager.store {
                        ids3 = append(ids4, id)
                }

                logger.Log.Info(fmt.Sprintf("--444444---ids4 :", ids4))
		*/
	}()

	logger.Log.Info(fmt.Sprintf("--=-------id : %s", id))
	logger.Log.Info(fmt.Sprintf("====start PID:", os.Getpid()))

	return id
}

/**
 * CmdManager 프로세스 종료하는 함수
 * @receiver    cmdManager  CmdManager 구조체
 * @param       id          cmdManager의 id
 * @return      error
 */
func cmdStop(id string, oCmdManager *CmdManager) string {
/*func (manager *CmdManager) cmdStop(id string, cmdManager *CmdManager) string {*/
	logger.Log.Info(fmt.Sprintf("====end PID:", os.Getpid()))
	logger.Log.Info(fmt.Sprintf("=====end id : %s", id))
	oCmdManager.mu.Lock()
	
	ids4 := make([]string, 0, len(oCmdManager.store))
        for id := range oCmdManager.store {
                 ids4 = append(ids4, id)
        }

        logger.Log.Info(fmt.Sprintf("--444444---ids4 :", ids4))

	cmd, ok := oCmdManager.store[id]
	oCmdManager.mu.Unlock()

	logger.Log.Info(fmt.Sprintf("=====end ok : %s", ok))
	logger.Log.Info(fmt.Sprintf("=====end !ok : %s", !ok))
	if !ok {
		return fmt.Sprintf("프로세스 ID 미존재: %s", id)
	}
	
	cmd.Process.Kill()
	return fmt.Sprintf("프로세스 종료 완료: %s", id)
}
