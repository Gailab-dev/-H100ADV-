package com.disabled.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;

import com.disabled.mapper.DashboardMapper;
import com.disabled.service.DashboardService;

/**
 * 대시보드 지도기반 페이지 서비스 구현 (작업계획서 10)
 *  - 조회 전용 → 기존 기능 영향 0.
 */
@Service
public class DashboardServiceImpl implements DashboardService {

	private static final Logger logger = LoggerFactory.getLogger(DashboardServiceImpl.class);

	@Autowired
	private DashboardMapper dashboardMapper;

	@Override
	public List<Map<String, Object>> getDeviceMapList() {
		try {
			return dashboardMapper.selectDeviceMapList();
		} catch (DataAccessException e) {
			logger.error("SQL문 수행 도중 오류 발생, dashboardMapper.selectDeviceMapList() : ", e);
			throw e;
		}
	}

	@Override
	public Map<String, Object> getDeviceDetail(Integer dvId) {
		Map<String, Object> out = new HashMap<String, Object>();
		try {
			Map<String, Object> device = dashboardMapper.selectDeviceBasic(dvId);
			Map<String, Object> todayCount = dashboardMapper.selectTodayEventCount(dvId);
			out.put("device", device);
			out.put("todayCount", todayCount);
			return out;
		} catch (DataAccessException e) {
			logger.error("SQL문 수행 도중 오류 발생, dashboardMapper.getDeviceDetail(dvId={}) : ", dvId, e);
			throw e;
		}
	}

	@Override
	public Map<String, Object> getTodaySummary() {
		try {
			return dashboardMapper.selectTodaySummary();
		} catch (DataAccessException e) {
			logger.error("SQL문 수행 도중 오류 발생, dashboardMapper.selectTodaySummary() : ", e);
			throw e;
		}
	}

	@Override
	public List<Map<String, Object>> getRecentEvents(int limit) {
		try {
			if (limit <= 0 || limit > 50) limit = 5;
			return dashboardMapper.selectRecentEvents(limit);
		} catch (DataAccessException e) {
			logger.error("SQL문 수행 도중 오류 발생, dashboardMapper.selectRecentEvents({}) : ", limit, e);
			throw e;
		}
	}
}
