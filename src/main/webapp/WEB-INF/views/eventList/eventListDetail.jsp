<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>eventDetail</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/eventDetail.css">
<%--  web.xml의 session time out 전역 변수, session time out 함수 --%>
<script>
   	window.SESSION_TIMEOUT_SECONDS = <%= session.getMaxInactiveInterval() %>;
   	const CONTEXT_PATH = "${pageContext.request.contextPath}";
</script>
<script src="${pageContext.request.contextPath}/resources/js/interceptor/sessionManager.js"></script>
<%--  web.xml의 session time out 전역 변수, session time out 함수 --%>

</head>
<body>
	<!-- 헤더 -->
	<header class="header">
	  <div class="logo">
	    <img src="${pageContext.request.contextPath}/resources/images/지아이랩-로고.png"
	         alt="GAILAB" class="header-icon">
	  </div>
	
	  <div class="right-group">
  	  	<c:if test="${useTblLog == false}">
			<div class="alert alert-warning">
		    	현재 로그 데이터 저장 공간이 매우 부족합니다. 관리자에게 문의해주세요.
		    </div>
		</c:if>
	    <div class="user">
	      <img src="${pageContext.request.contextPath}/resources/images/user.png"
	           alt="유저" class="user-image">
	      <span class="user-name">hskim</span>
	    </div>
	    <div class="logout">
	      <button onclick="location.href='${pageContext.request.contextPath}/user/logout'">로그아웃</button>
	    </div>
	  </div>
	</header>
	
    <div class="container">
		<aside class="sidebar">
              <ul class="menu">
                <li><a href="${pageContext.request.contextPath}/stats/viewStat.do"><img src="${pageContext.request.contextPath}/resources/images/icon_home.png" alt="홈" class="menu-icon">홈</a></li>
                <li><a href="${pageContext.request.contextPath}/deviceList/viewDeviceList.do"><img src="${pageContext.request.contextPath}/resources/images/icon_device.png" alt="디바이스" class="menu-icon">디바이스 리스트</a></li>
                <li><a href="${pageContext.request.contextPath}/eventList/viewEventList.do"><img src="${pageContext.request.contextPath}/resources/images/icon_parking.png" alt="불법주차" class="menu-icon">불법주차 리스트</a></li>
            </ul>
        </aside>
        <div class="content">
			<h3 class="detail-title">불법주차 리스트 상세</h3>
			
			<!-- 상세 이미지 -->
			<div class="image-wrapper">
				<img src="/imgFile/${fn:replace(eventListDetail.ev_img_path, '.enc', '')}" alt="불법주차 리스트 상세 이미지" class="detail-image">
			</div>
			<!-- 상세 정보 -->
			<div class="detail-table-wrapper">
				<table class="detail-table">
					<tr>
						<th>날짜</th>
						<td>
							<c:out value="${eventListDetail.ev_date}" escapeXml ="true"/>
						</td>
					</tr>
					<tr>
						<th>위치</th>
						<!-- 
						<td>${eventListDetail.dv_addr}</td>
						 -->
						 <td>
						 	<c:out value="${dvAddr}" escapeXml ="true"/>
						 </td>
					</tr>
					<tr>
						<th>차량번호</th>
						<td>							
							<c:out value="${eventListDetail.ev_car_num}" escapeXml ="true"/>
						</td>
					</tr>
					<tr>
						<th>유형</th>
						<td>
							<c:choose>
								<c:when test="${eventListDetail.ev_cd == 1}">미등록차량 🚫</c:when>
								<%-- 								
								<c:when test="${eventListDetail.ev_cd == 2}">장애인미탑승 🚫</c:when>
								<c:when test="${eventListDetail.ev_cd == 3}">스티커 불법 사용 🚫</c:when>
								 --%>
								<c:when test="${eventListDetail.ev_cd == 4}">위험상황 🚫</c:when>
								<c:when test="${eventListDetail.ev_cd == 5}">물건적재 🚫</c:when>
								<c:when test="${eventListDetail.ev_cd == 6}">이중주차 🚫</c:when>
								<c:otherwise>기타</c:otherwise>
							</c:choose>
							<button type="button"
							        class="video-icon-btn"
							        data-video="/videoFile/${fn:replace(eventListDetail.ev_mov_path, '.enc', '')}"  
							        aria-controls="photoModal" aria-expanded="false"><!-- 여기에 동영상 URL -->
								 <img alt="상세영상 보기"
								      src="${pageContext.request.contextPath}/resources/images/영상 버튼.png"
								      width="25" height="25">
							</button>
						</td>
					</tr>
				</table> 
			</div>
		
			<!-- 돌아가기 버튼 -->
			<div class="back-btn-wrapper">
				<button type="button" onclick="goToEventList()" class="back-btn"> 돌아가기</button>
			</div>   
        </div>    
    </div>    
   
	<div id="photoModal" class="lb-modal" aria-hidden="true" role="dialog">
		 <div class="lb-backdrop" data-close></div>
		 <div class="lb-dialog" role="document">
			<button class="lb-close" type="button" aria-label="닫기" onclick="closeModal()" style="z-index:1" data-close >&times;</button>

			<!-- ✅ 동영상 -->
			<video id="lbVideo" class="lb-video" controls playsinline></video>
		 </div>
	</div>
	
	<%-- 개인정보 수정 버튼 클릭시 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
	<script>
	  <c:if test="${not empty myInfoErrorMsg}">
	    alert('<c:out value="${myInfoErrorMsg}" />');
	  </c:if>
	</script>
	<%-- 개인정보 수정 버튼 클릭시 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
	<%--  뒤로가기 등 BFCache 복원시 강제 새로고침(뒤로가기 시 로그인 페이지로 이동) --%>
	<script>
	  window.addEventListener('pageshow', function (e) {
	    if (e.persisted) location.reload(); // BFCache에서 복원되면 강제 새로고침
	  });
	</script>
	<%--  뒤로가기 등 BFCache 복원시 강제 새로고침(뒤로가기 시 로그인 페이지로 이동) --%>
	<script>
	  
	// 불법 주차 리스트 화면으로 이동
	  function goToEventList(){
	    location.href ="viewEventList.do?&page=${page}&startDate=${startDate}&endDate=${endDate}&searchKeyword=${searchKeyword}";
	  }
	
	  document.addEventListener('DOMContentLoaded', function() {
	    const modal     = document.getElementById('photoModal');
	    const videoEl   = document.getElementById('lbVideo');
	    let hls = null;     
	    let timeoutId = null;
	
	    function cleanupVideo() {
	      if (timeoutId) { clearTimeout(timeoutId); timeoutId = null; }
	      if (hls) { try { hls.destroy(); } catch(e){} hls = null; }
	      try {
	        videoEl.pause();
	        videoEl.removeAttribute('src');
	        videoEl.load();
	      } catch(e){}
	    }
	
	    function loadVideo(src) {
	      cleanupVideo(); 
	      // 8초 타임아웃
	      timeoutId = setTimeout(function(){
	        alert('응답이 느려요. 잠시 후 다시 시도해 주세요.');
	      }, 8000);
	
	      const isHls = /\.m3u8(\?.*)?$/i.test(src);
	
	      const onError = (msg) => {
	        alert(msg || '동영상을 불러오지 못했어요.');
	        videoEl.style.display = 'none';
	        if (timeoutId) { clearTimeout(timeoutId); timeoutId = null; }
	      };
	
	      const onCanPlay = () => {
	        if (timeoutId) { clearTimeout(timeoutId); timeoutId = null; }
	        videoEl.style.display = 'block';
	        videoEl.play().catch(() => {/* 자동재생 실패 무시 */});
	      };
	
	      videoEl.oncanplay = onCanPlay;
	      videoEl.onerror   = () => onError('동영상을 불러오지 못했어요.');
	
	      if (isHls) {
	        if (videoEl.canPlayType('application/vnd.apple.mpegurl')) {
	          videoEl.src = src;
	          videoEl.load();
	          return;
	        }
	        if (window.Hls && window.Hls.isSupported()) {
	          hls = new Hls();
	          hls.on(Hls.Events.ERROR, function(event, data){
	            if (data?.fatal) onError('스트림 오류가 발생했어요.');
	          });
	          hls.loadSource(src);
	          hls.attachMedia(videoEl);
	          return;
	        }
	        onError('이 브라우저는 HLS를 바로 재생할 수 없어요. 사파리를 쓰거나 MP4 URL을 사용해 주세요.');
	        return;
	      }
	
	      // MP4/기타
	      videoEl.src = src;
	      videoEl.load();
	    }
	
	    function openModal(src) {
	      loadVideo(src);
	      modal.classList.add('is-open');
	      document.body.classList.add('lb-open');
	    }
	
	    function closeModal() {
	      modal.classList.remove('is-open');
	      document.body.classList.remove('lb-open');
	      cleanupVideo();
	    }
	
	    // 아이콘 클릭 → 열기
	    document.addEventListener('click', function(e) {
	      const btn = e.target.closest('.video-icon-btn[data-video]');
	      if (btn) {
	        const src = btn.getAttribute('data-video');
	        if (src) openModal(src);
	      }
	      if (e.target.matches('[data-close]')) closeModal();
	    });
	
	    // ESC로 닫기
	    document.addEventListener('keydown', function(e){
	      if (e.key === 'Escape' && modal.classList.contains('is-open')) closeModal();
	    });
	    
	    // 마우스 클릭시 닫기
      	document.addEventListener('click', function(e) {
    		// 닫기(버튼/배경 모두)
    		const closer = e.target.closest('[data-close]');
    		if (closer) {
      			e.preventDefault();
      			closeModal();
      			return;
    		}
	  	});
	    
	  });
	  
	</script>
	
</body>
</html>