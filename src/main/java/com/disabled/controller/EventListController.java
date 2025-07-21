package com.disabled.controller;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.apache.commons.collections.map.HashedMap;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import com.disabled.service.EventListService;

@Controller
@RequestMapping("/eventList")
public class EventListController {
	
	@Autowired
	EventListService eventListService;
	
	@RequestMapping("")
	public String rootRedirect() {
		
		System.out.println("viewEventList redirect");
		
		return "redirect:/eventList/viewEventList.do";
	}
	
	// 불법주차 리스트
	@RequestMapping("/viewEventList.do")
	public String viewEventList(
			@RequestParam(value="startDate", required=false) String startDate
			, @RequestParam(value="endDate", required=false) String endDate
			, @RequestParam(value="searchKeyword", required=false) String searchKeyword
			, @RequestParam(value="page", required=false) Integer page
			, Model model) {
		
		System.out.println("viewEventList in");
		
		List<Map<String, Object>> eventList = new ArrayList<Map<String,Object>>();
		
		// 페이징 객체
		PaginationInfo paginationInfo = new PaginationInfo();
		
		// 오늘 날짜 설정
		LocalDate today = LocalDate.now();
		DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyyMMdd");
		
		// 파라미터 값 설정
		Map<String, Object> paramMap = new HashedMap();
		
		try {
			
			//특별한 검색 조건을 지정하지 않을 경우 시작일은 그 달의 첫째날로 초기화, 마지막 날은 오늘로 초기화
			if(startDate == null || startDate.isEmpty()) {
				startDate = today.withDayOfMonth(1).format(formatter).toString();
			}else {
				startDate = startDate.formatted("yyyyMMdd").toString();
			}
			if(endDate == null || endDate.isEmpty()) {
				endDate = today.format(formatter).toString();
			}else {
				endDate = endDate.formatted("yyyyMMdd").toString();
			}
			
			//현재 페이지가 없는 경우 1페이지로 설정
			if(page == null || page < 0) {
				page = 1;
			}
			
			System.out.println("searchKeyword: "+ searchKeyword + " startDate: " + startDate + " endDate: " + endDate + " ");
			
			// 페이징 설정
			paginationInfo.setCurrentPageNo(page); // 현제 페이지 번호
			paginationInfo.setRecordCountPerPage(10);  // 한 페이지에 출력할 게시글 수
			paginationInfo.setPageSize(10); // 페이지 블록 수
			
			int firstIndex = paginationInfo.getFirstRecordIndex(); // LIMIT offset
			int recordCountPerPage = paginationInfo.getRecordCountPerPage();  //LIMIT count
			
			System.out.println("firstIndex: " + firstIndex);
			System.out.println("recordCountPerPage: " + recordCountPerPage);
			
			// DB 검색을 위한 파라미터 설정
			paramMap.put("firstIndex", firstIndex);
			paramMap.put("recordCountPerPage", recordCountPerPage);
			paramMap.put("searchKeyword", searchKeyword);
			paramMap.put("startDate",startDate);
			paramMap.put("endDate",endDate);
			
			System.out.println("getEventList");
			
			eventList = eventListService.getEventList(paramMap);
			
		} catch (Exception e) {
			System.out.println("이벤트 리스트 컨트롤러 오류");
			System.out.println(e + "");
			// TODO: handle exception
		}
		
		// model add
		model.addAttribute("paginationInfo",paginationInfo);
		model.addAttribute("eventList", eventList);
		model.addAttribute("searchKeyword", searchKeyword);
		model.addAttribute("startDate",startDate);
		model.addAttribute("endDate", endDate);
		
		System.out.println("return eventList");
		
		return "eventList/eventList";
	}
	
	// 불법주차 리스트 상세
	@GetMapping("/eventListDetail")
	private String eventListDetail(
			@RequestParam(value="evId") Integer evId
			, @RequestParam(value="startDate", required=false) String startDate
			, @RequestParam(value="endDate", required=false) String endDate
			, @RequestParam(value="searchKeyword",required=false) String searchKeyword
			, Model model) {
		
		System.out.println("eventListDetail in");
		
		Map<String, Object> eventListDetail = new HashedMap();
		
		try {
			
			System.out.println("getEventListDetail");
			
			eventListDetail = eventListService.getEventListDetail(evId);
		} catch (Exception e) {
			System.out.println("이벤트 리스트 상세 컨트롤러 오류");
			// TODO: handle exception
		}
		
		// mdoel add
		model.addAttribute("eventListDetail", eventListDetail);
		// 상세 화면에서 리스트 화면으로 돌아왔을 때에도 검색 조건 유지
		model.addAttribute("searchKeyword", searchKeyword);
		model.addAttribute("startDate", startDate);
		model.addAttribute("endDate", endDate);
		
		System.out.println("return eventListDetail");
		
		return "eventList/eventListDetail";
	}
}
