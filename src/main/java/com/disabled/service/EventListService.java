package com.disabled.service;

import java.io.File;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public interface EventListService {
	List<Map<String, Object>> getEventList(Map<String, Object> paramMap);
	Map<String, Object> getEventListDetail(Integer evId);
	Map<String, Object> getEventListDetail(Integer evId, Integer evId2);
	void viewImageOfFilePath(File file, HttpServletResponse res);
	void viewVideoOfFilePath(File file, HttpServletRequest req, HttpServletResponse res);
	void mkdirForStream(String filePath);
	String mkFullFilePath(String filePath);
	void fileCheck(File file);
	boolean requestFileFromModule(HttpServletResponse res, Integer dvId, Integer evId, Map<String, Object> eventListDetail);
	boolean requestFileDec(HttpServletResponse res, Integer evId, Map<String, Object> eventListDetail);

	// ====== ADR-008 디바이스 통신 우선순위 변경 (서버 파일 우선, AJAX 단계별 호출) ======
	boolean encImagesExistOnServer(Map<String, Object> eventListDetail);
	String fetchFromDevice(HttpServletResponse res, Integer dvId, Integer evId, Map<String, Object> eventListDetail);
	boolean decryptForView(Map<String, Object> eventListDetail);

	// ====== ADR-008 (2026-06-25) .enc 없을 때 평문 원본(dec 디렉토리) fallback ======
	boolean plainImagesExistOnServer(Map<String, Object> eventListDetail);

	// ====== 30번 — 영상 PULL 폴백 누락 수정: 이미지 존재 여부만으로 fetchFromDevice 스킵 여부를
	// 판단하던 기존 로직이 "이미지는 있는데 영상만 없는" 경우를 놓쳤다. 영상 준비 여부를 별도로
	// 확인해, 이미지 존재 여부와 함께 fetchFromDevice 호출 필요성을 판단한다.
	boolean videoReadyOnServer(Map<String, Object> eventListDetail);
	String getDvIpByEvId(Integer dvId, Integer evId);
	int getTotalRecordCount(Map<String, Object> paramMap);

    List<Map<String, Object>> getEventCountByEvCd(Map<String, Object> paramMap);

	// ====== 패치 2026-09-30 — 상세보기 이전/다음 탐색, 소프트 삭제 ======
	/**
	 * @param paramMap getEventList 와 동일한 검색조건·정렬기준(searchKeyword/startDate/endDate/evCd/evAction/sortCol/sortDir)
	 *                 + currentEvId(기준 이벤트) + step(다음=+1, 이전=-1)
	 * @return 인접한 이벤트의 ev_id, 없으면 null(첫/마지막 항목)
	 */
	Integer getAdjacentEventId(Map<String, Object> paramMap);

	/**
	 * 소프트 삭제(플래그만 세움, 파일·row는 유지) — 목록 다중 선택 삭제·상세보기 단건 삭제 공용
	 * @param evIds 삭제할 이벤트 ID 목록
	 * @param deletedBy 삭제 처리한 사용자 u_id
	 * @return 실제로 삭제 처리된 건수
	 */
	int softDeleteEvents(List<Integer> evIds, Integer deletedBy);
}
