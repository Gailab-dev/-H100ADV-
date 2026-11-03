package com.disabled.backup;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.disabled.backup.DeviceFilePullClient.PullResponse;
import com.disabled.backup.ServerFileLocator.ServerFile;

/**
 * 파일 한 개를 "서버 디스크에 정상 파일로" 만든다 — 일일 백업 스케줄러와 이벤트 삭제 흐름이 함께 쓰는 판정 로직.
 *
 * <p>순서(기존 상세보기와 같은 원칙: 서버 파일 우선 → 장비 PULL → NO_FILE):
 * ① 서버에 정상 파일이 있으면 그대로 VERIFIED(장비 호출 없음)
 * ② 없으면 장비에 PULL 요청 → 공통 지시서 4.2 판정(응답 code + 서버 디스크 존재 + 크기 일치)
 * ③ 응답 대기(10초)를 넘기는 대용량은 서버 디스크에 파일이 도착하는지 설정 시간까지 더 기다려 판정한다.</p>
 *
 * <p>판정 결과: VERIFIED / MISSING(장비에도 없음 — NO_FILE) / FAILED(오류 코드 포함, 재시도 대상).</p>
 */
@Component
public class DeviceFileFetcher {

	private static final Logger logger = LoggerFactory.getLogger(DeviceFileFetcher.class);

	/** 도착 대기 폴링 간격(ms) */
	private static final long ARRIVAL_POLL_MS = 2000L;

	/** 즉시 재시도 사이 대기(ms) */
	private static final long RETRY_PAUSE_MS = 2000L;

	@Autowired
	private ServerFileLocator locator;

	@Autowired
	private DeviceFilePullClient client;

	/** 파일 한 개의 처리 결과 */
	public static final class FetchOutcome {
		/** TransferStatus.VERIFIED / MISSING / FAILED */
		public final String status;
		/** FAILED 의 오류 코드(그 외 null) */
		public final String errorCode;
		/** 장비가 보고한 바이트(모르면 null) */
		public final Long deviceBytes;
		/** 서버 디스크 파일 바이트(VERIFIED 일 때) */
		public final Long serverBytes;
		/** 이번에 실제로 장비에 시도한 횟수(이미 서버에 있어 시도하지 않았으면 0) */
		public final int attempts;
		/** 장비 호출 없이 서버 디스크에서 바로 확인됐는지 */
		public final boolean alreadyOnServer;

		FetchOutcome(String status, String errorCode, Long deviceBytes, Long serverBytes, int attempts,
				boolean alreadyOnServer) {
			this.status = status;
			this.errorCode = errorCode;
			this.deviceBytes = deviceBytes;
			this.serverBytes = serverBytes;
			this.attempts = attempts;
			this.alreadyOnServer = alreadyOnServer;
		}

		public boolean isVerified() {
			return TransferStatus.VERIFIED.equals(status);
		}

		public boolean isMissing() {
			return TransferStatus.MISSING.equals(status);
		}

		public boolean isFailed() {
			return TransferStatus.FAILED.equals(status);
		}

		/** 장비와의 통신 자체 문제(오프라인·응답 없음·TLS)라 같은 장비의 나머지 파일도 실패할 가능성이 큰 오류 */
		public boolean isDeviceLevelFailure() {
			return isFailed() && ("DEVICE_UNREACHABLE".equals(errorCode) || DeviceFilePullClient.TIMEOUT.equals(errorCode)
					|| "TLS_ERROR".equals(errorCode) || "NO_DEVICE_IP".equals(errorCode));
		}

		static FetchOutcome verified(Long deviceBytes, long serverBytes, int attempts, boolean already) {
			return new FetchOutcome(TransferStatus.VERIFIED, null, deviceBytes, serverBytes, attempts, already);
		}

		static FetchOutcome missing(int attempts) {
			return new FetchOutcome(TransferStatus.MISSING, "NO_FILE", null, null, attempts, false);
		}

		static FetchOutcome failed(String code, Long deviceBytes, int attempts) {
			return new FetchOutcome(TransferStatus.FAILED, code, deviceBytes, null, attempts, false);
		}
	}

	/**
	 * @param knownDeviceBytes 이전 시도에서 알게 된 장비 바이트(크기 불일치 재시도에서만 값 전달, 그 외 null)
	 * @param waitSeconds      응답 10초를 넘기는 전송의 서버 도착 대기 상한(요청 시작부터, 초)
	 * @param extraRetries     FAILED 일 때 같은 호출 안에서 추가로 재시도할 횟수
	 */
	public FetchOutcome fetch(FileKind kind, String fileName, String dvIp, Long knownDeviceBytes, int waitSeconds,
			int extraRetries) {

		if (!ServerFileLocator.isSafeName(fileName)) {
			return FetchOutcome.failed("UNSAFE_NAME", null, 0);
		}

		// ① 서버에 정상 파일이 이미 있으면 장비를 부르지 않는다
		ServerFile existing = locator.find(kind, fileName, knownDeviceBytes);
		if (existing != null) {
			return FetchOutcome.verified(knownDeviceBytes, existing.bytes, 0, true);
		}

		if (dvIp == null || dvIp.isBlank()) {
			return FetchOutcome.failed("NO_DEVICE_IP", null, 0);
		}

		// ② 장비 PULL (+ FAILED 이면 즉시 재시도)
		int attempts = 0;
		FetchOutcome last = null;
		for (int i = 0; i <= extraRetries; i++) {
			if (Thread.currentThread().isInterrupted()) {
				return FetchOutcome.failed("INTERRUPTED", null, attempts);
			}
			attempts++;
			last = attemptOnce(kind, fileName, dvIp, waitSeconds);
			if (!last.isFailed()) {
				return withAttempts(last, attempts);
			}
			if (last.isDeviceLevelFailure()) {
				break; // 장비가 안 보이면 같은 호출 안에서 반복해도 소용없다
			}
			if (i < extraRetries) {
				try {
					Thread.sleep(RETRY_PAUSE_MS);
				} catch (InterruptedException ie) {
					Thread.currentThread().interrupt();
					return FetchOutcome.failed("INTERRUPTED", null, attempts);
				}
			}
		}
		return withAttempts(last, attempts);
	}

	private static FetchOutcome withAttempts(FetchOutcome o, int attempts) {
		return new FetchOutcome(o.status, o.errorCode, o.deviceBytes, o.serverBytes, attempts, o.alreadyOnServer);
	}

	/** 장비에 한 번 요청하고 판정한다(attempts 는 호출측이 채운다) */
	private FetchOutcome attemptOnce(FileKind kind, String fileName, String dvIp, int waitSeconds) {
		long startedAt = System.currentTimeMillis();
		PullResponse r = client.pull(dvIp, kind.pullType, fileName);

		if (r.transportError != null) {
			if (DeviceFilePullClient.TIMEOUT.equals(r.transportError)) {
				// 대용량 전송이 아직 진행 중일 수 있다 → 서버 디스크에 도착하는지 더 기다린다
				ServerFile arrived = waitForArrival(kind, fileName, startedAt + waitSeconds * 1000L);
				if (arrived != null) {
					return FetchOutcome.verified(null, arrived.bytes, 0, false);
				}
				return FetchOutcome.failed(DeviceFilePullClient.TIMEOUT, null, 0);
			}
			return FetchOutcome.failed(r.transportError, null, 0);
		}

		String code = r.code;
		if ("NO_FILE".equals(code)) {
			return FetchOutcome.missing(0);
		}
		if ("SERVER_REJECTED".equals(code) || "SEND_FAILED".equals(code)) {
			return FetchOutcome.failed(code, r.bytes, 0);
		}

		// code 가 OK 이거나(신형), code 자체가 없는 구형 module_d 응답 → 서버 디스크로 판정
		boolean legacy = (code == null);
		if (!legacy && !"OK".equals(code) && !Boolean.TRUE.equals(r.result)) {
			return FetchOutcome.failed(sanitizeCode("DEVICE_" + code), r.bytes, 0);
		}

		ServerFile sf = locator.find(kind, fileName, null);
		if (sf == null) {
			if (legacy) {
				// 구형 module_d 는 실패해도 true 를 주는 등 사유를 구분하지 못한다. 기존 상세보기와 같은 방식으로
				// "요청이 정상 응답했는데 서버에 파일이 없다"를 장비에도 없는 것(NO_FILE)으로 본다.
				logger.info("[FileBackup] 구형 장비 응답(code 없음) 후 서버에 파일 없음 → NO_FILE 로 판정 type={} file={}",
						kind.pullType, fileName);
				return FetchOutcome.missing(0);
			}
			return FetchOutcome.failed("NOT_ON_SERVER", r.bytes, 0);
		}
		if (r.bytes != null && r.bytes.longValue() != sf.bytes) {
			logger.warn("[FileBackup] 크기 불일치 type={} file={} 장비={} 서버={}", kind.pullType, fileName, r.bytes, sf.bytes);
			return FetchOutcome.failed("SIZE_MISMATCH", r.bytes, 0);
		}
		return FetchOutcome.verified(r.bytes, sf.bytes, 0, false);
	}

	/**
	 * 서버 디스크에 파일이 나타나 크기가 두 번 연속 같을 때까지(또는 기한까지) 기다린다.
	 * module_c 는 임시 파일 + rename 으로 저장하므로 파일이 보이면 완결본이지만, 구형 module_c 의 직접 쓰기에
	 * 대비해 크기 안정도 함께 확인한다.
	 */
	private ServerFile waitForArrival(FileKind kind, String fileName, long deadlineMs) {
		long lastSize = -1;
		while (System.currentTimeMillis() < deadlineMs) {
			try {
				Thread.sleep(ARRIVAL_POLL_MS);
			} catch (InterruptedException ie) {
				Thread.currentThread().interrupt();
				return null;
			}
			ServerFile sf = locator.find(kind, fileName, null);
			if (sf != null) {
				if (sf.bytes == lastSize) {
					return sf;
				}
				lastSize = sf.bytes;
			}
		}
		return null;
	}

	/** 장비가 준 임의 code 가 DB 컬럼(40자)·로그를 오염시키지 않게 정리 */
	private static String sanitizeCode(String raw) {
		String s = raw.replaceAll("[^A-Za-z0-9_]", "_");
		return s.length() > 40 ? s.substring(0, 40) : s;
	}
}
