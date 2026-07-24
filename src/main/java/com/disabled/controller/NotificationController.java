package com.disabled.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpSession;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.disabled.service.NotificationService;

/**
 * 헤더 알림 컨트롤러 (작업계획서 15 §4-2)
 *  - 안읽은 개수(30초 폴링): GET  /notification/unreadCount
 *  - 최근 목록            : GET  /notification/list
 *  - 단건 읽음            : POST /notification/read/{notiId}
 *  - 전체 읽음            : POST /notification/readAll
 *
 * 접근제어는 servlet-context.xml 의 LoginInterceptor(/**)가 담당(기존 컨트롤러와 동일 패턴).
 * 다만 세션 만료 후에도 폴링이 계속될 수 있으므로, 세션이 없으면 조회 없이 0/빈 목록을 돌려준다.
 */
@Controller
@RequestMapping("/notification")
public class NotificationController {

	@Autowired
	private NotificationService notificationService;

	private static boolean isLoggedIn(HttpSession session) {
		return session != null && session.getAttribute("uId") != null;
	}

	// 1. 안읽은 알림 개수 (헤더 배지 / 30초 폴링)
	@GetMapping("/unreadCount")
	@ResponseBody
	public Map<String, Object> unreadCount(HttpSession session) {
		Map<String, Object> result = new HashMap<>();
		result.put("unread_cnt", isLoggedIn(session) ? notificationService.getUnreadCount() : 0);
		return result;
	}

	// 2. 최근 알림 목록 (아이콘 클릭 시)
	@GetMapping("/list")
	@ResponseBody
	public List<Map<String, Object>> list(
			@RequestParam(defaultValue = "10") int limit,
			HttpSession session) {

		if (!isLoggedIn(session)) {
			return new java.util.ArrayList<>();
		}
		return notificationService.getRecentNotifications(limit);
	}

	// 3. 단건 읽음 처리 (알림 카드 클릭 시, 이동과 병행)
	@PostMapping("/read/{notiId}")
	@ResponseBody
	public Map<String, Object> read(@PathVariable int notiId, HttpSession session) {
		Map<String, Object> result = new HashMap<>();
		result.put("success", isLoggedIn(session) && notificationService.markAsRead(notiId));
		return result;
	}

	// 4. 전체 읽음 처리
	@PostMapping("/readAll")
	@ResponseBody
	public Map<String, Object> readAll(HttpSession session) {
		Map<String, Object> result = new HashMap<>();
		result.put("success", isLoggedIn(session) && notificationService.markAllAsRead());
		return result;
	}
}
