package com.disabled.service.impl;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.disabled.mapper.DeviceListMapper;
import com.disabled.service.DeviceListService;

@Service
@Transactional(rollbackFor = Exception.class)
public class DeviceListServiceImpl implements DeviceListService{

	@Autowired
	DeviceListMapper deviceListMapper;
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(DeviceListServiceImpl.class);
	
	/**
	 * 모든 디바이스 리스트를 가져옴
	 * @return 디바이스 리스트(List)
	 *   - dv_id : 장치 ID (String)
	 *   - dv_name : 장치명 (String)
	 *   - dv_addr : 장치설치주소(String)
	 */
	@Override
	public List<Map<String, Object>>  getDeviceList(Map<String, Object> paramMap) {
		
		List<Map<String, Object>> deviceList = new ArrayList<Map<String, Object>>();
		
		try {
			deviceList = deviceListMapper.getDeviceInfo(paramMap);
		} catch (DataAccessException e) {
			logger.error("SQL문 수행 도중 오류 발생, deviceListMapper.getDeviceInfo() : ",e);
			throw e;
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
			throw e;
		}
		
		return dvIp;
	}

	@Override
	public Integer getTotalRecordCount(String searchKeyword) {
		
		try {
			return deviceListMapper.getTotalRecordCount(searchKeyword);
		} catch (RuntimeException e) {
			logger.error("SQL문 수행 도중 오류 발생, deviceListMapper.getTotalRecordCount(searchKeyword) : ",e);
			throw e;
		}
	}
	
	/**
	 * 디바이스 등록
	 * @param dvName		 디바이스명(String)
	 * @param dvAddr		 디바이스가 설치된 주소(String)
	 * @param dvIp			 디바이스에 부여된 IP(String)
	 * @param dvStatus		 디바이스 상태(Integer), 1:정상, 0:오류
	 * @param dvSerialNumber 디바이스의 고유 번호(String)
	 */
	@Override
	public void insertDeviceInfo(String dvName, String dvAddr, String dvIp, Integer dvStatus, String dvSerialNumber) {
		
		try {
			
			// 디바이스 등록
			Integer rows1 = deviceListMapper.insertDeviceInfo(dvName,dvAddr,dvIp,dvStatus,dvSerialNumber);
			if(rows1 != 1) {
				logger.error("deviceListMapper.insertDeviceInfo SQL문에서 오류 발생");
				throw new IllegalStateException("deviceListMapper.insertDeviceInfo SQL문에서 오류 발생");
			}
			
		} catch (IllegalStateException e) {
			logger.error("SQL문 수행 도중 오류 발생, deviceListMapper.insertDeviceInfo : ",e);
			throw e;
		}
		
	}

	// 디바이스 삭제
	@Override
	public void deleteDeviceInfo(List<Integer> dvIds) {
		
		try {
			
			for (Integer dvId : dvIds) {
				Integer rows1 = deviceListMapper.deleteDeviceInfo(dvId);
				if(rows1 != 1) {
					logger.error("deviceListMapper.deleteDeviceInfo SQL문에서 오류 발생");
					throw new IllegalStateException("deviceListMapper.deleteDeviceInfo SQL문에서 오류 발생");
				}
			}
		} catch (IllegalStateException e) {
			logger.error("SQL문 수행 도중 오류 발생, deviceListMapper.deleteDeviceInfo : ",e);
			throw e;
		}
		
	}
	
	/**
	 * 디바이스 수정
	 * @param dvId				디바이스ID(String)
	 * @param dvName			디바이스명(String)
	 * @param dvAddr			디바이스주소(String)
	 * @param dvIp				디바이스IP(String)
	 * @param dvStatus			디바이스 상태(Integer), 1:정상, 0:오류
	 * @param dvSerialNumber	시리얼번호(디바이스고유번호) (String)
	 */
	@Override
	public void updateDeviceInfo(Integer dvId, String dvName, String dvAddr, String dvIp, Integer dvStatus,String dvSerialNumber) {
		try {
			
			Integer rows1 = deviceListMapper.updateDeviceInfo(dvId,dvName,dvAddr,dvIp,dvStatus,dvSerialNumber);
			if(rows1 != 1) {
				logger.error("deviceListMapper.updateDeviceInfo SQL문에서 오류 발생");
				throw new IllegalStateException("deviceListMapper.updateDeviceInfo SQL문에서 오류 발생");
			}
			
		} catch (IllegalStateException e) {
			logger.error("SQL문 수행 도중 오류 발생, deviceListMapper.updateDeviceInfo : ",e);
			throw e;
		}
		
	}
	
	/**
	 * dvId를 검색조건으로 디바이스 1개 정보 가져오기
	 * @param dvId
	 * @return Map(디바이스 정보)
	 */
	@Override
	public Map<String,Object> getDeviceInfo(Integer dvId) {
		try {
			
			return deviceListMapper.getOneDeviceInfo(dvId);
			
		} catch (IllegalStateException e) {
			logger.error("SQL문 수행 도중 오류 발생, deviceListMapper.getDeviceInfo : ",e);
			throw e;
		}
		
	}
	
	/**
	 * 이름과 디바이스명이 중복인 디바이스 여부를 조회
	 * @param body
	 * @return true: 중복, false: 중복아님
	 */
	@Override
	public boolean duplicatedNameAndAddr(Map<String, Object> body) {
		
		try {
			int count = deviceListMapper.getDeviceCountDvNameAndAddr(body);
			return count > 0 ;
		} catch (IllegalStateException e) {
			logger.error("SQL문 수행 도중 오류 발생, deviceListMapper.getDeviceDvNameAndAddr : ",e);
			throw e;

		}
	}
}
