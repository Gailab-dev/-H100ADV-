<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

	<script>

	</script>
	

<!-- 배경 오버레이 -->
<div class="video-modal-overlay" onclick="closeRealTimeVideoPopup()"></div>

<!-- 영상 모달 본체 -->
<div class="video-modal">
  <!-- 상단 헤더 -->
  <div class="video-modal-header">
    <span class="video-modal-title">실시간 영상</span>
    <button class="video-modal-close" onclick="closeRealTimeVideoPopup()">✕</button>
  </div>

  <!-- 비디오 영역 -->
  <div class="video-container">
    <video id="video" controls autoplay playsinline>
      <source src="" type="application/x-mpegURL">
      이 브라우저에서는 실시간 영상을 재생할 수 없습니다.
	  Chrome, Edge, 또는 Safari를 사용해주세요.
    </video>
    <%-- (38번 WP-2) 탭 숨김 일시 정지 안내. deviceList.jsp 의 setVideoOverlay() 가 문구와 표시를 제어한다.
         data-hidden-grace-ms: 탭 숨김 유예(ms, 서버 설정 video.hidden-grace-ms). 이 팝업은 innerHTML 로 삽입돼 <script> 가 실행되지 않으므로 data 속성으로 전달 --%>
    <div id="videoPausedOverlay" class="video-paused-overlay" role="status" aria-live="polite" style="display:none;"
         data-hidden-grace-ms="<c:out value='${hiddenGraceMs}' default='0'/>"></div>
  </div>

  <%-- (15번 4-4) 카메라 조종 조이스틱. 기존 tiltingBtnClick 경로 재사용(신규 API 없음).
       명령: U·D·L·R(화각) / H(중앙 복귀) — 클릭 1회 = 명령 1회, 200ms Throttle 로 통신 부하 제한 --%>
  <div class="joystick-container">
    <div class="joystick-pad">
      <button type="button" class="joystick-btn up"     data-cmd="U" title="위">▲</button>
      <button type="button" class="joystick-btn left"   data-cmd="L" title="왼쪽">◀</button>
      <button type="button" class="joystick-btn center" data-cmd="H" title="중앙 복귀">●</button>
      <button type="button" class="joystick-btn right"  data-cmd="R" title="오른쪽">▶</button>
      <button type="button" class="joystick-btn down"   data-cmd="D" title="아래">▼</button>
    </div>
  </div>
</div>

<style>
	/* (38번 WP-2) 일시 정지 안내 오버레이 — 영상 위에 겹쳐 표시(클릭은 영상 컨트롤로 통과) */
	.video-container { position: relative; }
	.video-paused-overlay {
		position: absolute; top: 0; left: 0; right: 0; bottom: 0; z-index: 2;
		display: none; align-items: center; justify-content: center;
		padding: 16px; text-align: center; line-height: 1.5;
		background: rgba(0,0,0,0.65); color: #fff; font-size: 15px;
		pointer-events: none;
	}
	.joystick-container { display: flex; justify-content: center; margin-top: 14px; }
	.joystick-pad {
		width: 150px; height: 150px; padding: 10px;
		background: radial-gradient(circle, #383351 0%, #6955A2 100%);
		border-radius: 50%;
		display: grid; grid-template-columns: 1fr 1fr 1fr; grid-template-rows: 1fr 1fr 1fr;
		box-shadow: 0 4px 12px rgba(0,0,0,0.3);
	}
	.joystick-btn {
		background: rgba(255,255,255,0.15); border: none; color: #fff;
		font-size: 18px; cursor: pointer; border-radius: 6px; transition: background .15s;
	}
	.joystick-btn:hover  { background: rgba(255,255,255,0.30); }
	.joystick-btn:active { background: rgba(255,255,255,0.50); }
	.joystick-btn:disabled { opacity: .45; cursor: not-allowed; }
	.joystick-btn.up     { grid-column: 2; grid-row: 1; }
	.joystick-btn.left   { grid-column: 1; grid-row: 2; }
	.joystick-btn.center { grid-column: 2; grid-row: 2; border-radius: 50%; }
	.joystick-btn.right  { grid-column: 3; grid-row: 2; }
	.joystick-btn.down   { grid-column: 2; grid-row: 3; }
</style>

<script>
(function() {
	// 200ms Throttle — 연속 클릭 시 디바이스 통신 부하 제한(계획서 §3-3)
	var TILT_THROTTLE_MS = 200;
	var lastTiltSent = 0;

	// 팝업은 innerHTML 로 삽입되므로 document 위임으로 바인딩
	$(document).off('click.joystick').on('click.joystick', '.joystick-btn', function() {
		var now = Date.now();
		if (now - lastTiltSent < TILT_THROTTLE_MS) return;
		lastTiltSent = now;

		// 기존 함수 재사용 — 스트리밍 중인지 검사·명령 전송·오류 처리 모두 그대로
		tiltingBtnClick($(this).attr('data-cmd'));
	});
})();
</script>