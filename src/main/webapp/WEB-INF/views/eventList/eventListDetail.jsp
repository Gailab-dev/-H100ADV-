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
	.container { height: auto !important; }
	.content { padding: 24px !important; overflow-y: visible !important; }
	.sidebar { width: 234px !important; }
</style>
<%--  web.xml의 session time out 전역 변수, session time out 함수 --%>
<script>
   	window.SESSION_TIMEOUT_SECONDS = <%=session.getMaxInactiveInterval()%>;
   	const CONTEXT_PATH = "${pageContext.request.contextPath}";
</script>
<script
	src="${pageContext.request.contextPath}/resources/js/interceptor/sessionManager.js"></script>
<script src="${pageContext.request.contextPath}/resources/js/common/excelDownload.js"></script>

<input type="hidden" name="evId" value="${eventListDetail.ev_id}" />

<div class="topTitle">
	<h3 class="detail-title">불법주차 리스트 상세</h3>
	<button id="btnExcel" type="button" class="delete-btn"
		title="엑셀 다운로드">
		<img
			src="${pageContext.request.contextPath}/resources/images/icon_excel.svg"
			alt="엑셀 다운로드">
	</button>
</div>
<!-- 상세 이미지 (ADR-008: 목록에서 AJAX 사전검증 완료 후 진입 → 직접 렌더) -->
<div class="image-wrapper">
	<div class="image-container">
		<div class="imgeTitle">진입 시</div>
		<img src="/imgFile/${fn:replace(eventListDetail.ev_img_path, '.enc', '')}" alt="불법주차 리스트 상세 이미지" class="detail-image">
	</div>
	<div class="image-container">
		<div class="imgeTitle">1분 후</div>
		<img src="/imgFile/${fn:replace(eventListDetail.ev_img_path2, '.enc', '')}" alt="불법주차 리스트 상세 이미지" class="detail-image">
	</div>
</div>
<!-- 상세 정보 -->
<div class="detail-table-wrapper">
	<table class="detail-table">
		<tr>
			<th>날짜</th>
			<td><c:out value="${eventListDetail.ev_date}"
					escapeXml="true" /></td>
		</tr>
		<tr>
			<th>유형</th>
			<td><c:choose>
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
				</button></td>
		</tr>
		<tr>
			<th>디바이스명</th>
			<td><c:out value="${eventListDetail.ev_dv_name}" escapeXml="true" /></td>
		</tr>
		<tr>
			<th>디바이스 주소</th>
			<td><c:out value="${eventListDetail.ev_dv_addr}" escapeXml="true" /></td>
		</tr>
		<tr>
			<th>차량번호</th>
			<td><c:out value="${eventListDetail.ev_car_num}"
					escapeXml="true" /></td>
		</tr>

	</table>
</div>

<!-- 돌아가기 버튼 -->
<div class="back-btn-wrapper">
	<button type="button" onclick="goToEventList()" class="back-btn">
		<svg width="16" height="16" viewBox="0 0 16 16" fill="none"
			xmlns="http://www.w3.org/2000/svg">
<path
				d="M2.86493 7.99864L8.52626 2.18064C8.57287 2.13375 8.60972 2.07809 8.63468 2.01687C8.65963 1.95564 8.6722 1.89008 8.67165 1.82397C8.6711 1.75786 8.65745 1.69252 8.63148 1.63172C8.60551 1.57092 8.56774 1.51588 8.52036 1.46977C8.47297 1.42367 8.41692 1.38742 8.35543 1.36312C8.29395 1.33882 8.22825 1.32696 8.16215 1.32822C8.09605 1.32947 8.03086 1.34383 7.97034 1.37045C7.90982 1.39707 7.85519 1.43543 7.8096 1.4833L1.8096 7.64997C1.71878 7.74331 1.66797 7.8684 1.66797 7.99864C1.66797 8.12887 1.71878 8.25396 1.8096 8.3473L7.8096 14.514C7.85519 14.5618 7.90982 14.6002 7.97034 14.6268C8.03086 14.6534 8.09605 14.6678 8.16215 14.6691C8.22825 14.6703 8.29395 14.6585 8.35543 14.6342C8.41692 14.6099 8.47297 14.5736 8.52036 14.5275C8.56774 14.4814 8.60551 14.4264 8.63148 14.3656C8.65745 14.3048 8.6711 14.2394 8.67165 14.1733C8.6722 14.1072 8.65963 14.0416 8.63468 13.9804C8.60972 13.9192 8.57287 13.8635 8.52626 13.8166L2.86493 7.99864Z"
				fill="black" />
</svg>

			돌아가기
	</button>
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
