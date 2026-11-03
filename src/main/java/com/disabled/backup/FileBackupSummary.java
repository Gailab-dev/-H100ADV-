package com.disabled.backup;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 백업 1회 실행 요약(일일 요약 로그·관리자 상태 조회용). 실행 스레드만 값을 쓰고 다른 스레드는 읽기만 한다.
 */
public class FileBackupSummary {

	/** RUNNING / DONE / ERROR */
	public volatile String state = "RUNNING";
	/** SCHEDULED / MANUAL */
	public String trigger;
	/** 대상일(KST, yyyy-MM-dd) */
	public String targetDate;
	/** 날짜를 관리자가 지정했는지(지정 재처리) */
	public boolean explicitDate;
	/** 장비 지정(없으면 전체) */
	public Integer dvId;
	public String startedAt;
	public volatile String finishedAt;

	/** 이번 실행에서 새로 PENDING 등록한 건수 */
	public volatile int registered;
	/** 날짜 지정 재처리로 PENDING 으로 되돌린 건수 */
	public volatile int requeued;
	/** 재시도 기한 경과로 LOST 확정한 건수 */
	public volatile int lost;
	/** 처리 대상(PENDING/FAILED) 건수 */
	public volatile int candidates;
	/** 이번에 장비에서 받아 검증 완료한 건수 */
	public volatile int transferred;
	/** 이미 서버에 있어 장비 호출 없이 검증 완료한 건수 */
	public volatile int alreadyOnServer;
	public volatile int failed;
	/** 장비에도 없음(MISSING) */
	public volatile int missing;
	/** 장비 연속 실패로 이번 실행에서 건너뛴 파일 수 */
	public volatile int skippedFiles;
	public final List<Integer> skippedDevices = new ArrayList<Integer>();
	public volatile String error;

	public Map<String, Object> toMap() {
		Map<String, Object> m = new LinkedHashMap<String, Object>();
		m.put("state", state);
		m.put("trigger", trigger);
		m.put("targetDate", targetDate);
		m.put("explicitDate", explicitDate);
		m.put("dvId", dvId);
		m.put("startedAt", startedAt);
		m.put("finishedAt", finishedAt);
		m.put("registered", registered);
		m.put("requeued", requeued);
		m.put("lost", lost);
		m.put("candidates", candidates);
		m.put("transferred", transferred);
		m.put("alreadyOnServer", alreadyOnServer);
		m.put("failed", failed);
		m.put("missing", missing);
		m.put("skippedFiles", skippedFiles);
		synchronized (skippedDevices) {
			m.put("skippedDevices", new ArrayList<Integer>(skippedDevices));
		}
		m.put("error", error);
		return m;
	}

	/** 일일 요약 로그 한 줄: 대상 N / 성공 / 실패 / 장비 누락(MISSING) / 이미 있음 */
	public String toLogLine() {
		return "[FileBackup] 요약(" + trigger + ") 대상일=" + targetDate
				+ " | 신규등록=" + registered
				+ " | 처리대상=" + candidates
				+ " | 성공(전송)=" + transferred
				+ " | 이미 있음=" + alreadyOnServer
				+ " | 실패=" + failed
				+ " | 장비 누락(MISSING)=" + missing
				+ " | 기한 경과(LOST)=" + lost
				+ " | 건너뛴 장비=" + skippedDevices.size() + "(파일 " + skippedFiles + "건)"
				+ (error == null ? "" : " | 오류=" + error);
	}
}
