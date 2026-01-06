package com.disabled.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.disabled.mapper.LocalMapper;
import com.disabled.mapper.LoginMapper;
import com.disabled.model.AccountLockStatus;
import com.disabled.service.UserService;

@Service
@Transactional
public class UserServiceImpl implements UserService {

	@Autowired
	LoginMapper loginMapper;
	
	@Autowired
	LocalMapper localMapper;
	
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
	/**
	 * 비밀번호 변경시 새 비밀번호로 수정
	 * @param uId
	 * @param encryptPwd
	 * @return
	 */
	public Integer updateNewPwd(Integer uId, String encryptPwd) {
		try {
			
			Integer rows1 = loginMapper.updateNewPwd(uId, encryptPwd);
			if(rows1 != 1) {
				logger.error("loginMapper.updateNewPwd SQL문에서 오류 발생");
				throw new IllegalStateException("loginMapper.updateNewPwd SQL문에서 오류 발생");
			}
			return rows1;
		} catch (RuntimeException e) {
			logger.error("loginMapper.updateNewPwd SQL문에서 오류 발생",e);
			throw e;
		}
		
	}

	/**
	 * uId값으로 비밀번호 가져오기 
	 * @param uId	uId(String)
	 * @return 		비밀번호(String)
	 */
	@Override
	public String getPwd(Integer uId) {
		
		try {
			return loginMapper.getPwd(uId);
		} catch (IllegalStateException e) {
			logger.error("loginMapper.getPwd SQL문에서 오류 발생",e);
			throw e;
		}
	}
	
	/**
	 * uId값으로 loginId 가져오기 
	 * @param uId
	 * @return
	 */
	@Override
	public String getLoginId(Integer uId) {
		try {
			return loginMapper.getLoginId(uId);
		} catch (IllegalStateException e) {
			logger.error("loginMapper.getLoginId SQL문에서 오류 발생",e);
			throw e;
		}
	}
	
	/**
	 * 로그인 실패 로직 
	 * @param id	아이디(uLoginId)(String)
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
	
	@Override
	/**
	 * 계정 잠금 여부 확인하여, 현재 잠금 상태를 갱신
	 * @param id					아이디(uLoginId)(String)
	 * @return NO_ACCOUNT			아이디가 없음
	 * @return NOT_LOCKED			잠금상태 아님
	 * @return LOCKED_UNDER_TERM	잠금상태이나, 잠금 후 5분이 지나 해제 가능 
	 * @return LOCKED_UNLOCKABLE	잠금상태이고, 잠금해제 불가능한 상태
	 */
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
	 * 로그인 성공하였음으로 실패 count를 0으로 초기화
	 * @param u_login_id 	로그인 Id(String)
	 * @return				true: update 성공, false: 오류 발생
	 */
	@Override
	public boolean resetFailCount(String u_login_id) {
		
		try {
			int rows1 = loginMapper.resetFailCount(u_login_id);
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
	 * @param id	로그인Id(uLoginId)(String)
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
	
	/**
	 * 새로운 사용자인지 확인
	 * @param uLoginId	로그인 id(String)
	 * @return true: 새로운 사용자, false: 기존 사용자
	 */
	@Override
	public boolean checkNewUserId(String uLoginId) {
		
		try {
			Integer rows1 = loginMapper.getCountUserIdAsParam(uLoginId);
			if(rows1 > 0) {
				logger.error("아이디가 중복입니다.");
				throw new IllegalStateException("loginMapper.getCountUserIdAsParam SQL문에서 오류 발생");
			}
			
			return true;
		} catch (RuntimeException e) {
			logger.error("checkNewUserId에서 오류 발생 : ",e);
			throw e;
		}
	}
	
	/**
	 * 회원가입
	 * @param paramMap	회원가입시 입력한 회원정보(map)
	 * @return			
	 */
	@Override
	public Integer insertUser(Map<String, Object> paramMap) {
		
		try {
			Integer rows1 = loginMapper.insertUser(paramMap);
			if(rows1 != 1) {
				logger.error("사용자 등록 중 오류 발생");
				return -1;
			}
			
			return rows1;
			
		} catch (IllegalStateException e) {
			logger.error("insertUser에서 SQL 오류 발생 : ",e);
			throw e;
		}
	}
	
	/**
	 * 지역 정보 가져오기
	 */
	@Override
	public List<Map<String, Object>> getAllLocals() {
		
		try {
			
			return localMapper.getLocalList();
			
		} catch (IllegalStateException e) {
			logger.error("getAllLocals에서 SQL 오류 발생 : ",e);
			throw e;
		}
		
	}
	
	/**
	 * id값 중복 확인
	 */
	@Override
	public boolean isDuplicatedId(String id) {
		
		try {
			Integer rows1 = loginMapper.getCountUserIdAsParam(id);
			if(rows1 > 0) {
				logger.error("isDuplicatedId 함수 실행 중 SQL 오류 발생");
				throw new IllegalStateException("loginMapper.getCountUserIdAsParam SQL문에서 오류 발생");
			}
			
			return true;
		} catch (RuntimeException e) {
			logger.error("isDuplicatedId 함수 실행 중 오류 발생");
			throw e;
		}
		
		
	}
	
	/**
	 * 아이디 결과 값 * 처리
	 */
	@Override
	public String maskMyId(String myId) {
		
		// 아이디 값 오류 처리
		if(myId == null || myId.length() <= 0) {
			return null;
		}
		
		int len = myId.length();
		
		// id 길이가 3 이하인 경우 첫번째 문자 빼고 나머지 * mask
		if(len <= 3) {
			return myId.charAt(0) + "*";
		}
		
		// id 길이가 5 이하인 경우 첫번째 글자와 마지막 글짜 빼고 * mask
		if(len <= 5) {
			return makeMaskStr(myId, len, 1);
			// id 길이가 5 이상인 경우 2개 빼고 가운데 글자 * mask
		}else {
			return makeMaskStr(myId, len, 2);
		}	
	}
	
	/*
	 * 마스킹 처리 된 문자열 리턴(prefix, suffix 같은 경우)
	 */
	private String makeMaskStr(String str, int len, int fix) {
		String prefixStr = str.substring(0, fix);
		String suffixStr = str.substring(len - fix);
		String mask = "*".repeat(len - fix - fix);
		return prefixStr + mask + suffixStr;
	}
	
	/*
	 * 마스킹 처리 된 문자열 리턴
	 */
	private String makeMaskStr(String str, int len, int prefix, int suffix) {
		String prefixStr = str.substring(0, prefix);
		String suffixStr = str.substring(len - suffix);
		String mask = "*".repeat(len - prefix - suffix);
		return prefixStr + mask + suffixStr;
	}
	
	/**
	 * 이름과 전화번호로 아이디 찾기
	 * @param body	회원 개인 정보(이름, 전화번호)(map)
	 * @return		아이디
	 */
	@Override
	public String findId(Map<String, Object> body) {
		
		try {
			return loginMapper.getLoginIdByNameAndPhone(body);
			
		} catch (IllegalStateException e) {
			logger.error("findId 함수 실행 도중 오류 발생 : ",e);
			return null;
		}
	}
	
	/**
	 * 비밀번호 찾기에서 이름, 전번, 아이디로 비밀번호 인증
	 * @param body	회원 개인 정보(이름, 전번, 아이디) (map)
	 * @return		true: 비밀번호 인증 성공, false: 비밀번호 인증 실패
	 */
	@Override
	public boolean authPwd(Map<String, Object> body) {
		
		try {
			
			System.out.println(body);
			
			int rows1 = loginMapper.getCountPwd(body);
			if(rows1 != 1) {
				logger.error("loginMapper.getCountPwd 함수 실행 중 SQL 오류 발생 : rows1 : "+rows1);
				return false;			
			}
			
			return true;
			
		} catch (RuntimeException e) {
			logger.error("authPwd 함수 실행 중 오류 발생 : ",e);
			
			throw e;
		}
	}
	
	/**
	 * 비밀번호 리셋
	 */
	@Override
	public boolean resetPwd(Map<String, Object> body) {
		try {
			
			Integer uId = Integer.parseInt(body.get("u_id").toString()) ;
			String encryptPwd = body.get("encryptPwd").toString();
			
			// 비밀번호 리셋
			int rows1 = loginMapper.updateNewPwd(uId,encryptPwd);
			if(rows1 != 1) {
				logger.error("resetPwd 함수 실행 중 오류 발생");
				return false;
			}
			
			return true;
		} catch (RuntimeException e) {
			logger.error("resetPwd 함수 실행 중 SQL 오류 발생 : ",e);
			throw e;
		}
	}
	
	/**
	 * 인증번호로 인증
	 * 2025.11.27. 인증번호 인증은 구현하지 않음, 추후 고도화시 논의
	 */
	@Override
	public boolean authWithAuthNumber(Map<String, Object> json) {
		
		return true;
	}

	/**
	 * 이름, 아이디, 전화번호로 고유번호 식별
	 */
	@Override
	public Integer getLoginIdWithNameAndIdAndPhone(Map<String, Object> body) {
		
		Integer uId = null;
		
		try {
			uId = loginMapper.getLoginIdWithNameAndIdAndPhone(body);
			if(uId == null) {
				logger.error("loginMapper.getLoginIdWithNameAndIdAndPhone SQL문에서 오류 발생");
				return null;
			}
			
			return uId;
		} catch (RuntimeException e) {
			logger.error("getLoginIdWithNameAndIdAndPhone 함수 실행 중 오류 발생 : ",e);
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
