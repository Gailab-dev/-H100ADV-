package com.disabled.interceptor;

import java.io.IOException;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * 사용자 정보 관리 화면·API(/userManage/**) 접근 제어(작업계획서 2026-11-06 WP-B, 결정 D-1).
 * tbl_user.u_grade 가 30(최고 관리자)인 사용자만 통과시킨다. 범위 비교(>=)는 쓰지 않는다.
 * 로그인 여부는 LoginInterceptor 가 먼저 확인하므로 여기서는 등급만 본다.
 * 메뉴 노출도 같은 판정({@link #isAllowedGrade})을 쓴다 — LoginInterceptor 가 요청 속성 canManageUsers 로 내려 준다.
 */
public class UserManageAccessInterceptor implements HandlerInterceptor {
	private static final Logger logger = LoggerFactory.getLogger(UserManageAccessInterceptor.class);

	public static final int GRADE_SUPER_ADMIN = 30;

	/** 요청 속성 이름 — left.jsp 메뉴 노출 판단용. */
	public static final String REQUEST_ATTR_CAN_MANAGE = "canManageUsers";

	/** 세션의 uGrade 값(Integer/Long/String 모두 가능)이 사용자 관리 접근 등급인지. */
	public static boolean isAllowedGrade(Object uGrade) {
		if (uGrade == null) return false;
		try {
			int grade = uGrade instanceof Number ? ((Number) uGrade).intValue() : Integer.parseInt(String.valueOf(uGrade).trim());
			return grade == GRADE_SUPER_ADMIN;
		} catch (NumberFormatException e) {
			return false;
		}
	}

	@Override
	public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws IOException {
		HttpSession session = request.getSession(false);
		Object grade = session == null ? null : session.getAttribute("uGrade");
		if (isAllowedGrade(grade)) return true;

		logger.warn("[UserManage] 권한 없는 접근 차단: {} (uId={})", request.getRequestURI(), session == null ? null : session.getAttribute("uId"));
		response.setHeader("Cache-Control", "no-store");
		String uri = request.getRequestURI();
		if (uri.endsWith("/list.do") || uri.endsWith("/update.do")) {
			response.setStatus(HttpServletResponse.SC_FORBIDDEN);
			response.setContentType("application/json; charset=UTF-8");
			response.getWriter().write("{\"ok\":false,\"code\":\"FORBIDDEN\",\"msg\":\"사용자 관리 권한이 없습니다.\"}");
		} else {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
		}
		return false;
	}
}
