package com.disabled.controller;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;

import com.disabled.component.SessionManager;
import com.disabled.mapper.StatsMapper;
import com.disabled.service.CryptoARIAService;
import com.disabled.service.StatsService;

@Controller
@RequestMapping("/stats")
public class StatsController {
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(StatsController.class);
	
	@Autowired
	StatsService statsService;
	
	@Autowired
	StatsMapper statsMapper;
	
	@Autowired
	CryptoARIAService cryptoARIAService;

	@Autowired
	SessionManager sessionManager;
	
	// 통계 화면으로 redirect
	@RequestMapping("")
	public String rootRedirect() {
		
		return "redirect:/stats/viewStat.do";
	}
	
	/*
	 * 통계 화면으로 이동
	 * 
	 */
	@RequestMapping("/viewStat.do")
	private String viewStat(Model model, HttpSession session) {
		
		// 접근 로그
		logger.info("{} 사용자의 {}에 viewStat 화면 접속.", session.getAttribute("uId"),LocalDateTime.now());
		
		List<Map<String,Object>> statsByMonth = new ArrayList<Map<String,Object>>();
		
		try {
			statsByMonth = statsService.getEventByMonth();
			
		} catch (IllegalArgumentException e) {
			logger.error("잘못된 인자 전달",e);
		}
		
		 // 세션에 저장된 회원의 등급(권한) 가져오기
	    Integer uGrade = Integer.parseInt(session.getAttribute("uGrade").toString()); 
		
	    model.addAttribute("uGrade",uGrade);
		model.addAttribute("statsByMonth", statsByMonth);
		return "stats/stats";
	}
	
}
