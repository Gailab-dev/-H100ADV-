package com.disabled.service;

import java.util.Map;

import com.disabled.model.AccountLockStatus;



public interface UserService {
	Map<String,Object> loginCheck(String id, String pwd);

	Integer updateNewPwd(Integer uId, String encryptPwd);

	String getPwd(Integer uId);

	String getLoginId(Integer uId);

	void loginFailService(String id);

	AccountLockStatus checkLockedAccount(String id);

	boolean resetFailCount(String id);

	void resetLoginFailCount(String id);

	// Map<String, Object> getMyInfo(Integer uId);

	// Integer updateMyInfoExceptPwd(Integer uId);

	// List<Map<String, Object>> getUserListManage(Integer uId, String searchKeyword);

	// Integer getTotalRecordCountByManaegUsers(Map<String, Object> paramMap);

	// List<Map<String, Object>> getUserListManage(Map<String, Object> paramMap);
}
