package com.minwon.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

import com.minwon.service.StatsService;

@Controller
@RequestMapping("/stats")
public class StatsController {
	
	@Autowired
	StatsService statsService;
	
	@RequestMapping("/")
	public String rootRedirect() {
		return "forward:/login.do";
	}
	
	@RequestMapping("/login.do")
	private String viewLogin() {
		return "stats/login";
	}
	
	@RequestMapping("/login")
	private String loginCheck(String id, String pwd) {
		
		System.out.println(id + " " + pwd );
		
		try {
			statsService.loginCheck(id, pwd);
		} catch (Exception e) {
			e.printStackTrace();
			
			return "stats/login";
			// TODO: handle exception
		} 
		
		return "stats/stats";
		
	}
	
}
