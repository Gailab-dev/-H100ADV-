package com.disabled.controller;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpSession;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.disabled.service.DeviceErrorLogService;

/**
 * 디바이스 이상 로그 컨트롤러 (작업계획서 15 §4-5)
 *  - 최근 이상 로그: GET /deviceErrorLog/list?dvId=&limit=
 *
 * 접근제어는 servlet-context.xml 의 LoginInterceptor(/**)가 담당(기존 컨트롤러와 동일 패턴).
 */
@Controller
@RequestMapping("/deviceErrorLog")
public class DeviceErrorLogController {

	@Autowired
	private DeviceErrorLogService deviceErrorLogService;

	@GetMapping("/list")
	@ResponseBody
	public List<Map<String, Object>> list(
			@RequestParam int dvId,
			@RequestParam(defaultValue = "30") int limit,
			HttpSession session) {

		if (session == null || session.getAttribute("uId") == null) {
			return new ArrayList<>();
		}
		return deviceErrorLogService.getRecentErrors(dvId, limit);
	}
}
