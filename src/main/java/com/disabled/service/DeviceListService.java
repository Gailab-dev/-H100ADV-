package com.disabled.service;

import java.util.List;
import java.util.Map;


public interface DeviceListService {
	List<Map<String, Object >> getDeviceList(Map<String,Object> paramMap);
	List<Map<String, Object >> getStatusList();   // 작업계획서 04: 디바이스 상태 실시간 조회
	String getDvIpByDvID(int dvId);
	Integer getTotalRecordCount(String searchKeyword, String endDate, String searchKeyword2);
	void insertDeviceInfo(String dvName, String dvAddr, String dvIp, Integer dvStatus, String dvSerialNumber);
	void deleteDeviceInfo(List<Integer> dvIds);
	void updateDeviceInfo(Integer dvId, String dvName, String dvAddr, String dvIp, Integer dvStatus, String dvSerialNumber);
	Map<String, Object > getDeviceInfo(Integer dvId);
	boolean duplicatedNameAndAddr(Map<String, Object> body);
}
