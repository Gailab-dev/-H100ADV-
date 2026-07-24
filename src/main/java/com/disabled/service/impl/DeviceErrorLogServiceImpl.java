package com.disabled.service.impl;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.disabled.mapper.DeviceErrorLogMapper;
import com.disabled.service.DeviceErrorLogService;

/**
 * 디바이스 이상 로그 서비스 구현 (작업계획서 15 §4-5)
 *
 * ※ 예외 흡수
 *   tbl_device_error_log DDL 실행 전이거나 DB 가 불안정할 때 예외를 그대로 올리면
 *   패널 열기 자체가 실패한다. 안전한 기본값(빈 목록)으로 떨어뜨리고 로그만 남긴다.
 */
@Service
public class DeviceErrorLogServiceImpl implements DeviceErrorLogService {

	private static final Logger logger = LoggerFactory.getLogger(DeviceErrorLogServiceImpl.class);

	/** 패널 표시 상한. 프론트가 큰 값을 보내도 여기서 잘라낸다. */
	private static final int MAX_LIMIT = 100;

	@Autowired
	private DeviceErrorLogMapper deviceErrorLogMapper;

	@Override
	public List<Map<String, Object>> getRecentErrors(int dvId, int limit) {
		if (dvId <= 0) {
			logger.warn("유효하지 않은 dvId: {}", dvId);
			return new ArrayList<>();
		}

		int safeLimit = limit;
		if (safeLimit <= 0) safeLimit = 30;
		if (safeLimit > MAX_LIMIT) safeLimit = MAX_LIMIT;

		try {
			Map<String, Object> paramMap = new HashMap<>();
			paramMap.put("dvId", dvId);
			paramMap.put("limit", safeLimit);

			List<Map<String, Object>> list = deviceErrorLogMapper.selectRecentByDevice(paramMap);
			return list == null ? new ArrayList<>() : list;
		} catch (Exception e) {
			logger.warn("이상 로그 조회 실패(빈 목록으로 처리). tbl_device_error_log 생성 여부 확인 필요: {}", e.getMessage());
			return new ArrayList<>();
		}
	}
}
