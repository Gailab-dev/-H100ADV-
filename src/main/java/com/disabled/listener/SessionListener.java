package com.disabled.listener;

import javax.servlet.annotation.WebListener;
import javax.servlet.http.HttpSessionEvent;
import javax.servlet.http.HttpSessionListener;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.disabled.component.SessionManager;

/**
 * HTTP 세션 생성 및 소멸을 감지하는 리스너
 */
@Component
@WebListener
public class SessionListener implements HttpSessionListener {

    private static final Logger logger = LoggerFactory.getLogger(SessionListener.class);

    @Autowired
    private SessionManager sessionManager;

    @Override
    public void sessionCreated(HttpSessionEvent se) {
        logger.debug("세션 생성 - 세션ID: {}", se.getSession().getId());
        // 세션 타임아웃 설정 (30분)
        se.getSession().setMaxInactiveInterval(1800);
    }

    @Override
    public void sessionDestroyed(HttpSessionEvent se) {
        String sessionId = se.getSession().getId();
        logger.debug("세션 소멸 - 세션ID: {}", sessionId);

        // 세션 맵에서 제거
        if (sessionManager != null) {
            sessionManager.removeSessionById(sessionId);
        }
    }
}
