package com.disabled.service.impl;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.disabled.mapper.MyInfoMapper;
import com.disabled.service.MyInfoService;

@Service
@Transactional(rollbackFor = Exception.class)
public class MyInfoServiceImpl implements MyInfoService{

	@Autowired
	MyInfoMapper myInfoMapper;
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(MyInfoServiceImpl.class);
	
	/**
	 * 사용자 정보 가져오기
	 * @param	uIdStr 회원 ID 
	 * @return	myInfoMap 사용자 정보 Map
	 */
	@Override
	public Map<String, Object> getMyInfoMap(Map<String, Object> paramMap) {
		
		Map<String, Object> myInfoMap = new HashMap<String, Object>();
		
		try {
			myInfoMap = myInfoMapper.getMyInfoMap(paramMap);
		} catch (DataAccessException e) {
			logger.error("SQL문 수행 도중 오류 발생, myInfoMapper.getMyInfoMap() : ",e);
			throw e;
		}
		
		return myInfoMap;
	}
}
