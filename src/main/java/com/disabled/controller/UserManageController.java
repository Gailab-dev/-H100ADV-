package com.disabled.controller;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import com.disabled.component.LogDiskManager;
import com.disabled.service.UserManageService;
import com.disabled.service.UserManageService.UpdateResult;
import com.disabled.service.UserService;

/**
 * 사용자 정보 관리 화면(작업계획서 2026-11-06 WP-B).
 * 접근 제어: LoginInterceptor(로그인) → UserManageAccessInterceptor(u_grade 30 만) — servlet-context.xml 의 /userManage/** 매핑.
 * POST API 는 추가로 세션 CSRF 토큰(X-H100-CSRF)을 확인한다(ROI 와 같은 방식).
 * 비밀번호·솔트·토큰 계열 값은 조회·응답·로그에 어디에도 싣지 않는다.
 */
@Controller
@RequestMapping("/userManage")
public class UserManageController {

	private static final Logger logger = LoggerFactory.getLogger(UserManageController.class);
	private static final String CSRF_ATTR = "userManageCsrf";

	@Autowired
	private UserManageService userManageService;

	@Autowired
	private UserService userService;

	@Autowired
	private LogDiskManager logDiskManager;

	@RequestMapping("")
	public String rootRedirect() {
		return "redirect:/userManage/viewUserManage.do";
	}

	/** 화면. 목록은 화면이 list.do 로 불러온다. */
	@RequestMapping("/viewUserManage.do")
	public String viewUserManage(Model model, HttpSession session) {
		Integer uId = actorId(session);
		model.addAttribute("uName", userService.getUNameBySession(uId));
		model.addAttribute("useTblLog", logDiskManager.hasEnoughLogSpace());
		model.addAttribute("userManageCsrf", csrfToken(session));
		return "userManage"; // Tiles 정의명(defaultLayout 적용)
	}

	/** 목록: 계정 ID·이름·이메일·연락처·등급(+ 본인 여부). */
	@GetMapping("/list.do")
	@ResponseBody
	public ResponseEntity<Map<String, Object>> list(HttpSession session) {
		Integer actor = actorId(session);
		List<Map<String, Object>> users = userManageService.getUsers();
		for (Map<String, Object> u : users) {
			u.put("is_self", actor != null && String.valueOf(actor).equals(String.valueOf(u.get("u_id"))));
		}
		Map<String, Object> body = new HashMap<String, Object>();
		body.put("ok", true);
		body.put("users", users);
		return noStore(200, body);
	}

	/** 수정: u_id 와 변경할 항목(u_email·u_phone·u_grade 중 보낸 것만)을 JSON 으로 받는다. */
	@PostMapping("/update.do")
	@ResponseBody
	public ResponseEntity<Map<String, Object>> update(@RequestBody Map<String, Object> body,
			HttpServletRequest request, HttpSession session) {
		if (!csrfOk(request, session)) {
			return result(403, false, "CSRF", "요청 인증에 실패했습니다. 화면을 새로고침하십시오.");
		}
		Integer actor = actorId(session);
		Integer target = asInt(body.get("u_id"));
		if (actor == null || target == null) {
			return result(400, false, "BAD_REQUEST", "요청 값이 올바르지 않습니다.");
		}
		// 허용 항목만 읽는다. 이름·계정 ID·비밀번호 등 다른 키는 무시한다.
		String email = asText(body, "u_email");
		String phone = asText(body, "u_phone");
		Integer grade = null;
		if (body.containsKey("u_grade") && body.get("u_grade") != null) {
			grade = asInt(body.get("u_grade"));
			if (grade == null) {
				return result(400, false, "INVALID_GRADE", "선택할 수 없는 권한입니다.");
			}
		}
		try {
			UpdateResult r = userManageService.updateUser(actor, target, email, phone, grade);
			return result(r.status, r.ok, r.code, r.msg);
		} catch (RuntimeException e) {
			logger.error("[UserManage] 사용자 정보 수정 중 오류 target={}", target, e);
			return result(500, false, "ERROR", "저장 중 오류가 발생했습니다. 잠시 후 다시 시도해 주십시오.");
		}
	}

	// ------------------------------------------------------------------ 내부

	private static Integer actorId(HttpSession session) {
		Object v = session == null ? null : session.getAttribute("uId");
		return v == null ? null : asInt(v);
	}

	private static Integer asInt(Object v) {
		if (v instanceof Number) {
			return ((Number) v).intValue();
		}
		if (v == null) {
			return null;
		}
		try {
			return Integer.valueOf(String.valueOf(v).trim());
		} catch (NumberFormatException e) {
			return null;
		}
	}

	/** 키가 있고 문자열이면 그 값, 없거나 null 이면 null(= 변경 안 함). */
	private static String asText(Map<String, Object> body, String key) {
		Object v = body.get(key);
		return (v == null) ? null : String.valueOf(v);
	}

	private static String csrfToken(HttpSession session) {
		synchronized (session) {
			Object t = session.getAttribute(CSRF_ATTR);
			if (t == null) {
				t = UUID.randomUUID().toString();
				session.setAttribute(CSRF_ATTR, t);
			}
			return (String) t;
		}
	}

	private static boolean csrfOk(HttpServletRequest request, HttpSession session) {
		Object expected = session.getAttribute(CSRF_ATTR);
		String supplied = request.getHeader("X-H100-CSRF");
		return expected != null && supplied != null
				&& MessageDigest.isEqual(String.valueOf(expected).getBytes(StandardCharsets.UTF_8),
						supplied.getBytes(StandardCharsets.UTF_8));
	}

	private static ResponseEntity<Map<String, Object>> result(int status, boolean ok, String code, String msg) {
		Map<String, Object> body = new HashMap<String, Object>();
		body.put("ok", ok);
		body.put("code", code);
		body.put("msg", msg);
		return noStore(status, body);
	}

	private static ResponseEntity<Map<String, Object>> noStore(int status, Map<String, Object> body) {
		return ResponseEntity.status(status).cacheControl(CacheControl.noStore()).body(body);
	}
}
