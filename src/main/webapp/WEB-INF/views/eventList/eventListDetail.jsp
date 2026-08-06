<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<%-- [Tiles fragment] patches 2026-07-09(8): 독립 HTML 페이지 → Tiles body 프래그먼트로 전환.
     공통 chrome(헤더/사이드바/푸터)은 defaultLayout(template.jsp)이 제공 → 신규 메뉴(대시보드·SIP CALL) 정상 노출.
     기존 하드코딩 header/sidebar 제거. eventDetail.css 의 구(舊) chrome 재정의는 아래 인라인으로 무효화. --%>
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/eventDetail.css">
<style>
	/* eventDetail.css 의 구 하드코딩 chrome 값 무효화 → 공통 Tiles 레이아웃 유지 */
	.content { padding: 24px !important;}
	.sidebar { width: 234px !important; }
</style>
<%--  web.xml의 session time out 전역 변수, session time out 함수 --%>
<script>
   	window.SESSION_TIMEOUT_SECONDS = <%=session.getMaxInactiveInterval()%>;
   	const CONTEXT_PATH = "${pageContext.request.contextPath}";
</script>
<script src="${pageContext.request.contextPath}/resources/js/interceptor/sessionManager.js"></script>
<script src="${pageContext.request.contextPath}/resources/js/common/excelDownload.js"></script>

<input type="hidden" name="evId" value="${eventListDetail.ev_id}" />

<div class="navigation-info">
	<svg viewBox="0 0 24 24" fill="currentColor"><path d="M19 21H5C4.44772 21 4 20.5523 4 20V11L1 11L11.3273 1.6115C11.7087 1.26475 12.2913 1.26475 12.6727 1.6115L23 11L20 11V20C20 20.5523 19.5523 21 19 21ZM6 19H18V9.15745L12 3.7029L6 9.15745V19Z"/></svg>
	<svg viewBox="0 0 24 24" fill="currentColor"><path d="M13.1717 12.0007L8.22192 7.05093L9.63614 5.63672L16.0001 12.0007L9.63614 18.3646L8.22192 16.9504L13.1717 12.0007Z"/></svg>
	<span>주차 단속 대상 내역</span>
	<svg viewBox="0 0 24 24" fill="currentColor"><path d="M13.1717 12.0007L8.22192 7.05093L9.63614 5.63672L16.0001 12.0007L9.63614 18.3646L8.22192 16.9504L13.1717 12.0007Z"/></svg>
	<b>상세 보기</b>
</div>
<div class="topTitle">
	<div class="title-text">
		<h3 class="detail-title">불법주차 리스트 상세</h3>
		<button id="btnExcel" type="button" class="delete-btn"  title="엑셀 다운로드">
			<svg viewBox="0 0 24 24" fill="currentColor"><path d="M2.85858 2.87732L15.4293 1.0815C15.7027 1.04245 15.9559 1.2324 15.995 1.50577C15.9983 1.52919 16 1.55282 16 1.57648V22.4235C16 22.6996 15.7761 22.9235 15.5 22.9235C15.4763 22.9235 15.4527 22.9218 15.4293 22.9184L2.85858 21.1226C2.36593 21.0522 2 20.6303 2 20.1327V3.86727C2 3.36962 2.36593 2.9477 2.85858 2.87732ZM4 4.73457V19.2654L14 20.694V3.30599L4 4.73457ZM17 19H20V4.99997H17V2.99997H21C21.5523 2.99997 22 3.44769 22 3.99997V20C22 20.5523 21.5523 21 21 21H17V19ZM10.2 12L13 16H10.6L9 13.7143L7.39999 16H5L7.8 12L5 7.99997H7.39999L9 10.2857L10.6 7.99997H13L10.2 12Z"/></svg>
			엑셀 다운로드
		</button>
	</div>
	<!-- 돌아가기 버튼 -->
	<div class="back-btn-wrapper">
		<button type="button" onclick="goToEventList()" class="back-btn">
			<svg width="16" height="16" viewBox="0 0 16 16" fill="none"><path d="M2.86493 7.99864L8.52626 2.18064C8.57287 2.13375 8.60972 2.07809 8.63468 2.01687C8.65963 1.95564 8.6722 1.89008 8.67165 1.82397C8.6711 1.75786 8.65745 1.69252 8.63148 1.63172C8.60551 1.57092 8.56774 1.51588 8.52036 1.46977C8.47297 1.42367 8.41692 1.38742 8.35543 1.36312C8.29395 1.33882 8.22825 1.32696 8.16215 1.32822C8.09605 1.32947 8.03086 1.34383 7.97034 1.37045C7.90982 1.39707 7.85519 1.43543 7.8096 1.4833L1.8096 7.64997C1.71878 7.74331 1.66797 7.8684 1.66797 7.99864C1.66797 8.12887 1.71878 8.25396 1.8096 8.3473L7.8096 14.514C7.85519 14.5618 7.90982 14.6002 7.97034 14.6268C8.03086 14.6534 8.09605 14.6678 8.16215 14.6691C8.22825 14.6703 8.29395 14.6585 8.35543 14.6342C8.41692 14.6099 8.47297 14.5736 8.52036 14.5275C8.56774 14.4814 8.60551 14.4264 8.63148 14.3656C8.65745 14.3048 8.6711 14.2394 8.67165 14.1733C8.6722 14.1072 8.65963 14.0416 8.63468 13.9804C8.60972 13.9192 8.57287 13.8635 8.52626 13.8166L2.86493 7.99864Z" fill="black" /></svg>
			목록으로 돌아가기
		</button>
	</div>
</div>
<!-- 상세 이미지 (ADR-008: 목록에서 AJAX 사전검증 완료 후 진입 → 직접 렌더) -->
<div class="image-wrapper">
	<div class="image-container">
		<div class="img-box">
			<div class="imgeTitle">진입 시</div>
			<img src="/imgFile/${fn:replace(eventListDetail.ev_img_path, '.enc', '')}" alt="불법주차 리스트 상세 이미지" class="detail-image" onerror="this.onerror=null; this.src='${pageContext.request.contextPath}/resources/images/default-image.svg';">
<%--			<img src="${pageContext.request.contextPath}/resources/images/${fn:replace(eventListDetail.ev_img_path, '.enc', '')}" alt="불법주차 리스트 상세 이미지" class="detail-image">--%>
		</div>
	</div>
	<div class="image-container">
		<div class="img-box">
			<div class="imgeTitle">1분 후</div>
			<img src="/imgFile/${fn:replace(eventListDetail.ev_img_path2, '.enc', '')}" alt="불법주차 리스트 상세 이미지" class="detail-image" onerror="this.onerror=null; this.src='${pageContext.request.contextPath}/resources/images/default-image.svg';">
<%--			<img src="${pageContext.request.contextPath}/resources/images/${fn:replace(eventListDetail.ev_img_path2, '.enc', '')}" alt="불법주차 리스트 상세 이미지" class="detail-image" onerror="this.onerror=null; this.src='${pageContext.request.contextPath}/resources/images/default-image.svg';">--%>
		</div>
	</div>
</div>
<!-- 상세 정보 -->
<div class="detail-table-wrapper">
	<label>단속 정보</label>
	<ul class="detail-table">
		<li>
			<div class="icon-area">
				<svg viewBox="0 0 24 24" fill="currentColor"><path d="M9 1V3H15V1H17V3H21C21.5523 3 22 3.44772 22 4V20C22 20.5523 21.5523 21 21 21H3C2.44772 21 2 20.5523 2 20V4C2 3.44772 2.44772 3 3 3H7V1H9ZM20 11H4V19H20V11ZM7 5H4V9H20V5H17V7H15V5H9V7H7V5Z"/></svg>
			</div>
			<div class="value-area">
				<label>날짜</label>
				<div class="value"><c:out value="${eventListDetail.ev_date}" escapeXml="true" /></div>
			</div>
		</li>
		<li>
			<div class="icon-area">
				<svg viewBox="0 0 24 24" fill="currentColor"><path d="M18.6175 13.0317C17.7315 13.6424 16.6575 14 15.5 14C12.4624 14 10 11.5376 10 8.5C10 5.46243 12.4624 3 15.5 3C18.5376 3 21 5.46243 21 8.5C21 9.6575 20.6424 10.7315 20.0317 11.6175L22.7071 14.2929L21.2929 15.7071L18.6175 13.0317ZM3 4H8V6H3V4ZM3 11H8V13H3V11ZM3 18H21V20H3V18Z"/></svg>
			</div>
			<div class="value-area">
				<label>유형</label>
				<div class="value">
					<c:choose>
						<c:when test="${eventListDetail.ev_cd == 1}">미등록차량 🚫</c:when>

						<%-- <c:when test="${eventListDetail.ev_cd == 2}">장애인미탑승 🚫</c:when> --%>
						<%-- <c:when test="${eventListDetail.ev_cd == 3}">스티커 불법 사용 🚫</c:when> --%>

						<c:when test="${eventListDetail.ev_cd == 4}">위험상황 🚫</c:when>
						<c:when test="${eventListDetail.ev_cd == 5}">물건적재 🚫</c:when>
						<c:when test="${eventListDetail.ev_cd == 6}">이중주차 🚫</c:when>
						<c:otherwise>기타</c:otherwise>
					</c:choose>
					<button type="button" class="video-icon-btn"
						data-video="/videoFile/${fn:replace(eventListDetail.ev_mov_path, '.enc', '')}"
						aria-controls="photoModal" aria-expanded="false">
						<!-- 여기에 동영상 URL -->
						<img alt="상세영상 보기"
							src="${pageContext.request.contextPath}/resources/images/영상 버튼.png"
							width="25" height="25">
					</button>
				</div>
			</div>
		</li>
		<li>
			<div class="icon-area">
				<svg viewBox="0 0 24 24" fill="currentColor"><path d="M17 9.2L22.2133 5.55071C22.4395 5.39235 22.7513 5.44737 22.9096 5.6736C22.9684 5.75764 23 5.85774 23 5.96033V18.0397C23 18.3158 22.7761 18.5397 22.5 18.5397C22.3974 18.5397 22.2973 18.5081 22.2133 18.4493L17 14.8V19C17 19.5523 16.5523 20 16 20H2C1.44772 20 1 19.5523 1 19V5C1 4.44772 1.44772 4 2 4H16C16.5523 4 17 4.44772 17 5V9.2Z"/></svg>
			</div>
			<div class="value-area">
				<label>디바이스명</label>
				<div class="value"><c:out value="${eventListDetail.ev_dv_name}" escapeXml="true" /></div>
			</div>
		</li>
		<li>
			<div class="icon-area">
				<svg viewBox="0 0 24 24" fill="currentColor"><path d="M18.364 17.364L12 23.7279L5.63604 17.364C2.12132 13.8492 2.12132 8.15076 5.63604 4.63604C9.15076 1.12132 14.8492 1.12132 18.364 4.63604C21.8787 8.15076 21.8787 13.8492 18.364 17.364ZM12 15C14.2091 15 16 13.2091 16 11C16 8.79086 14.2091 7 12 7C9.79086 7 8 8.79086 8 11C8 13.2091 9.79086 15 12 15ZM12 13C10.8954 13 10 12.1046 10 11C10 9.89543 10.8954 9 12 9C13.1046 9 14 9.89543 14 11C14 12.1046 13.1046 13 12 13Z"/></svg>
			</div>
			<div class="value-area">
				<label>디바이스 주소</label>
				<div class="value"><c:out value="${eventListDetail.ev_dv_addr}" escapeXml="true" /></div>
			</div>
		</li>
		<li>
			<div class="icon-area">
				<svg viewBox="0 0 24 24" fill="currentColor"><path d="M19 20H5V21C5 21.5523 4.55228 22 4 22H3C2.44772 22 2 21.5523 2 21V12L4.51334 5.29775C4.80607 4.51715 5.55231 4 6.386 4H17.614C18.4477 4 19.1939 4.51715 19.4867 5.29775L22 12V21C22 21.5523 21.5523 22 21 22H20C19.4477 22 19 21.5523 19 21V20ZM4.136 12H19.864L17.614 6H6.386L4.136 12ZM6.5 17C7.32843 17 8 16.3284 8 15.5C8 14.6716 7.32843 14 6.5 14C5.67157 14 5 14.6716 5 15.5C5 16.3284 5.67157 17 6.5 17ZM17.5 17C18.3284 17 19 16.3284 19 15.5C19 14.6716 18.3284 14 17.5 14C16.6716 14 16 14.6716 16 15.5C16 16.3284 16.6716 17 17.5 17Z"/></svg>
			</div>
			<div class="value-area">
				<label>차량 번호</label>
				<div class="value"><c:out value="${eventListDetail.ev_car_num}" escapeXml="true" /></div>
			</div>
		</li>
		<li>
			<div class="icon-area">
				<svg viewBox="0 0 24 24" fill="currentColor"><path d="M15 14L14.8834 14.0067C14.4243 14.0601 14.0601 14.4243 14.0067 14.8834L14 15V21H3.99826C3.44694 21 3 20.5551 3 20.0066V3.9934C3 3.44476 3.44495 3 3.9934 3H20.0066C20.5552 3 21 3.44749 21 3.9985V14H15ZM21 16L16 20.997V16H21Z"/></svg>
			</div>
			<div class="value-area">
				<label>비고</label>
				<div class="value">-</div>
			</div>
		</li>
	</ul>
</div>

<div id="photoModal" class="lb-modal" aria-hidden="true" role="dialog">
	<div class="lb-backdrop" data-close></div>
	<div class="lb-dialog" role="document">
		<button class="lb-close" type="button" aria-label="닫기"
			onclick="closeModal()" style="z-index: 1" data-close>&times;</button>

		<!-- ✅ 동영상 -->
		<video id="lbVideo" class="lb-video" controls playsinline></video>
	</div>
</div>

<script>
  <c:if test="${not empty myInfoErrorMsg}">
    alert('<c:out value="${myInfoErrorMsg}" />');
  </c:if>
</script>


<script>
  window.addEventListener('pageshow', function (e) {
    if (e.persisted) location.reload(); // BFCache에서 복원되면 강제 새로고침
  });
</script>

<script>

// 불법 주차 리스트 화면으로 이동
  function goToEventList(){
    location.href = CONTEXT_PATH + "/eventList/viewEventList.do?page=${page}&startDate=${startDate}&endDate=${endDate}&searchKeyword=${searchKeyword}";
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
    // closeModal 을 인라인 onclick(button)에서도 쓰므로 전역 노출
    window.closeModal = closeModal;

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


  // 엑셀 다운로드
  document.addEventListener('DOMContentLoaded', function () {
    document.getElementById('btnExcel').addEventListener('click', function () {
      const evId = '${eventListDetail.ev_id}';

      ExcelDownloader.downloadFineAdvanceNotice(evId)
        .catch(e => alert(e.message));
    });
  });


</script>
