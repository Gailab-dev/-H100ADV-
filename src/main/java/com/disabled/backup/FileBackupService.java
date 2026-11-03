package com.disabled.backup;

import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.disabled.backup.DeviceFileFetcher.FetchOutcome;
import com.disabled.mapper.FileTransferMapper;

/**
 * 일일 파일 백업(서버 주도) — 작업계획서 39 WP-2.
 *
 * <p>한 번 실행하면: ① 대상일(기본 어제 KST) 이벤트·통화 음성의 기대 파일을 이력에 PENDING 등록(이미 있으면 유지)
 * ② 재시도 기한(기본 30일)을 넘긴 미완료분을 LOST 확정 ③ 이력의 PENDING/FAILED 전부를 장비별로 순차 처리한다
 * (어제만 보지 않으므로 하루 누락돼도 다음 실행이 자동 보충한다).</p>
 *
 * <p>장비는 순차 처리하고, 한 장비에서 연속 실패가 임계값에 이르면 그 장비는 이번 실행에서 건너뛴다.
 * 동시 실행은 막는다(단일 웹 인스턴스 가정 — 웹이 여러 대가 되면 DB 락 등 별도 장치가 필요하다).
 * 긴 작업이 Spring 기본 단일 스케줄러 스레드(날씨 수집 등과 공유)를 막지 않도록 전용 스레드에서 실행한다.</p>
 */
@Service
public class FileBackupService {

	private static final Logger logger = LoggerFactory.getLogger(FileBackupService.class);

	/** 날짜 경계는 항상 KST 로 계산(서버 TZ 설정에 의존하지 않는다) */
	public static final ZoneId KST = ZoneId.of("Asia/Seoul");

	private static final DateTimeFormatter ISO_DATE = DateTimeFormatter.ofPattern("yyyy-MM-dd");
	private static final DateTimeFormatter ISO_DATETIME = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

	@Autowired
	private FileBackupProperties props;

	@Autowired
	private FileTransferHistoryService history;

	@Autowired
	private DeviceFileFetcher fetcher;

	@Autowired
	private FileTransferMapper fileTransferMapper;

	/** 동시 실행 방지 */
	private final AtomicBoolean running = new AtomicBoolean(false);

	private volatile FileBackupSummary current;
	private volatile FileBackupSummary last;

	private ExecutorService executor;

	@PostConstruct
	void init() {
		executor = Executors.newSingleThreadExecutor(r -> {
			Thread t = new Thread(r, "file-backup");
			t.setDaemon(true);
			return t;
		});
	}

	@PreDestroy
	void shutdown() {
		if (executor != null) {
			executor.shutdownNow();
		}
	}

	/** 기본 대상일 = 어제(KST) */
	public static LocalDate yesterdayKst() {
		return ZonedDateTime.now(KST).toLocalDate().minusDays(1);
	}

	public boolean isRunning() {
		return running.get();
	}

	/**
	 * 백업을 전용 스레드에서 시작한다.
	 * @param targetDate   null 이면 어제(KST). 지정하면 그 날짜만 재처리(FAILED/LOST 를 PENDING 으로 되돌린 뒤 처리)
	 * @param dvId         null 이면 전체 장비
	 * @param trigger      SCHEDULED / MANUAL
	 * @return false 면 이미 실행 중이라 시작하지 않음
	 */
	public boolean startAsync(LocalDate targetDate, Integer dvId, String trigger) {
		if (!running.compareAndSet(false, true)) {
			return false;
		}
		final boolean explicitDate = (targetDate != null);
		final LocalDate date = explicitDate ? targetDate : yesterdayKst();

		FileBackupSummary summary = new FileBackupSummary();
		summary.trigger = trigger;
		summary.targetDate = date.format(ISO_DATE);
		summary.explicitDate = explicitDate;
		summary.dvId = dvId;
		summary.startedAt = ZonedDateTime.now(KST).format(ISO_DATETIME);
		current = summary;

		try {
			executor.submit(() -> {
				try {
					runInternal(summary, date, explicitDate, dvId);
				} finally {
					last = summary;
					current = null;
					running.set(false);
				}
			});
		} catch (RuntimeException e) {
			running.set(false);
			current = null;
			throw e;
		}
		return true;
	}

	/** 현재 실행(있으면)·직전 실행 요약·상태별 이력 건수 */
	public Map<String, Object> status() {
		Map<String, Object> m = new java.util.LinkedHashMap<String, Object>();
		m.put("enabled", props.isEnabled());
		m.put("running", running.get());
		FileBackupSummary c = current;
		FileBackupSummary l = last;
		m.put("current", c == null ? null : c.toMap());
		m.put("last", l == null ? null : l.toMap());
		try {
			Map<String, Object> counts = new java.util.LinkedHashMap<String, Object>();
			for (Map<String, Object> row : fileTransferMapper.selectStatusCounts()) {
				counts.put(String.valueOf(row.get("ft_status")), row.get("cnt"));
			}
			m.put("historyCounts", counts);
		} catch (RuntimeException e) {
			logger.warn("[FileBackup] 이력 건수 조회 실패(이력 테이블 확인 필요): {}", e.toString());
			m.put("historyCounts", null);
		}
		return m;
	}

	// ------------------------------------------------------------------ 실행

	private void runInternal(FileBackupSummary s, LocalDate targetDate, boolean explicitDate, Integer dvId) {
		logger.info("[FileBackup] 시작({}) 대상일={} 장비={}", s.trigger, s.targetDate, dvId == null ? "전체" : dvId);
		try {
			// ① 대상 산출 → PENDING 등록
			s.registered = history.registerForDate(targetDate);

			// ② 기한 처리 / 날짜 지정 재처리 준비
			LocalDate today = ZonedDateTime.now(KST).toLocalDate();
			String fromDate;
			String toDate = null;
			if (explicitDate) {
				s.requeued = fileTransferMapper.requeueForDate(s.targetDate, dvId);
				fromDate = s.targetDate;
				toDate = s.targetDate;
			} else {
				String cutoff = today.minusDays(props.getRetryDeadlineDays()).format(ISO_DATE);
				s.lost = fileTransferMapper.markLostBefore(cutoff);
				fromDate = cutoff;
			}

			// ③ 처리 대상(PENDING/FAILED) 전부
			List<Map<String, Object>> rows = fileTransferMapper.selectProcessable(fromDate, toDate, dvId);
			s.candidates = rows.size();

			Integer currentDv = null;
			boolean dvStarted = false;
			int consecutiveFailures = 0;
			Set<Integer> skipped = new HashSet<Integer>();

			for (Map<String, Object> row : rows) {
				if (Thread.currentThread().isInterrupted()) {
					logger.warn("[FileBackup] 중단 요청으로 실행을 멈춥니다(남은 항목은 다음 실행에서 처리)");
					s.error = "INTERRUPTED";
					break;
				}
				Integer rowDv = row.get("ft_dv_id") == null ? Integer.valueOf(-1) : ((Number) row.get("ft_dv_id")).intValue();
				if (!dvStarted || !rowDv.equals(currentDv)) {
					currentDv = rowDv;
					dvStarted = true;
					consecutiveFailures = 0;
				}
				if (skipped.contains(rowDv)) {
					s.skippedFiles++;
					continue;
				}

				FileKind kind = FileKind.of(String.valueOf(row.get("ft_file_kind")));
				if (kind == null) {
					logger.warn("[FileBackup] 알 수 없는 파일 종류 ft_id={} kind={}", row.get("ft_id"), row.get("ft_file_kind"));
					continue;
				}
				long ftId = ((Number) row.get("ft_id")).longValue();
				Integer refId = ((Number) row.get("ft_ref_id")).intValue();
				String name = String.valueOf(row.get("ft_file_name"));
				String dvIp = row.get("dv_ip") == null ? null : row.get("dv_ip").toString();
				Long known = null;
				if ("SIZE_MISMATCH".equals(row.get("ft_last_error_code")) && row.get("ft_device_bytes") != null) {
					known = ((Number) row.get("ft_device_bytes")).longValue();
				}

				FetchOutcome o;
				try {
					o = fetcher.fetch(kind, name, dvIp, known, props.getPullTimeoutSeconds(), props.getImmediateRetries());
					history.applyOutcome(ftId, kind, refId, o);
				} catch (RuntimeException e) {
					// 한 파일의 예기치 못한 오류가 전체 실행을 멈추지 않게 한다(이력은 그대로 남아 다음 실행이 재시도)
					logger.error("[FileBackup] 파일 처리 중 오류 ft_id={} kind={}", ftId, kind, e);
					s.failed++;
					consecutiveFailures++;
					continue;
				}

				if (o.isVerified()) {
					if (o.alreadyOnServer) {
						s.alreadyOnServer++;
					} else {
						s.transferred++;
					}
					consecutiveFailures = 0;
				} else if (o.isMissing()) {
					s.missing++;
					consecutiveFailures = 0;
				} else {
					s.failed++;
					consecutiveFailures++;
					logger.warn("[FileBackup] 실패 ft_id={} dvId={} kind={} file={} code={} 시도={}", ftId, rowDv, kind, name,
							o.errorCode, o.attempts);
				}

				if (consecutiveFailures >= props.getDeviceFailSkipThreshold()) {
					skipped.add(rowDv);
					synchronized (s.skippedDevices) {
						s.skippedDevices.add(rowDv);
					}
					logger.warn("[FileBackup] 장비 {} 연속 실패 {}회 → 이번 실행에서 건너뜀(남은 항목은 다음 실행)", rowDv,
							consecutiveFailures);
				}
			}
			s.state = "DONE";
		} catch (Throwable t) {
			s.state = "ERROR";
			s.error = t.getClass().getSimpleName();
			logger.error("[FileBackup] 실행 중 오류", t);
		} finally {
			s.finishedAt = ZonedDateTime.now(KST).format(ISO_DATETIME);
			logger.info(s.toLogLine());
		}
	}
}
