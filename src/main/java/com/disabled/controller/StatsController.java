package com.disabled.controller;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.apache.ibatis.logging.LogException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;

import com.disabled.mapper.StatsMapper;
import com.disabled.service.StatsService;

@Controller
@RequestMapping("/stats")
public class StatsController {
	
	@Autowired
	StatsService statsService;
	
	@Autowired
	StatsMapper statsMapper;
	
	// 통계 화면으로 redicrec
	@RequestMapping("")
	public String rootRedirect() {
		
		System.out.println("stats rootRedirect");
		
		return "redirect:/stats/login.do";
	}
	
	// 로그인 화면 이동
	@RequestMapping("/login.do")
	private String viewLogin() {
		return "stats/login";
	}
	
	// 로그인 버튼 시 취해야 할 action
	@RequestMapping("/login")
	private String loginCheck(String id, String pwd) {
		
		System.out.println(id + " " + pwd );
		Integer checkErr = -1;
		
		try {
			checkErr = statsService.loginCheck(id, pwd);
			if(checkErr < 0) {
				throw new LogException("로그인 실패");
			}else {
				System.out.println("move deviceList");
				return "redirect:/deviceList";
			}
		} catch (Exception e) {
			e.printStackTrace();
			
			return "stats/login";
			// TODO: handle exception
		} 
		
	}
	
	/*
	 * 통계 화면으로 이동
	 * 
	 */
	@RequestMapping("/viewStat.do")
	private String viewStat(Model model) {
		
		System.out.println("viewStat in");
		
		List<Map<String,Object>> statsByMonth = new ArrayList<Map<String,Object>>();
		
		try {
			statsByMonth = statsService.getEventByMonth();
		} catch (Exception e) {
			System.out.println("통계 자료 로드 실패");
			// TODO: handle exception
		}
		
		System.out.println("return");
		
		model.addAttribute("statsByMonth", statsByMonth);
		return "stats/stats";
	}
	
}
