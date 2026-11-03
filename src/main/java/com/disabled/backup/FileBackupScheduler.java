package com.disabled.backup;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * 일일 파일 백업 스케줄러(Spring 내부 스케줄러 — WeatherFetchScheduler 와 같은 방식, OS 크론탭 사용 안 함).
 * 스케줄 활성화(@EnableScheduling)는 기존 SchedulerConfig 에 이미 선언되어 있다.
 *
 * <p>기본 비활성이다({@code file.backup.enabled=false}). 켜기 전에 module_d 의 자체 FileSendScheduler
 * (FILE_SEND_SCHEDULER_ENABLED)를 먼저 꺼서 이중 전송을 막아야 한다.
 * cron 은 {@code file.backup.cron}(초 분 시 일 월 요일, KST)이며 "-" 로 두면 Spring 이 예약 자체를 하지 않는다.</p>
 *
 * <p>실제 작업은 {@link FileBackupService} 전용 스레드에서 실행되므로 이 메서드는 즉시 반환한다
 * (Spring 기본 스케줄러는 단일 스레드라 오래 걸리는 작업이 날씨 수집 등을 막지 않게 하기 위함).</p>
 */
@Component
public class FileBackupScheduler {

	private static final Logger logger = LoggerFactory.getLogger(FileBackupScheduler.class);

	@Autowired
	private FileBackupProperties props;

	@Autowired
	private FileBackupService backupService;

	@Scheduled(cron = "${file.backup.cron:0 0 5 * * *}", zone = "Asia/Seoul")
	public void scheduledRun() {
		if (!props.isEnabled()) {
			logger.debug("[FileBackup] 스케줄러 비활성(file.backup.enabled=false) — 실행하지 않음");
			return;
		}
		try {
			if (!backupService.startAsync(null, null, "SCHEDULED")) {
				logger.warn("[FileBackup] 이전 실행이 아직 진행 중이라 이번 예약 실행은 건너뜁니다");
			}
		} catch (RuntimeException e) {
			logger.error("[FileBackup] 예약 실행 시작 실패", e);
		}
	}
}
