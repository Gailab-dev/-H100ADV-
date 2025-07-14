package com.disabled.controller;

import java.sql.Date;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Param;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
@RequestMapping("/eventList")
public class EventListController {
	
	@RequestMapping("")
	public String rootRedirect() {
		
		return "redirect:/eventList/viewEventList.do";
	}
	
	@RequestMapping("/viewEventList.do")
	public String viewEventList(
			@RequestParam(value="startDate", required=false) String startDate
			, @RequestParam(value="endDate", required=false) String endDate
			, @RequestParam(value="searchKeyword", required=false) String searchKeyword
			, Model model) {
		
		List<Map<String, Object>> eventList = new ArrayList<Map<String,Object>>();
		
		PaginationInfo paginationInfo = new PaginationInfo();
		
		try {
			
			//특별한 검색 조건을 지정하지 않을 경우 시작일은 그 달의 첫째날로 초기화
			// if 
			
			// eventList = 
		} catch (Exception e) {
			// TODO: handle exception
		}
		
		return "eventList/eventList";
	}
	
	@GetMapping("/eventListDetail")
	private String eventListDetail(Integer evId, Model model) {
		
		return "eventList/eventListDetail";
	}
}
