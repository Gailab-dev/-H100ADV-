package com.disabled.service;

import java.util.Map;


public interface MyInfoService {
	// 사용자 정보 가져오기
	Map<String, Object > getMyInfoMap (Map<String,Object> paramMap);
	// 사용자 정보 저장하기
	Integer updateMyInfo(Map<String, Object> paramMap);
}
