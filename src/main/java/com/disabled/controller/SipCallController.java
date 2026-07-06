package com.disabled.controller;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.disabled.mapper.LoginMapper;
import com.disabled.service.SipCallService;
import com.disabled.service.UserService;

/**
 * SIP CALL 로그 화면 컨트롤러 (작업계획서 07)
 *  - 화면: /sipcall/sipCallLog
 *  - 조회(AJAX): /sipcall/list
 *  - 오디오 재생: /sipcall/audio/{scId}
 *
 * 접근제어는 servlet-context.xml 의 LoginInterceptor(/** )가 담당(로그인 필수). 기존 컨트롤러와 동일 패턴.
 */
@Controller
@RequestMapping("/sipcall")
public class SipCallController {

	private static final Logger logger = LoggerFactory.getLogger(SipCallController.class);

	@Autowired
	private SipCallService sipCallService;

	@Autowired
	private LoginMapper loginMapper;

	@Autowired
	private UserService userService;

	// 루트 → 화면 redirect
	@RequestMapping("")
	public String rootRedirect() {
		return "redirect:/sipcall/sipCallLog";
	}

	// 1. SIP 통화 로그 화면
	@GetMapping("/sipCallLog")
	public String showSipCallLog(Model model, HttpSession session) {

		// 접근 로그 + 세션 확인(기존 컨트롤러 패턴)
		String uIdStr = session.getAttribute("uId") == null ? null : session.getAttribute("uId").toString();
		if (uIdStr == null) {
			return "/user/login.do";
		}
		Integer uId = Integer.parseInt(uIdStr);
		logger.info("{}({}) 사용자의 {}에 SIP 통화 로그 화면 접속.",
				uId, loginMapper.getLoginId(uId), LocalDateTime.now());

		model.addAttribute("uName", userService.getUNameBySession(uId));
		if (session.getAttribute("uGrade") != null) {
			model.addAttribute("uGrade", Integer.parseInt(session.getAttribute("uGrade").toString()));
		}
		// Tiles 정의명 반환(patches 2026-07-06). defaultLayout(header·left·footer) 적용 → 공용 chrome 표시
		return "sipCallLog";
	}

	// 2. 조회 (필터 + 페이지네이션)
	@GetMapping("/list")
	@ResponseBody
	public Map<String, Object> getSipCallList(
			@RequestParam(value = "keyword", required = false) String keyword,
			@RequestParam(value = "listSize", defaultValue = "10") int listSize,
			@RequestParam(value = "startDate", required = false) String startDate,
			@RequestParam(value = "endDate", required = false) String endDate,
			@RequestParam(value = "page", defaultValue = "1") int page) {

		// ====== 유효성 검증 [S] ======
		if (keyword != null && !keyword.isEmpty()) {
			if (keyword.length() > 100 || containsDangerousPattern(keyword)) {
				logger.warn("[SIP] 유효하지 않은 keyword: {}", keyword);
				return errorResult("유효하지 않은 검색어입니다.");
			}
		}
		if (startDate != null && !startDate.isEmpty() && (!isValidDate(startDate) || containsDangerousPattern(startDate))) {
			logger.warn("[SIP] 유효하지 않은 startDate: {}", startDate);
			return errorResult("유효하지 않은 시작 날짜입니다.");
		}
		if (endDate != null && !endDate.isEmpty() && (!isValidDate(endDate) || containsDangerousPattern(endDate))) {
			logger.warn("[SIP] 유효하지 않은 endDate: {}", endDate);
			return errorResult("유효하지 않은 종료 날짜입니다.");
		}
		if (listSize < 1 || listSize > 100) listSize = 10;
		if (page < 1 || page > 100000) page = 1;
		// ====== 유효성 검증 [E] ======

		try {
			return sipCallService.getList(keyword, listSize, startDate, endDate, page);
		} catch (RuntimeException e) {
			logger.error("[SIP] 통화 로그 조회 중 오류", e);
			return errorResult("통화 로그 조회 중 오류가 발생했습니다.");
		}
	}

	// 3. 오디오 재생 (Wavesurfer 가 url 로 fetch)
	@GetMapping("/audio/{scId}")
	public void getAudio(@PathVariable("scId") Integer scId, HttpServletResponse res) {
		int status = sipCallService.streamAudio(scId, res);
		if (status != HttpServletResponse.SC_OK && !res.isCommitted()) {
			res.setStatus(status);
		}
	}

	// 조회 오류용 응답(프론트는 total/list 사용, 오류 시 빈 리스트 + message)
	private Map<String, Object> errorResult(String message) {
		Map<String, Object> out = new HashMap<String, Object>();
		out.put("total", 0);
		out.put("list", new java.util.ArrayList<Object>());
		out.put("message", message);
		return out;
	}

	/** 날짜 형식 검증 (yyyy-MM-dd) */
	private boolean isValidDate(String dateStr) {
		if (dateStr == null || dateStr.isEmpty()) return false;
		if (!dateStr.matches("^\\d{4}-\\d{2}-\\d{2}$")) return false;
		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
		sdf.setLenient(false);
		try {
			sdf.parse(dateStr);
			return true;
		} catch (ParseException e) {
			return false;
		}
	}

	/** 위험한 패턴 검사 (SQL Injection, XSS, Path Traversal 방어) — 기존 컨트롤러 패턴 */
	private boolean containsDangerousPattern(String input) {
		if (input == null || input.isEmpty()) return false;
		String[] dangerousPatterns = {
			"<script", "</script>", "javascript:", "onerror=", "onload=",
			"'", "\"", "--", ";", "/*", "*/", "xp_", "sp_",
			"../", "..\\", "%2e%2e", "~",
			"<", ">", "&lt;", "&gt;",
			"union", "select", "insert", "update", "delete", "drop", "exec", "execute"
		};
		String lowerInput = input.toLowerCase();
		for (String pattern : dangerousPatterns) {
			if (lowerInput.contains(pattern.toLowerCase())) return true;
		}
		return false;
	}
}
