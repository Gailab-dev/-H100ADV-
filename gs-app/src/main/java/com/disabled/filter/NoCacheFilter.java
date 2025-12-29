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
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import lombok.NoArgsConstructor;

@NoArgsConstructor
public class NoCacheFilter implements Filter{

	private static final Logger logger = LoggerFactory.getLogger(NoCacheFilter.class);
	
    private List<Pattern> excludePatterns = Collections.emptyList();
	
    /**
     * 캐싱 예외 필터에 설정된 필터값을 제외한 나머지 웹페이지에는 no-cache 설정
     */

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

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;

        // 컨텍스트 루트를 제거한 경로로 매칭 (예: /gov-disabled-web-gs/css/.. → /css/..)
        String ctx = req.getContextPath();
        String uri = req.getRequestURI();
        String path = uri.startsWith(ctx) ? uri.substring(ctx.length()) : uri;

        boolean excluded = excludePatterns.stream().anyMatch(p -> p.matcher(path).matches());

        if (!excluded) {
            // 보호 페이지에만 캐시 금지
            res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
            res.setHeader("Pragma", "no-cache");
            res.setDateHeader("Expires", 0);
        }

        chain.doFilter(request, response);
    }

	@Override
	public void destroy() {
		// TODO Auto-generated method stub
		
	}
}
