package com.disabled.service;

import java.util.List;
import java.util.Map;

/**
 * 대시보드 지도기반 페이지 서비스 (작업계획서 10)
 */
public interface DashboardService {

	/** 지도 표시용 디바이스 리스트 (좌표·이름·주소·상태 5종·갱신시각) */
	List<Map<String, Object>> getDeviceMapList();

	/** 마커 오버 시 팝업 상세 (기본정보 + 오늘 처리 건수) */
	Map<String, Object> getDeviceDetail(Integer dvId);

	/** (작업계획서 12) 우측 카드 — 오늘 전체 처리 합계 (계도/단속) */
	Map<String, Object> getTodaySummary();

	/** (작업계획서 12) 하단 최근 이벤트 요약 N건 */
	List<Map<String, Object>> getRecentEvents(int limit);

	/** (작업계획서 14) 디바이스 상태 요약 — 정상/이상 건수 */
	Map<String, Object> getDeviceStatusSummary();

	/** (작업계획서 14) 최근 SIP 통화 N건 (대시보드 우하단 위젯) */
	List<Map<String, Object>> getRecentSipCalls(int limit);
}
