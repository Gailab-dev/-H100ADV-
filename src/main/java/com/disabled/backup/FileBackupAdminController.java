package com.disabled.backup;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

/**
 * 일일 파일 백업 수동 실행·상태 조회(관리자 등급 30 전용 내부 엔드포인트, 작업계획서 39 WP-2 ①).
 *
 * <ul>
 *   <li>로그인은 LoginInterceptor(/**), 등급 30 은 이 컨트롤러가 직접 확인한다(기존 엔드포인트에는 등급 검사를 넣지 않았다).</li>
 *   <li>POST 는 세션 CSRF 토큰(X-H100-CSRF)을 확인한다. 토큰은 GET /admin/fileBackup/csrf 로 받는다.</li>
 *   <li>화면은 없다. 예) 날짜·장비 지정 재처리: POST /admin/fileBackup/run {"date":"2026-11-02","dvId":3}</li>
 * </ul>
 */
@Controller
@RequestMapping("/admin/fileBackup")
public class FileBackupAdminController {

	private static final Logger logger = LoggerFactory.getLogger(FileBackupAdminController.class);

	private static final int SUPER_ADMIN_GRADE = 30;
	private static final String CSRF_ATTR = "fileBackupCsrf";

	@Autowired
	private FileBackupService backupService;

	@GetMapping("/csrf")
	@ResponseBody
	public ResponseEntity<Map<String, Object>> csrf(HttpSession session) {
		if (!isSuperAdmin(session)) {
			return forbidden();
		}
		Map<String, Object> body = new HashMap<String, Object>();
		body.put("token", csrfToken(session));
		return noStore(HttpStatus.OK, body);
	}

	@GetMapping("/status")
	@ResponseBody
	public ResponseEntity<Map<String, Object>> status(HttpSession session) {
		if (!isSuperAdmin(session)) {
			return forbidden();
		}
		return noStore(HttpStatus.OK, backupService.status());
	}

	/**
	 * 수동 실행. 본문(모두 선택): date(yyyy-MM-dd, 지정하면 그 날짜 재처리) / dvId(장비 지정).
	 * 백그라운드로 시작하고 즉시 202 를 돌려준다(진행·결과는 /status). 이미 실행 중이면 409.
	 */
	@PostMapping("/run")
	@ResponseBody
	public ResponseEntity<Map<String, Object>> run(@RequestBody(required = false) Map<String, Object> body,
			HttpServletRequest request, HttpSession session) {
		if (!isSuperAdmin(session)) {
			return forbidden();
		}
		if (!csrfOk(request, session)) {
			return result(HttpStatus.FORBIDDEN, false, "CSRF", "요청 인증에 실패했습니다. 토큰을 다시 받으십시오.");
		}

		LocalDate date = null;
		Integer dvId = null;
		try {
			if (body != null && body.get("date") != null && !String.valueOf(body.get("date")).isBlank()) {
				date = LocalDate.parse(String.valueOf(body.get("date")).trim());
				if (date.isAfter(FileBackupService.yesterdayKst())) {
					return result(HttpStatus.BAD_REQUEST, false, "BAD_DATE", "오늘 이후 날짜는 지정할 수 없습니다(어제까지).");
				}
			}
			if (body != null && body.get("dvId") != null && !String.valueOf(body.get("dvId")).isBlank()) {
				dvId = Integer.valueOf(String.valueOf(body.get("dvId")).trim());
			}
		} catch (DateTimeParseException | NumberFormatException e) {
			return result(HttpStatus.BAD_REQUEST, false, "BAD_PARAM", "date(yyyy-MM-dd) 또는 dvId 형식이 올바르지 않습니다.");
		}

		boolean started = backupService.startAsync(date, dvId, "MANUAL");
		if (!started) {
			return result(HttpStatus.CONFLICT, false, "ALREADY_RUNNING", "백업이 이미 실행 중입니다.");
		}
		logger.info("[FileBackup] 관리자 수동 실행 요청 uId={} date={} dvId={}", session.getAttribute("uId"),
				date == null ? "어제" : date, dvId);
		return result(HttpStatus.ACCEPTED, true, "STARTED", "백업을 시작했습니다. /admin/fileBackup/status 로 진행을 확인하십시오.");
	}

	// ------------------------------------------------------------------ 내부

	private static boolean isSuperAdmin(HttpSession session) {
		if (session == null || session.getAttribute("uId") == null) {
			return false;
		}
		Object g = session.getAttribute("uGrade");
		if (g == null) {
			return false;
		}
		try {
			int grade = g instanceof Number ? ((Number) g).intValue() : Integer.parseInt(String.valueOf(g).trim());
			return grade == SUPER_ADMIN_GRADE;
		} catch (NumberFormatException e) {
			return false;
		}
	}

	private static ResponseEntity<Map<String, Object>> forbidden() {
		return result(HttpStatus.FORBIDDEN, false, "FORBIDDEN", "권한이 없습니다.");
	}

	private static ResponseEntity<Map<String, Object>> result(HttpStatus status, boolean ok, String code, String msg) {
		Map<String, Object> body = new HashMap<String, Object>();
		body.put("ok", ok);
		body.put("code", code);
		body.put("msg", msg);
		return noStore(status, body);
	}

	private static ResponseEntity<Map<String, Object>> noStore(HttpStatus status, Map<String, Object> body) {
		return ResponseEntity.status(status).cacheControl(CacheControl.noStore()).body(body);
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
		return expected != null && supplied != null && MessageDigest.isEqual(
				String.valueOf(expected).getBytes(StandardCharsets.UTF_8), supplied.getBytes(StandardCharsets.UTF_8));
	}
}
