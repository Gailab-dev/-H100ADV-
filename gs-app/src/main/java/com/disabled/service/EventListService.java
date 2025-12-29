package com.disabled.service;

import java.io.File;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public interface EventListService {
	List<Map<String, Object>> getEventList();
	List<Map<String, Object>> getEventList(Map<String, Object> paramMap);
	Map<String, Object> getEventListDetail(Integer evId, Integer evId2);
	void viewImageOfFilePath(File file, HttpServletResponse res);
	void viewVideoOfFilePath(File file, HttpServletRequest req, HttpServletResponse res);
	void mkdirForStream(String filePath);
	String mkFullFilePath(String filePath);
	void fileCheck(File file);
	boolean requestFileFromModule(HttpServletResponse res, Integer dvId, Integer evId, Map<String, Object> eventListDetail);
	boolean requestFileDec(HttpServletResponse res, Integer evId, Map<String, Object> eventListDetail);
	String getDvIpByEvId(Integer dvId, Integer evId);
	int getTotalRecordCount(String startDate, String endDate, String searchKeyword);
}
