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
}
