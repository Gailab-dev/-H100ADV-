package com.disabled.backup;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * 일일 파일 백업 설정(globals.properties 의 file.backup.* — 환경변수 H100_FILE_BACKUP_* 로 덮어쓸 수 있다).
 * 스케줄러는 기본 비활성이다(module_d 의 자체 FileSendScheduler 와 이중 전송되지 않도록 운영에서 맞춘 뒤 켠다).
 */
@Component
public class FileBackupProperties {

	/** 스케줄러 사용 여부(기본 false). 관리자 수동 실행은 이 값과 무관하게 동작한다. */
	@Value("${file.backup.enabled:false}")
	private boolean enabled;

	/** 장비당 즉시 재시도 횟수(첫 시도 제외, 같은 실행 안에서 FAILED 파일을 다시 시도하는 횟수) */
	@Value("${file.backup.immediate-retries:1}")
	private int immediateRetries;

	/** 재시도 기한(일). 대상일로부터 이 기간이 지난 미완료 항목은 LOST */
	@Value("${file.backup.retry-deadline-days:30}")
	private int retryDeadlineDays;

	/** 스케줄러 전용 PULL 응답 대기(초). 상세보기의 10초와 분리(대용량 영상 고려) */
	@Value("${file.backup.pull-timeout-seconds:180}")
	private int pullTimeoutSeconds;

	/** 이벤트 삭제 흐름의 비동기 PULL 응답 대기(초) */
	@Value("${file.backup.delete-pull-timeout-seconds:120}")
	private int deletePullTimeoutSeconds;

	/** 장비 연결 대기(초) */
	@Value("${file.backup.connect-timeout-seconds:5}")
	private int connectTimeoutSeconds;

	/** 한 장비에서 연속 실패가 이 횟수에 이르면 이번 실행에서는 그 장비를 건너뛴다 */
	@Value("${file.backup.device-fail-skip-threshold:3}")
	private int deviceFailSkipThreshold;

	/** dv_ip 에 포트가 없을 때 붙이는 module_d 포트(ApiServiceImpl 과 동일 기본값 8087) */
	@Value("${file.backup.device-port:8087}")
	private String devicePort;

	public boolean isEnabled() {
		return enabled;
	}

	public int getImmediateRetries() {
		return Math.max(0, immediateRetries);
	}

	public int getRetryDeadlineDays() {
		return Math.max(1, retryDeadlineDays);
	}

	public int getPullTimeoutSeconds() {
		return Math.max(10, pullTimeoutSeconds);
	}

	public int getDeletePullTimeoutSeconds() {
		return Math.max(10, deletePullTimeoutSeconds);
	}

	public int getConnectTimeoutSeconds() {
		return Math.max(1, connectTimeoutSeconds);
	}

	public int getDeviceFailSkipThreshold() {
		return Math.max(1, deviceFailSkipThreshold);
	}

	public String getDevicePort() {
		return devicePort == null || devicePort.isBlank() ? "8087" : devicePort.trim();
	}
}
