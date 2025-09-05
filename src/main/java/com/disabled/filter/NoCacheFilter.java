package com.disabled.filter;

import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@WebFilter("/*")
public class NoCacheFilter implements Filter{

	private static final Logger logger = LoggerFactory.getLogger(NoCacheFilter.class);
	
    private List<Pattern> excludePatterns = Collections.emptyList();
	
	@Override
	public void init(FilterConfig filterConfig) throws ServletException {
        
		// 캐싱 예외 필터 설정
		String patterns = filterConfig.getInitParameter("excludePatterns");
        if (patterns != null && !patterns.trim().isEmpty()) {
            excludePatterns = Arrays.stream(patterns.split("\\s*,\\s*"))
                    .filter(s -> !s.isEmpty())
                    .map(Pattern::compile) // 정규식 컴파일
                    .collect(Collectors.toList());
        }
		
        logger.info("[NoCacheFilter] initialized. excludePatterns={}",excludePatterns);
        
	}

	@Override
	public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
			throws IOException, ServletException {
		
		HttpServletResponse res = (HttpServletResponse) response;
		
		// 모든 페이지에 캐시 금지 헤더 설정
	    res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
	    res.setHeader("Pragma", "no-cache");
	    res.setDateHeader("Expires", 0);

	    chain.doFilter(request, response);
		
	}

	@Override
	public void destroy() {
		// TODO Auto-generated method stub
		
	}
	
}
