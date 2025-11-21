package com.disabled.controller;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.disabled.component.SessionManager;
import com.disabled.service.CryptoARIAService;
import com.disabled.service.UserService;

@Controller
@RequestMapping("/user")
public class UserController {
	
	// 로그 기록
	private static final Logger logger = LoggerFactory.getLogger(UserController.class);
	
	@Autowired
	UserService userService;

	@Autowired
	CryptoARIAService cryptoARIAService;

	@Autowired
	SessionManager sessionManager;
	
	// 로그인 화면으로 redirect
	@RequestMapping("")
	public String rootRedirect() {
		
		return "redirect:/user/login.do";
	}
	
	// 로그인 화면 이동
	@RequestMapping("/login.do")
	private String viewLogin(HttpServletRequest request, HttpServletResponse response) {

	    // 캐시 방지 (뒤로가기 시 로그인 화면이 캐시로 보이는 현상 방지)
	    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
	    response.setHeader("Pragma", "no-cache");
	    response.setDateHeader("Expires", 0L);
	    
		// 세션 확인하여 남은 세션 정리
	    HttpSession s = request.getSession(false);
	    if (s != null) {
	    	s.invalidate();
	    }	

		return "user/login";
	}
	
	// 사용자 ID,PW를 확인하여 가입되었다면 통계 화면으로, 그렇지 않다면 로그인 화면으로 이동
	@ResponseBody
	@PostMapping( value = "/login", produces = "application/json; charset=UTF-8")
	private Map<String,Object> loginCheck( @RequestBody Map<String,String> body, HttpSession session) {
		
		// resultMap
		Map<String, Object> resultMap = new HashMap<String, Object>();
		
		try {
			
			String id  = (body.get("id")  == null) ? "" : body.get("id").trim();
	        String pwd = (body.get("pwd") == null) ? "" : body.get("pwd").trim();
			
			if(id.isEmpty() || pwd.isEmpty()) {
				resultMap.put("ok", false); // 로그인 실패하면 false 반환
				resultMap.put("msg", "아이디/비밀번호를 입력하세요.");
				return resultMap;
			}
			
			// 암호화
			String encryptPwd = cryptoARIAService.encryptPassword(pwd);
			if(encryptPwd == null || encryptPwd.isEmpty()) {
				resultMap.put("ok", false); 
				resultMap.put("msg", "암호화 실패.");
			}
			
			Map<String, Object> checkErr = userService.loginCheck(id, encryptPwd); //db에 해당 사용자가 있는지 체크
			if(checkErr == null) {
				
				// 로그인 실패
				logger.info("{} 사용자가 {}에 로그인 실패하였습니다.",id,LocalDateTime.now());
				resultMap.put("ok", false); // 로그인 실패하면 false 반환
				resultMap.put("msg", "아이디 또는 비밀번호가 다릅니다.");
				return resultMap;
			}else {

				if( Integer.parseInt(checkErr.get("u_pwd_changed").toString()) == 0 ) {
					
					// session에 uId와 비밀번호 변경 하지 않음(false)로 저장
					session.setAttribute("uId", checkErr.get("u_id"));
					session.setAttribute("pwdChanged", false);
					
					// resultMap에 uId와 비밀번호 변경 하지 않음(false)로 저장
					resultMap.put("pwdChanged", false);
					resultMap.put("uId", checkErr.get("u_id"));
				}else {
					// session에 uId와 비밀번호 변경함(true)로 저장
					session.setAttribute("uId", checkErr.get("u_id"));
					session.setAttribute("pwdChanged", true);
					
					// resultMap에 uId와 비밀번호 변경함(true)로 저장
					resultMap.put("pwdChanged", true);
					resultMap.put("uId", checkErr.get("u_id"));
				}

				resultMap.put("ok", true); // 로그인 성공하면 true 반환

				// 중복 로그인 체크 및 기존 세션 무효화
				boolean hadDuplicateSession = sessionManager.addSession(checkErr.get("u_id").toString(), session);
				if (hadDuplicateSession) {
					logger.warn("{} 사용자의 중복 로그인 감지. 기존 세션이 무효화되었습니다.", id);
				}

				// 세션에 계정 정보 추가
				logger.info("{} 사용자가 {}에 로그인하였습니다.",id,LocalDateTime.now());

				return resultMap;
			}
		} catch (IllegalStateException e) {
			
			logger.error("아이디 또는 비밀번호가 다릅니다",e);
			resultMap.put("ok", false); // 로그인 실패하면 false 반환
			resultMap.put("msg", "아이디 또는 비밀번호가 다릅니다.");
			return resultMap;
		} catch (NullPointerException e) {
			
			logger.error("NullPointerException => ",e);
			resultMap.put("ok", false); // 로그인 실패하면 false 반환
			resultMap.put("msg", "로그인 처리 중 오류 발생.");
			return resultMap;
		} catch (RuntimeException e) {
			
			logger.error("RuntimeException => ",e);
			resultMap.put("ok", false); // 로그인 실패하면 false 반환
			resultMap.put("msg", "로그인 처리 중 오류 발생.");
			return resultMap;
		} 
	}
	// 초기 사용자 로그인 변경 화면
	@RequestMapping("/viewPwdChanged.do")
	public String viewPwdChanged( 
			@RequestParam("uId") Integer uId,
			HttpServletResponse response,
			HttpSession session,
			Model model) {
		
		// 아이디가 없거나 비밀번호 변경상태 관련 세션 없는 상태에서 접근시 로그인 화면으로 이동
		if(session.getAttribute("uId") == null || session.getAttribute("pwdChanged") == null) {
			return "redirect:/user/login.do";
		}
		
		// 캐시 금지 헤더
	    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
	    response.setHeader("Pragma", "no-cache");
	    response.setDateHeader("Expires", 0L);
		
		model.addAttribute("uId", uId);
	    
		return "user/pwdChanged";
	}
	
	/*
	 * 로그아웃
	 */
	@RequestMapping("/logout")
	public String logout(HttpSession session, Model model) {
		String uId = (String) session.getAttribute("uId");
		
		String loginId = userService.getLoginId(Integer.parseInt(uId));
		if(loginId == null) {
			model.addAttribute("errorMsg", "로그아웃 중 오류가 발생했습니다.");
		}
		
		logger.info("{} 가 {}에 로그아웃하였습니다.", loginId, LocalDateTime.now());

		// 세션 매니저에서 사용자 세션 제거
		if (uId != null) {
			sessionManager.removeSession(uId);
		}

		session.invalidate(); // 세션 만료
		return "redirect:/user/login.do";
	}

	// 비밀번호 변경시 변경 내용 반영
	@ResponseBody
	@PostMapping("/updateNewPwd")
	public Map<String,Object> updateNewPwd(@RequestBody Map<String,Object> body, HttpSession session ) {
		
		Map<String,Object> res = new HashMap<>();
		
		try {
			
			// body 값 검증
	        Integer uId = (body.get("uId") instanceof Number)
	                ? ((Number) body.get("uId")).intValue()
	                : Integer.valueOf(String.valueOf(body.get("uId")));
            String newPwd = String.valueOf(body.get("newPwd"));

            if (uId == null || newPwd == null || newPwd.trim().isEmpty()) {
                res.put("ok", false);
                res.put("msg", "새 비밀번호를 입력해주세요.");
                return res;
            }
			
			// 평문 암호화
			String encryptPwd = cryptoARIAService.encryptPassword(newPwd);
			if(encryptPwd == null || encryptPwd.isEmpty()) {
				res.put("ok", false); 
				res.put("msg", "암호화 실패.");
				return res;
			}
			
			// 비밀번호 업데이트 전 비밀번호 비교하여 같으면 재입력 요청
			String oldPwd = userService.getPwd(uId);
			if(oldPwd == null || oldPwd.equals("") ) {
				res.put("ok", false); 
				res.put("msg", "이전 비밀번호를 가져오는 도중 오류 발생.");
				return res;
			}
			
			boolean result2 = cryptoARIAService.match(newPwd, oldPwd);
			if(result2) {
				res.put("ok", false); 
				res.put("msg", "새 비밀번호는 이전 비밀번호와 달라야 합니다.");
				return res;
			}
			
			// 비밀번호 update
			Integer result = userService.updateNewPwd(uId, encryptPwd);
			if(result != 1) {
				res.put("ok", false); 
				res.put("msg", "비밀번호 업데이트 실패.");
				return res;
			}
			
			// session에 id값, 비밀번호 변경 추가
			logger.info("{} 사용자가 {}에 로그인하였습니다.",uId,LocalDateTime.now());
			session.setAttribute("uId", uId.toString());
			session.setAttribute("pwdChanged", true);
			
		} catch(DataAccessException e2) {
	        logger.error("DB 처리 중 오류(updateNewPwd): ", e2);
	        res.put("ok", false);
	        res.put("msg", "데이터베이스 처리 중 오류가 발생했습니다.");
	        return res;
		} catch (RuntimeException e) {
			logger.error("updateNewPwd에서 오류 발생 : ",e);
	        res.put("ok", false);
	        res.put("msg", "비밀번호 변경 중 오류가 발생했습니다.");
			return res;
		}
		
		res.put("ok", true);
		return res;
		
	}
	
	/**
	 * 회원가입 화면 이동
	 * @return
	 */
	@RequestMapping("/register.do")
	public String viewRegister(Model model) {
		
		//  지역정보 가져오기
		List<Map<String,Object>> resultList = userService.getAllLocals();
		
		model.addAttribute("resultList", resultList);
		return "user/register";
	}
	
	/**
	 * 회원가입
	 * @param body
	 * @return
	 */
	@ResponseBody
	@PostMapping(value = "/register", produces = "application/json; charset=UTF-8")
	public Map<String,Object> register(
			@RequestBody Map<String,Object> body
			){
		
		Map<String,Object> resultMap = new HashMap<String, Object>();
		
		try {		
			
			// 신규 아이디인지 확인
			String uLoginId = body.get("u_login_id").toString();
			boolean isNewId = userService.checkNewUserId(uLoginId);
			if(!isNewId) {
				resultMap.put("ok", false);
				resultMap.put("msg", "이미 존재하는 ID입니다.");
				return resultMap;
			}
			
			// 암호화
			String uLoignPwd = body.get("u_login_pwd").toString();
			String encryptPwd = cryptoARIAService.encryptPassword(uLoignPwd);
			if(encryptPwd == null || encryptPwd.isEmpty()) {
				resultMap.put("ok", false); 
				resultMap.put("msg", "암호화 실패.");
				return resultMap;
			}
			
			// 데이터 insert
			body.put("encryptPwd", encryptPwd);
			Integer rows1 = userService.insertUser(body);
			if(rows1 != 1){
				resultMap.put("ok",false);
				resultMap.put("msg","회원가입 도중 오류 발생");
				return resultMap;
			}
			
			resultMap.put("ok",true);
			return resultMap;
		} catch (RuntimeException e) {
			logger.error("회원가입 중 오류 발생 : ",e);
			resultMap.put("ok",false);
			resultMap.put("msg","회원가입 도중 오류 발생");
			return resultMap;
		}
		
		
	}
	
	/**
	 * 아이디 중복 체크
	 * @param id
	 * @return
	 */
	@GetMapping("checkId")
	@ResponseBody
	public Map<String,Object> checkId(String id){
		
		Map<String, Object> resultMap = new HashMap<String, Object>();
		
		try {
			
			boolean isDuplicated = userService.isDuplicatedId(id);
			if(isDuplicated) {
				resultMap.put("ok", false);
				return resultMap;
			}
			
			resultMap.put("ok", true);
			return resultMap;
			
		} catch (RuntimeException e) {
			logger.error("아이디 체크 도중 오류 발생");
			resultMap.put("ok",false);
			return resultMap;
		}
		
	}
	
	/**
	 * 아이디 비번 찾기 화면 이동
	 * @return
	 */
	@RequestMapping("findIdPwd.do")
	public String viewfindIdPwd() {
		return "/user/findIdPwd";
	}
	
	/**
	 * 아이디 찾기
	 * @param body
	 * @return
	 */
	@ResponseBody
	@PostMapping(value = "/findId", produces = "application/json; charset=UTF-8")
	public Map<String, Object> findId(
			@RequestBody Map<String,Object> body){
		
		Map<String,Object> resultMap = new HashMap<String, Object>();
		
		try {
			
			String myId = userService.findId(body);
			if(myId == null || myId.toString().trim().isEmpty()) {
				resultMap.put("ok", false);
				resultMap.put("msg", "입력한 정보에 해당하는 아이디가 없습니다.");
			}
			
			// 아이디 결과 값 중간 * 처리
			String maskMyId = userService.maskMyId(myId);
			if(maskMyId == null || maskMyId.length() <= 0) {
				resultMap.put("ok", false);
				resultMap.put("msg", "아이디 마스킹 처리 실패");
			}
			
			resultMap.put("ok", true);
			resultMap.put("maskMyId", maskMyId);
			return resultMap;
		} catch (RuntimeException e) {
			logger.error("아이디 찾기 도중 오류 발생",e);
			resultMap.put("ok", false);
			resultMap.put("msg", "아이디 찾는 도중 오류 발생");
			return resultMap;
		}
		
	}
	
	/**
	 * 아이디 찾기 서브페이지
	 */
	@RequestMapping("/viewfindIdSubpage.do")
	public String viewFindIdSubpage() {
		
		return "/subpage/user/findIdSubpage";
	}
	
	/**
	 * 비밀번호 찾기 서브페이지
	 */
	@RequestMapping("viewfindPwdSubpage.do")
	public String viewfindPwdSubpage() {
		return "/subpage/user/findPwdSubpage";
	}
	
	/**
	 * 마스크 된 아이디를 보여주는 서브페이지 출력
	 */
	@RequestMapping("viewShowMaskedIdSubpage.do")
	public String viewShowMaskedIdSubpage(
			@RequestParam("maskedId") String maskedId
			, Model model) {
		
		model.addAttribute("maskedId", maskedId);
		return "/subpage/user/showMaskedIdSubpage";
		
	}
	
	
	/**
	 * 이름, 전번, 아이디로 비밀번호 인증하기
	 */
	@ResponseBody
	@PostMapping(value = "/authPwd", produces = "application/json; charset=UTF-8")
	public Map<String,Object> authPwd(
			@RequestBody Map<String,Object> body
			){
		
		Map<String,Object> resultMap = new HashMap<String, Object>();
		
		try {
			
			boolean isAuthPwd = userService.authPwd(body);
			if(isAuthPwd) {
				resultMap.put("ok", false);
				resultMap.put("msg", "인증 중 오류 발생");
				return resultMap;
			}
			
			resultMap.put("ok", true);
			return resultMap;
		} catch (RuntimeException e) {
			logger.error("인증 중 오류 발생 : ",e);
			resultMap.put("ok", false);
			resultMap.put("msg", "인증 중 오류 발생");
			return resultMap;
		}
	}
	
	/**
	 * 비밀번호 리셋 서브페이지 보여주기
	 */
	@RequestMapping("viewResetPwdSubpage.do")
	public String viewResetPwdSubpage() {
		return "/subpage/user/resetPwdSubpage";
	}
	
	/**
	 * 비밀번호 리셋
	 */
	@PostMapping(value = "/resetPwd", produces = "application/json; charset=UTF-8")
	public Map<String,Object> resetPwd(
			@RequestBody Map<String, Object> body
			){
		
		Map<String,Object> resultMap = new HashMap<String, Object>();
		
		try {
			
			// 암호화
			String uLoignPwd = body.get("u_login_pwd").toString();
			String encryptPwd = cryptoARIAService.encryptPassword(uLoignPwd);
			if(encryptPwd == null || encryptPwd.isEmpty()) {
				resultMap.put("ok", false); 
				resultMap.put("msg", "암호화 실패.");
				return resultMap;
			}
			
			// 비밀번호 리셋
			body.put("encryptPwd", encryptPwd);
			boolean isResetPwd = userService.resetPwd(body);
			if(!isResetPwd) {
				resultMap.put("ok", false);
				resultMap.put("msg", "비밀번호 리셋 중 오류 발생");
				return resultMap;
			}
			
			resultMap.put("ok", true);
			return resultMap;
		} catch (RuntimeException e) {
			logger.error("비밀번호 리셋 중 오류 발생 : ",e);
			resultMap.put("ok", false);
			resultMap.put("msg", "비밀번호 리셋 중 오류 발생");
			return resultMap;
		}
	}
	
	
	// 내 정보 수정 페이지 이동
	/*
	@RequestMapping("/viewMyInfo")
	public String viewMyInfo(@RequestParam("uId") Integer uId, Model model, HttpServletRequest request, RedirectAttributes redirectAttributes) {
		
		Map<String,Object> resultMap = new HashMap<String, Object>();
		
		try {
			resultMap = userService.getMyInfo(uId);
			if(resultMap == null) {
				logger.error("내 정보 가져오기 실패, resultMap이 null");
				
	            // 사용자에게 알림을 주고 싶다면(선택)
	            redirectAttributes.addFlashAttribute("myInfoErrorMsg", "내 정보를 가져오지 못했습니다.");

	            String referer = request.getHeader("Referer");
	            return "redirect:" + referer;   // 바로 직전 페이지로
				
			}
		} catch (RuntimeException e) {
			logger.error("viewMyInfo에서 오류 발생 : ",e);
			
			redirectAttributes.addFlashAttribute("myInfoErrorMsg", "내 정보 수정 페이지 이동 중 오류가 발생했습니다.");

            String referer = request.getHeader("Referer");
            return "redirect:" + referer;   // 바로 직전 페이지로
		}
		
		model.addAttribute("myInfo", resultMap);
		return "/user/myInfo";
	}
	
	// 개인정보 수정(비번 수정은 비번 수정 함수에서)
	@ResponseBody
	@PostMapping("/updateMyInfo")
	public Map<String,Object> updateMyInfo(
			@RequestParam("uId") Integer uId
			// 지역 , @RequestParam("")
			){
		
		Map<String, Object> res = new HashMap<String, Object>();
		
		try {
			
			// 비밀번호 제외한 내 정보 수정
			Integer row1 = userService.updateMyInfoExceptPwd(uId);
			if(row1 != 1) {
				res.put("ok", false);
				res.put("msg","내 정보 수정중 오류가 발생했습니다.");
				return res;
			}
			
			res.put("ok", true);
			return res;
		} catch (RuntimeException e) {
			logger.error("updateMyInfo에서 오류 발생 : ",e);
			res.put("ok", false);
			res.put("msg","내 정보 수정중 오류가 발생했습니다.");
			return res;
		}
		
	}
	
	// 회원관리 화면으로 이동
	@RequestMapping("/viewManageUsers")
	public String viewManageUsers(
			@RequestParam("uId") Integer uId
			, @RequestParam(value="startDate", required=false) String startDate
			, @RequestParam(value="endDate", required=false) String endDate
			, @RequestParam(value="searchKeyword", required=false) String searchKeyword
			, @RequestParam(value="page", defaultValue = "1") Integer page
			, @RequestParam(value="size", defaultValue = "10") Integer size
			, Model model
			, HttpSession session
			, HttpServletRequest request
			) {
		
		List<Map<String,Object>> resultMap = new ArrayList<Map<String,Object>>();
		
		try {
			Map<String, Object> paramMap = new HashMap<String, Object>();
			paramMap.put("startDate", startDate);
			paramMap.put("endDate", endDate);
			paramMap.put("searchKeyword", searchKeyword);
			
			Integer totalRecordCount = userService.getTotalRecordCountByManaegUsers(paramMap);
			
			Paging paging = new Paging(page, size, totalRecordCount);
			
			paging.computeWithTotal(totalRecordCount);
			
			// 세션과 비교해 검색 결과가 달라졌다면 검색 결과 1로 설정(필터 변경으로 페이징 수가 줄어들었을 경우 빈 화면이 나오는 것 방지)
			
			String prevSig = (String) session.getAttribute("userListSearchSig");
			String sig = startDate + "|" + endDate + "|" + searchKeyword;
			if (!sig.equals(prevSig)) {
				page = 1;
			    session.setAttribute("userListSearchSig", sig);
			}
			
			
		    // 마지막 페이지 계산 후 page 보정
			paging.currectionPage();
			
			paramMap.put("offset", paging.getOffset());
			paramMap.put("limit", paging.getLimit());
			resultMap = userService.getUserListManage(paramMap);
		} catch (IllegalStateException e) {
			logger.error("viewManageUsers에서 오류 발생",e);
			
			String referer = request.getHeader("Referer");
			return "redirect:" + referer;
		}
		
		model.addAttribute("page", page);
		model.addAttribute("userList", resultMap);
		return "/user/manageUsers";
	}
	*/
}
