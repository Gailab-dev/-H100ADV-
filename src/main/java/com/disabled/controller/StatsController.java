package com.disabled.controller;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.disabled.common.ExcelColumn;
import com.disabled.common.ExcelSheetSpec;
import com.disabled.component.LogDiskManager;
import com.disabled.component.SessionManager;
import com.disabled.mapper.LoginMapper;
import com.disabled.mapper.StatsMapper;
import com.disabled.service.CodeConversionService;
import com.disabled.service.CryptoARIAService;
import com.disabled.service.ExcelService;
import com.disabled.service.StatsService;

@Controller
@RequestMapping("/stats")
public class StatsController {
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(StatsController.class);
	
	@Autowired
	StatsService statsService;
	
	@Autowired
	StatsMapper statsMapper;
	
	@Autowired
	LoginMapper loginMapper;
	
	@Autowired
	CryptoARIAService cryptoARIAService;

	@Autowired
	SessionManager sessionManager;
	
	@Autowired
	LogDiskManager logDiskManager;
	
	@Autowired
	CodeConversionService codeConversionService;
	
	@Autowired
	ExcelService excelService;
	
	// 통계 화면으로 redirect
	@RequestMapping("")
	public String rootRedirect() {
		
		return "redirect:/stats/viewStat.do";
	}
	
	/**
	 * 통계 화면으로 이동
	 * @param model
	 * @param session
	 * @return
	 */
	@RequestMapping("/viewStat.do")
	private String viewStat(
			@RequestParam(name="startDate",required=false) String startDate
			, @RequestParam(name ="endDate",required=false) String endDate
			, @RequestParam(name="stCd",required=false) Integer stCd
			, Model model, HttpSession session) {
		
		// 접근 로그
		String uIdStr = session.getAttribute("uId") == null ? null : session.getAttribute("uId").toString();
		if(uIdStr != null) {
			logger.info("{}(" + loginMapper.getLoginId( Integer.parseInt(uIdStr)) + ") 사용자의 {}에 홈 화면 접속.", session.getAttribute("uId"),LocalDateTime.now());
		}

		// ====== 변수 선언부 [S] ======
		List<Map<String,Object>> statsByMonth = new ArrayList<Map<String,Object>>();
		boolean useTblLog = false;	// 로그 스토리지 사용 가능 여부
		// ====== 변수 선언부 [E] ======
		
		// ====== 유효성 검사 [S] ======
		// 이벤트 코드가 1~6까지의 숫자가 아닌 경우 오류 문자 출력하고 리턴
		if(stCd >= 7 || stCd <= 0) {
			model.addAttribute("errorMsg", "이벤트 코드 오류");
			return "stats/stats";
		}
		
		// ====== 유효성 검사 [E] ======

		
		try {
			// ====== 서비스 [S] ======
			// 최근 1년간 월별 불법주차 통계 데이터 조회 
			//statsByMonth = statsService.getEventByMonth();
			
			// 검색 조건에 따른 최근 1년간 월별 불법주차 통계 데이터 조회
			statsByMonth = statsService.getEventByMonthAndSearchParams(startDate,endDate,stCd);
			
			// 로그 스토리지 사용 가능 여부 조회
			useTblLog = logDiskManager.hasEnoughLogSpace();
			
			 // 세션에 저장된 회원의 등급(권한) 조회
		    Integer uGrade = Integer.parseInt(session.getAttribute("uGrade").toString()); 
			// ====== 서비스 [E] ======
			
		    // ====== model add [S] ======
		    model.addAttribute("uGrade",uGrade);
			model.addAttribute("statsByMonth", statsByMonth);
			model.addAttribute("useTblLog", useTblLog);
			// ====== model add [E] ======
			
			return "stats/stats";
			
		} catch (IllegalArgumentException e) {
			logger.error("잘못된 인자 전달",e);
			return "redirect:/user/login.do";
		}

	}
	
	/**
	 * 엑셀 다운로드
	 * @param startDate
	 * @param endDate
	 * @param stCd
	 * @param response
	 */
	@ResponseBody()
	@PostMapping("/excelDownload")
	public void execlDownload(
			@RequestParam(name="startDate",required=false) String startDate
			, @RequestParam(name ="endDate",required=false) String endDate
			, @RequestParam(name="stCd",required=false) Integer stCd
			, HttpServletResponse response){

		// ====== 변수 선언부 [S] ======
		List<Map<String,Object>> statsByMonth = new ArrayList<Map<String,Object>>();
		// ====== 변수 선언부 [E] ======

		try {
			// ====== 서비스 [S] ======

			// 검색 조건에 따른 최근 1년간 월별 불법주차 통계 데이터 조회
			statsByMonth = statsService.getEventByMonthAndSearchParams(startDate,endDate,stCd);
			
			// statsByMonth의 stCd 코드를 문자열로 변환
			statsByMonth = codeConversionService.StCdConverstionIntToStr(statsByMonth);
			
			// 엑셀 컬럼 추가
		    List<ExcelColumn> columns = List.of(
	            new ExcelColumn("st_date", "월"),
	            new ExcelColumn("st_cd", "이벤트"),
	            new ExcelColumn("st_cnt", "개수")
	        );
		    
		    // 엑셀 시트 생성
		    ExcelSheetSpec sheet = ExcelSheetSpec.builder()
		            .sheetName("통계")
		            .columns(columns)
		            .data(statsByMonth)
		            .build();
		    
		    // 엑셀 파일 생성 및 다운로드
		    // 엑셀 파일명, 엑셀 시트, 다운로드를 위한 response 객체
		    excelService.download("월별_이벤트_통계.xlsx", sheet, response);
		    
			// ====== 서비스 [E] ======
			
		} catch (Exception e) {
			// TODO: handle exception
		}
		
		
		
		
	}
	
}
