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
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
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

		// 세션 확인 - 이미 로그인되어 있다면 메인 화면으로 이동
	    HttpSession s = request.getSession(false);
	    if (s != null && s.getAttribute("id") != null) {
	    	String userId = (String) s.getAttribute("id");
	    	
	    	// sessionManager에 등록된 유효한 세션인지 확인
	    	HttpSession registeredSession = sessionManager.getSession(userId);
	    	if (registeredSession != null && registeredSession.getId().equals(s.getId())) {
	    		// 유효한 세션이면 메인 화면으로 리다이렉트 (필요시 변경)
	    		return "redirect:/stats/viewStat.do";
	    	} else {
	    		// sessionManager에 없거나 다른 세션이면 기존 세션 무효화
	    		try { s.invalidate(); } catch (IllegalStateException ignore) {logger.debug("",ignore);}
	    	}
	    } else if (s != null) {
	    	// 세션은 있지만 id가 없으면 무효화
	        try { s.invalidate(); } catch (IllegalStateException ignore) {logger.debug("",ignore);}
	    }
	    // 캐시 방지 (뒤로가기 시 로그인 화면이 캐시로 보이는 현상 방지)
	    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
	    response.setHeader("Pragma", "no-cache");
	    response.setDateHeader("Expires", 0L);

		return "user/login";
	}
	
	// 사용자 ID,PW를 확인하여 가입되었다면 통계 화면으로, 그렇지 않다면 로그인 화면으로 이동
	@ResponseBody
	@PostMapping("/login")
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
					resultMap.put("pwdChanged", false);
					resultMap.put("uId", checkErr.get("u_id"));
				}else {
					resultMap.put("pwdChanged", true);
				}

				resultMap.put("success", true); // 로그인 성공하면 true 반환

				// 중복 로그인 체크 및 기존 세션 무효화
				boolean hadDuplicateSession = sessionManager.addSession(id, session);
				if (hadDuplicateSession) {
					logger.warn("{} 사용자의 중복 로그인 감지. 기존 세션이 무효화되었습니다.", id);
				}

				// 세션에 계정 정보 추가
				logger.info("{} 사용자가 {}에 로그인하였습니다.",id,LocalDateTime.now());
				session.setAttribute("id", id);

				return resultMap;
			}
		} catch (IllegalArgumentException e) {
			
			logger.error("잘못된 인자 전달",e);
			resultMap.put("ok", false); // 로그인 실패하면 false 반환
			resultMap.put("msg", "로그인 처리 중 오류 발생.");
			
		} catch (NullPointerException e) {
			
			logger.error("NullPointerException => ",e);
			resultMap.put("ok", false); // 로그인 실패하면 false 반환
			resultMap.put("msg", "로그인 처리 중 오류 발생.");
			
		} catch (RuntimeException e) {
			
			logger.error("RuntimeException => ",e);
			resultMap.put("ok", false); // 로그인 실패하면 false 반환
			resultMap.put("msg", "로그인 처리 중 오류 발생.");
			
		} 
		
		return resultMap;
	}
	
	// 초기 사용자 로그인 변경 화면
	@RequestMapping("/viewPwdChanged.do")
	public String viewPwdChanged( 
			@RequestParam("uId") Integer uId,
			Model model) {
		
		model.addAttribute("uId", uId);
		return "user/pwdChanged";
	}
	
	/*
	 * 로그아웃
	 */
	@RequestMapping("/logout")
	public String logout(HttpSession session) {
		String userId = (String) session.getAttribute("id");
		logger.info("{} 사용자가 {}에 로그아웃하였습니다.", userId, LocalDateTime.now());

		// 세션 매니저에서 사용자 세션 제거
		if (userId != null) {
			sessionManager.removeSession(userId);
		}

		session.invalidate(); // 세션 만료
		return "redirect:/user/login.do";
	}

	// 비밀번호 변경시 변경 내용 반영
	@ResponseBody
	@PostMapping("/updateNewPwd")
	public Map<String,Object> updateNewPwd(@RequestBody Map<String,Object> body) {
		
		Map<String,Object> res = new HashMap<>();
		
		try {
			
			// body 값 검증
	        Integer uId = (body.get("uId") instanceof Number)
	                ? ((Number) body.get("uId")).intValue()
	                : Integer.valueOf(String.valueOf(body.get("uId")));
            String newPwd = String.valueOf(body.get("newPwd"));

            if (uId == null || newPwd == null || newPwd.trim().isEmpty()) {
                res.put("ok", false);
                res.put("msg", "요청 값이 올바르지 않습니다.");
                return res;
            }
			
			// 평문 암호화
			String encryptPwd = cryptoARIAService.encryptPassword(newPwd);
			
			// 비밀번호 update
			userService.updateNewPwd(uId, encryptPwd);
			
		} catch (RuntimeException e) {
			logger.error("updateNewPwd에서 오류 발생 : ",e);
	        res.put("ok", false);
	        res.put("msg", "비밀번호 변경 중 오류가 발생했습니다.");
			return res;
		}
		
		res.put("ok", true);
		return res;
		
	}
}
