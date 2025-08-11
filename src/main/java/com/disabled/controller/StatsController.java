package com.disabled.controller;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpSession;

import org.apache.ibatis.logging.LogException;
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
	private static final Logger logger = LoggerFactory.getLogger(DeviceListController.class);
	
	@Autowired
	StatsService statsService;
	
	@Autowired
	StatsMapper statsMapper;
	
	@Autowired
	CryptoARIAService cryptoARIAService;
	
	// 통계 화면으로 redirect
	@RequestMapping("")
	public String rootRedirect() {
		
		// GS인증시 삭제
		System.out.println("stats rootRedirect");
		// GS인증시 삭제
		
		return "redirect:/stats/login.do";
	}
	
	// 로그인 화면 이동
	@RequestMapping("/login.do")
	private String viewLogin() {
		return "stats/login";
	}
	
	// 로그인 버튼 클릭 시 action
	@ResponseBody
	@PostMapping("/login")
	private Map<String,Object> loginCheck( @RequestBody Map<String,String> body, HttpSession session) {
		
		String id = body.get("id");
		String pwd = body.get("pwd");
		String encryptPwd = null;
		Integer checkErr = -1;
		Map<String, Object> resultMap = new HashMap<String, Object>();
		
		//GS인증시 해당 소스는삭제)
		System.out.println(id + " " + pwd );
		//GS인증시 해당 솟스튼 삭제 삭제)
		
		try {
			
			// 암호화
			encryptPwd = cryptoARIAService.encryptPassword(pwd);
			
			checkErr = statsService.loginCheck(id, pwd); //db에 해당 사용자가 있는지 체크
			if(checkErr < 0) {
				throw new LogException("로그인 실패");
			}else {
				System.out.println("move deviceList");
				
				resultMap.put("success", true); // 로그인 성공하면 true 반환
				
				// 세션에 계정 정보 추가
				session.setAttribute("id", id);
				session.setAttribute("pwd", pwd);
				
				return resultMap;
			}
		} catch (Exception e) {
			
			logger.error("로그인 에러: {}" +e);
			resultMap.put("success", false); // 로그인 실패하면 false 반환
			return resultMap;
		}
		
	}
	
	/*
	 * 로그아웃
	 */
	@RequestMapping("/logout")
	public String logout(HttpSession session) {
	    session.invalidate(); // 세션 만료
	    return "redirect:/login";
	}
	
	/*
	 * 통계 화면으로 이동
	 * 
	 */
	@RequestMapping("/viewStat.do")
	private String viewStat(Model model) {
		
		// GS인증시 지워야 함
		System.out.println("viewStat in");
		// GS인증시 지워야 함
		
		logger.info("viewStat in");
		
		List<Map<String,Object>> statsByMonth = new ArrayList<Map<String,Object>>();
		
		try {
			statsByMonth = statsService.getEventByMonth();
		} catch (Exception e) {
			
			logger.error("통계 화면에서 에러 발생: {}" +e);
			
			// GS인증시 지워야 함
			System.out.println("통계 자료 로드 실패");
			// GS인증시 지워야 함
		}
	
		
		model.addAttribute("statsByMonth", statsByMonth);
		return "stats/stats";
	}
	
}
