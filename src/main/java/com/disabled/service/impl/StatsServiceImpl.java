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

import com.disabled.mapper.LoginMapper;
import com.disabled.mapper.StatsMapper;
import com.disabled.service.StatsService;

@Service
public class StatsServiceImpl implements StatsService{
	
	@Autowired
	LoginMapper loginMapper;
	
	@Autowired
	StatsMapper statsMapper;
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(StatsServiceImpl.class);
	
	/*
	 * 월별 통계 데이터를 조회하여 리스트로 반환
	 * @Param
	 * - startDate: 검색 시작일(String)
	 * - endDate: 검색 마지막일(String)
	 * - 
	 */
	@Override
	public List<Map<String, Object>> getEventByMonth(String startDate, String endDate) {
		
		List<Map<String, Object>> getEventByMonth = new ArrayList<Map<String,Object>>();
		
		try {
			
			Map<String,Object> param = new HashMap<String, Object>();
			param.put("startDate", startDate);
			param.put("endDate", endDate);
			
			getEventByMonth = statsMapper.getEventByMonth(param);
		} catch (DataAccessException e) {
			
			logger.error("SQL문 처리 도중 오류 발생 getEventByMonth(String startDate, String endDate) : ",e);
			
		}
		
		return getEventByMonth;
	}
	
	/*
	 * 통계 데이터 화면에 출력
	 */
	@Override
	public List<Map<String, Object>> getEventByMonth() {
		List<Map<String, Object>> getEventByMonth = new ArrayList<Map<String,Object>>();
		
		try {
			getEventByMonth = statsMapper.getAllEvent();
		} catch (DataAccessException e) {
			
			logger.error("SQL문 처리 도중 오류 발생 getEventByMonth() : ",e);
		}
		
		return getEventByMonth;
	}

	@Override
	public List<Map<String, Object>> getEventByMonthAndSearchParams(String startDate, String endDate, Integer stCd) {
		List<Map<String, Object>> resultList = new ArrayList<Map<String,Object>>();
		
		
		try {
			resultList = statsMapper.getEventByMonthAndSearchParams(startDate, endDate, stCd);
		} catch (DataAccessException e) {
			
			logger.error("SQL문 처리 도중 오류 발생 getEventByMonth() : ",e);
		}
		
		return resultList;
	}
	
}
