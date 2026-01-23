package com.disabled.controller;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import com.disabled.mapper.LoginMapper;
import com.disabled.service.CryptoARIAService;
import com.disabled.service.MyInfoService;
import com.disabled.service.UserService;

@Controller
@RequestMapping("/myInfo")
public class MyInfoController {
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(MyInfoController.class);
	
	@Autowired
	UserService userService;
	
	@Autowired
	MyInfoService myInfoService;

	@Autowired
	CryptoARIAService cryptoARIAService;
	
	@Autowired
	LoginMapper loginMapper;
	
	// 디바이스 리스트 화면으로 redirect
	@RequestMapping("")
	public String rootRedirect() {
		
		return "redirect:/deviceList/viewDeviceList.do";
	}
	
	// 내 정보 화면 조회
	@RequestMapping("/viewMyInfo.do")
	private String viewMyInfo(
			@RequestParam(value="searchKeyword", required=false) String searchKeyword
			, @RequestParam(value="startDate", required=false) String startDate
			, @RequestParam(value="endDate", required=false) String endDate
			, @RequestParam(value="page", required=false) Integer page
			, @RequestParam(value="pageSize", defaultValue="10") Integer pageSize
			, Model model
			, HttpSession session  ) {
		
		// 접근 로그
		String uIdStr = session.getAttribute("uId") == null ? null : session.getAttribute("uId").toString();
		if(uIdStr != null) {
			logger.info("{}(" + loginMapper.getLoginId(Integer.parseInt(uIdStr)) + ") 사용자 {}에 내 정보 화면 접속.", session.getAttribute("uId"),LocalDateTime.now());
		}
		boolean useTblLog = false;	// 로그 스토리지 사용 가능 여부

		// DB 검색을 위한 파라미터 설정
		Map<String, Object> paramMap = new HashMap<String, Object>();
		paramMap.put("uIdStr", uIdStr);
		
		// 사용자 정보 가져오기
		Map<String, Object> myInfoMap = myInfoService.getMyInfoMap(paramMap);
		
	    model.addAttribute("myInfoMap",myInfoMap);
		model.addAttribute("useTblLog", useTblLog);
		
		return "/myInfo/myInfo";
	}
	
	// 내 정보 수정
	@RequestMapping("/saveMyInfo.do")
	private Map<String,Object> saveMyInfo(
			@RequestBody Map<String,String> body
			, Model model
			, HttpSession session  ) {
		Map<String,Object> res = new HashMap<>();
		String uIdStr = session.getAttribute("uId") == null ? null : session.getAttribute("uId").toString();
		
		String currentPw  = (body.get("currentPw") == null) ? "" : body.get("currentPw");
		String newPw  = (body.get("newPw") == null) ? "" : body.get("newPw");
		String confirmPw  = (body.get("confirmPw") == null) ? "" : body.get("confirmPw");
		String name = (body.get("name") == null) ? "" : body.get("name");
		
		// DB 검색을 위한 파라미터 설정
		Map<String, Object> paramMap = new HashMap<String, Object>();
		paramMap.put("uIdStr", uIdStr);
		
		// ====== 서비스 [S] ====== //
		if(!currentPw.isEmpty() || !newPw.isEmpty() || !confirmPw.isEmpty() ){
			// ====== 유효성 검사 [S] ====== //
			if(currentPw.isEmpty()){
				res.put("ok", false); 
				res.put("msg", "기존 비밀번호 미입력");
				logger.info("{}(" + loginMapper.getLoginId(Integer.parseInt(uIdStr)) + ") 사용자가 {}에 내 정보 수정에 실패하였습니다. - 기존 비밀번호 미입력", uIdStr, LocalDateTime.now());
				return res;
			}
			
			if(newPw.isEmpty()){
				res.put("ok", false); 
				res.put("msg", "새 비밀번호 미입력");
				logger.info("{}(" + loginMapper.getLoginId(Integer.parseInt(uIdStr)) + ") 사용자가 {}에 내 정보 수정에 실패하였습니다. - 새 비밀번호 미입력", uIdStr, LocalDateTime.now());
				return res;
			}
			
			if(confirmPw.isEmpty()){
				res.put("ok", false); 
				res.put("msg", "비밀번호 확인 미입력");
				logger.info("{}(" + loginMapper.getLoginId(Integer.parseInt(uIdStr)) + ") 사용자가 {}에 내 정보 수정에 실패하였습니다. - 비밀번호 확인 미입력", uIdStr, LocalDateTime.now());
				return res;
			}
			// ====== 유효성 검사 [E] ====== //
			
			// 수정 전 비밀번호(암호화) 조회
			String oldPwd = userService.getPwd(Integer.parseInt(uIdStr));
			if(oldPwd == null || oldPwd.equals("") ) {
				res.put("ok", false); 
				res.put("msg", "이전 비밀번호를 가져오는 도중 오류 발생.");
				logger.info("{}(" + loginMapper.getLoginId(Integer.parseInt(uIdStr)) + ") 사용자가 {}에 로그인 실패하였습니다. - 수정 전 비밀번호를 가져오는 도중 오류 발생", uIdStr, LocalDateTime.now());
				return res;
			}
			
			// 기존 비밀번호 평문 암호화
			String encryptCrPwd = cryptoARIAService.encryptPassword(currentPw);
			if(encryptCrPwd == null || encryptCrPwd.isEmpty()) {
				res.put("ok", false); 
				res.put("msg", "기존 비밀번호 암호화 실패.");
				logger.info("{}(" + loginMapper.getLoginId(Integer.parseInt(uIdStr)) + ") 사용자가 {}에 내 정보 수정에 실패하였습니다. - 기존 비밀번호 암호화 실패", uIdStr, LocalDateTime.now());
				return res;
			}
			
			// 수정 전 비밀번호(암호화)와 새 비밀번호(암호화)가 같으면 재입력 요청 
			boolean result = !cryptoARIAService.match(currentPw, oldPwd);
			if(result) {
				res.put("ok", false); 
				res.put("msg", "기존 비밀번호가 알맞지 않습니다.");
				logger.info("{}(" + loginMapper.getLoginId(Integer.parseInt(uIdStr)) + ") 사용자가 {}에 내 정보 수정에 실패하였습니다. - 새 비밀번호와 이전 비밀번호 동일", uIdStr, LocalDateTime.now());
				return res;
			}
			
			// 새 비밀번호 평문 암호화
			String encryptPwd = cryptoARIAService.encryptPassword(newPw);
			if(encryptPwd == null || encryptPwd.isEmpty()) {
				res.put("ok", false); 
				res.put("msg", "암호화 실패.");
				logger.info("{}(" + loginMapper.getLoginId(Integer.parseInt(uIdStr)) + ") 사용자가 {}에 내 정보 수정에 실패하였습니다. - 암호화 실패", uIdStr, LocalDateTime.now());
				return res;
			}
			
			// 수정 전 비밀번호(암호화)와 새 비밀번호(암호화)가 같으면 재입력 요청 
			boolean result2 = cryptoARIAService.match(newPw, oldPwd);
			if(result2) {
				res.put("ok", false); 
				res.put("msg", "새 비밀번호는 이전 비밀번호와 달라야 합니다.");
				logger.info("{}(" + loginMapper.getLoginId(Integer.parseInt(uIdStr)) + ") 사용자가 {}에 내 정보 수정에 실패하였습니다. - 새 비밀번호와 이전 비밀번호 동일", uIdStr, LocalDateTime.now());
				return res;
			}
			
			// 비밀번호 update
			Integer result3 = userService.updateNewPwd(Integer.parseInt(uIdStr), encryptPwd);
			if(result3 != 1) {
				res.put("ok", false); 
				res.put("msg", "비밀번호 업데이트 실패.");
				logger.error("{}(" + loginMapper.getLoginId(Integer.parseInt(uIdStr)) + ") 사용자가 {}에 내 정보 수정에 실패하였습니다. - 비밀번호 업데이트 실패", uIdStr, LocalDateTime.now());
				return res;
			}
		}
		
		
		
		res.put("ok", true); // 로그인 성공하면 true 반환
		return res;
		// ====== 서비스 [E] ====== //
	}
}

