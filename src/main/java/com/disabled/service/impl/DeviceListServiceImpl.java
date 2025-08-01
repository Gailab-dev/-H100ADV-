package com.disabled.service.impl;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.disabled.mapper.DeviceListMapper;
import com.disabled.service.DeviceListService;

@Service
public class DeviceListServiceImpl implements DeviceListService{

	@Autowired
	DeviceListMapper deviceListMapper;
	
	/**
	 * 모든 디바이스 리스트를 가져오는 함수
	 * @return 디바이스 리스트(List)
	 *   - dv_id : 장치 ID (String)
	 *   - dv_name : 장치명 (String)
	 *   - dv_addr : 장치설치주소(String)
	 */
	@Override
	public List<Map<String, Object>>  getDeviceList() {
		
		List<Map<String, Object>> deviceList = new ArrayList<Map<String, Object>>();
		
		deviceList = deviceListMapper.getDeviceInfo();
		
		return deviceList;
	}
	
	/**
	 * 디바이스 id를 통해 해당 디바이스의 ip를 조회
	 * @param 
	 *   - dvId : 디바이스 ID (int)
	 * @return
	 *   - dvIp : 디바이스 IP (String)
	 */
	@Override
	public String getDvIpByDvID(int dvId) {
		
		return deviceListMapper.getDvIpByDvId(dvId);
	}

}
