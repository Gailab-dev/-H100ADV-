package com.disabled.service;

import java.io.File;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public interface EventListService {
	List<Map<String, Object>> getEventList();
	List<Map<String, Object>> getEventList(Map<String, Object> paramMap);
	Integer getEventListCount();
	Map<String, Object> getEventListDetail(Integer evId);
	void viewImageOfFilePath(File file, HttpServletResponse res);
	void viewVideoOfFilePath(File file, HttpServletRequest req, HttpServletResponse res);
	void mkdirForStream(String filePath);
	String mkFullFilePath(String filePath);
	void fileCheck(File file);
	void requestFileFromModule(HttpServletResponse res, Integer evId, Map<String, Object> eventListDetail);
	String getDvIpByEvId(Integer evId);
	int getTotalRecordCount(String startDate, String endDate, String searchKeyword);
}
