package com.disabled.component;

import java.util.concurrent.ConcurrentHashMap;

import javax.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * 세션 관리 컴포넌트
 * 사용자별 세션을 관리하여 중복 로그인을 방지
 */
@Component
public class SessionManager {

    private static final Logger logger = LoggerFactory.getLogger(SessionManager.class);

    // 사용자 ID를 키로, 세션을 값으로 저장하는 맵
    private final ConcurrentHashMap<String, HttpSession> userSessionMap = new ConcurrentHashMap<>();

    /**
     * 사용자 세션 등록
     * @param userId 사용자 ID
     * @param session 현재 세션
     * @return 기존 세션이 있었다면 true, 없었다면 false
     */
    public boolean addSession(String userId, HttpSession session) {
        HttpSession oldSession = userSessionMap.get(userId);

        // 기존 세션이 존재하면 무효화
        if (oldSession != null && !oldSession.getId().equals(session.getId())) {
            try {
                logger.info("중복 로그인 감지 - 사용자: {}, 기존 세션 무효화", userId);
                oldSession.invalidate();
            } catch (IllegalStateException e) {
                logger.debug("이미 무효화된 세션 - 사용자: {}", userId, e);
            }
            userSessionMap.put(userId, session);
            return true; // 기존 세션이 있었음
        }

        // 새로운 세션 등록
        userSessionMap.put(userId, session);
        logger.info("새 세션 등록 - 사용자: {}, 세션ID: {}", userId, session.getId());
        return false; // 기존 세션이 없었음
    }

    /**
     * 사용자 세션 제거
     * @param userId 사용자 ID
     */
    public void removeSession(String userId) {
        HttpSession session = userSessionMap.remove(userId);
        if (session != null) {
            logger.info("세션 제거 - 사용자: {}, 세션ID: {}", userId, session.getId());
        }
    }

    /**
     * 세션 ID로 사용자 세션 제거
     * @param sessionId 세션 ID
     */
    public void removeSessionById(String sessionId) {
        userSessionMap.entrySet().removeIf(entry -> {
            if (entry.getValue().getId().equals(sessionId)) {
                logger.info("세션 제거 - 사용자: {}, 세션ID: {}", entry.getKey(), sessionId);
                return true;
            }
            return false;
        });
    }

    /**
     * 특정 사용자의 세션 가져오기
     * @param userId 사용자 ID
     * @return 세션 (없으면 null)
     */
    public HttpSession getSession(String userId) {
        return userSessionMap.get(userId);
    }

    /**
     * 현재 관리 중인 세션 개수
     * @return 세션 개수
     */
    public int getSessionCount() {
        return userSessionMap.size();
    }
}
