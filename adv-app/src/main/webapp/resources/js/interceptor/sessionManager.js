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

})();