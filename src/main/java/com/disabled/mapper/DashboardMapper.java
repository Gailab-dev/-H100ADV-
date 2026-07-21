package com.disabled.mapper;

import java.util.List;
import java.util.Map;

import org.egovframe.rte.psl.dataaccess.mapper.Mapper;
import org.springframework.stereotype.Repository;

/**
 * 대시보드 지도기반 페이지 SQL (작업계획서 10 / DB설계서 v0.0.8)
 *  - MapperScannerConfigurer(basePackage=com.disabled.mapper)로 자동 등록.
 *
 * DB v0.0.8 정합:
 *  - 상태는 5종(dv_status_pc/cctv/lens/speaker/sip). dv_status_display 는 v0.0.8 에도 미존재로 제외(04/05 일관).
 *  - dv_addr_detail(varchar200 NULL) 은 v0.0.8 정합 → 조회 포함. (Postcode 통합 등록화면은 후속 deviceRegist 작업)
 */
@Mapper
@Repository
public interface DashboardMapper {

	// 지도 표시용 디바이스 리스트 (좌표 있는 것만)
	List<Map<String, Object>> selectDeviceMapList() throws IllegalStateException;

	// 팝업 기본 정보(단건)
	Map<String, Object> selectDeviceBasic(Integer dvId) throws IllegalStateException;

	// 오늘 처리 건수 (ev_action 별: 계도/단속/과태료)
	Map<String, Object> selectTodayEventCount(Integer dvId) throws IllegalStateException;

	// (작업계획서 12) 우측 카드 — 오늘 전체 디바이스 처리 합계 (계도/단속)
	Map<String, Object> selectTodaySummary() throws IllegalStateException;

	// (작업계획서 12) 하단 최근 이벤트 요약 N건
	List<Map<String, Object>> selectRecentEvents(Integer limit) throws IllegalStateException;

	// (작업계획서 14) 디바이스 상태 요약 — 정상/이상 건수
	Map<String, Object> selectDeviceStatusSummary() throws IllegalStateException;

	// (작업계획서 14) 최근 SIP 통화 N건 (대시보드 우하단 위젯)
	List<Map<String, Object>> selectRecentSipCalls(Integer limit) throws IllegalStateException;
}
