/**
 * 세션 만료시 자동 로그아웃
 */

(function () {

    // === 세션 타임 아웃 값 가져오기 ===
   const SESSION_TIMEOUT_SECONDS = window.SESSION_TIMEOUT_SECONDS;
    if (!SESSION_TIMEOUT_SECONDS) return; // 로그인 안된 페이지는 실행 안함

    const loginUrl = CONTEXT_PATH + "/user/login.do?errorMsg=장기간 미사용으로 로그아웃되었습니다."; // 세션 만료 후 이동할 URL
	
    // === 내부 계산 ===
    const sessionTimeoutMs = SESSION_TIMEOUT_SECONDS * 1000;
    let logoutTimerId  = null;


    // === 세션 만료 리다이렉트 ===
    function redirectToLogin() {
        window.location.href = loginUrl;
    }
    
      // === 타이머 모두 정리 ===
	  function clearTimers() {
	    if (logoutTimerId !== null) {
	      clearTimeout(logoutTimerId);
	      logoutTimerId = null;
	    }
	  }
    
    // === 타이머 다시 시작 ===
  	function startTimers() {
    	clearTimers();
    	
    	logoutTimerId = setTimeout(redirectToLogin,sessionTimeoutMs);
	}
	
	  // === 사용자 활동 발생 시 타이머 리셋 ===
	  function onUserActivity() {
	    // 여기에서 서버로 요청을 던지는 게 아니기 때문에
	    // 실제 서버 세션 연장은 “요청이 있는 경우”에만 일어남
	    // 이 코드는 클라이언트 쪽 UX용 타이머 리셋 역할
	    startTimers();
	  }
	
	  // 감지할 이벤트들
	  const activityEvents = ['click', 'keydown', 'scroll', 'mousemove', 'touchstart'];
	
	  activityEvents.forEach(function (evtName) {
	    window.addEventListener(evtName, onUserActivity, { passive: true });
	  });
	
    // === 타이머 작동 ===
     startTimers();

    // === (패치 2026-09-05) 다른 PC 로그인으로 인한 세션 무효화 감지 ===
    // 이 화면과 동일한 PC/브라우저에서 계속 열려 있는 페이지가, 다른 PC의 로그인으로 이 세션이
    // 무효화된 사실을 사용자가 다음에 뭔가 클릭할 때까지 모르게 두지 않도록 주기적으로 확인한다.
    // 장기 미사용 로그아웃(위 타이머)과 달리 "언제 발생할지 알 수 없는 이벤트"라 폴링 방식을 쓴다 —
    // 이 프로젝트의 다른 자동 갱신(알림 배지 등)도 모두 폴링이라 같은 패턴을 재사용한다.
    const DUPLICATE_LOGIN_POLL_MS = 5000;

    function redirectWithReason(message) {
        window.location.href = CONTEXT_PATH + "/user/login.do?errorMsg=" + encodeURIComponent(message);
    }

    function checkDuplicateLoginLogout() {
        fetch(CONTEXT_PATH + "/user/sessionStatus", { cache: "no-store" })
            .then(function (r) { return r.json(); })
            .then(function (d) {
                if (d && d.loggedOutElsewhere) {
                    clearInterval(duplicateLoginPollId);
                    clearTimers();
                    redirectWithReason(d.message || "다른 PC에서 로그인하여 이 PC에서는 로그아웃합니다.");
                }
            })
            .catch(function () { /* 일시적 네트워크 오류는 무시 — 다음 폴링에서 재시도 */ });
    }

    const duplicateLoginPollId = setInterval(checkDuplicateLoginLogout, DUPLICATE_LOGIN_POLL_MS);

})();