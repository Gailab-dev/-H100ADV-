package com.disabled.filter;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

/**
 * 세션 만료시 로그아웃 기능을 구현하기 위해, 톰켓에서 web.xml의 session-timeout 시간 값을 가져오는 filter
 * @author 지아이랩
 *
 */
public class SessionTimeoutFilter implements  Filter{

	@Override
	public void init(FilterConfig filterConfig) throws ServletException {
		// TODO Auto-generated method stub
		
	}
	
	/**
	 * session에서 sessionTimeout 이름으로 web.xml의 time-out 값 추가
	 */
	@Override
	public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
			throws IOException, ServletException {
        
		HttpServletRequest req = (HttpServletRequest) request;
        HttpSession session = req.getSession(false);

        if (session != null) {
        	// session에서 sessionTimeout 이름으로 jsp 등에서 불러올 수 있음
            request.setAttribute("sessionTimeout", session.getMaxInactiveInterval());
        }

        chain.doFilter(request, response);
		
	}

	@Override
	public void destroy() {
		// TODO Auto-generated method stub
		
	}

}
