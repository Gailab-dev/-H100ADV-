package com.disabled.service.impl;

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
		
		try {
			return loginMapper.cntUsrByIdAndPwd(id,pwd);
		} catch (RuntimeException e) {
			
			logger.error("로그인 체크 오류 : ",e);
			throw e;
		} 
	}

	@Override
	public void updateNewPwd(Integer uId, String encryptPwd) {
		try {
			Integer rows1 = loginMapper.updateNewPwd(uId, encryptPwd);
			if(rows1 != 1) {
				logger.error("loginMapper.updateNewPwd SQL문에서 오류 발생");
				throw new IllegalStateException("loginMapper.updateNewPwd SQL문에서 오류 발생");
			}
		} catch (IllegalStateException e) {
			logger.error("loginMapper.updateNewPwd SQL문에서 오류 발생",e);
		}
		
	}

}
