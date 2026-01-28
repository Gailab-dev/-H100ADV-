package com.disabled.controller;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
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
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.disabled.common.CodeConversionService;
import com.disabled.common.ExcelColumn;
import com.disabled.common.ExcelSheetSpec;
import com.disabled.component.LogDiskManager;
import com.disabled.component.SessionManager;
import com.disabled.mapper.LoginMapper;
import com.disabled.mapper.StatsMapper;
import com.disabled.model.MonthlyStatsWithChartSpec;
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
		Map<String,Object> paramMap = new HashMap<String, Object>();
		List<Map<String,Object>> statsByMonth = new ArrayList<Map<String,Object>>(); // 통계 데이터
		boolean useTblLog = false;	// 로그 스토리지 사용 가능 여부
		// ====== 변수 선언부 [E] ======
		
		// ====== 유효성 검사 [S] ======
		// 이벤트 코드가 1~6까지의 숫자가 아닌 경우 오류 문자 출력하고 리턴
		if(stCd != null && (stCd > 7 || stCd < 1)) {
			model.addAttribute("errorMsg", "이벤트 코드 오류");
			return "stats/stats";
		}
		
		// ====== 유효성 검사 [E] ======

		
		try {
			// ====== 서비스 [S] ======
			
			//startDate, endDate 값 편집
			//yyyy-MM-dd 형식의 값을 yyyyMM으로 편집
			String startMonth = "";
			String endMonth = "";
			if(startDate != null && startDate != "") startMonth = startDate.replace("-", "").substring(0, 6).trim();
			if(endDate != null && endDate != "") endMonth = endDate.replace("-", "").substring(0, 6).trim();
			
			System.out.println(startMonth + "  " + endMonth);
			
			// 최근 1년간 월별 불법주차 통계 데이터 조회 
			//statsByMonth = statsService.getEventByMonth();
			// 검색 조건에 따른 최근 1년간 월별 불법주차 통계 데이터 조회
			paramMap.put("endMonth", startMonth);
			paramMap.put("endMonth", endMonth);
			paramMap.put("stCd", stCd);	
			statsByMonth = statsService.getEventByMonthAndSearchParams(paramMap);
			
			/*
			for (Iterator iterator = statsByMonth.iterator(); iterator.hasNext();) {
				Map<String, Object> map = (Map<String, Object>) iterator.next();
				System.out.println("st_date : " + map.get("st_date").toString());
				System.out.println("d : " + map.get("d").toString());
				System.out.println("st_cd : " + map.get("st_cd").toString());
				System.out.println("st_cnt : " + map.get("st_cnt").toString());
				
			}
			*/
			
			// 로그 스토리지 사용 가능 여부 조회
			useTblLog = logDiskManager.hasEnoughLogSpace();
			
			 // 세션에 저장된 회원의 등급(권한) 조회
		    Integer uGrade = Integer.parseInt(session.getAttribute("uGrade").toString()); 
			// ====== 서비스 [E] ======
			
		    // ====== model add [S] ======
		    model.addAttribute("uGrade",uGrade);
			model.addAttribute("statsByMonth", statsByMonth);
			model.addAttribute("startDate", startDate);
			model.addAttribute("endDate", endDate);
			model.addAttribute("stCd", stCd);
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
	 * @param paramMap
	 * 	@param startDate
	 * 	@param endDate
	 * 	@param stCd
	 * @param response
	 */
	@ResponseBody()
	@PostMapping("/excelDownload")
	public void execlDownload(
			@RequestBody Map<String,Object> paramMap
			, HttpServletResponse response){
		
		// ====== 디버깅 로그 [S] ======
		logger.info("excelDownload map ; {}",paramMap);
		// ====== 디버깅 로그 [E] ======
		
		// ====== 변수 선언부 [S] ======
		List<Map<String,Object>> statsByMonth = new ArrayList<Map<String,Object>>();
		
		// startDate, endDate를 startMonth, endMonth로 변환
		// yyyy-MM-dd 형태 데이터를 yyyyMM으로 변환
		if(paramMap.get("startDate") != null && !paramMap.get("startDate").toString().isEmpty()) {
			paramMap.put("startMonth", paramMap.get("startDate").toString().replace("-","").substring(0, 6).trim());
		}
		if(paramMap.get("endDate") != null && !paramMap.get("endDate").toString().isEmpty()) {
			paramMap.put("endMonth", paramMap.get("endDate").toString().replace("-","").substring(0, 6).trim());
		}
		
		// stCd값 빈문자열이면 null값으로  변경
		Object stCdObj = paramMap.get("stCd");
		Integer stCd = null;
		if (stCdObj == null || stCdObj.toString().trim().isEmpty()) {
		    paramMap.put("stCd", stCd);
		} else {
			stCd = Integer.parseInt(stCdObj.toString());
		}
		// ====== 변수 선언부 [E] ======

		try {
			// ====== 서비스 [S] ======

			// 검색 조건에 따른 최근 1년간 월별 불법주차 통계 데이터 조회
			statsByMonth = statsService.getEventByMonthAndSearchParams(paramMap);
			
			// statsByMonth의 stCd 코드를 문자열로 변환
			// statsByMonth = codeConversionService.StCdConverstionIntToStr(statsByMonth);
			
		    
		    // 엑셀 시트 생성
			MonthlyStatsWithChartSpec sheet = MonthlyStatsWithChartSpec.builder()
		            .sheetName("월별_이벤트_통계")
		            .data(statsByMonth)
		            .stCd(stCd)
		            .build();
		    
		    // 엑셀 파일 생성 및 다운로드
		    // 엑셀 파일명, 엑셀 시트, 다운로드를 위한 response 객체
		    excelService.downloadMonthlyStatsWithChart("월별_이벤트_통계.xlsx", sheet, response);
		    
			// ====== 서비스 [E] ======
			
		} catch (Exception e) {
			logger.error("엑셀 파일 생성 중 오류 발생",e);
		}
		
	}
	
}
