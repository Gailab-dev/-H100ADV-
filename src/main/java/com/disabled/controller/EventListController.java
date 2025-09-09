package com.disabled.controller;

import java.io.File;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

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
	private static final Logger logger = LoggerFactory.getLogger(EventListController.class);
	
	// 초기화면으로 redirect
	@RequestMapping("")
	public String rootRedirect() {
		
		return "redirect:/eventList/viewEventList.do";
	}
	
	// 불법주차 리스트
	@RequestMapping("/viewEventList.do")
	public String viewEventList(
			@RequestParam(value="startDate", required=false) String startDate
			, @RequestParam(value="endDate", required=false) String endDate
			, @RequestParam(value="searchKeyword", required=false) String searchKeyword
			, @RequestParam(value="page", required=false) Integer page
			, Model model
			, HttpSession session) {
		
		// 접근 로그
		logger.info("{} 사용자의 {}에 deviceList 화면 접속.", session.getAttribute("id"),LocalDateTime.now());
		
		List<Map<String, Object>> eventList = new ArrayList<Map<String,Object>>();
		
		// 페이징 객체
		PaginationInfo paginationInfo = new PaginationInfo();
		
		// 파라미터 값 설정
		Map<String, Object> paramMap = new HashMap<String, Object>();
		
		// dateType Input 태그의 format에 맞게 날짜를 convert한 날짜 문자열
		String convertStartDate = null;
		String convertEndDate = null;
		
		try {
			
			//특별한 검색 조건을 지정하지 않을 경우 초기화
			if(startDate == null || startDate.isEmpty()) {
				startDate = "";
			}else {
				startDate = startDate.replace("-", "");
			}
			if(endDate == null || endDate.isEmpty()) {
				endDate = "";
			}else {
				endDate = endDate.replace("-", "");;
			}
			
			//현재 페이지가 없는 경우 1페이지로 설정
			if(page == null || page < 0) {
				page = 1;
			}
			
			
			// 페이징 설정
			paginationInfo.setCurrentPageNo(page); // 현제 페이지 번호
			paginationInfo.setRecordCountPerPage(10);  // 한 페이지에 출력할 게시글 수
			paginationInfo.setPageSize(10); // 페이지 블록 수
			
			int firstIndex = paginationInfo.getFirstRecordIndex(); // LIMIT offset
			int recordCountPerPage = paginationInfo.getRecordCountPerPage();  //LIMIT count
			int totalRecordCount = eventListService.getTotalRecordCount(startDate,endDate,searchKeyword);
			
			paginationInfo.setTotalRecordCount(totalRecordCount);
			
			// DB 검색을 위한 파라미터 설정
			paramMap.put("firstIndex", firstIndex);
			paramMap.put("recordCountPerPage", recordCountPerPage);
			paramMap.put("searchKeyword", searchKeyword);
			paramMap.put("startDate",startDate);
			paramMap.put("endDate",endDate);
			
			// 검색 조건에 따른 이벤트 리스트 조회
			eventList = eventListService.getEventList(paramMap);
			
			// date 타입 input태그에 날짜가 표시되도록 format 변환
			// stringTypeInputTagFormat: 문자열을 날짜로 변환
			SimpleDateFormat stringTypeInputTagFormat = new SimpleDateFormat("yyyyMMdd");
			
			// 날짜를 문자열로 변환
			SimpleDateFormat DateTypeInputTagFormat = new SimpleDateFormat("yyyy-MM-dd");
			
			// 검색조건의 시작 날짜의 타입을 날짜로 변환한 뒤, 원하는 형식의 문자열로 재변환
			if(startDate != "" && !startDate.isEmpty() && startDate != null) {
				Date start = stringTypeInputTagFormat.parse(startDate);
				convertStartDate = DateTypeInputTagFormat.format(start);
			}
			
			// 검색조건의 끝 날짜의 타입을 날짜로 변환한 뒤, 원하는 형식의 문자열로 재변환
			if(endDate != "" && !endDate.isEmpty() && endDate != null) {
				Date end = stringTypeInputTagFormat.parse(endDate);
				convertEndDate = DateTypeInputTagFormat.format(end);
			}
			
		}catch (ParseException e) {
			logger.error("데이터 타입 변환 중 오류 발생 : ",e);
		}
		
		// model add
		model.addAttribute("paginationInfo",paginationInfo);
		model.addAttribute("eventList", eventList);
		model.addAttribute("searchKeyword", searchKeyword);
		model.addAttribute("startDate",convertStartDate);
		model.addAttribute("endDate", convertEndDate);
		
		return "eventList/eventList";
	}
	
	// 불법주차 리스트 상세
	@GetMapping("/eventListDetail")
	private String eventListDetail(
			@RequestParam(value="evId") Integer evId
			, @RequestParam(value="startDate", required=false) String startDate
			, @RequestParam(value="endDate", required=false) String endDate
			, @RequestParam(value="searchKeyword",required=false) String searchKeyword
			, Model model
			, HttpServletResponse res
			, HttpSession session) {
		
		// 접근 로그
		logger.info("{} 사용자의 {}에 deviceList 화면 접속.", session.getAttribute("id"),LocalDateTime.now());
		
		try {
			Map<String, Object> eventListDetail = new HashMap<String, Object>();
			
			eventListDetail = eventListService.getEventListDetail(evId);

			// mdoel add
			model.addAttribute("eventListDetail", eventListDetail);
			// 상세 화면에서 리스트 화면으로 돌아왔을 때에도 검색 조건 유지
			model.addAttribute("searchKeyword", searchKeyword);
			model.addAttribute("startDate", startDate);
			model.addAttribute("endDate", endDate);
			
			// 이미지파일, 영상 파일 module에서 수신
			eventListService.requestFileFromModule(res, evId,eventListDetail);
			
		} catch (IllegalArgumentException e) {
			logger.error("잘못된 인자 전달로 인한 오류 발생 : ",e);
		}

		return "eventList/eventListDetail";
	}
	
	/**
	 * 외부 URL을 통한 이미지 화면에 출력
	 * @Param
	 * - filePath: 파일경로
	 */
	@RequestMapping("/imageView.do")
	public void imageView(@RequestParam("filePath") String filePath, HttpServletResponse res) {
		
		// 최종 fullFilePath 
		String fullFilePath = null;
		
		try {
			
	    	if(filePath == null || filePath == "") {
	    		throw new IllegalArgumentException("filePath는 null이거나 공백이어서는 안 됩니다.");
	    	}
			
			// OS별 fullFilePath 반환
			fullFilePath = eventListService.mkFullFilePath(filePath);
	    	
			// 디렉토리 생성
			eventListService.mkdirForStream(fullFilePath);
			
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
		} catch (IllegalArgumentException e) {
			logger.error("잘못된 인자 전달 : ",e);
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
	    	
	    	if(filePath == null || filePath == "") {
	    		throw new IllegalArgumentException("filePath는 null이거나 공백이어서는 안 됩니다.");
	    	}
	    	
			// OS별 fullFilePath 반환
			fullFilePath = eventListService.mkFullFilePath(filePath);
	    	
			// 디렉토리 생성
			eventListService.mkdirForStream(fullFilePath);
			
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
	        
	    } catch (IllegalArgumentException e) {
	        logger.error("잘못된 인자 전달 오류 발생: ",e);
	    } catch (IndexOutOfBoundsException e2) {
	    	logger.error("잘못된 index 오류 발생 : ",e2);
	    }
	}


}
