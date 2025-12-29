package com.disabled.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.apache.logging.log4j.core.config.plugins.validation.constraints.Required;
import org.egovframe.rte.ptl.mvc.tags.ui.pagination.PaginationInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.disabled.service.UserManageService;


/**
 * 회원 관리 화면
 * @author 지아이랩
 *
 */
@RequestMapping("/userManage")
@Controller
public class UserManageController {
	
	@Autowired
	UserManageService userManageService;
	
	private static final Logger logger = LoggerFactory.getLogger(UserManageController.class);
	
	// 초기 화면으로 redirect
	@RequestMapping("")
	public String rootRedirect() {
		
		return "redirect:/userManage/viewUserManage.do";
	}
	
	@RequestMapping("/viewUserManage.do")
	public String viewUserManage(
			@RequestParam(value="startDate", required=false) String startDate
			, @RequestParam(value="endDate", required = false) String endDate
			, @RequestParam(value="type", required = false) Integer type
			, @RequestParam(value = "searchKeyword", required = false) String searchKeyword
			, @RequestParam(value="page", required = false) Integer page
			, HttpSession session
			, Model model
			, HttpServletRequest req
			, RedirectAttributes redirectAttributes) {
		
		// 페이지 null 방지
		if (page == null || page < 1) page = 1;
		
		// getTotalRecordCount 가져오기 위한 파라미터 값 설정
	    Map<String, Object> paramMap = new HashMap<String, Object>();
	    paramMap.put("startDate", startDate);
	    paramMap.put("endDate", endDate);
	    paramMap.put("searchKeyword", searchKeyword);
		
		// 페이징 객체
		PaginationInfo paginationInfo = new PaginationInfo();
		
		// 페이징 설정
		paginationInfo.setCurrentPageNo(page); // 현제 페이지 번호
		paginationInfo.setRecordCountPerPage(15);  // 한 페이지에 출력할 게시글 수
		paginationInfo.setPageSize(10); // 페이지 블록 수
		
		int recordCountPerPage = paginationInfo.getRecordCountPerPage();  //LIMIT count
		int totalRecordCount = userManageService.getTotalRecordCount(paramMap);
		paginationInfo.setTotalRecordCount(totalRecordCount);
		
	    // 마지막 페이지 계산 후 page 보정
	    int lastPage = (int) Math.ceil(totalRecordCount / (double) recordCountPerPage);
	    if (lastPage < 1) lastPage = 1;

	    int currentPage = Math.min(Math.max(page, 1), lastPage);
	    paginationInfo.setCurrentPageNo(currentPage);

	    // offset 재계산
	    int firstIndex = (currentPage - 1) * recordCountPerPage;
	    
	    // 회원 리스트 가져오기 위한 추가 파라미터 설정
	    paramMap.put("firstIndex", firstIndex);
	    paramMap.put("recordCountPerPage", recordCountPerPage);
	    
	    // 최고관리자의 지역 가져오기
	    Integer uRegion = userManageService.getRegionByAdmin(Integer.parseInt(session.getAttribute("u_id").toString()));
	    if(uRegion == null) {
	    	logger.error("지역을 가져오는 데 실패하였습니다.");

	        redirectAttributes.addFlashAttribute("errorMsg", "지역 정보를 가져오지 못했습니다.");

	        // 이전 페이지
	        String referer = req.getHeader("Referer");
	        if (referer != null && !referer.isBlank()) {
	            // 동일 도메인인지 간단히 체크해주는 게 안전
	            return "redirect:" + referer;
	        }

	        // referer 없으면 기본 페이지로
	        return "redirect:/stat/viewStat.do";
	    }
	    
	    // 지역 파라미터 추가
	    paramMap.put("uRegion", uRegion);
	    
	    // 회원 리스트 가져오기
	    List<Map<String,Object>> userManageList = userManageService.getUserManageList(paramMap);
	
	    model.addAttribute("userManageList", userManageList);
	    model.addAttribute("paginationInfo", paginationInfo);
	    model.addAttribute("startDate",startDate);
	    model.addAttribute("endDate", endDate);
	    model.addAttribute("searchKeyword", searchKeyword);
	    
		return "/userManage/userManage";
	}
	
}
