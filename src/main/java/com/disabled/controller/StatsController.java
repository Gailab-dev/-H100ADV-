package com.disabled.controller;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

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
	
	// 통계 화면으로 redirect
	@RequestMapping("")
	public String rootRedirect() {
		
		return "redirect:/stats/login.do";
	}
	
	// 로그인 화면 이동
	@RequestMapping("/login.do")
	private String viewLogin(HttpServletRequest request) {
		
		// 세션 확인하여 옛날 세션이 남아 있다면 세션 없애기
	    HttpSession s = request.getSession(false);
	    if (s != null) {
	        try { s.invalidate(); } catch (IllegalStateException ignore) {}
	    }
	    // 캐시 방지 (뒤로가기 시 로그인 화면이 캐시로 보이는 현상 방지)
	    request.setAttribute("noCache", true);
		
		return "stats/login";
	}
	
	// 사용자 ID,PW를 확인하여 가입되었다면 통계 화면으로, 그렇지 않다면 로그인 화면으로 이동
	@ResponseBody
	@PostMapping("/login")
	private Map<String,Object> loginCheck( @RequestBody Map<String,String> body, HttpSession session) {
		
		// 초기값 설정
		String id = "";
		String pwd = "";
		String encryptPwd = null;
		Map<String, Object> checkErr = null;
		Map<String, Object> resultMap = new HashMap<String, Object>();
		
		try {
			
			if(body.get("id") == null || body.get("pwd") == null) {
				resultMap.put("success", false); // 로그인 실패하면 false 반환
				return resultMap;
			}else {
				id = body.get("id");
				pwd = body.get("pwd");
			}
			
			// 암호화
			encryptPwd = cryptoARIAService.encryptPassword(pwd);
			
			checkErr = statsService.loginCheck(id, encryptPwd); //db에 해당 사용자가 있는지 체크
			if(checkErr == null) {
				
				// 로그인 실패
				logger.info("{} 사용자가 {}에 로그인 실패하였습니다.",id,LocalDateTime.now());
				resultMap.put("success", false); // 로그인 실패하면 false 반환
				return resultMap;
			}else {
				
				resultMap.put("success", true); // 로그인 성공하면 true 반환
				
				// 세션에 계정 정보 추가
				logger.info("{} 사용자가 {}에 로그인하였습니다.",id,LocalDateTime.now());
				session.setAttribute("id", id);
				
				return resultMap;
			}
		} catch (IllegalArgumentException e) {
			
			logger.error("잘못된 인자 전달",e);
			resultMap.put("success", false); // 로그인 실패하면 false 반환
			
		} catch (NullPointerException e) {
			
			logger.error("NullPointerException => ",e);
			resultMap.put("success", false); // 로그인 실패하면 false 반환
			
		} catch (RuntimeException e) {
			
			logger.error("RuntimeException => ",e);
			resultMap.put("success", false); // 로그인 실패하면 false 반환
			
		} 
		
		return resultMap;
	}
	
	/*
	 * 로그아웃
	 */
	@RequestMapping("/logout")
	public String logout(HttpSession session) {
		logger.info("{} 세션이 {}에 만료되어 로그인 페이지로 돌아갑니다.",session , LocalDateTime.now());
	    session.invalidate(); // 세션 만료
	    return "redirect:/login";
	}
	
	/*
	 * 통계 화면으로 이동
	 * 
	 */
	@RequestMapping("/viewStat.do")
	private String viewStat(Model model, HttpSession session) {
		
		// 접근 로그
		logger.info("{} 사용자의 {}에 viewStat 화면 접속.", session.getAttribute("id"),LocalDateTime.now());
		
		List<Map<String,Object>> statsByMonth = new ArrayList<Map<String,Object>>();
		
		try {
			statsByMonth = statsService.getEventByMonth();
			
		} catch (IllegalArgumentException e) {
			logger.error("잘못된 인자 전달",e);
		}
		model.addAttribute("statsByMonth", statsByMonth);
		return "stats/stats";
	}
	
}
