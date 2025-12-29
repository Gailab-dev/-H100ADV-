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
	
	@Autowired
	LogDiskManager logDiskManager;
	
	@Autowired
	LoginMapper loginMapper;
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(EventListController.class);
	
	// 초기화면으로 redirect
	@RequestMapping("")
	public String rootRedirect() {
		
		return "redirect:/eventList/viewEventList.do";
	}
	
	/**
	 * 불법주차 리스트 화면 이동
	 * @param startDate 	검색 시작 날짜(String)
	 * @param endDate 		검색 종료 날짜(String)
	 * @param searchKeyword	검색어(String)
	 * @param page			페이지 수(Integer)
	 * @param pageSize		한 화면에 보여줄 컬럼의 크기(Integer)
	 * @param model
	 * @param session
	 * @return
	 */
	// 불법주차 리스트
	@RequestMapping("/viewEventList.do")
	public String viewEventList(
			@RequestParam(value="startDate", required=false) String startDate
			, @RequestParam(value="endDate", required=false) String endDate
			, @RequestParam(value="searchKeyword", required=false) String searchKeyword
			, @RequestParam(value="page", required=false) Integer page
			, @RequestParam(value="pageSize", defaultValue = "10" ) Integer pageSize
			, Model model
			, HttpSession session) {
		
		// 접근 로그
		String uIdStr = session.getAttribute("uId") == null ? null : session.getAttribute("uId").toString();
		if(uIdStr != null) {
			logger.info("{}(" + loginMapper.getLoginId(Integer.parseInt(uIdStr)) + ") 사용자의 {}에 불법주차 리스트 화면 접속.", session.getAttribute("uId"),LocalDateTime.now());
		}
		boolean useTblLog = false;	// 로그 스토리지 사용 가능 여부
		
		List<Map<String, Object>> eventList = new ArrayList<Map<String,Object>>();
		
		int totalRecordCount = 0;

		// ====== 유효성 검증 [S] ====== //
		// startDate 검증 (날짜 형식 및 SQL Injection 방어)
		if (startDate != null && !startDate.isEmpty()) {
			if (!isValidDate(startDate) || containsDangerousPattern(startDate)) {
				logger.warn("유효하지 않은 startDate 요청: {}", startDate);
				model.addAttribute("errorMessage", "유효하지 않은 시작 날짜 형식입니다.");
				return "error";
			}
		}

		// endDate 검증 (날짜 형식 및 SQL Injection 방어)
		if (endDate != null && !endDate.isEmpty()) {
			if (!isValidDate(endDate) || containsDangerousPattern(endDate)) {
				logger.warn("유효하지 않은 endDate 요청: {}", endDate);
				model.addAttribute("errorMessage", "유효하지 않은 종료 날짜 형식입니다.");
				return "error";
			}
		}

		// searchKeyword 검증 (XSS, SQL Injection 방어)
		if (searchKeyword != null && !searchKeyword.isEmpty()) {
			if (searchKeyword.length() > 100 || containsDangerousPattern(searchKeyword)) {
				logger.warn("유효하지 않은 searchKeyword 요청: {}", searchKeyword);
				model.addAttribute("errorMessage", "유효하지 않은 검색어입니다.");
				return "error";
			}
		}

		// page 검증 (정수 범위 검증)
		if (page != null) {
			if (page < 0 || page > 100000) {
				logger.warn("유효하지 않은 page 요청: {}", page);
				model.addAttribute("errorMessage", "유효하지 않은 페이지 번호입니다.");
				return "error";
			}
		}

		// pageSize 검증 (정수 범위 검증)
		if (pageSize != null) {
			if (pageSize < 1 || pageSize > 100) {
				logger.warn("유효하지 않은 pageSize 요청: {}", pageSize);
				model.addAttribute("errorMessage", "유효하지 않은 페이지 크기입니다.");
				return "error";
			}
		}
		// ====== 유효성 검증 [E] ====== //
		
		// 페이지 null 방지
		if (page == null || page < 1) page = 1;
		
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
			
			// 세션과 비교해 검색 결과가 달라졌다면 검색 결과 1로 설정
			String prevSig = (String) session.getAttribute("eventListSearchSig");
			String sig = startDate + "|" + endDate + "|" + searchKeyword;
			if (!sig.equals(prevSig)) {
				page = 1;
			    session.setAttribute("eventListSearchSig", sig);
			}
			
			
			// 페이징 설정
			paginationInfo.setCurrentPageNo(page); // 현제 페이지 번호
			paginationInfo.setRecordCountPerPage(10);  // 한 페이지에 출력할 게시글 수
			paginationInfo.setPageSize(10); // 페이지 블록 수
			
			int recordCountPerPage = paginationInfo.getRecordCountPerPage();  //LIMIT count
			totalRecordCount = eventListService.getTotalRecordCount(startDate,endDate,searchKeyword);
			
			paginationInfo.setTotalRecordCount(totalRecordCount);
			
		    // 마지막 페이지 계산 후 page 보정
		    int lastPage = (int) Math.ceil(totalRecordCount / (double) recordCountPerPage);
		    if (lastPage < 1) lastPage = 1;

		    int currentPage = Math.min(Math.max(page, 1), lastPage);
		    paginationInfo.setCurrentPageNo(currentPage);

		    // offset 재계산
		    int firstIndex = (currentPage - 1) * recordCountPerPage;
			
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
			
			// 로그 스토리지 사용 가능 여부 조회
			useTblLog = logDiskManager.hasEnoughLogSpace();
			
		}catch (ParseException e) {
			logger.error("데이터 타입 변환 중 오류 발생 : ",e);
		}
		
		// model add
		model.addAttribute("paginationInfo",paginationInfo);
		model.addAttribute("eventList", eventList);
		model.addAttribute("searchKeyword", searchKeyword);
		model.addAttribute("startDate",convertStartDate);
		model.addAttribute("endDate", convertEndDate);
		model.addAttribute("useTblLog", useTblLog);
		model.addAttribute("pageSize", pageSize);
		model.addAttribute("totalRecordCount", totalRecordCount);
		
		return "eventList/eventList";
	}
	
	/**
	 * 불법주라 리스트 상세 정보를 가져오는 함수
	 * @param dvId
	 * @param evId
	 * @param startDate
	 * @param endDate
	 * @param searchKeyword
	 * @param dvAddr
	 * @param model
	 * @param res
	 * @param session
	 * @return 오류라면 "error", 정상이라면 불법주차 리스트 상세 화면 URL
	 */
	// 불법주차 리스트 상세
	@GetMapping("/eventListDetail")
	private String eventListDetail(
			@RequestParam(value="dvId", required=false) Integer dvId
			, @RequestParam(value="evId") Integer evId
			, @RequestParam(value="startDate", required=false) String startDate
			, @RequestParam(value="endDate", required=false) String endDate
			, @RequestParam(value="searchKeyword",required=false) String searchKeyword
			, @RequestParam(value="dvAddr", required = false) String dvAddr
			, Model model
			, HttpServletResponse res
			, HttpSession session) {
		
		// 접근 로그
		logger.info("{} 사용자의 {}에 deviceList 화면 접속.", session.getAttribute("uId"),LocalDateTime.now());
		
		try {
			
			// ====== 유효성 검증 [S] ====== //
			// evId 유효성 검증 (Injection 방어)
			if (evId == null || evId <= 0) {
				logger.warn("유효하지 않은 evId 요청: {}", evId);
				model.addAttribute("errorMessage", "유효하지 않은 이벤트 ID입니다.");
				return "error";
			}

			// evId 범위 검증 (정수 오버플로우 방지)
			if (evId > Integer.MAX_VALUE / 2) {
				logger.warn("범위를 벗어난 evId 요청: {}", evId);
				model.addAttribute("errorMessage", "유효하지 않은 이벤트 ID입니다.");
				return "error";
			}

			// startDate 검증 (날짜 형식 및 SQL Injection 방어)
			if (startDate != null && !startDate.isEmpty()) {
				if (!isValidDate(startDate) || containsDangerousPattern(startDate)) {
					logger.warn("유효하지 않은 startDate 요청: {}", startDate);
					model.addAttribute("errorMessage", "유효하지 않은 날짜 형식입니다.");
					return "error";
				}
			}

			// endDate 검증 (날짜 형식 및 SQL Injection 방어)
			if (endDate != null && !endDate.isEmpty()) {
				if (!isValidDate(endDate) || containsDangerousPattern(endDate)) {
					logger.warn("유효하지 않은 endDate 요청: {}", endDate);
					model.addAttribute("errorMessage", "유효하지 않은 날짜 형식입니다.");
					return "error";
				}
			}

			// searchKeyword 검증 (XSS, SQL Injection 방어)
			if (searchKeyword != null && !searchKeyword.isEmpty()) {
				if (searchKeyword.length() > 100 || containsDangerousPattern(searchKeyword)) {
					logger.warn("유효하지 않은 searchKeyword 요청: {}", searchKeyword);
					model.addAttribute("errorMessage", "유효하지 않은 검색어입니다.");
					return "error";
				}
			}

			// dvAddr 검증 (XSS, SQL Injection, Path Traversal 방어)
			if (dvAddr != null && !dvAddr.isEmpty()) {
				if (dvAddr.length() > 301 || containsDangerousPattern(dvAddr)) {
					logger.warn("유효하지 않은 dvAddr 요청: {}", dvAddr);
					model.addAttribute("errorMessage", "유효하지 않은 주소입니다.");
					return "error";
				}
			}
			
			// ====== 유효성 검증 [E] ====== //
			
			// ====== 변수 선언 [S] ====== //
			// 불법주차 리스트 상세 정보
			Map<String, Object> eventListDetail = new HashMap<String, Object>();
			// ====== 변수 선언 [S] ====== //
			
			// ====== 서비스 [S] ====== //
			// 불법주차 리스트 상세 정보 가져오기
			eventListDetail = eventListService.getEventListDetail(evId);
			if(eventListDetail != null) {
				String evCd = String.valueOf(eventListDetail.get("ev_cd"));
				String ev_cd_name = "";
			    switch (evCd) {
		        case "1": ev_cd_name = "미등록차량"; break;
		        case "4": ev_cd_name = "위험상황"; break;
		        case "5": ev_cd_name = "물건적재"; break;
		        case "6": ev_cd_name = "이중주차"; break;
		        default: 
		            logger.warn("ev_cd 값이 null 또는 정의되지 않음: {}", evCd);
			    }
			    
				// 접근 로그
			    String uIdStr = session.getAttribute("uId") == null ? null : session.getAttribute("uId").toString();
			    if(uIdStr != null) {
				logger.info("{}(" + loginMapper.getLoginId(Integer.parseInt(uIdStr)) + ") 사용자의 {}에 불법주차 리스트 상세 화면 접속 - 위치: " + dvAddr 
						+ ", 날짜: " + eventListDetail.get("ev_date") 
						+ ", 차량번호: " + eventListDetail.get("ev_car_num") 
						+ ", 유형: " 	+ ev_cd_name
						, session.getAttribute("uId"),LocalDateTime.now());
			    }
			}
			
			// 이미지파일, 영상 파일 module에서 수신
			boolean moduleCheck = false;
			moduleCheck = eventListService.requestFileFromModule(res, evId,eventListDetail);
			if(!moduleCheck) {
				logger.error("Device와 파일 송수신 도중 오류 발생 / response : " + res.getStatus() + "/ evId : "+evId + " / eventListDetail : " + eventListDetail);
				model.addAttribute("errorMsg", "상세 조회 중 오류가 발생했습니다.");
				return "redirect:/eventList/viewEventList.do";
			}
			
			// 이미지, 영상 파일 복호화
		    boolean decCheck = false;
		    decCheck = eventListService.requestFileDec(res, evId,eventListDetail);
		    if(!decCheck) {
		    	logger.error("이미지, 영상 파일 복호화 중 오류 발생 / response : " + res.getStatus() + "/ evId : "+evId + " / eventListDetail : " + eventListDetail);
		    	model.addAttribute("errorMsg", "상세 조회 중 이미지, 영상 파일 복호화 오류가 발생했습니다.");
		    	return "redirect:/eventList/viewEventList.do";
		    }
			
			// ====== 서비스 [E] ====== //
			
			// ====== mdoel add [S] ====== //
			model.addAttribute("eventListDetail", eventListDetail);
			model.addAttribute("searchKeyword", searchKeyword);
			model.addAttribute("startDate", startDate);
			model.addAttribute("endDate", endDate);
			// ====== mdoel add [E] ====== //
			
		} catch (IllegalArgumentException e) {
			logger.error("잘못된 인자 전달로 인한 오류 발생 : ",e);
			model.addAttribute("errorMsg", "상세 조회 중 오류가 발생했습니다.");
			return "redirect:/eventList/viewEventList.do";
			
		}

		return "eventList/eventListDetail";
	}
	
	/**
	 * tomcat 외부 경로에 저장된 이미지 파일 불러오기
	 * @Param
	 * - filePath: 파일경로
	 */
	@RequestMapping("/imageView.do")
	public void imageView(@RequestParam("filePath") String filePath, HttpServletResponse res) {
		
		// 최종 fullFilePath 
		String fullFilePath = null;
		
		try {
			
			// ====== 유효성 검증 [S] ====== //
	    	if(filePath == null || filePath == "") {
	    		throw new IllegalArgumentException("filePath는 null이거나 공백이어서는 안 됩니다.");
	    	}
	    	// filePath 길이 검증
			if (filePath.length() > 500) {
				logger.warn("유효하지 않은 filePath 길이: {}", filePath.length());
				throw new IllegalArgumentException("파일 경로가 너무 깁니다.");
			}

			// Path Traversal 방어
			if (isPathTraversal(filePath)) {
				logger.warn("Path Traversal 시도 감지: {}", filePath);
				throw new IllegalArgumentException("유효하지 않은 파일 경로입니다.");
			}

			// 이미지 확장자 검증
			if (!isValidImageExtension(filePath)) {
				logger.warn("유효하지 않은 이미지 확장자: {}", filePath);
				throw new IllegalArgumentException("유효하지 않은 파일 형식입니다.");
			}
			// ====== 유효성 검증 [E] ====== //
			
			// ====== 서비스 [S] ====== //
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
			// ====== 서비스ㅜ [E] ====== //
		} catch (IllegalArgumentException e) {
			logger.error("잘못된 인자 전달 : ",e);
		}
		

		
	}
	
	/**
	 * tomcat 외부 경로에 저장된 비디오 파일 불러오기
	 * @Param
	 * - filePath: 파일경로
	 */
	@RequestMapping("/videoView.do")
	public void videoView(@RequestParam("filePath") String filePath, HttpServletRequest req, HttpServletResponse res) {
	    
		// 최종 fullFilePath 
		String fullFilePath = null;

	    try {
	    	
			// ====== 유효성 검증 [S] ====== //
	    	if(filePath == null || filePath.isEmpty()) {
				logger.warn("filePath 값 없음: {}", filePath);
	    		throw new IllegalArgumentException("filePath는 null이거나 공백이어서는 안 됩니다.");
	    	}

			// filePath 길이 검증
			if (filePath.length() > 500) {
				logger.warn("유효하지 않은 filePath 길이: {}", filePath.length());
				throw new IllegalArgumentException("파일 경로가 너무 깁니다.");
			}

			// Path Traversal 방어
			if (isPathTraversal(filePath)) {
				logger.warn("Path Traversal 시도 감지: {}", filePath);
				throw new IllegalArgumentException("유효하지 않은 파일 경로입니다.");
			}

			// 비디오 확장자 검증
			if (!isValidVideoExtension(filePath)) {
				logger.warn("유효하지 않은 비디오 확장자: {}", filePath);
				throw new IllegalArgumentException("유효하지 않은 파일 형식입니다.");
			}
			// ====== 유효성 검증 [E] ====== //
	    	
			// ====== 서비스 [S] ====== //
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
	    	// ====== 서비스 [E] ====== //
	    	
	    } catch (IllegalArgumentException e) {
	        logger.error("잘못된 인자 전달 오류 발생: ",e);
	    } catch (IndexOutOfBoundsException e2) {
	    	logger.error("잘못된 index 오류 발생 : ",e2);
	    }
	}


	/**
	 * 날짜 형식 검증 (yyyy-MM-dd)
	 * @param dateStr 날짜 문자열
	 * @return 유효한 날짜 형식이면 true
	 */
	private boolean isValidDate(String dateStr) {
		if (dateStr == null || dateStr.isEmpty()) {
			return false;
		}

		// 날짜 형식 정규식 검증 (yyyy-MM-dd)
		if (!dateStr.matches("^\\d{4}-\\d{2}-\\d{2}$")) {
			return false;
		}

		// 실제 날짜 유효성 검증
		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
		sdf.setLenient(false);
		try {
			sdf.parse(dateStr);
			return true;
		} catch (ParseException e) {
			return false;
		}
	}

	/**
	 * 위험한 패턴 검사 (SQL Injection, XSS, Path Traversal 방어)
	 * @param input 검사할 문자열
	 * @return 위험한 패턴이 포함되어 있으면 true
	 */
	private boolean containsDangerousPattern(String input) {
		if (input == null || input.isEmpty()) {
			return false;
		}

		// 위험한 패턴 목록
		String[] dangerousPatterns = {
			"<script", "</script>", "javascript:", "onerror=", "onload=",  // XSS
			"'", "\"", "--", ";", "/*", "*/", "xp_", "sp_",  // SQL Injection
			"../", "..\\", "%2e%2e", "~",  // Path Traversal
			"<", ">", "&lt;", "&gt;",  // HTML 태그
			"union", "select", "insert", "update", "delete", "drop", "exec", "execute"  // SQL 키워드
		};

		String lowerInput = input.toLowerCase();
		for (String pattern : dangerousPatterns) {
			if (lowerInput.contains(pattern.toLowerCase())) {
				return true;
			}
		}

		return false;
	}

	/**
	 * Path Traversal 공격 감지
	 * @param filePath 파일 경로
	 * @return Path Traversal 패턴이 포함되어 있으면 true
	 */
	private boolean isPathTraversal(String filePath) {
		if (filePath == null || filePath.isEmpty()) {
			return false;
		}

		// Path Traversal 패턴 목록
		String[] pathTraversalPatterns = {
			"../", "..\\",           // 기본 패턴
			"%2e%2e/", "%2e%2e\\",   // URL 인코딩
			"..%2f", "..%5c",        // URL 인코딩 (혼합)
			"%2e%2e%2f", "%2e%2e%5c" // 완전 URL 인코딩
		};

		String lowerPath = filePath.toLowerCase();
		for (String pattern : pathTraversalPatterns) {
			if (lowerPath.contains(pattern.toLowerCase())) {
				return true;
			}
		}

		// null 바이트 검사
		if (filePath.contains("\0") || filePath.contains("%00")) {
			return true;
		}

		return false;
	}

	/**
	 * 이미지 파일 확장자 검증
	 * @param filePath 파일 경로
	 * @return 유효한 이미지 확장자이면 true
	 */
	private boolean isValidImageExtension(String filePath) {
		if (filePath == null || filePath.isEmpty()) {
			return false;
		}

		String lowerPath = filePath.toLowerCase();
		String[] validExtensions = {".jpg", ".jpeg", ".png", ".gif", ".bmp"};

		for (String ext : validExtensions) {
			if (lowerPath.endsWith(ext)) {
				return true;
			}
		}

		return false;
	}

	/**
	 * 비디오 파일 확장자 검증
	 * @param filePath 파일 경로
	 * @return 유효한 비디오 확장자이면 true
	 */
	private boolean isValidVideoExtension(String filePath) {
		if (filePath == null || filePath.isEmpty()) {
			return false;
		}

		String lowerPath = filePath.toLowerCase();
		String[] validExtensions = {".mp4", ".webm", ".avi", ".mov", ".wmv", ".flv"};

		for (String ext : validExtensions) {
			if (lowerPath.endsWith(ext)) {
				return true;
			}
		}

		return false;
	}
}
