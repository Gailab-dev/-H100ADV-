package com.disabled.service.impl;

import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.disabled.mapper.UserManageMapper;
import com.disabled.service.UserManageService;

@Service
@Transactional
public class UserManageServiceImpl implements UserManageService{
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(UserManageServiceImpl.class);
	
	@Autowired
	UserManageMapper userManageMapper;
	
	/**
	 * 검색 조건에 따른 레코드 갯수
	 */
	@Override
	public int getTotalRecordCount(Map<String, Object> paramMap) {
		
		try {
			
			return userManageMapper.getTotalRecordCount(paramMap);
			
		} catch (IllegalStateException e) {
			logger.error("getTotalRecordCount 함수를 실행하는 도중 SQL 오류 발생 : ",e);
			throw e;
		} catch (RuntimeException e2) {
			logger.error("getTotalRecordCount 함수를 실행하는 도중 오류 발생 : ",e2);
			throw e2;
		}
	}
	
	/**
	 * 회원 관리 리스트
	 */
	@Override
	public List<Map<String, Object>> getUserManageList(Map<String, Object> paramMap) {
		
		try {
			
			List<Map<String, Object>> resultList = userManageMapper.getUserManageList(paramMap); 
			
			
		} catch (IllegalStateException e) {
			logger.error("getUserManageList 함수를 실행하는 도중 SQL 오류 발생 : ",e);
			throw e;
		} catch (RuntimeException e2) {
			logger.error("getUserManageList 함수를 실행하는 도중 오류 발생 : ",e2);
			throw e2;
		}
		
		return null;
	}
	
	/**
	 * 최고 관리자의 지역 가져오기
	 */
	@Override
	public Integer getRegionByAdmin(Integer uId) {
		
		try {
			Integer uRegion = userManageMapper.getRegionByAdmin(uId);
			if(uRegion == null) {
				logger.error("지역값이 null입니다.");
				return null;
			}
			return uRegion;
		} catch (IllegalStateException e2) {
			logger.error("userManageMapper.getRegionByAdmin SQL 문에서 오류 발생");
			throw e2;
		} catch (RuntimeException e) {
			logger.error("userManageMapper.getRegionByAdmin에서 오류 발생");
			throw e;
		} 
	}
	
}
