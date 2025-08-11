package com.disabled.controller;

import java.io.File;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(DeviceListController.class);
	
	// 초기화면으로 redirect
	@RequestMapping("")
	public String rootRedirect() {
		
		// GS 인증시 삭제
		System.out.println("viewEventList redirect");
		// GS 인증시 삭제
		
		logger.info("viewEventList redirect");
		
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
		
		// GS인증시 지워야함
		System.out.println("viewEventList in");
		System.out.println("파라미터 초기화 전 startDate"+startDate+"endDate: "+endDate+"searchKeyword: "+searchKeyword+"page: "+page);
		// GS인증시 지워야함
		
		
		
		List<Map<String, Object>> eventList = new ArrayList<Map<String,Object>>();
		
		// 페이징 객체
		PaginationInfo paginationInfo = new PaginationInfo();
		
		// 오늘 날짜 설정
		LocalDate today = LocalDate.now();
		DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyyMMdd");
		
		// 파라미터 값 설정
		Map<String, Object> paramMap = new HashMap<String, Object>();
		
		// dateType Input 태그의 format에 맞게 날짜를 convert한 날짜 문자열
		String convertStartDate = null;
		String convertEndDate = null;
		
		try {
			
			//특별한 검색 조건을 지정하지 않을 경우 시작일은 그 달의 첫째날로 초기화, 마지막 날은 오늘로 초기화
			if(startDate == null || startDate.isEmpty()) {
				// startDate = today.withDayOfMonth(1).format(formatter).toString();
			}else {
				startDate = startDate.replace("-", "");
			}
			if(endDate == null || endDate.isEmpty()) {
				// endDate = today.format(formatter).toString();
			}else {
				endDate = endDate.replace("-", "");;
			}
			
			//현재 페이지가 없는 경우 1페이지로 설정
			if(page == null || page < 0) {
				page = 1;
			}
			
			System.out.println("파라미터 초기화 후 searchKeyword: "+ searchKeyword + " startDate: " + startDate + " endDate: " + endDate + " ");
			
			// 페이징 설정
			paginationInfo.setCurrentPageNo(page); // 현제 페이지 번호
			paginationInfo.setRecordCountPerPage(10);  // 한 페이지에 출력할 게시글 수
			paginationInfo.setPageSize(10); // 페이지 블록 수
			
			int firstIndex = paginationInfo.getFirstRecordIndex(); // LIMIT offset
			int recordCountPerPage = paginationInfo.getRecordCountPerPage();  //LIMIT count
			
			// GS 인증시 삭제
			System.out.println("firstIndex: " + firstIndex);
			System.out.println("recordCountPerPage: " + recordCountPerPage);
			// GS 인증시 삭제
			
			// DB 검색을 위한 파라미터 설정
			paramMap.put("firstIndex", firstIndex);
			paramMap.put("recordCountPerPage", recordCountPerPage);
			paramMap.put("searchKeyword", searchKeyword);
			paramMap.put("startDate",startDate);
			paramMap.put("endDate",endDate);
			
			// GS 인증시 삭제
			System.out.println("getEventList");
			// GS 인증시 삭제
			
			// 검색 조건에 따른 이벤트 리스트 조회
			eventList = eventListService.getEventList(paramMap);
			
			// date 타입 input태그에 날짜가 표시되도록 format 변환
			SimpleDateFormat stringTypeInputTagFormat = new SimpleDateFormat("yyyyMMdd");
			Date start = stringTypeInputTagFormat.parse(startDate);
			Date end = stringTypeInputTagFormat.parse(endDate);
			SimpleDateFormat DateTypeInputTagFormat = new SimpleDateFormat("yyyy-MM-dd");
			convertStartDate = DateTypeInputTagFormat.format(start);
			convertEndDate = DateTypeInputTagFormat.format(end);
			
		} catch (Exception e) {
			// GS 인증시 삭제
			System.out.println("이벤트 리스트 컨트롤러 오류");
			System.out.println(e + "");
			// GS 인증시 삭제
			logger.error("이벤트 리스트 컨트롤러 오류: {}" + e);
		}
		
		System.out.println("model에 input된 객체 / paginationInfo: "+ paginationInfo 
				+ " eventList: " + eventList 
				+ " searchKeyword: " + searchKeyword
				+ " convertStartDate: " + convertStartDate
				+ " convertEndDate: "+ convertEndDate
				);
		
		// model add
		model.addAttribute("paginationInfo",paginationInfo);
		model.addAttribute("eventList", eventList);
		model.addAttribute("searchKeyword", searchKeyword);
		model.addAttribute("startDate",convertStartDate);
		model.addAttribute("endDate", convertEndDate);
		
		// GS 인증시 삭제
		System.out.println("return eventList");
		// GS 인증시 삭제
		
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
		
		// GS 인증시 삭제
		System.out.println("eventListDetail in");
		// GS 인증시 삭제
		
		Map<String, Object> eventListDetail = new HashMap<String, Object>();
		
		try {
			
			// GS 인증시 삭제
			System.out.println("getEventListDetail");
			// GS 인증시 삭제
			
			eventListDetail = eventListService.getEventListDetail(evId);
		} catch (Exception e) {
			
			// GS 인증시 삭제
			System.out.println("이벤트 리스트 상세 컨트롤러 오류");
			// GS 인증시 삭제
			
			logger.error("이벤트 리스트 상세 컨트롤러 오류: {}"+e);
			
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
	
	/**
	 * 외부 URL을 통한 이미지 화면에 출력
	 * @Param
	 * - filePath: 파일경로
	 */
	@RequestMapping("/imageView.do")
	public void imageView(@RequestParam("filePath") String filePath, HttpServletResponse res) {
		
		// GS 인증시 삭제
		System.out.println("imageView in : "+filePath);
		// GS 인증시 삭제
		
		// 최종 fullFilePath 
		String fullFilePath = null;
		
		try {
			
			// 디렉토리 생성
			eventListService.mkdirForStream(filePath);
			
			// OS별 fullFilePath 반환
			fullFilePath = eventListService.mkFullFilePath(filePath);
			
			// GS 인증시 삭제
			System.out.println("mkFullFilePath result : " + fullFilePath);
			// GS 인증시 삭제
			
			// file 객체 생성
			File file = new File(fullFilePath);
			
	        // Content-Type 설정 (간단히 jpg/png로 처리)
	        if (filePath.endsWith(".png")) {
	            res.setContentType("image/png");
	        } else if (filePath.endsWith(".jpg") || filePath.endsWith(".jpeg")) {
	            res.setContentType("image/jpeg");
	        } else {
	            res.setContentType("application/octet-stream");
	        }
	        
	        // 이미지 송출 전 오류 점검
	        eventListService.fileCheck(file);
	        
			// 외부 저장소에 저장된 image 파일의 외부 경로로 웹 화면에 이미지 송출
			eventListService.viewImageOfFilePath(file, res);
			
		} catch (Exception e) {
			logger.error("외부 URL을 통한 이미지를 화면에 출력하는 도중 오류 발생: {}"+e);
		}
	}
	
	/**
	 * 외부 URL을 통한 비디오 화면에 스트리밍
	 * @Param
	 * - filePath: 파일경로
	 */
	@RequestMapping("/videoView.do")
	public void videoView(@RequestParam("filePath") String filePath, HttpServletRequest req, HttpServletResponse res) {
	    
		// 최종 fullFilePath 
		String fullFilePath = null;

	    try {
	    	
			// 디렉토리 생성
			eventListService.mkdirForStream(filePath);
			
			// OS별 fullFilePath 반환
			fullFilePath = eventListService.mkFullFilePath(filePath);
			
			// GS 인증시 삭제
			System.out.println("mkFullFilePath result : " + fullFilePath);
			// GS 인증시 삭제
			
			// file 객체 생성
			File file = new File(fullFilePath);
			
	        // 비디오 확장자에 따라 Content-Type 설정
	        if (filePath.endsWith(".mp4")) {
	            res.setContentType("video/mp4");
	        } else if (filePath.endsWith(".webm")) {
	            res.setContentType("video/webm");
	        } else {
	            res.setContentType("application/octet-stream");
	        }
	    	
	        // 이미지 송출 전 오류 점검
	        eventListService.fileCheck(file);
	        
	    	// 외부 저장소에 저장된 video 파일의 외부 경로로 웹 화면에 비디오 파일 스트리밍
	    	eventListService.viewVideoOfFilePath(file, req, res);
	        
	    } catch (Exception e) {
	        logger.error("비디오 파일 스티미밍 도중 에러 발생: {}"+e);
	    }
	}


}
