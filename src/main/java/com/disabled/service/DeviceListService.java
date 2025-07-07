package com.disabled.service;

import java.util.List;
import java.util.Map;


public interface DeviceListService {
	List<Map<String, Object >> getDeviceList();
	String getDvIpByDvID(int dvId);
	
}
