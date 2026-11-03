package com.disabled.backup;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.disabled.backup.DeviceFileFetcher.FetchOutcome;
import com.disabled.backup.ServerFileLocator.ServerFile;
import com.disabled.mapper.FileTransferMapper;
import com.disabled.mapper.NotificationMapper;
import com.disabled.service.EventListService;

/**
 * 이벤트 삭제 흐름 — 작업계획서 39 WP-6.
 *
 * <ol>
 *   <li>check: 선택한 이벤트의 이미지·영상 서버 파일을 확인한다(이력 등록 + 서버 디스크 검증).
 *       모두 있으면 바로 DONE. 없는 파일이 있으면 비동기 작업으로 장비에서 내려받는다(RUNNING → 진행 팝업).</li>
 *   <li>내려받기 결과: 성공은 VERIFIED, 장비에도 없음(NO_FILE)은 MISSING(확인 후 삭제 허용),
 *       장비 오프라인·실패는 BLOCKED(삭제 중단 + 사유 안내).</li>
 *   <li>confirm: BLOCKED 가 하나라도 있으면 아무것도 삭제하지 않는다(전부-아니면-없음). MISSING 이 있으면
 *       사용자가 "그래도 삭제"를 확인(allowMissing)해야 한다. 삭제는 기존 소프트 삭제(ev_is_deleted)를 쓰고
 *       이력을 DELETED_EVENT 로 바꾸며 해당 이벤트의 알림을 삭제한다.</li>
 * </ol>
 *
 * <p>작업 상태는 메모리에 둔다(단일 웹 인스턴스 가정, 요청자(u_id) 본인만 조회·확정 가능, 30분 후 폐기).</p>
 */
@Service
public class EventDeleteFlowService {

	private static final Logger logger = LoggerFactory.getLogger(EventDeleteFlowService.class);

	/** 한 번에 선택할 수 있는 최대 이벤트 수 */
	public static final int MAX_EVENTS = 200;

	/** 작업 보관 시간(ms) */
	private static final long JOB_TTL_MS = 30L * 60 * 1000;

	/** 확인 완료 후 삭제 확정까지 허용하는 시간(ms) — 지나면 다시 확인해야 한다 */
	private static final long CONFIRM_VALID_MS = 10L * 60 * 1000;

	private static final String ITEM_TODO = "TODO";
	private static final String ITEM_OK = "OK";
	private static final String ITEM_MISSING = "MISSING";
	private static final String ITEM_FAILED = "FAILED";

	private static final String EV_READY = "READY";
	private static final String EV_NEEDS_CONFIRM = "NEEDS_CONFIRM";
	private static final String EV_BLOCKED = "BLOCKED";
	private static final String EV_GONE = "GONE";

	@Autowired
	private FileTransferMapper fileTransferMapper;

	@Autowired
	private FileTransferHistoryService history;

	@Autowired
	private DeviceFileFetcher fetcher;

	@Autowired
	private ServerFileLocator locator;

	@Autowired
	private FileBackupProperties props;

	@Autowired
	private EventListService eventListService;

	@Autowired
	private NotificationMapper notificationMapper;

	private final Map<String, Job> jobs = new ConcurrentHashMap<String, Job>();

	private ExecutorService executor;

	@PostConstruct
	void init() {
		executor = Executors.newFixedThreadPool(2, r -> {
			Thread t = new Thread(r, "event-delete-pull");
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

	// ------------------------------------------------------------------ 모델

	private static final class FileItem {
		FileKind kind;
		String name;
		long ftId;
		Long knownBytes;
		volatile String result = ITEM_TODO;
		volatile String errorCode;
	}

	private static final class EventCheck {
		int evId;
		Integer dvId;
		String dvIp;
		final List<FileItem> items = new ArrayList<FileItem>();
		String result = EV_READY;
		String reason;
	}

	private static final class Job {
		final String id = UUID.randomUUID().toString();
		final int ownerUId;
		final long createdAt = System.currentTimeMillis();
		final List<EventCheck> checks = new ArrayList<EventCheck>();
		volatile String state = "RUNNING";
		volatile long doneAt;
		volatile int pullTotal;
		final AtomicInteger pullDone = new AtomicInteger();

		Job(int ownerUId) {
			this.ownerUId = ownerUId;
		}
	}

	// ------------------------------------------------------------------ 1단계: 확인

	/**
	 * 삭제 전 파일 확인을 시작한다. 서버에 이미 다 있으면 즉시 DONE 상태의 작업을 돌려주고,
	 * 내려받을 파일이 있으면 비동기로 진행하는 RUNNING 작업을 돌려준다.
	 */
	public Map<String, Object> startCheck(List<Integer> rawEvIds, int uId) {
		Set<Integer> unique = new LinkedHashSet<Integer>(rawEvIds);
		List<Integer> evIds = new ArrayList<Integer>(unique);
		if (evIds.isEmpty() || evIds.size() > MAX_EVENTS) {
			return fail("BAD_REQUEST", "삭제할 항목 수가 올바르지 않습니다(1~" + MAX_EVENTS + "건).");
		}
		purgeOldJobs();

		Job job = new Job(uId);
		try {
			// 1단계(동기): 이력 등록 + 서버 디스크 검증. 내려받을 파일을 추린다.
			for (Integer evId : evIds) {
				job.checks.add(prepare(evId));
			}
		} catch (RuntimeException e) {
			logger.error("[EventDelete] 파일 확인 준비 중 오류(전송 이력 테이블 확인 필요)", e);
			return fail("CHECK_FAILED", "삭제 전 파일 확인 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.");
		}

		int todo = 0;
		for (EventCheck c : job.checks) {
			for (FileItem it : c.items) {
				if (ITEM_TODO.equals(it.result)) {
					todo++;
				}
			}
		}
		job.pullTotal = todo;
		jobs.put(job.id, job);

		if (todo == 0) {
			finishJob(job);
		} else {
			// 2단계(비동기): 없는 파일만 장비에서 내려받는다.
			try {
				executor.submit(() -> runPulls(job));
			} catch (RuntimeException e) {
				jobs.remove(job.id);
				logger.error("[EventDelete] 내려받기 작업 시작 실패", e);
				return fail("CHECK_FAILED", "삭제 전 파일 확인을 시작하지 못했습니다. 잠시 후 다시 시도해 주세요.");
			}
		}
		return view(job);
	}

	/** 이벤트 한 건의 기대 파일을 이력에 등록하고 서버 디스크를 확인한다(장비 호출 없음) */
	private EventCheck prepare(Integer evId) {
		EventCheck c = new EventCheck();
		c.evId = evId;

		Map<String, Object> ev = fileTransferMapper.selectEventForBackup(evId);
		if (ev == null || toInt(ev.get("ev_is_deleted")) != 0) {
			c.result = EV_GONE;
			return c;
		}
		c.dvId = ev.get("ev_dv_id") == null ? null : toInt(ev.get("ev_dv_id"));
		c.dvIp = ev.get("dv_ip") == null ? null : ev.get("dv_ip").toString();

		history.registerForEvent(evId);
		Map<String, Map<String, Object>> rowsByKind = new HashMap<String, Map<String, Object>>();
		for (Map<String, Object> row : history.findByEvent(evId)) {
			rowsByKind.put(String.valueOf(row.get("ft_file_kind")), row);
		}

		addItem(c, rowsByKind, FileKind.EVENT_IMAGE1, ev.get("ev_img_path"));
		addItem(c, rowsByKind, FileKind.EVENT_IMAGE2, ev.get("ev_img_path2"));
		addItem(c, rowsByKind, FileKind.EVENT_VIDEO, ev.get("ev_mov_path"));
		return c;
	}

	private void addItem(EventCheck c, Map<String, Map<String, Object>> rowsByKind, FileKind kind, Object rawName) {
		if (rawName == null || rawName.toString().isBlank() || "null".equals(rawName.toString().trim())) {
			return; // 이 이벤트에는 해당 파일이 없다
		}
		FileItem it = new FileItem();
		it.kind = kind;
		it.name = rawName.toString().trim();

		Map<String, Object> row = rowsByKind.get(kind.name());
		if (row == null) {
			it.result = ITEM_FAILED;
			it.errorCode = "HISTORY_MISSING";
			c.items.add(it);
			return;
		}
		it.ftId = ((Number) row.get("ft_id")).longValue();
		if ("SIZE_MISMATCH".equals(row.get("ft_last_error_code")) && row.get("ft_device_bytes") != null) {
			it.knownBytes = ((Number) row.get("ft_device_bytes")).longValue();
		}

		if (!ServerFileLocator.isSafeName(it.name)) {
			it.result = ITEM_FAILED;
			it.errorCode = "UNSAFE_NAME";
		} else {
			// 이력이 VERIFIED 여도 디스크가 실제 기준이다(디스크에 없으면 다시 받는다).
			ServerFile sf = locator.find(kind, it.name, it.knownBytes);
			if (sf != null) {
				it.result = ITEM_OK;
				if (!TransferStatus.VERIFIED.equals(row.get("ft_status"))) {
					history.applyOutcome(it.ftId, kind, c.evId, FetchOutcome.verified(null, sf.bytes, 0, true));
				}
			}
		}
		c.items.add(it);
	}

	/** 비동기 내려받기. 장비가 응답하지 않으면 같은 장비의 남은 파일은 시도하지 않고 같은 사유로 실패 처리한다 */
	private void runPulls(Job job) {
		Map<Integer, String> downDevices = new HashMap<Integer, String>();
		try {
			for (EventCheck c : job.checks) {
				for (FileItem it : c.items) {
					if (!ITEM_TODO.equals(it.result)) {
						continue;
					}
					Integer dv = c.dvId == null ? Integer.valueOf(-1) : c.dvId;
					if (downDevices.containsKey(dv)) {
						it.result = ITEM_FAILED;
						it.errorCode = downDevices.get(dv);
						job.pullDone.incrementAndGet();
						continue;
					}
					FetchOutcome o = fetcher.fetch(it.kind, it.name, c.dvIp, it.knownBytes,
							props.getDeletePullTimeoutSeconds(), 0);
					history.applyOutcome(it.ftId, it.kind, c.evId, o);
					if (o.isVerified()) {
						it.result = ITEM_OK;
					} else if (o.isMissing()) {
						it.result = ITEM_MISSING;
					} else {
						it.result = ITEM_FAILED;
						it.errorCode = o.errorCode;
						if (o.isDeviceLevelFailure()) {
							downDevices.put(dv, o.errorCode);
						}
					}
					job.pullDone.incrementAndGet();
				}
			}
			finishJob(job);
		} catch (Throwable t) {
			logger.error("[EventDelete] 내려받기 작업 중 오류", t);
			job.state = "ERROR";
			job.doneAt = System.currentTimeMillis();
		}
	}

	/** 이벤트별 결과 확정 후 DONE */
	private void finishJob(Job job) {
		for (EventCheck c : job.checks) {
			if (EV_GONE.equals(c.result)) {
				continue;
			}
			boolean anyFailed = false;
			boolean anyMissing = false;
			String failedCode = null;
			for (FileItem it : c.items) {
				if (ITEM_FAILED.equals(it.result)) {
					anyFailed = true;
					if (failedCode == null) {
						failedCode = it.errorCode;
					}
				} else if (ITEM_MISSING.equals(it.result)) {
					anyMissing = true;
				}
			}
			if (anyFailed) {
				c.result = EV_BLOCKED;
				c.reason = reasonText(failedCode);
			} else if (anyMissing) {
				c.result = EV_NEEDS_CONFIRM;
			} else {
				c.result = EV_READY;
			}
		}
		job.doneAt = System.currentTimeMillis();
		job.state = "DONE";
	}

	// ------------------------------------------------------------------ 진행 조회

	public Map<String, Object> status(String jobId, int uId) {
		Job job = owned(jobId, uId);
		if (job == null) {
			return fail("JOB_NOT_FOUND", "확인 결과가 없습니다. 다시 시도해 주세요.");
		}
		return view(job);
	}

	private Map<String, Object> view(Job job) {
		Map<String, Object> m = new LinkedHashMap<String, Object>();
		m.put("success", !"ERROR".equals(job.state));
		m.put("jobId", job.id);
		m.put("state", job.state);
		m.put("total", job.checks.size());
		m.put("pullTotal", job.pullTotal);
		m.put("pullDone", job.pullDone.get());
		if ("ERROR".equals(job.state)) {
			m.put("code", "CHECK_FAILED");
			m.put("message", "이미지·영상을 내려받는 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.");
		}
		if ("DONE".equals(job.state)) {
			int ready = 0, needs = 0, blocked = 0, gone = 0;
			List<Map<String, Object>> blockedList = new ArrayList<Map<String, Object>>();
			for (EventCheck c : job.checks) {
				if (EV_READY.equals(c.result)) {
					ready++;
				} else if (EV_NEEDS_CONFIRM.equals(c.result)) {
					needs++;
				} else if (EV_GONE.equals(c.result)) {
					gone++;
				} else {
					blocked++;
					Map<String, Object> b = new LinkedHashMap<String, Object>();
					b.put("evId", c.evId);
					b.put("reason", c.reason);
					blockedList.add(b);
				}
			}
			m.put("readyCount", ready);
			m.put("missingCount", needs);
			m.put("blockedCount", blocked);
			m.put("goneCount", gone);
			m.put("blocked", blockedList);
		}
		return m;
	}

	// ------------------------------------------------------------------ 2단계: 삭제 확정

	public Map<String, Object> confirm(String jobId, int uId, boolean allowMissing) {
		Job job = owned(jobId, uId);
		if (job == null) {
			return fail("JOB_NOT_FOUND", "확인 결과가 만료되었습니다. 다시 시도해 주세요.");
		}
		if (!"DONE".equals(job.state)) {
			return fail("NOT_READY", "아직 파일 확인이 끝나지 않았습니다.");
		}
		if (System.currentTimeMillis() - job.doneAt > CONFIRM_VALID_MS) {
			jobs.remove(job.id);
			return fail("JOB_EXPIRED", "확인 후 시간이 지났습니다. 다시 시도해 주세요.");
		}

		Map<String, Object> v = view(job);
		if (((Number) v.get("blockedCount")).intValue() > 0) {
			Map<String, Object> m = fail("BLOCKED", "일부 이벤트의 파일을 장비에서 내려받지 못해 삭제하지 않았습니다.");
			m.put("blocked", v.get("blocked"));
			return m;
		}
		if (((Number) v.get("missingCount")).intValue() > 0 && !allowMissing) {
			Map<String, Object> m = fail("MISSING_CONFIRM_REQUIRED", "파일이 존재하지 않는 이벤트가 있습니다. 확인이 필요합니다.");
			m.put("missingCount", v.get("missingCount"));
			return m;
		}

		List<Integer> deletable = new ArrayList<Integer>();
		for (EventCheck c : job.checks) {
			if (EV_READY.equals(c.result) || (allowMissing && EV_NEEDS_CONFIRM.equals(c.result))) {
				deletable.add(c.evId);
			}
		}
		jobs.remove(job.id);
		if (deletable.isEmpty()) {
			return fail("NOTHING_TO_DELETE", "삭제할 수 있는 이벤트가 없습니다(이미 삭제되었거나 존재하지 않습니다).");
		}

		int deleted = finalizeDelete(deletable, uId);
		Map<String, Object> m = new LinkedHashMap<String, Object>();
		m.put("success", deleted > 0);
		m.put("deletedCount", deleted);
		return m;
	}

	/**
	 * 삭제 확정 공통 처리: 소프트 삭제(ev_is_deleted) → 이력 DELETED_EVENT 기록 → 해당 이벤트 알림 삭제.
	 * 이력·알림 후처리 실패는 이미 끝난 소프트 삭제를 되돌리지 않고 로그로 남긴다.
	 * @return 실제로 소프트 삭제된 건수
	 */
	public int finalizeDelete(List<Integer> evIds, Integer deletedBy) {
		int deleted = eventListService.softDeleteEvents(evIds, deletedBy);
		if (deleted <= 0) {
			return deleted;
		}
		List<Integer> reallyDeleted = new ArrayList<Integer>();
		for (Integer evId : new HashSet<Integer>(evIds)) {
			try {
				Map<String, Object> ev = fileTransferMapper.selectEventForBackup(evId);
				if (ev != null && toInt(ev.get("ev_is_deleted")) == 1) {
					reallyDeleted.add(evId);
				}
			} catch (RuntimeException e) {
				logger.error("[EventDelete] 삭제 결과 확인 실패 evId={}", evId, e);
			}
		}
		for (Integer evId : reallyDeleted) {
			try {
				history.markEventDeleted(evId, deletedBy, locator);
			} catch (RuntimeException e) {
				logger.error("[EventDelete] 전송 이력 DELETED_EVENT 기록 실패 evId={}", evId, e);
			}
		}
		if (!reallyDeleted.isEmpty()) {
			try {
				Map<String, Object> p = new HashMap<String, Object>();
				p.put("evIds", reallyDeleted);
				int n = notificationMapper.deleteByEventIds(p);
				logger.info("[EventDelete] 삭제된 이벤트의 알림 {}건 삭제 evIds={}", n, reallyDeleted);
			} catch (RuntimeException e) {
				logger.error("[EventDelete] 이벤트 알림 삭제 실패 evIds={}", reallyDeleted, e);
			}
		}
		return deleted;
	}

	// ------------------------------------------------------------------ 유틸

	private Job owned(String jobId, int uId) {
		if (jobId == null) {
			return null;
		}
		Job job = jobs.get(jobId);
		if (job == null || job.ownerUId != uId) {
			return null;
		}
		return job;
	}

	private void purgeOldJobs() {
		long now = System.currentTimeMillis();
		for (Map.Entry<String, Job> e : jobs.entrySet()) {
			if (now - e.getValue().createdAt > JOB_TTL_MS) {
				jobs.remove(e.getKey());
			}
		}
	}

	private static int toInt(Object o) {
		return o instanceof Number ? ((Number) o).intValue() : Integer.parseInt(String.valueOf(o));
	}

	private static Map<String, Object> fail(String code, String message) {
		Map<String, Object> m = new LinkedHashMap<String, Object>();
		m.put("success", false);
		m.put("code", code);
		m.put("message", message);
		return m;
	}

	/** 장비 오류 코드 → 사용자 안내 문구 */
	private static String reasonText(String code) {
		if (code == null) {
			return "장비에서 파일을 내려받지 못했습니다.";
		}
		switch (code) {
		case "DEVICE_UNREACHABLE":
			return "장비에 연결할 수 없습니다(오프라인).";
		case "TIMEOUT":
			return "장비 응답 시간이 초과되었습니다.";
		case "TLS_ERROR":
			return "장비와 보안 연결에 실패했습니다.";
		case "NO_DEVICE_IP":
			return "장비 주소 정보가 없어 파일을 내려받을 수 없습니다.";
		case "SERVER_REJECTED":
		case "SEND_FAILED":
			return "장비가 서버로 파일을 보내지 못했습니다.";
		case "SIZE_MISMATCH":
			return "받은 파일의 크기가 장비와 일치하지 않습니다.";
		case "NOT_ON_SERVER":
			return "장비는 전송했다고 응답했으나 서버에 파일이 저장되지 않았습니다.";
		default:
			return "장비에서 파일을 내려받지 못했습니다.";
		}
	}
}
