package com.disabled.service.impl;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;

import com.disabled.controller.DeviceListController;
import com.disabled.mapper.DeviceListMapper;
import com.disabled.service.DeviceListService;

@Service
public class DeviceListServiceImpl implements DeviceListService{

	@Autowired
	DeviceListMapper deviceListMapper;
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(DeviceListServiceImpl.class);
	
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
		
		try {
			deviceList = deviceListMapper.getDeviceInfo();
		} catch (DataAccessException e) {
			logger.error("SQL문 수행 도중 오류 발생, deviceListMapper.getDeviceInfo() : ",e);
		}
		
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
		
		String dvIp = null;
		
		try {
			dvIp =  deviceListMapper.getDvIpByDvId(dvId);
		} catch (DataAccessException e) {
			logger.error("SQL문 수행 도중 오류 발생, deviceListMapper.getDvIpByDvId(dvId) : ",e);
		}
		
		return dvIp;
	}

}
