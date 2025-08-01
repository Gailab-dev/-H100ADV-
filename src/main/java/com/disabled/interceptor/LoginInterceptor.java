package com.disabled.interceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.springframework.web.servlet.HandlerInterceptor;

public class LoginInterceptor implements HandlerInterceptor{
    
	/*
	 * 세션이 사라지면 자동으로 로그아웃하여 로그인 페이지로 이동
	 * handler:
	 * - 현재 요청을 처리한 대상 핸들러 객체
	 * - @Controller 클래스 내의 메서드 정보를 가지고 있음
	 * - 2025.07.31. 현재는 해당 변수 사용하고 있지 않으나 추후 기능 추가가 필요한 경우를 위해 남겨놓았음
	 */
	@Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
        throws Exception {

        HttpSession session = request.getSession(false);
        String uri = request.getRequestURI();
        
        // id 값이 session에 없다면 login 화면으로 이동
        if (session == null || session.getAttribute("id") == null) {
            if (!uri.contains("/login.do")) {
                response.sendRedirect("/gov-disabled-web-gs/stats/login.do?timeout=true");
                return false;
            }
        }

        return true;
    }
}
