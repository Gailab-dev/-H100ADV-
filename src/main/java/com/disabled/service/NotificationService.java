package com.disabled.service;

import java.util.List;
import java.util.Map;

/**
 * 헤더 알림 서비스 (작업계획서 15 §4-2)
 *
 * 헤더는 모든 화면에 공통으로 붙고 30초마다 폴링하므로,
 * 알림 조회 실패가 화면 전체를 막지 않도록 구현체에서 예외를 흡수한다.
 */
public interface NotificationService {

	/** 안읽은 알림 개수. 조회 실패 시 0 */
	int getUnreadCount();

	/** 최근 알림 목록. 조회 실패 시 빈 목록 */
	List<Map<String, Object>> getRecentNotifications(int limit);

	/** 단건 읽음 처리 */
	boolean markAsRead(int notiId);

	/** 전체 읽음 처리 */
	boolean markAllAsRead();
}
