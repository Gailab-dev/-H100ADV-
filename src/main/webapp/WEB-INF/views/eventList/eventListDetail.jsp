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
                <li><a
						href="${pageContext.request.contextPath}/eventList/viewEventList.do">
							<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20"
								fill="none" xmlns="http://www.w3.org/2000/svg">
						<path fill-rule="evenodd" clip-rule="evenodd"
									d="M2.70837 5.83203C2.70837 5.66627 2.77422 5.5073 2.89143 5.39009C3.00864 5.27288 3.16761 5.20703 3.33337 5.20703H16.6667C16.8325 5.20703 16.9914 5.27288 17.1086 5.39009C17.2259 5.5073 17.2917 5.66627 17.2917 5.83203C17.2917 5.99779 17.2259 6.15676 17.1086 6.27397C16.9914 6.39118 16.8325 6.45703 16.6667 6.45703H3.33337C3.16761 6.45703 3.00864 6.39118 2.89143 6.27397C2.77422 6.15676 2.70837 5.99779 2.70837 5.83203ZM2.70837 9.9987C2.70837 9.83294 2.77422 9.67397 2.89143 9.55676C3.00864 9.43955 3.16761 9.3737 3.33337 9.3737H12.5C12.6658 9.3737 12.8248 9.43955 12.942 9.55676C13.0592 9.67397 13.125 9.83294 13.125 9.9987C13.125 10.1645 13.0592 10.3234 12.942 10.4406C12.8248 10.5578 12.6658 10.6237 12.5 10.6237H3.33337C3.16761 10.6237 3.00864 10.5578 2.89143 10.4406C2.77422 10.3234 2.70837 10.1645 2.70837 9.9987ZM2.70837 14.1654C2.70837 13.9996 2.77422 13.8406 2.89143 13.7234C3.00864 13.6062 3.16761 13.5404 3.33337 13.5404H7.50004C7.6658 13.5404 7.82477 13.6062 7.94198 13.7234C8.05919 13.8406 8.12504 13.9996 8.12504 14.1654C8.12504 14.3311 8.05919 14.4901 7.94198 14.6073C7.82477 14.7245 7.6658 14.7904 7.50004 14.7904H3.33337C3.16761 14.7904 3.00864 14.7245 2.89143 14.6073C2.77422 14.4901 2.70837 14.3311 2.70837 14.1654Z"
									fill="currentColor" />
						</svg>불법주차 리스트
					</a></li>
					<li><a
						href="${pageContext.request.contextPath}/stats/viewStat.do"> <svg
								class="menu-icon" width="20" height="20" viewBox="0 0 20 20"
								fill="none" xmlns="http://www.w3.org/2000/svg">
							<g clip-path="url(#clip0_300_3167)">
								<path d="M18.3333 18.3359H1.66663" stroke="currentColor"
									stroke-width="1.4" stroke-linecap="round" />
								<path
									d="M17.5 18.3346V12.0846C17.5 11.7531 17.3683 11.4352 17.1339 11.2008C16.8995 10.9663 16.5815 10.8346 16.25 10.8346H13.75C13.4185 10.8346 13.1005 10.9663 12.8661 11.2008C12.6317 11.4352 12.5 11.7531 12.5 12.0846V18.3346V4.16797C12.5 2.98964 12.5 2.40047 12.1333 2.03464C11.7683 1.66797 11.1792 1.66797 10 1.66797C8.82083 1.66797 8.2325 1.66797 7.86667 2.03464C7.5 2.39964 7.5 2.9888 7.5 4.16797V18.3346V7.91797C7.5 7.58645 7.3683 7.26851 7.13388 7.03408C6.89946 6.79966 6.58152 6.66797 6.25 6.66797H3.75C3.41848 6.66797 3.10054 6.79966 2.86612 7.03408C2.6317 7.26851 2.5 7.58645 2.5 7.91797V18.3346"
									stroke="currentColor" stroke-width="1.4" />
							</g>
							<defs>
							<clipPath id="clip0_300_3167">
							<rect width="20" height="20" fill="white" />	</clipPath></defs>
						</svg>통계
					</a></li>

					<li><a
						href="${pageContext.request.contextPath}/deviceList/viewDeviceList.do">
							<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20"
								fill="none" xmlns="http://www.w3.org/2000/svg">
							<path
									d="M7.50004 15H12.5M15 2.5C15.4421 2.5 15.866 2.67559 16.1786 2.98816C16.4911 3.30072 16.6667 3.72464 16.6667 4.16667V15.8333C16.6667 16.2754 16.4911 16.6993 16.1786 17.0118C15.866 17.3244 15.4421 17.5 15 17.5H5.00004C4.55801 17.5 4.13409 17.3244 3.82153 17.0118C3.50897 16.6993 3.33337 16.2754 3.33337 15.8333V4.16667C3.33337 3.72464 3.50897 3.30072 3.82153 2.98816C4.13409 2.67559 4.55801 2.5 5.00004 2.5H15Z"
									stroke="currentColor" stroke-width="1.4" stroke-linecap="round"
									stroke-linejoin="round" />
						</svg>디바이스 리스트
					</a></li>
					<li><a
						href="${pageContext.request.contextPath}/deviceList/viewDeviceList.do">
							<svg class="menu-icon" width="20" height="20" viewBox="0 0 30 30" fill="none" xmlns="http://www.w3.org/2000/svg">
							<circle cx="15" cy="15" r="14.5" fill="white" stroke="currentColor"/>
							<path d="M23 24V22C23 20.9391 22.5786 19.9217 21.8284 19.1716C21.0783 18.4214 20.0609 18 19 18H11C9.93913 18 8.92172 18.4214 8.17157 19.1716C7.42143 19.9217 7 20.9391 7 22V24M19 10C19 12.2091 17.2091 14 15 14C12.7909 14 11 12.2091 11 10C11 7.79086 12.7909 6 15 6C17.2091 6 19 7.79086 19 10Z" 
							stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
							</svg>내 정보
					</a></li>

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