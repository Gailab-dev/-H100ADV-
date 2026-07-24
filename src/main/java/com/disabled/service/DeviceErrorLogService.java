package com.disabled.service;

import java.util.List;
import java.util.Map;

/**
 * 디바이스 이상 로그 서비스 (작업계획서 15 §4-5)
 *
 * slide-in 패널에서 호출하며, 조회 실패가 화면을 막지 않도록 구현체에서 예외를 흡수한다.
 */
public interface DeviceErrorLogService {

	/** 특정 디바이스의 최근 이상 로그. 조회 실패 시 빈 목록 */
	List<Map<String, Object>> getRecentErrors(int dvId, int limit);
}
