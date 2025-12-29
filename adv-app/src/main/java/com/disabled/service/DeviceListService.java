package com.disabled.service;

import java.util.List;
import java.util.Map;


public interface DeviceListService {
	List<Map<String, Object >> getDeviceList(Map<String,Object> paramMap);
	String getDvIpByDvID(int dvId);
	Integer getTotalRecordCount(String searchKeyword);
	void insertDeviceInfo(String dvName, String dvAddr, String dvIp, Integer dvStatus, String dvSerialNumber);
	void deleteDeviceInfo(List<Integer> dvIds);
	void updateDeviceInfo(Integer dvId, String dvName, String dvAddr, String dvIp, Integer dvStatus, String dvSerialNumber);
	Map<String, Object > getDeviceInfo(Integer dvId);
	boolean duplicatedNameAndAddr(Map<String, Object> body);
}
