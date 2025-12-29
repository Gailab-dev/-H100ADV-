package com.disabled.component;

import java.io.IOException;
import java.nio.file.*;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class LogDiskManager {
	
	// Globals.properties 에서 주입
    @Value("${LogFilePath}")
    private String logFilePath;

    // 최소 여유 공간 (5GB)
    private static final long MIN_FREE_BYTES = 5L * 1024 * 1024 * 1024;
    
    /**
     * 로그 파일이 저장되는 디스크의 남은 공간이 충분한지 체크
     */
    public boolean hasEnoughLogSpace() {
        try {
            Path logPath = Paths.get(logFilePath).toAbsolutePath();
            Path logDir = logPath.getParent();        // 로그 디렉토리
            if (logDir == null) {
                // 상대 경로나 이상한 값이 들어왔을 때는 현재 디렉토리 기준
                logDir = Paths.get(".").toAbsolutePath();
            }

            FileStore store = Files.getFileStore(logDir);
            long usable = store.getUsableSpace();     // 실제 사용 가능한 공간
            return usable >= MIN_FREE_BYTES;
        } catch (IOException e) {
            // 디스크 정보 조회 실패 시, 보수적으로 "공간 부족"으로 간주하거나
            // 필요에 따라 true로 처리할 수도 있음
            return true;
        }
    }
}

