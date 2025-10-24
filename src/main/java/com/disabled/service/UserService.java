package com.disabled.service;

import java.util.Map;

public interface UserService {
	Map<String,Object> loginCheck(String id, String pwd);

	void updateNewPwd(Integer uId, String encryptPwd);
}
