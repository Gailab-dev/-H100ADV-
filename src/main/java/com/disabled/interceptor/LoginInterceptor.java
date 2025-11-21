package com.disabled.interceptor;

import java.io.IOException;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.ModelAndView;

@Component
public class LoginInterceptor implements HandlerInterceptor{
    
	private final Logger logger = LoggerFactory.getLogger(this.getClass());
	
	/*
	 * 세션이 사라지면 자동으로 로그아웃하여 로그인 페이지로 이동
	 * handler:
	 * - 현재 요청을 처리한 대상 핸들러 객체
	 * - @Controller 클래스 내의 메서드 정보를 가지고 있음
	 * - 2025.07.31. 현재는 해당 변수 사용하고 있지 않으나 추후 기능 추가가 필요한 경우를 위해 남겨놓았음
	 */
	@Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
        throws RuntimeException {
		
		// 컨텍스트 패스
		String ctx = request.getContextPath(); 
		
		// 화면 이동 등 요청 uri
		String uri = request.getRequestURI();
		
        HttpSession session = request.getSession(false);
        
        //session의 로그인 id 값
        Object uId = (session != null) ? session.getAttribute("uId") : null;
        
        
        // 로그인 페이지와 정적 자원은 제외
        /*
         * 
         */
        if (uri.contains("/user/login.do") 
        		|| uri.contains("/user/login")
        		|| uri.contains("/user/register.do")
        		|| uri.contains("/user/register")
        		|| uri.contains("/user/checkId")
        		|| uri.contains("/user/findIdPwd.do")
        		|| uri.contains("/user/findId")
        		|| uri.contains("/user/findPwd")
        		|| uri.contains("/user/viewfindIdSubpage.do")
        		|| uri.contains("/user/viewfindPwdSubpage.do")
        		|| uri.contains("/user/viewShowMaskedIdSubpage.do")
        		|| uri.contains("/user/authPwd")
        		|| uri.contains("/user/viewResetPwdSubpage.do")
        		|| uri.contains("/user/resetPwd")
        		|| uri.contains("/logout")
        		|| uri.contains("/css") 
        		|| uri.contains("/js") 
        		|| uri.contains("/images")
        		|| uri.contains("/font")) {
            return true;
        }
        
        // id 값이 session에 없다면 login 화면으로 이동
        if (uId == null) {
        	
        	setNoStore(response);
            
            try {
                response.sendRedirect(ctx + "/user/login.do"); // 실제 로그인 엔드포인트로
            } catch (IOException e) {
                logger.error("LoginInterceptor에서 session에 id값이 없어 login 화면으로 이동하는 중 오류: ", e);
            }
            return false;
        }
        
        // 최초 비밀번호 미변경시 비밀번호 변경 관련 url 허용
        Boolean pwdChanged = (session == null) ? null : (Boolean) session.getAttribute("pwdChanged");
        boolean isPwdEndpoints =
                uri.equals(ctx + "/user/viewPwdChanged.do") ||
                uri.equals(ctx + "/user/updateNewPwd");
        
        if (Boolean.FALSE.equals(pwdChanged)) {
            if (isPwdEndpoints) {
            	return true;
            }else {
            	
            	setNoStore(response);
            	
            	try {
					response.sendRedirect(ctx + "/user/viewPwdChanged.do?uId="+uId);
				} catch (IOException e) {
					logger.error("LoginInterceptor에서 비밀번호 변경 페이지로 이동 중 오류: ", e);
				}
            	return false;
            }
        }
        
        // 비밀번호 변경 확인시 메인 화면으로 이동 허용
        if (Boolean.TRUE.equals(pwdChanged) && isPwdEndpoints) {
            try {
            	setNoStore(response);
				response.sendRedirect(ctx + "/stats/viewStat.do");
			} catch (IOException e) {
				logger.error("LoginInterceptor에서 로그인 되었고, 비밀번호까지 변경한 사용자가 메인 페이지로 이동 중 오류: ", e);
			}
            return false;
        }
        
        // 그 외 허용
        return true;
    }
	
    @Override
    public void postHandle(HttpServletRequest req, HttpServletResponse res, Object handler,
                           ModelAndView modelAndView) {
        // 민감 화면에는 캐시 금지(뒤/앞으로 가기 시 재요청 유도)
        final String uri = req.getRequestURI();
        final String ctx = req.getContextPath();
        if (uri.equals(ctx + "/user/login.do")
         || uri.equals(ctx + "/user/viewPwdChanged.do")
         || uri.equals(ctx + "/user/register.do")
         || uri.startsWith(ctx + "/stats/")) {
            setNoStore(res);
        }
    }
	
	
    // 캐시 금지 헤더
    private static void setNoStore(HttpServletResponse res) {
        res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
        res.setHeader("Pragma", "no-cache");
        res.setDateHeader("Expires", 0L);
    }
}
