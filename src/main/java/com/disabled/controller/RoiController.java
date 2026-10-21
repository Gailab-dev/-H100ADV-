package com.disabled.controller;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.Map;
import java.util.UUID;
import java.util.function.Supplier;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.disabled.roi.RoiActor;
import com.disabled.roi.RoiResult;
import com.disabled.service.RoiService;
import com.disabled.service.UserService;
import com.fasterxml.jackson.databind.JsonNode;

/**
 * 웹 ROI 설정(34번 작업계획서). 브라우저(Konva) -> 이 컨트롤러 -> module_c -> module_d.
 *
 * 접근 제어는 RoiAccessInterceptor(u_grade 25/30)가 /deviceList/roi* 전체에 적용되고(servlet-context.xml),
 * 로그인 확인은 LoginInterceptor 가 한다. POST API 는 추가로 세션 CSRF 토큰(X-H100-CSRF)을 확인한다 —
 * 토큰은 roiView.do 가 세션에 만들어 화면에 심어 준다. 파일 경로·장비 주소는 항상 서버가 DB·세션으로 결정한다.
 */
@Controller
@RequestMapping("/deviceList")
public class RoiController {
	private static final Logger logger = LoggerFactory.getLogger(RoiController.class);
	private static final String CSRF_ATTR = "roiCsrf";
	private static final String ACTOR_ATTR = "roiActor";

	@Autowired
	private RoiService roiService;

	@Autowired
	private UserService userService;

	/** 편집 화면(NAV 에 노출하지 않는 전용 페이지). */
	@GetMapping("/roiView.do")
	public String roiView(@RequestParam(value = "deviceId", defaultValue = "0") int deviceId, HttpSession session,
			HttpServletResponse response, Model model) throws IOException {
		RoiResult info = roiService.deviceInfo(deviceId);
		if (info.status != 200) {
			response.sendError(info.status == 404 ? HttpServletResponse.SC_NOT_FOUND : HttpServletResponse.SC_BAD_REQUEST);
			return null;
		}
		model.addAttribute("deviceId", deviceId);
		model.addAttribute("deviceName", info.body.get("name"));
		model.addAttribute("serial", info.body.get("serial"));
		model.addAttribute("roiCsrf", csrfToken(session));
		model.addAttribute("loginUid", String.valueOf(session.getAttribute("uId")));
		response.setHeader("Cache-Control", "no-store");
		return "roiEditor"; // Tiles 정의명(defaultLayout 적용)
	}

	@PostMapping("/roiLoad.do")
	@ResponseBody
	public ResponseEntity<?> roiLoad(@RequestBody JsonNode body, HttpServletRequest request, HttpSession session) {
		return guarded(request, session, () -> roiService.load(body.path("deviceId").asInt(0)));
	}

	@PostMapping("/roiSnapshot.do")
	@ResponseBody
	public ResponseEntity<?> roiSnapshot(@RequestBody JsonNode body, HttpServletRequest request, HttpSession session) {
		return guarded(request, session, () -> roiService.snapshot(body.path("deviceId").asInt(0), actor(session)));
	}

	@PostMapping("/roiSave.do")
	@ResponseBody
	public ResponseEntity<?> roiSave(@RequestBody JsonNode body, HttpServletRequest request, HttpSession session) {
		return guarded(request, session, () -> {
			Long rollback = body.hasNonNull("rollbackRhId") ? body.get("rollbackRhId").asLong(0) : null;
			if (rollback != null && rollback <= 0) return RoiResult.error(400, "BAD_REQUEST", "되돌릴 이력이 올바르지 않습니다.");
			if (rollback == null && !body.hasNonNull("rois")) return RoiResult.error(400, "BAD_REQUEST", "ROI 내용이 없습니다.");
			return roiService.save(body.path("deviceId").asInt(0), body.get("rois"), body.path("baseHash").asText(""), rollback, actor(session));
		});
	}

	@PostMapping("/roiCheck.do")
	@ResponseBody
	public ResponseEntity<?> roiCheck(@RequestBody JsonNode body, HttpServletRequest request, HttpSession session) {
		return guarded(request, session, () -> roiService.check(body.path("rhId").asLong(0), actor(session)));
	}

	@PostMapping("/roiHistory.do")
	@ResponseBody
	public ResponseEntity<?> roiHistory(@RequestBody JsonNode body, HttpServletRequest request, HttpSession session) {
		return guarded(request, session, () -> roiService.history(body.path("deviceId").asInt(0), body.path("limit").asInt(50)));
	}

	@PostMapping("/roiHistoryDetail.do")
	@ResponseBody
	public ResponseEntity<?> roiHistoryDetail(@RequestBody JsonNode body, HttpServletRequest request, HttpSession session) {
		return guarded(request, session, () -> roiService.historyDetail(body.path("rhId").asLong(0)));
	}

	/**
	 * 스냅샷 이미지 스트리밍. 정적 URL 로 노출하지 않고, 파일 경로는 서버가 결정한다:
	 *  - deviceId + camera : 본인의 임시 스냅샷(편집 중)
	 *  - rsId              : DB(tbl_roi_snapshot)에 기록된 기준 스냅샷(이력 미리보기·롤백)
	 */
	@GetMapping("/roiImage.do")
	public ResponseEntity<?> roiImage(@RequestParam(value = "deviceId", defaultValue = "0") int deviceId,
			@RequestParam(value = "camera", required = false) String camera,
			@RequestParam(value = "rsId", defaultValue = "0") long rsId, HttpSession session) {
		try {
			Path file = rsId > 0 ? roiService.baselineSnapshot(rsId) : roiService.tempSnapshot(deviceId, camera, actor(session));
			if (file == null) return ResponseEntity.notFound().build();
			byte[] data = Files.readAllBytes(file);
			CacheControl cache = rsId > 0 ? CacheControl.maxAge(java.time.Duration.ofMinutes(5)).cachePrivate() : CacheControl.noStore();
			return ResponseEntity.ok().contentType(MediaType.IMAGE_JPEG).cacheControl(cache)
					.header("X-Content-Type-Options", "nosniff").body(data);
		} catch (IOException | RuntimeException e) {
			logger.error("[ROI] 스냅샷 이미지 전송 실패: ", e);
			return ResponseEntity.status(500).build();
		}
	}

	// ------------------------------------------------------------------ 내부

	/** CSRF 확인 + 예외를 일반 오류로 감싼다(주소·내부 메시지를 응답에 싣지 않는다). */
	private ResponseEntity<?> guarded(HttpServletRequest request, HttpSession session, Supplier<RoiResult> call) {
		if (!csrfOk(request, session)) {
			return reply(RoiResult.error(403, "CSRF", "요청 인증에 실패했습니다. 화면을 새로고침하십시오."));
		}
		try {
			return reply(call.get());
		} catch (RuntimeException e) {
			logger.error("[ROI] 요청 처리 중 오류: ", e);
			return reply(RoiResult.error(500, "SERVER_ERROR", "서버 처리 중 오류가 발생했습니다."));
		}
	}

	private static ResponseEntity<Map<String, Object>> reply(RoiResult res) {
		return ResponseEntity.status(res.status).cacheControl(CacheControl.noStore()).body(res.body);
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
				&& MessageDigest.isEqual(String.valueOf(expected).getBytes(StandardCharsets.UTF_8), supplied.getBytes(StandardCharsets.UTF_8));
	}

	/** 요청자의 로그인 ID(임시 스냅샷 폴더)와 이름(이력). 세션에 캐시하되 사용자가 바뀌면 다시 조회한다. */
	private RoiActor actor(HttpSession session) {
		Object uId = session.getAttribute("uId");
		Object cached = session.getAttribute(ACTOR_ATTR);
		if (cached instanceof CachedActor && ((CachedActor) cached).uId.equals(String.valueOf(uId))) {
			return ((CachedActor) cached).actor;
		}
		Integer id = Integer.valueOf(String.valueOf(uId));
		String loginId = userService.getLoginId(id);
		String name = userService.getUNameBySession(id);
		RoiActor actor = new RoiActor(loginId, name);
		session.setAttribute(ACTOR_ATTR, new CachedActor(String.valueOf(uId), actor));
		return actor;
	}

	private static final class CachedActor implements java.io.Serializable {
		private static final long serialVersionUID = 1L;
		final String uId;
		final RoiActor actor;

		CachedActor(String uId, RoiActor actor) {
			this.uId = uId;
			this.actor = actor;
		}
	}
}
