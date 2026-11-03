package com.disabled.service;

import java.util.List;
import java.util.Map;


public interface DeviceListService {
	List<Map<String, Object >> getDeviceList(Map<String,Object> paramMap);
	List<Map<String, Object >> getStatusList();   // 작업계획서 04: 디바이스 상태 실시간 조회
	String getDvIpByDvID(int dvId);
	Integer getTotalRecordCount(String searchKeyword, String endDate, String searchKeyword2);
	/** 목록 정렬·검색 조건 기준 해당 장비의 순번(1부터). 조건에 없거나 조회 실패면 null */
	Integer getDeviceRank(String startDate, String endDate, String searchKeyword, String sortCol, String sortDir, Integer dvId);
	void insertDeviceInfo(String dvName, String dvAddr, String dvAddrDetail, String dvIp, Integer dvStatus, String dvSerialNumber, String dvLat, String dvLng);
	void deleteDeviceInfo(List<Integer> dvIds);
	void updateDeviceInfo(Integer dvId, String dvName, String dvAddr, String dvAddrDetail, String dvIp, Integer dvStatus, String dvSerialNumber, String dvLat, String dvLng);
	Map<String, Object > getDeviceInfo(Integer dvId);
	boolean duplicatedNameAndAddr(Map<String, Object> body);
}
