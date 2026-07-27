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
	String getDvIpByEvId(Integer dvId, Integer evId);
	int getTotalRecordCount(Map<String, Object> paramMap);

    List<Map<String, Object>> getEventCountByEvCd(Map<String, Object> paramMap);
}
