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

import org.apache.poi.ss.usermodel.BorderStyle;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.VerticalAlignment;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.ss.util.RegionUtil;
import org.apache.poi.xssf.usermodel.XSSFColor;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.disabled.common.CodeConversionService;
import com.disabled.common.CommonValidation;
import com.disabled.common.ExcelColumn;
import com.disabled.common.ExcelSheetSpec;
import com.disabled.common.ImageByteLoader;
import com.disabled.component.LogDiskManager;
import com.disabled.mapper.LoginMapper;
import com.disabled.service.EventListService;
import com.disabled.service.ExcelService;
import com.disabled.service.UserService;

@Controller
@RequestMapping("/eventList")
public class EventListController {
	
	@Autowired
	EventListService eventListService;
	
	@Autowired
	LogDiskManager logDiskManager;
	
	@Autowired
	LoginMapper loginMapper;
	
	@Autowired
	CommonValidation commonValidation;
	
	@Autowired
	CodeConversionService codeConversionService;
	
	@Autowired
	ExcelService excelService;
	
	@Autowired
	private ImageByteLoader imageByteLoader;
	
	@Autowired
	private javax.servlet.ServletContext servletContext;
	
	@Autowired
	UserService userService;
	
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
	 * @param sortCol		정렬 대상이 되는 열(String)
	 * @param sortDir		정렬방법(ASE, DESC 외 오류!) (String) 
	 * @param model
	 * @param session
	 * @return
	 */
	// 불법주차 리스트
	@RequestMapping("/viewEventList.do")
	public String viewEventList(
			@RequestParam(value="startDate", required=false) String startDate
			, @RequestParam(value="endDate", required=false) String endDate
			, @RequestParam(value="evCd", required = false) Integer evCd
			, @RequestParam(value="searchKeyword", required=false) String searchKeyword
			, @RequestParam(value="page", required=false) Integer page
			, @RequestParam(value="pageSize", defaultValue = "10" ) Integer pageSize
	        , @RequestParam(value="sortCol", defaultValue="ev_date") String sortCol
	        , @RequestParam(value="sortDir", defaultValue="DESC") String sortDir
			, Model model
			, HttpSession session) {
		
		// 접근 로그
		String uIdStr = session.getAttribute("uId") == null ? null : session.getAttribute("uId").toString();
		Integer uId = null;
		if(uIdStr != null) {
			logger.info("{}(" + loginMapper.getLoginId(Integer.parseInt(uIdStr)) + ") 사용자의 {}에 디바이스 리스트 화면 접속.", session.getAttribute("uId"),LocalDateTime.now());
			uId = Integer.parseInt(uIdStr.toString());
		}else {
			return "/user/login.do"; 
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
		
		// 유형 검증
		if(evCd != null && (evCd >= 7 || evCd <= 0)) {
			logger.warn("유효하지 않은 유형: {}",evCd);
			model.addAttribute("errorMessage", "유효하지 않은 유형입니다.");
			return "error";

		}
		
		// sortDir 검증
		if(!"ASC".equals(sortDir) && !"DESC".equals(sortDir)) {
			logger.warn("유효하지 않은 sortDir 요청: {}",sortDir);
			model.addAttribute("errorMessage", "유효하지 않은 정렬방법입니다.");
			return "error";

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
			paginationInfo.setRecordCountPerPage(pageSize);  // 한 페이지에 출력할 게시글 수
			paginationInfo.setPageSize(10); // 페이지 블록 수
			
			// DB 검색을 위한 파라미터 설정
			paramMap.put("searchKeyword", searchKeyword);
			paramMap.put("startDate",startDate);
			paramMap.put("endDate",endDate);
			paramMap.put("evCd", evCd);
			
			int recordCountPerPage = paginationInfo.getRecordCountPerPage();  //LIMIT count
			totalRecordCount = eventListService.getTotalRecordCount(paramMap);
			
			paginationInfo.setTotalRecordCount(totalRecordCount);
			
		    // 마지막 페이지 계산 후 page 보정
		    int lastPage = (int) Math.ceil(totalRecordCount / (double) recordCountPerPage);
		    if (lastPage < 1) lastPage = 1;

		    int currentPage = Math.min(Math.max(page, 1), lastPage);
		    paginationInfo.setCurrentPageNo(currentPage);

		    // offset 재계산
		    int firstIndex = (currentPage - 1) * recordCountPerPage;
			
			// DB 검색을 위한 파라미터 설정
		    paramMap.put("sortCol", sortCol);
		    paramMap.put("sortDir", sortDir);
			paramMap.put("firstIndex", firstIndex);
			paramMap.put("recordCountPerPage", recordCountPerPage);
		    
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
		
		// 세션에 저장된 회원의 이름 조회
		String uName = userService.getUNameBySession(uId);
		
		// model add
		model.addAttribute("uName", uName);
		model.addAttribute("paginationInfo",paginationInfo);
		model.addAttribute("eventList", eventList);
		model.addAttribute("searchKeyword", searchKeyword);
		model.addAttribute("startDate",convertStartDate);
		model.addAttribute("endDate", convertEndDate);
		model.addAttribute("useTblLog", useTblLog);
		model.addAttribute("pageSize", pageSize);
		model.addAttribute("totalRecordCount", totalRecordCount);
		model.addAttribute("evCd", evCd);
	    model.addAttribute("sortCol", sortCol);
	    model.addAttribute("sortDir", sortDir);
		
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
				if (!commonValidation.isValidDate(startDate) || containsDangerousPattern(startDate)) {
					logger.warn("유효하지 않은 startDate 요청: {}", startDate);
					model.addAttribute("errorMessage", "유효하지 않은 날짜 형식입니다.");
					return "error";
				}
			}

			// endDate 검증 (날짜 형식 및 SQL Injection 방어)
			if (endDate != null && !endDate.isEmpty()) {
				if (!commonValidation.isValidDate(endDate) || containsDangerousPattern(endDate)) {
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
			moduleCheck = eventListService.requestFileFromModule(res, dvId,evId,eventListDetail);
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
	
	/**
	 * 엑셀 다운로드(불법주차 리스트)
	 * @param startDate		이벤트 발생일 기준 검색 시작일(String)
	 * @param endDate		이벤트 발생일 기준 검색 종료일(String)
	 * @param stCd			이벤트 유형 코드(Integer)
	 * @param searchKeyword	검색어
	 * @param response		HttpServletResponse 객체
	 */
	@PostMapping("/excelDownload")
	@ResponseBody
	public void excelDownload(
			@RequestBody Map<String,Object> paramMap
			, HttpServletResponse response) {
		
		// ====== 디버깅 로그 [S] ======
		System.out.println("excelDownload map ; {}" + paramMap);
		logger.info("excelDownload map ; {}",paramMap);
		// ====== 디버깅 로그 [E] ======
		
		try {
			// ====== 서비스 [S] ======
			
			// 두 파라미터 값 0이 들어가지 않게 방어코드
			paramMap.put("recordCountPerPage", null);
			paramMap.put("firstIndex", null);
			
			// startDate, endDate 값 변경 yyyy-MM-dd > yyyymmdd
			Object startDateObj = paramMap.get("startDate");
			Object endDateObj = paramMap.get("endDate");
			String startDate = "";
			String endDate = "";
			
			if(startDateObj != null) {
				startDate = startDateObj.toString().replace("-", "").trim();
			}
			if(endDateObj != null) {
				endDate = endDateObj.toString().replace("-", "").trim();
			}
			paramMap.put("startDate", startDate);
			paramMap.put("endDate", endDate);
			
			
			// 데이터 가져오기
			List<Map<String,Object>> eventList = eventListService.getEventList(paramMap);
			
			System.out.println("eventList { " + eventList + " } ");
			
			// 엑셀 컬럼 추가
		    List<ExcelColumn> columns = List.of(
	            new ExcelColumn("ev_reg_date", "날짜"),
	            new ExcelColumn("ev_cd", "유형"),
	            new ExcelColumn("dv_name", "디바이스명"),
	            new ExcelColumn("dv_addr", "디바이스 주소"),
	            new ExcelColumn("ev_car_num", "차량번호")
	        );
		    
		    // 유형 문자열로 변환
		    if(!eventList.isEmpty()) {
			    eventList = codeConversionService.evCdConverstionIntToStr(eventList);
		    }
		    
		    
		    // 엑셀 시트 생성
		    ExcelSheetSpec sheet = ExcelSheetSpec.builder()
		            .sheetName("이벤트목록")
		            .columns(columns)
		            .data(eventList)
		            .build();
		    
		    // 엑셀 파일 생성 및 다운로드
		    excelService.download("이벤트_목록.xlsx", sheet, response);
			// ====== 서비스 [E] ======

		} catch (Exception e) {
			logger.error("엑셀 파일 생성 중 오류 발생",e);
			return;
		}
	}
	
	/**
	 * 엑셀 다운로드(불법주차 리스트 상세)
	 * @param startDate		이벤트 발생일 기준 검색 시작일(String)
	 * @param endDate		이벤트 발생일 기준 검색 종료일(String)
	 * @param stCd			이벤트 유형 코드(Integer)
	 * @param searchKeyword	검색어
	 * @param response		HttpServletResponse 객체
	 */
	@PostMapping("/excelDownloadDetail")
	@ResponseBody
	public void excelDownloadDetail(
			@RequestBody Map<String,Object> paramMap
			, HttpServletResponse response) {
		
		// ====== 디버깅 로그 [S] ======
		System.out.println("excelDownload map ; {}" + paramMap);
		logger.info("excelDownload map ; {}",paramMap);
		// ====== 디버깅 로그 [E] ======
		
		try {
			// ====== 변수 선언부 [S] ======
			
			// ev_id null 검사
			Object evIdObj = paramMap.get("ev_id");
			Integer evId = null;
			if(evIdObj != null) {
				evId = Integer.parseInt(evIdObj.toString()); 
			}else {
				logger.info("ev_id가 null입니다.");
				return;
			}
			
			// ====== 변수 선언부 [E] ======
			// ====== 서비스 [S] ======
			
			// 두 파라미터 값 0이 들어가지 않게 방어코드
			paramMap.put("recordCountPerPage", null);
			paramMap.put("firstIndex", null);
			
			// 데이터 가져오기
			Map<String,Object> eventListDetail = eventListService.getEventListDetail(evId);
			
			System.out.println("eventList { " + eventListDetail + " } ");
			
			// 불법주차 단속 이미지 파일명 가져오기
			String photo1Path = eventListDetail.get("ev_img_path") == null ? "" : eventListDetail.get("ev_img_path").toString();
	        String photo2Path = eventListDetail.get("ev_img_path2") == null ? "" : eventListDetail.get("ev_img_path2").toString();
			

	        byte[] photo1 = imageByteLoader.readillegalParkingImage(photo1Path);
	        byte[] photo2 = imageByteLoader.readillegalParkingImage(photo2Path);
	        
		    // 유형 문자열로 변환
		    eventListDetail = codeConversionService.evCdConverstionIntToStr(eventListDetail);
		    
		    // 정적 이미지 가져오기
	        byte[] sealImage = imageByteLoader.readWebAppResource(servletContext, "/resources/images/seal.png");
	        byte[] collectorImage = imageByteLoader.readWebAppResource(servletContext, "/resources/images/collector.png");
		    
		    // 엑셀 시트 생성
	        Workbook wb = new XSSFWorkbook();
	        Sheet sheet = wb.createSheet("과태료 통지서");

	        // 컬럼 너비
	        for (int i = 0; i < 12; i++) {
	            sheet.setColumnWidth(i, 4000);
	        }

	        // ===== 스타일 =====
	        XSSFColor lightSkyBlue = new XSSFColor(new java.awt.Color(220, 235, 247), null);
	        XSSFColor lightRed = new XSSFColor(new java.awt.Color(255, 163, 163), null);
	        
	        CellStyle titleStyle = wb.createCellStyle();
	        Font titleFont = wb.createFont();
	        titleFont.setBold(true);
	        titleFont.setFontHeightInPoints((short) 10);
	        titleFont.setColor(IndexedColors.WHITE.getIndex());
	        titleStyle.setFont(titleFont);
	        titleStyle.setAlignment(HorizontalAlignment.CENTER);
	        titleStyle.setVerticalAlignment(VerticalAlignment.CENTER);
	        titleStyle.setFillForegroundColor(IndexedColors.SKY_BLUE.getIndex());
	        titleStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
	        
	        CellStyle noticeStyle = wb.createCellStyle();
	        Font noticeFont = wb.createFont();
	        noticeFont.setFontHeightInPoints((short) 9);
	        noticeFont.setColor(IndexedColors.SKY_BLUE.getIndex());
	        noticeStyle.setFont(noticeFont);
	        noticeStyle.setAlignment(HorizontalAlignment.LEFT);
	        noticeStyle.setVerticalAlignment(VerticalAlignment.CENTER);
	        
	        Font bodyFont9 = wb.createFont();
	        bodyFont9.setFontHeightInPoints((short) 9);

	        CellStyle labelStyle = wb.createCellStyle();
	        labelStyle.setFont(bodyFont9);
	        labelStyle.setBorderBottom(BorderStyle.THIN);
	        labelStyle.setBorderTop(BorderStyle.THIN);
	        labelStyle.setBorderLeft(BorderStyle.THIN);
	        labelStyle.setBorderRight(BorderStyle.THIN);
	        labelStyle.setAlignment(HorizontalAlignment.CENTER);
	        labelStyle.setFillForegroundColor(lightSkyBlue);
	        labelStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
	        labelStyle.setTopBorderColor(IndexedColors.SKY_BLUE.getIndex());
	        labelStyle.setBottomBorderColor(IndexedColors.SKY_BLUE.getIndex());
	        labelStyle.setLeftBorderColor(IndexedColors.SKY_BLUE.getIndex());
	        labelStyle.setRightBorderColor(IndexedColors.SKY_BLUE.getIndex());

	        CellStyle valueStyle = wb.createCellStyle();
	        valueStyle.cloneStyleFrom(labelStyle);
	        valueStyle.setFillForegroundColor(IndexedColors.AUTOMATIC.getIndex());
	        valueStyle.setFillPattern(FillPatternType.NO_FILL);
	        valueStyle.setAlignment(HorizontalAlignment.LEFT);

	        CellStyle labelStyle2 = wb.createCellStyle();
	        Font labelFont2 = wb.createFont();
	        labelFont2.setFontHeightInPoints((short) 9);
	        labelFont2.setColor(IndexedColors.RED.getIndex());
	        labelStyle2.setFont(labelFont2);
	        labelStyle2.setBorderBottom(BorderStyle.THIN);
	        labelStyle2.setBorderTop(BorderStyle.THIN);
	        labelStyle2.setBorderLeft(BorderStyle.THIN);
	        labelStyle2.setBorderRight(BorderStyle.THIN);
	        labelStyle2.setAlignment(HorizontalAlignment.CENTER);
	        labelStyle2.setFillForegroundColor(lightRed);
	        labelStyle2.setFillPattern(FillPatternType.SOLID_FOREGROUND);
	        labelStyle2.setTopBorderColor(IndexedColors.RED.getIndex());
	        labelStyle2.setBottomBorderColor(IndexedColors.RED.getIndex());
	        labelStyle2.setLeftBorderColor(IndexedColors.RED.getIndex());
	        labelStyle2.setRightBorderColor(IndexedColors.RED.getIndex());
	        
	        CellStyle valueStyle2 = wb.createCellStyle();
	        valueStyle2.cloneStyleFrom(labelStyle2);
	        valueStyle2.setFillForegroundColor(IndexedColors.AUTOMATIC.getIndex());
	        valueStyle2.setFillPattern(FillPatternType.NO_FILL);
	        valueStyle2.setAlignment(HorizontalAlignment.LEFT);

	        CellStyle basicStyle = wb.createCellStyle();
	        basicStyle.setFont(bodyFont9);
	        basicStyle.setAlignment(HorizontalAlignment.CENTER);
	        
	        // ===== 제목 =====
	        Row row2 = sheet.createRow(1);
	        row2.setHeightInPoints(28);
	        Cell title = row2.createCell(0);
	        title.setCellValue("과태료 부과 사전통지서 및 영수증 (납부자보관용)");
	        title.setCellStyle(titleStyle);
	        sheet.addMergedRegion(new CellRangeAddress(1,1,0,3));
	        
	        // ===== 안내 정보 =====
	        Row row4 = sheet.createRow(3);
	        Cell notCel = row4.createCell(0);
	        notCel.setCellValue("대상자:");
	        notCel.setCellStyle(noticeStyle);
	        
	        Row row5 = sheet.createRow(4);
	        notCel = row5.createCell(0);
	        notCel.setCellValue("주   소:");
	        notCel.setCellStyle(noticeStyle);

	        
	        Row row8 = sheet.createRow(7);
	        notCel = row8.createCell(0);
	        notCel.setCellValue("귀하에 대하여 장애인·노인·임산부 등의 편익증진 보장에 관한 법률 제 27조에 따라 아래와");
	        notCel.setCellStyle(noticeStyle);
	        
	        Row row9 = sheet.createRow(8);
	        notCel = row9.createCell(0);
	        notCel.setCellValue("같이 과태료를 부과하고자 하오니 의견이 있으시면 기한내 의견을 주시기 바랍니다.");
	        notCel.setCellStyle(noticeStyle);

	        // ===== 기본 정보 =====
	        createRow(sheet, 10, "차량번호", "35더3975", "일반일시", "2025.06.10 10:30:20", labelStyle, valueStyle);
	        createRow(sheet, 11, "위반장소", "광주 북구 용두택지 66", "과태료금액", "", labelStyle, valueStyle);
	        createRow(sheet, 12, "위반내용", "비장애인 주차", "적용법", "", labelStyle, valueStyle);
	        createRow(sheet, 13, "감경금액", "", "의견제출기한", "", labelStyle, valueStyle);

	        // ===== 전자납부번호 =====
		    
	        Row row16 = sheet.createRow(15);
	        Cell payNo = row16.createCell(0);
	        payNo.setCellValue("전자납부번호");
	        payNo.setCellStyle(labelStyle2);
	        
	        CellRangeAddress leftLabelRegion1 =
		            new CellRangeAddress(15, 15, 0, 1);
	        sheet.addMergedRegion(leftLabelRegion1);

	        RegionUtil.setBorderTop(BorderStyle.THIN, leftLabelRegion1, sheet);
	        RegionUtil.setBorderBottom(BorderStyle.THIN, leftLabelRegion1, sheet);
	        RegionUtil.setBorderLeft(BorderStyle.THIN, leftLabelRegion1, sheet);
	        RegionUtil.setBorderRight(BorderStyle.THIN, leftLabelRegion1, sheet);
	        RegionUtil.setTopBorderColor(IndexedColors.RED.getIndex(), leftLabelRegion1, sheet);
	        RegionUtil.setBottomBorderColor(IndexedColors.RED.getIndex(), leftLabelRegion1, sheet);
	        RegionUtil.setLeftBorderColor(IndexedColors.RED.getIndex(), leftLabelRegion1, sheet);
	        RegionUtil.setRightBorderColor(IndexedColors.RED.getIndex(), leftLabelRegion1, sheet);
	        
	        Cell payNo16_1 = row16.createCell(2);
	        payNo16_1.setCellStyle(valueStyle2);
	        
	        CellRangeAddress leftValueRegion1 =
		            new CellRangeAddress(15, 15, 2, 5);
	        sheet.addMergedRegion(leftValueRegion1);
	        
	        RegionUtil.setBorderTop(BorderStyle.THIN, leftValueRegion1, sheet);
	        RegionUtil.setBorderBottom(BorderStyle.THIN, leftValueRegion1, sheet);
	        RegionUtil.setBorderLeft(BorderStyle.THIN, leftValueRegion1, sheet);
	        RegionUtil.setBorderRight(BorderStyle.THIN, leftValueRegion1, sheet);
	        RegionUtil.setTopBorderColor(IndexedColors.RED.getIndex(), leftValueRegion1, sheet);
	        RegionUtil.setBottomBorderColor(IndexedColors.RED.getIndex(), leftValueRegion1, sheet);
	        RegionUtil.setLeftBorderColor(IndexedColors.RED.getIndex(), leftValueRegion1, sheet);
	        RegionUtil.setRightBorderColor(IndexedColors.RED.getIndex(), leftValueRegion1, sheet);
	        
	        
	        // ===== 안내 정보 2 =====
	        
	        Row row18 = sheet.createRow(17);
	        notCel = row18.createCell(0);
	        notCel.setCellValue("귀하께서 위 의견제출기한 내에 이의제기 없이 과태료를 납부 하고자하는 경우에는");
	        notCel.setCellStyle(noticeStyle);
	        
	        Row row19 = sheet.createRow(18);
	        notCel = row19.createCell(0);
	        notCel.setCellValue("감경금액으로 납부하실 수 있습니다. 의견제출은 기한 내에만 가능하며 의견진술을");
	        notCel.setCellStyle(noticeStyle);
	        
	        Row row20 = sheet.createRow(19);
	        notCel = row20.createCell(0);
	        notCel.setCellValue("하여도 자진납부 기한은 연장되지 않습니다.");
	        notCel.setCellStyle(noticeStyle);
	        
	        Row row23 = sheet.createRow(22);
	        notCel = row23.createCell(1);
	        notCel.setCellValue("2026년");
	        notCel.setCellStyle(basicStyle);
	        
	        notCel = row23.createCell(2);
	        notCel.setCellValue("1월");
	        notCel.setCellStyle(basicStyle);
	        
	        notCel = row23.createCell(3);
	        notCel.setCellValue("27일");
	        notCel.setCellStyle(basicStyle);
	        
	        Row row24 = sheet.createRow(23);
	        notCel = row24.createCell(3);
	        notCel.setCellValue("용인시 기흥구");
	        notCel.setCellStyle(basicStyle);
	        
	        // ===== 불법주차 이미지 =====
	        
	        CellRangeAddress region =
	                new CellRangeAddress(4, 22, 7, 10);

	        RegionUtil.setBorderTop(BorderStyle.THIN, region, sheet);
	        RegionUtil.setBorderBottom(BorderStyle.THIN, region, sheet);
	        RegionUtil.setBorderLeft(BorderStyle.THIN, region, sheet);
	        RegionUtil.setBorderRight(BorderStyle.THIN, region, sheet);


	        // ===== 이미지 삽입 =====
//	        InputStream is = new FileInputStream("C:/images/car.jpg"); // 실제 서버 경로
//	        byte[] bytes = IOUtils.toByteArray(is);
//	        int pictureIdx = wb.addPicture(bytes, Workbook.PICTURE_TYPE_JPEG);
//	        is.close();
//
//	        Drawing<?> drawing = sheet.createDrawingPatriarch();
//	        CreationHelper helper = wb.getCreationHelper();
//
//	        ClientAnchor anchor1 = helper.createClientAnchor();
//	        anchor1.setCol1(8);
//	        anchor1.setRow1(6);
//	        anchor1.setCol2(12);
//	        anchor1.setRow2(13);
//
//	        Picture pic1 = drawing.createPicture(anchor1, pictureIdx);
//	        pic1.resize();

	        // ===== 응답 =====
	        response.setContentType(
	            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
	        response.setHeader(
	            "Content-Disposition",
	            "attachment; filename=과태료부과_사전통지서.xlsx");

	        wb.write(response.getOutputStream());
	        wb.close();
 		    
		    // ====== 서비스 [E] ======

		} catch (Exception e) {
			logger.error("엑셀 파일 생성 중 오류 발생",e);
			return;
		}
	}
	
	private void createRow(
        Sheet sheet, int rowNum,
        String label1, String value1,
        String label2, String value2,
        CellStyle labelStyle, CellStyle valueStyle) {

	    Row row = sheet.createRow(rowNum);

	    Cell c0 = row.createCell(0);
	    c0.setCellValue(label1);
	    c0.setCellStyle(labelStyle);

	    Cell c1 = row.createCell(1);
	    c1.setCellValue(value1);
	    c1.setCellStyle(valueStyle);
	    
	    CellRangeAddress leftValueRegion =
	            new CellRangeAddress(rowNum, rowNum, 1, 2);
        sheet.addMergedRegion(leftValueRegion);

        RegionUtil.setBorderTop(BorderStyle.THIN, leftValueRegion, sheet);
        RegionUtil.setBorderBottom(BorderStyle.THIN, leftValueRegion, sheet);
        RegionUtil.setBorderLeft(BorderStyle.THIN, leftValueRegion, sheet);
        RegionUtil.setBorderRight(BorderStyle.THIN, leftValueRegion, sheet);
        
        RegionUtil.setTopBorderColor(IndexedColors.SKY_BLUE.getIndex(), leftValueRegion, sheet);
        RegionUtil.setBottomBorderColor(IndexedColors.SKY_BLUE.getIndex(), leftValueRegion, sheet);
        RegionUtil.setLeftBorderColor(IndexedColors.SKY_BLUE.getIndex(), leftValueRegion, sheet);
        RegionUtil.setRightBorderColor(IndexedColors.SKY_BLUE.getIndex(), leftValueRegion, sheet);
        

	    Cell c3 = row.createCell(3);
	    c3.setCellValue(label2);
	    c3.setCellStyle(labelStyle);

	    Cell c4 = row.createCell(4);
	    c4.setCellValue(value2);
	    c4.setCellStyle(valueStyle);
	    
	    CellRangeAddress rightValueRegion =
	            new CellRangeAddress(rowNum, rowNum, 4, 5);
        sheet.addMergedRegion(rightValueRegion);

        RegionUtil.setBorderTop(BorderStyle.THIN, rightValueRegion, sheet);
        RegionUtil.setBorderBottom(BorderStyle.THIN, rightValueRegion, sheet);
        RegionUtil.setBorderLeft(BorderStyle.THIN, rightValueRegion, sheet);
        RegionUtil.setBorderRight(BorderStyle.THIN, rightValueRegion, sheet);
        
        RegionUtil.setTopBorderColor(IndexedColors.SKY_BLUE.getIndex(), rightValueRegion, sheet);
        RegionUtil.setBottomBorderColor(IndexedColors.SKY_BLUE.getIndex(), rightValueRegion, sheet);
        RegionUtil.setLeftBorderColor(IndexedColors.SKY_BLUE.getIndex(), rightValueRegion, sheet);
        RegionUtil.setRightBorderColor(IndexedColors.SKY_BLUE.getIndex(), rightValueRegion, sheet);
	    
        c0.setCellStyle(labelStyle);
        c3.setCellStyle(labelStyle);
	    
	}
	
}
