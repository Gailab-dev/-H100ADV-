package com.disabled.controller;

import java.time.LocalDateTime;
import java.util.HashMap;
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
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.disabled.component.SessionManager;
import com.disabled.mapper.LoginMapper;
import com.disabled.model.AccountLockStatus;
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
	
	@Autowired
	LoginMapper loginMapper;
	
	// 로그인 화면으로 redirect
	@RequestMapping("")
	public String rootRedirect() {
		
		return "redirect:/user/login.do";
	}
	
	// 로그인 화면 이동
	@RequestMapping("/login.do")
	private String viewLogin(
			HttpServletRequest request
			, HttpServletResponse response
			, @RequestParam(value = "errorMsg", required = false) String errorMsg
			, Model model) {
		
		if(errorMsg == "") {
			errorMsg = null;
		}
		
	    // 캐시 방지 (뒤로가기 시 로그인 화면이 캐시로 보이는 현상 방지)
	    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
	    response.setHeader("Pragma", "no-cache");
	    response.setDateHeader("Expires", 0L);
	    
		// 세션 확인하여 남은 세션 정리
	    HttpSession s = request.getSession(false);
	    if (s != null) {
	    	s.invalidate();
	    }	
	    
	    model.addAttribute("errorMsg", errorMsg);
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
			
			//id 기준 계정 조회하여 계정 잠금 로직 수행
			AccountLockStatus status = userService.checkLockedAccount(id);
			switch (status) {
			case NO_ACCOUNT:
				resultMap.put("ok", false);
				resultMap.put("msg", "아이디 또는 비밀번호가 다릅니다.");
				logger.info("{} 사용자가 {}에 로그인 실패하였습니다. - 아이디 또는 비밀번호가 다름",id,LocalDateTime.now());
				return resultMap;
			case LOCKED_UNDER_TERM:
				resultMap.put("ok", false);
				resultMap.put("msg", "5회 이상 비밀번호가 틀렸음으로 계정이 잠금 처리되었습니다. 5분 이후에 다시 시도하세요.");
				logger.info("{} 사용자가 {}에 로그인 실패하였습니다. - 5회 이상 비밀번호가 틀림",id,LocalDateTime.now());
				return resultMap;
			
			case LOCKED_UNLOCKABLE:
				boolean isUpdated = userService.resetFailCount(id);
				if(!isUpdated) {
					resultMap.put("ok", false); // 로그인 성공하면 true 반환
					resultMap.put("msg", "로그인 성공 후 계정 정보 update 실패.");
					logger.info("{} 사용자가 {}에 로그인 실패하였습니다. - 로그인 성공 후 계정 정보 update 실패",id,LocalDateTime.now());
					return resultMap;
				}
				break;
			case NOT_LOCKED:	
				break;
				
			default:
				break;
			}		
			
			// 암호화
			String encryptPwd = cryptoARIAService.encryptPassword(pwd);
			if(encryptPwd == null || encryptPwd.isEmpty()) {
				resultMap.put("ok", false); 
				resultMap.put("msg", "암호화 실패.");
			}
			
			Map<String, Object> checkErr = userService.loginCheck(id, encryptPwd); //db에 해당 사용자가 있는지 체크
			if(checkErr == null) {
				
				// 로그인 실패 로직 수행
				userService.loginFailService(id);
				
				// 로그인 실패 메시지 전달
				logger.info("{} 사용자가 {}에 로그인 실패하였습니다. - 아이디 또는 비밀번호가 다름",id,LocalDateTime.now());
				resultMap.put("msg", "아이디 또는 비밀번호가 다릅니다.");
				resultMap.put("ok", false); // 로그인 실패하면 false 반환
				return resultMap;
			}else {
				
				// 로그인 실패한 count값 0으로 초기화
				userService.resetLoginFailCount(id);
				
				// 최초 사용자라면 비밀변호 변경 또는 비밀번호 변경일이 180일 이상이라면 비밀번호 변경
		        Object obj = checkErr.get("pwdPassedDays");
		        Integer passedDays = 0;
		        if(obj != null) passedDays = ((Number) obj).intValue(); 
		        if( Integer.parseInt(checkErr.get("u_pwd_changed").toString()) == 0 || passedDays >= 180) {
					
					// session에 uId와 비밀번호 변경 하지 않음(false)로 저장
					session.setAttribute("uId", checkErr.get("u_id"));
					session.setAttribute("pwdChanged", false);
					
					// resultMap에 uId와 비밀번호 변경 하지 않음(false)로 저장
					resultMap.put("pwdChanged", false);
					resultMap.put("uId", checkErr.get("u_id"));
					resultMap.put("pwdPassedDays", passedDays);
				}else {
					// session에 uId와 비밀번호 변경함(true)로 저장
					session.setAttribute("uId", checkErr.get("u_id"));
					session.setAttribute("pwdChanged", true);
					
					// resultMap에 uId와 비밀번호 변경함(true)로 저장
					resultMap.put("pwdChanged", true);
					resultMap.put("uId", checkErr.get("u_id"));
				}

				// 중복 로그인 체크 및 기존 세션 무효화
				boolean hadDuplicateSession = sessionManager.addSession(checkErr.get("u_id").toString(), id, session);
				if (hadDuplicateSession) {
					logger.warn("{} 사용자의 중복 로그인 감지. 기존 세션이 무효화되었습니다.", id);
				}
				
				logger.info("{} 사용자가 {}에 로그인하였습니다.", id, LocalDateTime.now());
				resultMap.put("ok", true); // 로그인 성공하면 true 반환
				return resultMap;
			}
		} catch (IllegalStateException e) {
			logger.info("{} 사용자가 {}에 로그인 실패하였습니다.", body.get("id"), LocalDateTime.now());
			logger.error("아이디 또는 비밀번호가 다릅니다",e);
			resultMap.put("ok", false); // 로그인 실패하면 false 반환
			resultMap.put("msg", "아이디 또는 비밀번호가 다릅니다.");
			return resultMap;
		} catch (NullPointerException e) {
			logger.info("{} 사용자가 {}에 로그인 실패하였습니다.", body.get("id"), LocalDateTime.now());
			logger.error("NullPointerException => ",e);
			resultMap.put("ok", false); // 로그인 실패하면 false 반환
			resultMap.put("msg", "로그인 처리 중 오류 발생.");
			return resultMap;
		} catch (RuntimeException e) {
			logger.info("{} 사용자가 {}에 로그인 실패하였습니다.", body.get("id"), LocalDateTime.now());
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
		
		logger.info("{}(" + loginMapper.getLoginId((int)session.getAttribute("uId")) + ") 사용자가 {}에 초기 사용자 비밀번호 변경을 진행합니다.",uId,LocalDateTime.now());
		
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
		String uId = session.getAttribute("uId").toString();
		
		String loginId = userService.getLoginId(Integer.parseInt(uId));
		if(loginId == null) {
			model.addAttribute("errorMsg", "로그아웃 중 오류가 발생했습니다.");
		}
		
		logger.info("{} 가 {}에 로그아웃하였습니다.", loginId, LocalDateTime.now());

		// 세션 매니저에서 사용자 세션 제거
		if (uId != null) {
			sessionManager.removeSession(uId, loginId);
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
                logger.info("{}(" + loginMapper.getLoginId(uId) + ") 사용자가 {}에 로그인 실패하였습니다. - 새 비밀번호를 입력 필요",uId,LocalDateTime.now());
                return res;
            }
			
			// 평문 암호화
			String encryptPwd = cryptoARIAService.encryptPassword(newPwd);
			if(encryptPwd == null || encryptPwd.isEmpty()) {
				res.put("ok", false); 
				res.put("msg", "암호화 실패.");
				logger.info("{}(" + loginMapper.getLoginId(uId) + ") 사용자가 {}에 로그인 실패하였습니다. - 암호화 실패",uId,LocalDateTime.now());
				return res;
			}
			
			// 비밀번호 업데이트 전 비밀번호 비교하여 같으면 재입력 요청
			String oldPwd = userService.getPwd(uId);
			if(oldPwd == null || oldPwd.equals("") ) {
				res.put("ok", false); 
				res.put("msg", "이전 비밀번호를 가져오는 도중 오류 발생.");
				logger.info("{}(" + loginMapper.getLoginId(uId) + ") 사용자가 {}에 로그인 실패하였습니다. - 이전 비밀번호를 가져오는 도중 오류 발생",uId,LocalDateTime.now());
				return res;
			}
			
			boolean result2 = cryptoARIAService.match(newPwd, oldPwd);
			if(result2) {
				res.put("ok", false); 
				res.put("msg", "새 비밀번호는 이전 비밀번호와 달라야 합니다.");
				logger.info("{}(" + loginMapper.getLoginId(uId) + ") 사용자가 {}에 로그인 실패하였습니다. - 이전 비밀번호와 동일",uId,LocalDateTime.now());
				return res;
			}
			
			// 비밀번호 update
			Integer result = userService.updateNewPwd(uId, encryptPwd);
			if(result != 1) {
				res.put("ok", false); 
				res.put("msg", "비밀번호 업데이트 실패.");
				logger.info("{}(" + loginMapper.getLoginId(uId) + ") 사용자가 {}에 로그인 실패하였습니다. - 비밀번호 업데이트 실패",uId,LocalDateTime.now());
				return res;
			}
			
			// session에 id값, 비밀번호 변경 추가
			logger.info("비밀번호 변경 성공! {}(" + loginMapper.getLoginId(uId) + ") 사용자가 {}에 로그인하였습니다.",uId,LocalDateTime.now());
			session.setAttribute("uId", uId.toString());
			session.setAttribute("pwdChanged", true);
			
		} catch(DataAccessException e2) {
			logger.info("{}(" + loginMapper.getLoginId((int)body.get("uId")) + ") 사용자가 {}에 로그인 실패하였습니다.",body.get("uId"),LocalDateTime.now());
	        logger.error("DB 처리 중 오류(updateNewPwd): ", e2);
	        res.put("ok", false);
	        res.put("msg", "데이터베이스 처리 중 오류가 발생했습니다.");
	        return res;
		} catch (RuntimeException e) {
			logger.info("{}(" + loginMapper.getLoginId((int)body.get("uId")) + ") 사용자가 {}에 로그인 실패하였습니다.",body.get("uId"),LocalDateTime.now());
			logger.error("updateNewPwd에서 오류 발생 : ",e);
	        res.put("ok", false);
	        res.put("msg", "비밀번호 변경 중 오류가 발생했습니다.");
	        
			return res;
		}
		
		res.put("ok", true);
		return res;
		
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
