package com.disabled.service.impl;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.disabled.mapper.NotificationMapper;
import com.disabled.service.NotificationService;

/**
 * 헤더 알림 서비스 구현 (작업계획서 15 §4-2)
 *
 * ※ 예외 흡수 이유
 *   헤더는 전 화면 공통이고 30초마다 폴링한다. tbl_notification DDL 실행 전이거나
 *   DB 가 일시적으로 불안정할 때 예외를 그대로 올리면 모든 화면에서 콘솔 오류가 반복된다.
 *   따라서 조회 계열은 안전한 기본값(0 / 빈 목록)으로 떨어뜨리고 로그만 남긴다.
 */
@Service
public class NotificationServiceImpl implements NotificationService {

	private static final Logger logger = LoggerFactory.getLogger(NotificationServiceImpl.class);

	/** 팝업 목록 상한. 프론트가 큰 값을 보내도 여기서 잘라낸다. */
	private static final int MAX_LIMIT = 50;

	@Autowired
	private NotificationMapper notificationMapper;

	@Override
	public int getUnreadCount() {
		try {
			return notificationMapper.countUnread();
		} catch (Exception e) {
			logger.warn("알림 개수 조회 실패(0 으로 처리). tbl_notification 생성 여부 확인 필요: {}", e.getMessage());
			return 0;
		}
	}

	@Override
	public List<Map<String, Object>> getRecentNotifications(int limit) {
		int safeLimit = limit;
		if (safeLimit <= 0) safeLimit = 10;
		if (safeLimit > MAX_LIMIT) safeLimit = MAX_LIMIT;

		try {
			Map<String, Object> paramMap = new HashMap<>();
			paramMap.put("limit", safeLimit);

			List<Map<String, Object>> list = notificationMapper.selectRecent(paramMap);
			return list == null ? new ArrayList<>() : list;
		} catch (Exception e) {
			logger.warn("알림 목록 조회 실패(빈 목록으로 처리): {}", e.getMessage());
			return new ArrayList<>();
		}
	}

	@Override
	public boolean markAsRead(int notiId) {
		if (notiId <= 0) {
			logger.warn("유효하지 않은 notiId: {}", notiId);
			return false;
		}
		try {
			// 이미 읽은 건이면 0 행 → 오류가 아니므로 true 로 본다.
			notificationMapper.updateRead(notiId);
			return true;
		} catch (Exception e) {
			logger.error("알림 읽음 처리 실패. notiId={}", notiId, e);
			return false;
		}
	}

	@Override
	public boolean markAllAsRead() {
		try {
			notificationMapper.updateReadAll();
			return true;
		} catch (Exception e) {
			logger.error("알림 전체 읽음 처리 실패", e);
			return false;
		}
	}
}
