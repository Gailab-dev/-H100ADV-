package com.disabled.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

import com.disabled.service.StatsService;

@Controller
@RequestMapping("/stats")
public class StatsController {
	
	@Autowired
	StatsService statsService;
	
	@RequestMapping("")
	public String rootRedirect() {
		
		System.out.println("stats rootRedirect");
		
		return "redirect:/stats/login.do";
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
		
		System.out.println("move deviceList");
		
		return "redirect:/deviceList";
		
	}
	
}
