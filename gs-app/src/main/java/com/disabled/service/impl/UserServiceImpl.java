package com.disabled.service.impl;

import java.util.HashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.disabled.mapper.LoginMapper;
import com.disabled.model.AccountLockStatus;
import com.disabled.service.UserService;

@Service
@Transactional
public class UserServiceImpl implements UserService {

	@Autowired
	LoginMapper loginMapper;
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(UserServiceImpl.class);
	
	// 계정 상태 잠금 코드
	
	
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
				return null;
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
	
	/**
	 * 로그인 실패 로직 
	 */
	@Override
	public void loginFailService(String id) {
		
		try {
					
			// 잠금 count 늘리기
			loginMapper.increaseFailCount(id);
			
			// 그 값이 5 이상이라면 잠금
			loginMapper.lockAccount(id);
			
		} catch (IllegalStateException e2) {
			logger.error("loginFailService 함수에서 SQL 사용시 오류 발생 : ",e2);
			throw e2;
		} catch (RuntimeException e) {
			logger.error("loginFailService 함수에서 오류 발생 : ",e);
			throw e;
		}
	}
	
	/**
	 * 계정 잠금 여부 확인하여 잠금 로직 진행
	 */
	@Override
	public AccountLockStatus checkLockedAccount(String id) {
		
		try {
			
			// id값만 가지고 계정 여부 확인
			Map<String,Object> resultMap = loginMapper.getUserByULoginId(id);
			if(resultMap == null) {
				return AccountLockStatus.NO_ACCOUNT;
			}
			
			// 잠금이 아니라면 통과
			String uAccountLocked = resultMap.get("u_account_locked").toString();
			if("N".equals(uAccountLocked)) {
				return AccountLockStatus.NOT_LOCKED;
			}
			
			// 잠금이여도 5분 이상 지났다면 통과
			Object passedObj = resultMap.get("passedMinutes");
			if(passedObj == null) {
				return AccountLockStatus.LOCKED_UNDER_TERM;
			}
			
			Integer passedMin = ((Number) passedObj).intValue();
			if(passedMin >= 5) {
				return AccountLockStatus.LOCKED_UNLOCKABLE;
			}else {
				return AccountLockStatus.LOCKED_UNDER_TERM;
			}

		} catch (RuntimeException e) {
			logger.error("checkLockedAccount 함수 실행 중 오류 발생 ",e);
			throw e;
		}
		
		
	}
	
	/**
	 * 로그인 성공하였음으로 실패 관련 정보 update
	 */
	@Override
	public boolean resetFailCount(String id) {
		
		try {
			int rows1 = loginMapper.resetFailCount(id);
			if(rows1 != 1) {
				logger.error("resetFailCount 함수 실행 중 update 항목 없음");
				return false;
			}
			return true;
		} catch (RuntimeException e) {
			logger.error("resetFailCount 함수 실행 중 오류 발생 ",e);
			throw e;
		}
	}

	/**
	 * 로그인 실패 카운트 초기화
	 */
	@Override
	public void resetLoginFailCount(String id) {
		try {
			int row1 = loginMapper.updateLoginFailCountZero(id);
			if(row1 != 1) {
				logger.error("resetLoginFailCount SQL 실행 도중 오류 발생");
				throw new IllegalStateException("resetLoginFailCount SQL 실행 도중 오류 발생");
			}
			return;
		} catch (RuntimeException e) {
			logger.error("resetLoginFailCount 함수에서 오류 발생 : ",e);
			throw e;
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
