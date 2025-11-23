package com.disabled.service;

import java.util.List;
import java.util.Map;

public interface UserService {
	Map<String,Object> loginCheck(String id, String pwd);

	Integer updateNewPwd(Integer uId, String encryptPwd);

	String getPwd(Integer uId);

	String getLoginId(Integer uId);

	boolean checkNewUserId(String uLoginId);

	Integer insertUser(Map<String, Object> paramMap);

	List<Map<String, Object>> getAllLocals();

	boolean isDuplicatedId(String id);

	String maskMyId(String myId);

	String findId(Map<String, Object> body);

	boolean authPwd(Map<String, Object> body);

	boolean resetPwd(Map<String, Object> body);

	boolean authWithAuthNumber(Map<String, Object> json);

	Integer getLoginIdWithNameAndIdAndPhone(Map<String, Object> body);

	// Map<String, Object> getMyInfo(Integer uId);

	// Integer updateMyInfoExceptPwd(Integer uId);

	// List<Map<String, Object>> getUserListManage(Integer uId, String searchKeyword);

	// Integer getTotalRecordCountByManaegUsers(Map<String, Object> paramMap);

	// List<Map<String, Object>> getUserListManage(Map<String, Object> paramMap);
}
