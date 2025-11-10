package com.disabled.service.impl;

import java.util.HashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.disabled.mapper.LoginMapper;
import com.disabled.service.UserService;

@Service
@Transactional
public class UserServiceImpl implements UserService {

	@Autowired
	LoginMapper loginMapper;
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(UserServiceImpl.class);
	
	/*
	 * 아이디와 비밀번호를 통해 DB에 해당 계정이 있는지 확인
	 * @Param
	 * - id: 아이디(String)
	 * - pw: 비밀번호(String)
	 */
	@Override
	public Map<String,Object> loginCheck(String id, String pwd) {
		
		Map<String,Object> resultMap = new HashMap<String, Object>();
		
		try {
			resultMap = loginMapper.existUsrByIdAndPwd(id,pwd);
			if(resultMap == null) {
				logger.error("loginMapper.existUsrByIdAndPwd SQL문에서 오류 발생");
				throw new IllegalStateException("loginMapper.existUsrByIdAndPwd SQL문에서 오류 발생");
			}
			return resultMap;
		} catch (RuntimeException e) {
			
			logger.error("로그인 체크 오류 : ",e);
			throw e;
		} 
	}

	@Override
	public Integer updateNewPwd(Integer uId, String encryptPwd) {
		try {
			
			Integer rows1 = loginMapper.updateNewPwd(uId, encryptPwd);
			if(rows1 != 1) {
				logger.error("loginMapper.updateNewPwd SQL문에서 오류 발생");
				throw new IllegalStateException("loginMapper.updateNewPwd SQL문에서 오류 발생");
			}
			return rows1;
		} catch (IllegalStateException e) {
			logger.error("loginMapper.updateNewPwd SQL문에서 오류 발생",e);
			return 0;
		}
		
	}

	/**
	 * uId값으로 비밀번호 가져오기 
	 */
	@Override
	public String getPwd(Integer uId) {
		
		try {
			return loginMapper.getPwd(uId);
		} catch (IllegalStateException e) {
			logger.error("loginMapper.getPwd SQL문에서 오류 발생",e);
			return null;
		}
	}
	

	/**
	 * uId값으로 loginId 가져오기 
	 */
	@Override
	public String getLoginId(Integer uId) {
		try {
			return loginMapper.getLoginId(uId);
		} catch (IllegalStateException e) {
			logger.error("loginMapper.getLoginId SQL문에서 오류 발생",e);
			return null;
		}
	}

	/*
	@Override
	public Map<String, Object> getMyInfo(Integer uId) {
		try {
			return loginMapper.getMyInfo(uId);
		} catch (IllegalStateException e) {
			logger.error("loginMapper.getMyInfo SQL문에서 오류 발생",e);
			return null;
		}
		
	}
	
	// 추후 구현
	@Override
	public Integer updateMyInfoExceptPwd(Integer uId) {
		try {
			
			Integer rows1 = loginMapper.updateMyInfoExceptPwd(uId);
			if(rows1 != 1) {
				logger.error("loginMapper.updateMyInfoExceptPwd SQL문에서 오류 발생");
				throw new IllegalStateException("loginMapper.updateMyInfoExceptPwd SQL문에서 오류 발생");
			}
			return rows1;
			
			return 1;
		} catch (IllegalStateException e) {
			logger.error("loginMapper.updateMyInfoExceptPwd SQL문에서 오류 발생",e);
			return -1;
		}
	}

	// 추후 구현
	@Override
	public List<Map<String, Object>> getUserListManage(Map<String,Object> paramMap) {
		
		List<Map<String, Object>> resultMap = new ArrayList<Map<String,Object>>();
		
		try {
			// resultMap = loginMapper.getUserListManage(paramMap);
		} catch (IllegalStateException e) {
			logger.error("loginMapper.getUserListManage SQL문에서 오류 발생",e);
			return null;
		}
		
		return resultMap;
	}
	*/


}
