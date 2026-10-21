package com.disabled.interceptor;

import java.io.IOException;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * ROI 화면·API(/deviceList/roi*) 접근 제어(34번 작업계획서 확정사항 14).
 * tbl_user.u_grade 가 25(장비관리자) 또는 30(최고관리자)인 사용자만 통과시킨다.
 * 범위 비교(>=)는 쓰지 않는다 — 기존 코드에 u_grade 범위 비교가 생기면 25 가 관리자(20) 기능까지 얻기 때문이다.
 * 로그인 여부는 LoginInterceptor 가 먼저 확인하므로 여기서는 등급만 본다.
 */
public class RoiAccessInterceptor implements HandlerInterceptor {
	private static final Logger logger = LoggerFactory.getLogger(RoiAccessInterceptor.class);

	public static final int GRADE_DEVICE_MANAGER = 25;
	public static final int GRADE_SUPER_ADMIN = 30;

	/** 세션의 uGrade 값(Integer/Long/String 모두 가능)이 ROI 접근 등급인지. */
	public static boolean isRoiGrade(Object uGrade) {
		if (uGrade == null) return false;
		int grade;
		try {
			grade = uGrade instanceof Number ? ((Number) uGrade).intValue() : Integer.parseInt(String.valueOf(uGrade).trim());
		} catch (NumberFormatException e) {
			return false;
		}
		return grade == GRADE_DEVICE_MANAGER || grade == GRADE_SUPER_ADMIN;
	}

	@Override
	public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws IOException {
		HttpSession session = request.getSession(false);
		Object grade = session == null ? null : session.getAttribute("uGrade");
		if (isRoiGrade(grade)) return true;

		logger.warn("[ROI] 권한 없는 접근 차단: {} (uId={})", request.getRequestURI(), session == null ? null : session.getAttribute("uId"));
		response.setHeader("Cache-Control", "no-store");
		String uri = request.getRequestURI();
		if (uri.endsWith("/roiView.do") || uri.endsWith("/roiImage.do")) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN);
		} else {
			response.setStatus(HttpServletResponse.SC_FORBIDDEN);
			response.setContentType("application/json; charset=UTF-8");
			response.getWriter().write("{\"ok\":false,\"code\":\"FORBIDDEN\",\"msg\":\"ROI 설정 권한이 없습니다.\"}");
		}
		return false;
	}
}
