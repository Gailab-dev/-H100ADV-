package com.disabled.component;

import java.security.SecureRandom;
import java.util.Base64;
import java.util.Iterator;
import java.util.Map;
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

    // (37 WP-L1) 로그인 화면에 표시할 사유 코드(화이트리스트). URL 로는 코드만 오가고,
    // 화면 문구는 아래 reasonMessage() 가 서버 고정 문구로 바꿔 준다(임의 문자열 표시 금지).
    public static final String REASON_DUPLICATE = "DUP";      // 다른 PC 에서 로그인
    public static final String REASON_IDLE = "IDLE";          // 장기간 미사용
    public static final String REASON_EXPIRED = "EXPIRED";    // 세션 만료(요청 쿠키의 세션이 이미 무효)

    // (37 WP-L1) 이전 버전 화면/캐시된 JS 가 보내는 errorMsg 문구와의 호환 — 정확히 일치하는 고정 문구만 코드로 환산한다.
    private static final String LEGACY_MSG_IDLE = "장기간 미사용으로 로그아웃되었습니다.";
    private static final String LEGACY_MSG_DUPLICATE = "다른 PC에서 로그인하여 이 PC에서는 로그아웃합니다.";

    /** 사유 코드 → 화면 문구. 허용 코드 목록이기도 하다. */
    public static String reasonMessage(String code) {
        if (code == null) {
            return null;
        }
        switch (code) {
        case REASON_DUPLICATE:
            return "다른 PC에서 로그인하여 이 PC에서는 로그아웃되었습니다.";
        case REASON_IDLE:
            return LEGACY_MSG_IDLE;
        case REASON_EXPIRED:
            return "세션이 만료되어 로그아웃되었습니다. 다시 로그인해 주세요.";
        default:
            return null;
        }
    }

    /** 구 errorMsg 파라미터 문구를 사유 코드로 환산(일치하지 않으면 null — 임의 문구는 표시하지 않는다). */
    public static String reasonCodeFromLegacyMessage(String msg) {
        if (LEGACY_MSG_IDLE.equals(msg)) {
            return REASON_IDLE;
        }
        if (LEGACY_MSG_DUPLICATE.equals(msg)) {
            return REASON_DUPLICATE;
        }
        return null;
    }

    // 사용자 ID를 키로, 세션을 값으로 저장하는 맵
    private final ConcurrentHashMap<String, HttpSession> userSessionMap = new ConcurrentHashMap<>();

    // (패치 2026-09-05) 다른 PC 로그인으로 무효화된 (구)세션ID → 사용자에게 보여줄 사유.
    // invalidate() 이후엔 세션 객체 자체에서 값을 꺼낼 수 없으므로, 무효화 직전에 세션ID를 키로
    // 별도 보관해둔다. 무효화된 PC의 폴링(UserController#sessionStatus)이 세션ID(쿠키값 — 세션이
    // 죽은 뒤에도 request.getRequestedSessionId()로 읽을 수 있음)로 조회해 1회 소비한다.
    // (37 WP-L1) 값은 문구가 아니라 사유 코드. 소비되지 않고 남는 항목(이전 PC 가 꺼진 경우 등)이 쌓이지 않도록
    // 등록 시각을 같이 두고 REASON_TTL_MS 가 지나면 정리한다.
    private final ConcurrentHashMap<String, TimedValue> logoutReasonBySessionId = new ConcurrentHashMap<>();
    private static final long REASON_TTL_MS = 12L * 60 * 60 * 1000;

    // (37 WP-L2) 새 로그인 확인용 1회용 토큰. 비밀번호 검증을 통과한 인증 건에만 발급하고,
    // 인증 요청을 보낸 브라우저의 세션ID 에 묶으며, 짧게 유지하고(60초) 1회만 쓸 수 있다.
    private final ConcurrentHashMap<String, LoginConfirm> loginConfirmMap = new ConcurrentHashMap<>();
    public static final long LOGIN_CONFIRM_TTL_MS = 60L * 1000;
    private final SecureRandom secureRandom = new SecureRandom();

    private static final class TimedValue {
        final String value;
        final long createdAt = System.currentTimeMillis();

        TimedValue(String value) {
            this.value = value;
        }
    }

    /**
     * (37 WP-L2) 비밀번호 검증을 통과한 인증 건 정보. 비밀번호는 담지 않는다.
     */
    public static final class LoginConfirm {
        public final String userId;
        public final String loginId;
        public final String requesterSessionId;
        public final String requesterIp;
        public final Object uIdValue;      // DB 에서 읽은 u_id 원본(세션 속성에 그대로 저장하는 값)
        public final Object uGradeValue;   // DB 에서 읽은 u_grade 원본
        public final boolean pwdChanged;
        public final long createdAt = System.currentTimeMillis();

        LoginConfirm(String userId, String loginId, String requesterSessionId, String requesterIp,
                Object uIdValue, Object uGradeValue, boolean pwdChanged) {
            this.userId = userId;
            this.loginId = loginId;
            this.requesterSessionId = requesterSessionId;
            this.requesterIp = requesterIp;
            this.uIdValue = uIdValue;
            this.uGradeValue = uGradeValue;
            this.pwdChanged = pwdChanged;
        }

        boolean isExpired() {
            return System.currentTimeMillis() - createdAt > LOGIN_CONFIRM_TTL_MS;
        }
    }

    /**
     * (37 WP-L2) 이 사용자가 "다른 브라우저/PC 의 살아 있는 세션"으로 접속 중인지.
     * 세션 맵은 SessionListener 가 실제로는 동작하지 않아(web.xml metadata-complete=true, 리스너가 Spring 빈이 아닌
     * 인스턴스로 만들어지면 sessionManager 가 null) 만료·무효화된 세션 객체가 남아 있을 수 있으므로,
     * 맵에 있다는 사실만으로 접속 중이라고 판단하지 않고 세션 속성을 읽어 보아 살아 있는지 확인한다
     * (무효화·만료된 세션의 getAttribute 는 IllegalStateException).
     * @param userId  사용자 ID
     * @param current 지금 로그인을 요청한 브라우저의 세션(같은 세션이면 "다른 곳"이 아니다 — 같은 PC 의 다른 탭 포함)
     */
    public boolean hasActiveSession(String userId, HttpSession current) {
        HttpSession old = userSessionMap.get(userId);
        if (old == null) {
            return false;
        }
        if (current != null && old.getId().equals(current.getId())) {
            return false;
        }
        if (isAlive(old)) {
            return true;
        }
        // 죽은 세션 — 맵에서 정리(다른 로그인이 막 등록한 세션을 지우지 않도록 값까지 비교)
        userSessionMap.remove(userId, old);
        return false;
    }

    private static boolean isAlive(HttpSession s) {
        try {
            return s.getAttribute("uId") != null;
        } catch (IllegalStateException e) {
            return false;
        }
    }

    private static Object attrOrNull(HttpSession s, String name) {
        try {
            return s.getAttribute(name);
        } catch (IllegalStateException e) {
            return null;
        }
    }

    /**
     * 사용자 세션 등록
     * @param userId 사용자 ID
     * @param id 	 회원 계정 ID
     * @param session 현재 세션
     * @return 기존(살아 있는) 세션이 있었다면 true, 없었다면 false
     */
    public boolean addSession(String userId, String id, HttpSession session) {
        purgeExpired();
        HttpSession oldSession = userSessionMap.get(userId);

        // 기존 세션이 존재하면 무효화
        if (oldSession != null && !oldSession.getId().equals(session.getId())) {
            boolean wasAlive = isAlive(oldSession);
            String oldSessionId = oldSession.getId();
            if (wasAlive) {
                // (37 WP-L2) 누가·누구를·IP·시각 — 세션ID·비밀번호는 남기지 않는다.
                logger.warn("중복 로그인 감지 - 사용자: {}({}), 새 접속 IP: {}, 기존 접속 IP: {}(로그인 {}) 의 세션을 종료",
                        userId, id, attrOrNull(session, "loginIp"), attrOrNull(oldSession, "loginIp"),
                        attrOrNull(oldSession, "loginAt"));
            }
            try {
                // (패치 2026-09-05) 무효화 직전에 사유를 등록 — 이전 PC가 폴링으로 이 사유를 확인하고
                // "다른 PC에서 로그인하여 이 PC에서는 로그아웃합니다" 안내 후 로그아웃하도록 한다.
                // (37 WP-L1) 살아 있던 세션에만 등록(이미 죽은 세션이면 소비할 사람이 없다). 값은 사유 코드.
                if (wasAlive) {
                    logoutReasonBySessionId.put(oldSessionId, new TimedValue(REASON_DUPLICATE));
                }
                oldSession.invalidate();
            } catch (IllegalStateException e) {
                logger.debug("이미 무효화된 세션 - 사용자: " + userId + " (" + id + ") ", e);
            }
            userSessionMap.put(userId, session);
            return wasAlive; // 살아 있는 기존 세션이 있었음
        }

        // 새로운 세션 등록
        userSessionMap.put(userId, session);
        logger.info("새 세션 등록 - 사용자: " + userId + "(" + id + "), 세션ID: {}", session.getId());
        return false; // 기존 세션이 없었음
    }

    /**
     * (패치 2026-09-05) 이 세션ID가 다른 PC 로그인으로 무효화된 것인지 확인하고, 사유를
     * 1회 소비(조회 즉시 제거)한다. 폴링마다 같은 사유가 반복 응답되지 않도록 하기 위함이다.
     * @param sessionId 브라우저가 보낸 세션ID(request.getRequestedSessionId()) — 세션이 이미
     *                  무효화된 뒤에도 요청 쿠키값 자체는 읽을 수 있다.
     * @return (37 WP-L1) 사유 코드(REASON_*), 해당 없으면 null
     */
    public String consumeLogoutReason(String sessionId) {
        if (sessionId == null) {
            return null;
        }
        TimedValue v = logoutReasonBySessionId.remove(sessionId);
        if (v == null || System.currentTimeMillis() - v.createdAt > REASON_TTL_MS) {
            return null;
        }
        return v.value;
    }

    /** 소비되지 않고 오래된 사유 항목·만료된 확인 토큰을 정리한다(별도 스케줄러 없이 로그인 때마다 가볍게). */
    private void purgeExpired() {
        long now = System.currentTimeMillis();
        for (Iterator<Map.Entry<String, TimedValue>> it = logoutReasonBySessionId.entrySet().iterator(); it.hasNext();) {
            if (now - it.next().getValue().createdAt > REASON_TTL_MS) {
                it.remove();
            }
        }
        loginConfirmMap.entrySet().removeIf(e -> e.getValue().isExpired());
    }

    /**
     * (37 WP-L2) 새 로그인 확인용 1회용 토큰 발급. 비밀번호 검증이 성공한 직후에만 호출한다.
     * @return 토큰(URL-safe Base64, 256bit 난수)
     */
    public String issueLoginConfirm(String userId, String loginId, String requesterSessionId, String requesterIp,
            Object uIdValue, Object uGradeValue, boolean pwdChanged) {
        purgeExpired();
        byte[] raw = new byte[32];
        secureRandom.nextBytes(raw);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(raw);
        loginConfirmMap.put(token, new LoginConfirm(userId, loginId, requesterSessionId, requesterIp,
                uIdValue, uGradeValue, pwdChanged));
        return token;
    }

    /**
     * (37 WP-L2) 토큰 조회(소비하지 않음) — 확인 대기 중 상태 확인용.
     * 다른 브라우저 세션이 보낸 토큰·만료 토큰은 null.
     */
    public LoginConfirm peekLoginConfirm(String token, String requesterSessionId) {
        if (token == null || requesterSessionId == null) {
            return null;
        }
        LoginConfirm c = loginConfirmMap.get(token);
        if (c == null || !requesterSessionId.equals(c.requesterSessionId)) {
            return null;
        }
        if (c.isExpired()) {
            loginConfirmMap.remove(token, c);
            return null;
        }
        return c;
    }

    /**
     * (37 WP-L2) 토큰 1회 소비. remove(key, value) 가 원자적이므로 더블클릭 등 동시 요청 중 한 건만 성공한다.
     * @return 성공 시 인증 건 정보, 실패(없음·만료·다른 세션·이미 사용) 시 null
     */
    public LoginConfirm consumeLoginConfirm(String token, String requesterSessionId) {
        LoginConfirm c = peekLoginConfirm(token, requesterSessionId);
        if (c == null) {
            return null;
        }
        return loginConfirmMap.remove(token, c) ? c : null;
    }

    /** (37 WP-L2) 사용자가 취소했을 때 토큰 폐기. 자기 세션에 묶인 토큰만 폐기된다. */
    public void discardLoginConfirm(String token, String requesterSessionId) {
        LoginConfirm c = peekLoginConfirm(token, requesterSessionId);
        if (c != null) {
            loginConfirmMap.remove(token, c);
        }
    }

    /**
     * 사용자 세션 제거
     * @param userId 사용자 ID
     * @param uLoginId 회원 계정 ID
     */
    public void removeSession(String userId, String uLoginId) {
        HttpSession session = userSessionMap.remove(userId);
        if (session != null) {
            logger.info("세션 제거 - 사용자: " + userId + "(" + uLoginId + "), 세션ID: {}", session.getId());
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
