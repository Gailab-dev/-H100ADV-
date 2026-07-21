package com.disabled.controller;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.disabled.mapper.LoginMapper;
import com.disabled.service.DashboardService;

/**
 * 대시보드 지도기반 페이지 컨트롤러 (작업계획서 10)
 *  - 화면: /dashboard
 *  - 지도용 디바이스 리스트(AJAX): /dashboard/deviceMapList
 *  - 마커 오버 상세(AJAX): /dashboard/deviceDetail/{dvId}
 *
 * 접근제어는 servlet-context.xml 의 LoginInterceptor(/** )가 담당(로그인 필수).
 */
@Controller
@RequestMapping("/dashboard")
public class DashboardController {

	private static final Logger logger = LoggerFactory.getLogger(DashboardController.class);

	@Autowired
	private DashboardService dashboardService;

	@Autowired
	private LoginMapper loginMapper;

	/**
	 * 카카오 지도 JavaScript SDK 키(프론트). globals.properties kakao.map.js-key
	 * (환경변수 KAKAO_MAP_JS_KEY 로 주입 — 코드/Git 미포함). 미설정 시 빈 값.
	 */
	@Value("${kakao.map.js-key:}")
	private String kakaoMapJsKey;

	/** 대시보드 지도 메인 화면 */
	@GetMapping("")
	public String dashboard(Model model, HttpSession session) {

		// 접근 로그 + 세션 확인(기존 컨트롤러 패턴)
		String uIdStr = session.getAttribute("uId") == null ? null : session.getAttribute("uId").toString();
		if (uIdStr == null) {
			return "/user/login.do";
		}
		Integer uId = Integer.parseInt(uIdStr);
		logger.info("{}({}) 사용자의 {}에 대시보드 지도 화면 접속.", uId, loginMapper.getLoginId(uId), LocalDateTime.now());

		model.addAttribute("kakaoMapJsKey", kakaoMapJsKey);
		// Tiles 정의명 반환(patches 2026-07-06). defaultLayout(header·left·footer) 적용 → 공용 chrome 표시
		return "dashboard";
	}

	/** 지도용 디바이스 리스트 (좌표·이름·주소·상태 5종·갱신시각) */
	@GetMapping("/deviceMapList")
	@ResponseBody
	public List<Map<String, Object>> getDeviceMapList() {
		return dashboardService.getDeviceMapList();
	}

	/** 마우스 오버 시 팝업 상세 정보 (이름·주소·오늘 처리 건수·상태 5종) */
	@GetMapping("/deviceDetail/{dvId}")
	@ResponseBody
	public Map<String, Object> getDeviceDetail(@PathVariable("dvId") Integer dvId) {
		return dashboardService.getDeviceDetail(dvId);
	}

	/** (작업계획서 12) 우측 카드 — 오늘 전체 처리 합계 (계도/단속) */
	@GetMapping("/todaySummary")
	@ResponseBody
	public Map<String, Object> getTodaySummary() {
		return dashboardService.getTodaySummary();
	}

	/** (작업계획서 12) 하단 최근 이벤트 요약 (기본 5건) */
	/** (작업계획서 14-4-5) 디바이스 상태 요약 — 정상/이상 건수 */
	@GetMapping("/deviceStatusSummary")
	@ResponseBody
	public Map<String, Object> deviceStatusSummary() {
		return dashboardService.getDeviceStatusSummary();
	}

	/** (작업계획서 14-4-7) 최근 SIP 통화 N건 (우하단 위젯, 기본 3건) */
	@GetMapping("/recentSipCalls")
	@ResponseBody
	public List<Map<String, Object>> recentSipCalls(
			@RequestParam(value = "limit", defaultValue = "3") int limit) {
		return dashboardService.getRecentSipCalls(limit);
	}

	@GetMapping("/recentEvents")
	@ResponseBody
	public List<Map<String, Object>> getRecentEvents(
			@org.springframework.web.bind.annotation.RequestParam(value = "limit", defaultValue = "5") int limit) {
		return dashboardService.getRecentEvents(limit);
	}
}
