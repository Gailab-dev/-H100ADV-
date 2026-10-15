<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<%-- [Tiles fragment] patches 2026-07-09(8): 독립 HTML 페이지 → Tiles body 프래그먼트로 전환.
     공통 chrome(헤더/사이드바/푸터)은 defaultLayout(template.jsp)이 제공 → 신규 메뉴(대시보드·SIP CALL) 정상 노출.
     기존 하드코딩 header/sidebar 제거. 상세 화면과 반응형 스타일은 eventDetail.css에서 관리한다. --%>
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/eventDetail.css">
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
<jsp:include page="vehicleWorkspace.jsp" />

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
    location.href = CONTEXT_PATH + "/eventList/viewEventList.do?page=${page}&startDate=${startDate}&endDate=${endDate}&searchKeyword=${searchKeyword}"
        + "&evCd=${evCd}&evAction=${evAction}&sortCol=${sortCol}&sortDir=${sortDir}";
  }

  // (패치 2026-09-30) 이전/다음 탐색·삭제 후 자동 이동 — 목록과 동일한 검색조건·정렬기준을
  // 그대로 실어 보내야 같은 필터/정렬 결과 안에서 인접 이벤트를 찾을 수 있다.
  function _h100FilterQuery(){
    return "&searchKeyword=" + encodeURIComponent("${searchKeyword != null ? searchKeyword : ''}")
         + "&startDate=" + encodeURIComponent("${startDate != null ? startDate : ''}")
         + "&endDate=" + encodeURIComponent("${endDate != null ? endDate : ''}")
         + "&evCd=" + encodeURIComponent("${evCd != null ? evCd : ''}")
         + "&evAction=" + encodeURIComponent("${evAction != null ? evAction : ''}")
         + "&sortCol=" + encodeURIComponent("${sortCol != null ? sortCol : 'ev_date'}")
         + "&sortDir=" + encodeURIComponent("${sortDir != null ? sortDir : 'DESC'}");
  }

  function _h100GoToAdjacent(step){
    var currentEvId = ${eventListDetail.ev_id};
    var qs = "currentEvId=" + currentEvId + "&step=" + step + _h100FilterQuery();
    fetch(CONTEXT_PATH + "/eventList/adjacentEvent?" + qs, { headers: { 'X-Requested-With': 'XMLHttpRequest' } })
      .then(function(r){ return r.json(); })
      .then(function(d){
        if (d && d.evId) {
          location.href = CONTEXT_PATH + "/eventList/eventListDetail?evId=" + d.evId + "&dvId=${dvId}" + _h100FilterQuery();
        } else {
          alert(step > 0 ? '마지막 항목입니다.' : '첫 번째 항목입니다.');
        }
      })
      .catch(function(){ alert('이동 중 오류가 발생했습니다.'); });
  }

  document.getElementById('btnPrevEvent').addEventListener('click', function(){ _h100GoToAdjacent(-1); });
  document.getElementById('btnNextEvent').addEventListener('click', function(){ _h100GoToAdjacent(1); });

  // (패치 2026-09-30) 삭제(소프트 삭제) — 확인창 → 삭제 전(현재 행이 아직 살아있어 순번 계산이
  // 가능할 때) 다음 항목을 먼저 조회 → 삭제 실행 → 다음 항목 있으면 이동, 없으면 목록으로 복귀.
  document.getElementById('btnDeleteEvent').addEventListener('click', function(){
    if (!confirm('이 항목을 삭제하시겠습니까?\n삭제된 항목은 목록·상세보기에서 사라집니다.')) return;

    var currentEvId = ${eventListDetail.ev_id};
    var qs = "currentEvId=" + currentEvId + "&step=1" + _h100FilterQuery();

    fetch(CONTEXT_PATH + "/eventList/adjacentEvent?" + qs, { headers: { 'X-Requested-With': 'XMLHttpRequest' } })
      .then(function(r){ return r.json(); })
      .then(function(adj){
        var nextEvId = adj && adj.evId;
        return fetch(CONTEXT_PATH + "/eventList/deleteEvents", {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
          body: JSON.stringify({ evIds: [currentEvId] })
        })
        .then(function(r){ return r.json(); })
        .then(function(d){
          if (!d || !d.success) {
            alert('삭제에 실패했습니다. 잠시 후 다시 시도해주세요.');
            return;
          }
          if (nextEvId) {
            location.href = CONTEXT_PATH + "/eventList/eventListDetail?evId=" + nextEvId + "&dvId=${dvId}" + _h100FilterQuery();
          } else {
            goToEventList(); // 마지막 항목이었던 경우 목록으로 복귀
          }
        });
      })
      .catch(function(){ alert('삭제 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.'); });
  });

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
