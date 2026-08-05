<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>

<%-- [Tiles fragment] 공용 chrome(헤더/사이드바/푸터)은 defaultLayout 제공. 이하 이 페이지 전용 CSS/JS/콘텐츠 --%>
<meta charset="UTF-8">
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/eventList.css">
<%-- patches 2026-07-07: 열너비 균형 (외부 CSS 캐시 무관 인라인 !important).
     8열: 체크박스4 / 번호6 / 날짜12 / 유형12 / 디바이스명15 / 디바이스주소25 / 차량번호14 / 상세12 (합100%) --%>
<style>
	.event-table { table-layout: fixed !important; width: 100% !important; }
	.event-table th:nth-child(1), .event-table td:nth-child(1) { width: 4%  !important; }
	.event-table th:nth-child(2), .event-table td:nth-child(2) { width: 6%  !important; }
	.event-table th:nth-child(3), .event-table td:nth-child(3) { width: 12% !important; }
	.event-table th:nth-child(4), .event-table td:nth-child(4) { width: 12% !important; }
	.event-table th:nth-child(5), .event-table td:nth-child(5) { width: 15% !important; }
	.event-table th:nth-child(6), .event-table td:nth-child(6) { width: 25% !important; }
	.event-table th:nth-child(7), .event-table td:nth-child(7) { width: 14% !important; }
	.event-table th:nth-child(8), .event-table td:nth-child(8) { width: 12% !important; }
	/* patches 2026-07-09(3): 10건 조회 시 오른쪽 스크롤 없이 한 화면에 꽉 차도록 세로 여백 미세 축소 */
	.content { padding: 16px 24px 12px 24px !important; }        /* 상/하 32·29 → 16·12 */
	.filter-form { margin-bottom: 12px !important; }             /* 20 → 12 */
	.event-table th, .event-table td { padding: 9px 12px !important; }  /* 12 → 9 (행당 -6px) */
	.pagination { margin-top: 12px !important; }                 /* 20 → 12 */
</style>
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/pagination.css">
<title>주차 단속 대상 내역</title>

<%-- 상세 보기 버튼 클릭시 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
<%-- ADR-008(2026-06-17): errorMsg alert 블록 제거. 상세 실패는 AJAX 사전검증 후 목록 오버레이 메시지로 처리(페이지 이동·alert 없음). --%>
<%-- 상세 보기 버튼 클릭시 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
<%-- 개인정보 수정 버튼 클릭시 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
<script>
  <c:if test="${not empty myInfoErrorMsg}">
    alert('<c:out value="${myInfoErrorMsg}" />');
    
    // ✅ URL에서 errorMsg 제거, 새로고침 등으로 오류 메시지 재출력 방지
    const url = new URL(window.location.href);
    url.searchParams.delete('myInfoErrorMsg');
    history.replaceState(null, '', url.toString());
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
<%--  web.xml의 session time out 전역 변수, session time out 함수 --%>
<script>
   	window.SESSION_TIMEOUT_SECONDS = <%=session.getMaxInactiveInterval()%>;
   	const CONTEXT_PATH = "${pageContext.request.contextPath}";
</script>
<script src="${pageContext.request.contextPath}/resources/js/interceptor/sessionManager.js"></script>
<script src="${pageContext.request.contextPath}/resources/js/common/excelDownload.js"></script>

<%--  web.xml의 session time out 전역 변수, session time out 함수 --%>
<script>
	// 검색 input에서 100자 이상 입력시 알림 출력
	document.addEventListener('DOMContentLoaded', function () {
	  const MAX_LEN = 100;
	
	  // 1) 폼 찾기
	  const searchForm = document.getElementById('eventListSearchForm');
	  if (!searchForm) {
	    // 이 페이지에는 검색 폼이 없으면 그냥 조용히 종료
	    return;
	  }
	
	  // 2) input 요소 찾기 (name="searchKeyword" 기준)
	  const searchElement = searchForm.elements['searchKeyword'];
	  if (!searchElement) {
	    // 요소 없으면 종료
	    return;
	  }
	
	  // 3) 길이 제한 + 경고 로직
	  let warnedOnce = false; // 계속 알람 뜨는 것 방지용
	
	  searchElement.addEventListener('input', function () {
	    const val = this.value || '';
	
	    if (val.length > MAX_LEN) {
	      // 초과 입력 잘라내기
	      this.value = val.slice(0, MAX_LEN);
	      alert("검색어는 100자를 넘을 수 없습니다. \n 모든 문자 입력 가능합니다.");
	    } 
	  });

	});

	loadEventCounts(); //ev_cd 건별 총합 추가
	// ev_cd별 이벤트 총합
	function loadEventCounts() {
		$.ajax({
			url: CONTEXT_PATH + "/eventList/eventCounts",
			method: "GET",
			dataType: "json",

			success: function(data) {
				console.log("이벤트 건수 조회:", data);

				for (var i = 1; i <= 6; i++) {
					$('#eventCount' + i).text(data[i] || 0);
				}
			},

			error: function(xhr, status, error) {
				console.error("이벤트 건수 조회 실패:", status, error);
				console.error("응답:", xhr.responseText);

				for (var i = 1; i <= 6; i++) {
					$('#eventCount' + i).text(0);
				}
			}
		});
	}

	// pagination 객체를 활용한 페이지 이동
	window.goPage = function(pageNo){
		let startDate = encodeURIComponent('${startDate != null ? startDate : ""}');
    	let endDate   = encodeURIComponent('${endDate != null ? endDate : ""}');
    	let searchKeyword   = encodeURIComponent('${searchKeyword != null ? searchKeyword : ""}');
		let pageSize = encodeURIComponent('${pageSize != null ? pageSize : ""}');
		let evCd = encodeURIComponent('${evCd != null ? evCd : ""}');
    	location.href = "viewEventList.do?page=" + pageNo + "&startDate=" + startDate + "&endDate=" + endDate + "&searchKeyword=" + searchKeyword +"&pageSize="+pageSize+"&evCd="+evCd;
	}
		
	// 상세보기 클릭시 불법주차 상세 화면으로 이동
	window.eventListDetail = function(dvId, evId, dvAddr){
		let startDate = encodeURIComponent('${startDate != null ? startDate : ""}');
	    let endDate   = encodeURIComponent('${endDate != null ? endDate : ""}');
	    let searchKeyword   = encodeURIComponent('${searchKeyword != null ? searchKeyword : ""}');
	    let pageSize = encodeURIComponent('${pageSize != null ? pageSize : ""}');
	    
	    
	    // 결과가 '가능'일 때 이동할 상세 URL (파라미터는 목록이 보유)
	    const detailUrl = 'eventListDetail?dvId='+dvId+'&evId='+ evId + "&page=${page}&startDate=" + startDate + "&endDate=" + endDate + "&searchKeyword=" + searchKeyword +"&dvAddr="+dvAddr+"&pageSize="+pageSize;

	    // (ADR-008) 즉시 로딩 오버레이 → 비동기 사전검증 → 가능 시 동기 이동, 아니면 "파일 없음" 표시
	    const _h100Started = Date.now();
	    const _h100MinShow = 300; // 깜박임 방지(최소 표시 시간 ms)
	    showLoadingOverlay('처리 중...');
	    const _h100Ctrl = new AbortController();
	    const _h100To = setTimeout(function(){ _h100Ctrl.abort(); }, 10000); // 10초 상한
	    fetch(CONTEXT_PATH + '/eventList/detail/check?evId=' + encodeURIComponent(evId) + '&dvId=' + encodeURIComponent(dvId==null?'':dvId),
	          { headers: { 'X-Requested-With': 'XMLHttpRequest' }, signal: _h100Ctrl.signal })
	      .then(function(r){ return r.json(); })
	      .then(function(d){
	        clearTimeout(_h100To);
	        if (d && d.available) { location.href = detailUrl; return; } // 동기 페이지 이동
	        const wait = Math.max(0, _h100MinShow - (Date.now() - _h100Started));
	        setTimeout(function(){ hideLoadingOverlay(); showMessageOverlay((d && d.message) || '파일이 존재하지 않습니다'); }, wait);
	      })
	      .catch(function(){ clearTimeout(_h100To); hideLoadingOverlay(); showMessageOverlay('파일이 존재하지 않습니다'); });
	}

	// 상세보기 버튼 — 이벤트 위임(인라인 onclick 대신). data 속성에서 값 안전 추출 → SyntaxError 방지
	document.addEventListener('click', function(e){
	    var btn = e.target.closest('.detailButton');
	    if (!btn) return;
	    var dvId   = btn.getAttribute('data-dv-id');
	    var evId   = btn.getAttribute('data-ev-id');
	    var dvAddr = btn.getAttribute('data-dv-addr') || '';
	    eventListDetail((dvId === '' ? null : dvId), evId, dvAddr);
	});

	// (15번 4-2) 이벤트 알림 클릭 이동 수신 처리.
	//   헤더 알림에서 ?evId=X 로 진입하면 해당 행을 강조·스크롤한다.
	//   ※ 목록은 서버 페이지네이션이라 대상이 현재 페이지에 없을 수 있음 → 없으면 안내만.
	document.addEventListener('DOMContentLoaded', function(){
	    var evId = new URLSearchParams(window.location.search).get('evId');
	    if(!evId) return;

	    var btn = document.querySelector('.detailButton[data-ev-id="'
	        + (window.CSS && CSS.escape ? CSS.escape(evId) : evId) + '"]');
	    if(!btn){
	        console.warn('evId 에 해당하는 이벤트가 현재 페이지 목록에 없습니다:', evId);
	        return;
	    }
	    var row = btn.closest('tr');
	    if(!row) return;
	    row.style.transition = 'background .4s';
	    row.style.background = '#fff6d6';   // 잠시 강조 후 원복
	    row.scrollIntoView({ behavior: 'smooth', block: 'center' });
	    setTimeout(function(){ row.style.background = ''; }, 2600);
	});
	
	// ===== ADR-008 로딩/메시지 오버레이 헬퍼 (목록 페이지 위) =====
	function showLoadingOverlay(msg){
	  const ov = document.getElementById('h100Overlay');
	  const sp = document.getElementById('h100OverlaySpinner');
	  const mt = document.getElementById('h100OverlayMsg');
	  const cl = document.getElementById('h100OverlayClose');
	  if(!ov) return;
	  clearTimeout(window.__h100OvTimer);
	  if(sp) sp.style.display = 'block';
	  if(cl) cl.style.display = 'none';
	  if(mt) mt.textContent = msg || '처리 중...';
	  ov.style.display = 'flex';
	}
	function hideLoadingOverlay(){
	  const ov = document.getElementById('h100Overlay');
	  if(ov) ov.style.display = 'none';
	}
	function showMessageOverlay(msg){
	  const ov = document.getElementById('h100Overlay');
	  const sp = document.getElementById('h100OverlaySpinner');
	  const mt = document.getElementById('h100OverlayMsg');
	  const cl = document.getElementById('h100OverlayClose');
	  if(!ov) return;
	  if(sp) sp.style.display = 'none';
	  if(mt) mt.textContent = msg || '파일이 존재하지 않습니다';
	  if(cl) cl.style.display = 'inline-block';
	  ov.style.display = 'flex';
	  clearTimeout(window.__h100OvTimer);
	  window.__h100OvTimer = setTimeout(hideLoadingOverlay, 3000); // 3초 후 자동 사라짐
	}

	// 검색 조건에 따른 검색
	window.searchEventList = function(pageNo){
		
		let form = document.getElementById('eventListSearchForm');
	  	const startDate = form.elements['startDate']?.value; // 'yyyy-MM-dd'
	  	const endDate   = form.elements['endDate']?.value;
	  	const evCd = form.elements['evCd']?.value;
	  	const evAction = form.elements['evAction']?.value;   // patches 13: 처리상태 필터
	  	const searchKeyword   = form.elements['searchKeyword']?.value;
	 	const pageSize = document.getElementById('pageSize')?.value;
	  	
	  	if( searchKeyword.length >= 100 ){
	  		alert("검색어는 100자를 넘을 수 없습니다. \n 모든 문자 입력 가능합니다.");
	  		return;
	  	}
		
		if( startDate > endDate ){
			alert("날짜를 확인해주세요.");
			return;
		}
		
		if(evCd !== ""){
			if( evCd != null && (evCd >=7 || evCd <= 0)){
				alert("유효하지 않은 유형입니다.");
				return;
			}
		}
		

		
	  	// 검색 파라미터 변경으로 인한 페이지 번호 1로 변경
	  	pageNo = Math.max(1, Number.isFinite(+pageNo) ? Math.trunc(+pageNo) : 0);
		
		location.href = "viewEventList.do?page=" + pageNo + "&startDate=" + startDate + "&endDate=" + endDate + "&evCd=" + evCd + "&evAction=" + evAction + "&searchKeyword=" + searchKeyword +"&pageSize="+pageSize;

	}
	
	//  Pagination 
	document.addEventListener('DOMContentLoaded', function () {
		  const $wrap = document.querySelector('.pagination');
		  if (!$wrap) return;

		  const links = Array.from($wrap.querySelectorAll('a'));
		  const current = $wrap.querySelector('strong'); // 현재 페이지(예: <strong>3</strong>)
		  const curPage = current ? parseInt(current.textContent.trim(), 10) : NaN;

		  // 유틸: goPage(숫자)에서 숫자만 뽑기
		  const getPageFromHref = (a) => {
		    const m = a.getAttribute('href')?.match(/goPage\((\d+)\)/);
		    return m ? parseInt(m[1], 10) : null;
		  };

		  // 이동 버튼 텍스트 치환 및 클래스 세팅
		  links.forEach(a => {
		    const txt = a.textContent.replace(/\s+/g,'').trim();
		    const page = getPageFromHref(a);

		    if (/\[처음\]/.test(txt)) {
		      a.textContent = '«';
		      a.classList.add('pg-first');
		      if (curPage && curPage <= 1) a.classList.add('is-disabled');
		    } else if (/\[이전\]/.test(txt)) {
		      a.textContent = '‹';
		      a.classList.add('pg-prev');
		      if (curPage && curPage <= 1) a.classList.add('is-disabled');
		    } else if (/\[다음\]/.test(txt)) {
		      a.textContent = '›';
		      a.classList.add('pg-next');
		      // 다음이 마지막을 넘어가면 비활성
		      if (curPage && page && page <= curPage) a.classList.add('is-disabled');
		    } else if (/\[마지막\]/.test(txt)) {
		      a.textContent = '»';
		      a.classList.add('pg-last');
		      // 마지막 페이지 계산이 어려우니 “goPage(n)” 값이 현재와 같거나 작으면 비활성
		      if (curPage && page && page <= curPage) a.classList.add('is-disabled');
		    } else {
		      // 숫자 링크는 그대로 두되 불필요한 공백 제거
		      if (/^\d+$/.test(txt)) a.textContent = txt;
		    }
		  });
	  });
	
	  // 각 컬럼별 정렬 버튼 클릭시 데이터 정렬
	  document.addEventListener('DOMContentLoaded', function () {  
			
		  	// 화살표 버튼 이미지 파일 경로
		  	const BASE = '${pageContext.request.contextPath}';
		  	const ICON_UP = BASE + '/resources/images/icon_arrow_up.svg';
		  	const ICON_DOWN = BASE + '/resources/images/icon_arrow_down.svg';
		  
		    // 현재 정렬 상태 (url값 사용)
		    const url = new URL(window.location.href);
		    let currentSortCol = url.searchParams.get('sortCol') || 'ev_id';
		    let currentSortDir = (url.searchParams.get('sortDir') || 'DESC').toUpperCase();

			
		    //각 정렬 버튼 별 이벤트 추가
		    document.querySelectorAll('.sort-btn').forEach(btn => {
		        
		    	// 정렬 대상이 되는 컬럼
		    	const col = btn.dataset.column;
		    	
		    	// 오름차순, 내림차순 표시하는 화살표 이미지
		        const img = btn.querySelector('img');
		        if (!img) return;

		        // 🔹 현재 정렬 컬럼 표시
		        if (col === currentSortCol) {
		            
		        	// active로 정렬 활성화
		        	btn.classList.add('active');
		            
		        	// 이미지 아이콘 변경
		        	img.src = (currentSortDir === 'ASC') ? ICON_UP : ICON_DOWN;
		            if (currentSortDir === 'ASC') {
		                btn.classList.add('asc');
		            }
		        }

		        btn.addEventListener('click', function () {
		            

		            // 다음 이벤트 발생시 정렬 조건을 변수에 저장
		            let nextDir = 'DESC';
		            if (currentSortCol === col) {
		                nextDir = (currentSortDir === 'DESC') ? 'ASC' : 'DESC';
		            }

		            // 🔹 기존 파라미터 유지
		            const url = new URL(window.location.href);
					
		            // 정렬 컬럼, 다음 이벤트시 정렬 조건을 검색 파라미터 추가
		            url.searchParams.set('sortCol', col);
		            url.searchParams.set('sortDir', nextDir);

		            // 정렬 변경 시 페이지는 1페이지로
		            url.searchParams.set('page', 1);
					
		            // 정렬
		            window.location.href = url.toString();
		        });
		    });
		});
	  
		// ---------------------------- 체크박스 관련 자바스크립트 -------------------------------  		
	    window.onload = function() {
      	const checkAll = document.getElementById("checkAll"); // 테이블 헤더 체크박스
      	const rowChecks = document.querySelectorAll(".row-check"); // 각 행 체크박스
      	const selectedText = document.querySelector(".selected-text");

	        // ✅ 선택 개수 갱신 함수
	        function updateSelectedCount() {
	            const checked = document.querySelectorAll(".row-check:checked").length;
	            selectedText.textContent = `\${checked}개 선택됨`;
	            checkAll.checked = (checked === rowChecks.length); // 전체선택 상태 반영
	        }

	        // ✅ 개별 체크박스 클릭 시 갱신
	        rowChecks.forEach(chk => chk.addEventListener("change", updateSelectedCount));

	        // ✅ 전체선택 (표 헤더 체크박스 클릭 시)
	        checkAll.addEventListener("change", function() {
	            rowChecks.forEach(chk => chk.checked = checkAll.checked);
	            updateSelectedCount();
	        });

	        // 초기 표시
	        updateSelectedCount();
  	};
		// ---------------------------- 체크박스 관련 자바스크립트 -------------------------------
		// --------------------------- 엑셀 다운로드 -----------------------------
		
		/**
		 @opt
			endpoint: url 경로(contextPath는 고정)
		    formSelector: form Id
		    mapping : form 하위의 input 태그의 name 속성값 또는 #id 값을 json 형식으로 입력
		    예)
		    responseType: 함수 실행 결과를 받을 데이터 타입(기본값:blob)
			downloadFilename: 엑셀 파일명
		*/
		document.addEventListener('DOMContentLoaded', function () {
			document.getElementById('btnExcel').addEventListener('click',function(){
				ExcelDownloader.excelDownload({
					endpoint:'/eventList/excelDownload',
					formSelector:'#eventListSearchForm',
					mapping: {
						startDate:'startDate',
						endDate:'endDate',
						evCd:'evCd',
						searchKeyword:'searchKeyword'
					},
					responseType:'blob',
					downloadFilename:'불법주차_리스트.xlsx'
				}).catch(function(e){alert(e.message);});
			})

			// 날짜 표기 방식 변경
			document.querySelectorAll(".ev-date").forEach(function(el){
				let text = el.textContent.trim();

				// 소수점 제거
				text = text.replace(/\.\d+$/, "");
				// 앞의 '20' 제거 (2026 → 26)
				text = text.substring(2);

				el.textContent = text;
				el.title = text;
			});
		});
  		/*
		async function excelDownload(){
			
			let form = document.getElementById('eventListSearchForm');
		  	let val1 = form.elements['searchKeyword']?.value;
		  	let searchKeyword = encodeURIComponent(val1);
		  	let val2 = form.elements['startDate']?.value;
		  	let startDate = encodeURIComponent(val2);
		  	let val3 = form.elements['endDate']?.value;
		  	let endDate = encodeURIComponent(val3);
		  	let pageSize = document.getElementById('pageSize')?.value;
			
			const body = {
					'startDate': startDate,
					'endDate': endDate,
					'searchKeyword':searchKeyword
				};
				
				try{
			    	const response = await fetch('${pageContext.request.contextPath}/eventList/excelDownload', {
			      		method: 'POST'
			      		, headers: { 'Content-Type': 'application/json' }
			      		, body: JSON.stringify(body)
			      		, credentials : 'same-origin'
			      		, cache:'no-store'
			    		});
			    	
			    	// fetch는 항상 response 객체로 리턴
			    	if (!response.ok) return;
					
			    	// response에서 json값 가져오기
			    	let data = await response.json();
			    	await sleep(2000);
			    	
			    	return;
				}catch(e){
					return;
				}

		}
  		*/
		// --------------------------- 엑셀 다운로드 -----------------------------
</script>

	<ul class="checkdown-state">
		<li>
			<div class="ico-checkdown unregistered">
				<svg viewBox="0 0 24 24" fill="currentColor">
					<path d="M22.207 20.793L20.793 22.207L19.5859 21H16V17.4141L15 16.4141V21H9V10.4141L1.79297 3.20703L3.20703 1.79297L22.207 20.793ZM8 21H2V13H8V21ZM4 19H6V15H4V19ZM11 19H13V14.4141L11 12.4141V19ZM22 17.7578L20 15.7578V5H18V13.7578L16 11.7578V3H22V17.7578ZM15 10.7578L12.2422 8H15V10.7578Z"/>
				</svg>
			</div>
			<div class="checkdown-text">
				<div class="label">미등록차량</div>
				<div class="value"><span id="eventCount1">0</span>건</div>
			</div>
		</li>
		<%--			<li>--%>
		<%--				<div class="ico-checkdown noDisability">--%>
		<%--					<svg viewBox="0 0 19.04 20.79">--%>
		<%--						<g>--%>
		<%--							<path d="M9.52,15.14h1.14l-4.14-4.6v1.6c0,1.66,1.34,3,3,3Z"/>--%>
		<%--							<path d="M12.52,10.72v-2.59c0-1.66-1.34-3-3-3-.59,0-1.14.18-1.6.47l4.6,5.11Z"/>--%>
		<%--							<path d="M9.52,5.14c1.38,0,2.5-1.12,2.5-2.5S10.9.14,9.52.14s-2.5,1.12-2.5,2.5,1.12,2.5,2.5,2.5Z"/>--%>
		<%--							<path d="M11.56,16.14h-.58c-.69,1.2-1.98,2-3.46,2-2.21,0-4-1.79-4-4,0-1.48.8-2.77,2-3.46v-1.25s-.61-.67-.61-.67c-2,.97-3.39,3.01-3.39,5.39,0,3.31,2.69,6,6,6,2.15,0,4.02-1.14,5.08-2.84l-1.04-1.16Z"/>--%>
		<%--						</g>--%>
		<%--						<rect x="8.35" y="-2.53" width="2.35" height="25.86"--%>
		<%--							  transform="translate(-4.51 9.04) rotate(-41.98)"/>--%>
		<%--					</svg>--%>
		<%--				</div>--%>
		<%--				<div class="checkdown-text">--%>
		<%--					<div class="label">장애인미탑승</div>--%>
		<%--					<div class="value"><span id="eventCount2">0</span>건</div>--%>
		<%--				</div>--%>
		<%--			</li>--%>
		<%--			<li>--%>
		<%--				<div class="ico-checkdown illegalStickers">--%>
		<%--					<svg viewBox="0 0 24 24" fill="currentColor">--%>
		<%--						<path d="M21.9024 10.5976C21.4442 10.5333 20.976 10.5 20.5 10.5C17.2404 10.5 14.3455 12.0604 12.5212 14.471C12.3501 14.4887 12.1763 14.4978 12 14.4978C10.7188 14.4978 9.55217 14.0172 8.66691 13.2248L7.33309 14.7151C8.41871 15.6868 9.81141 16.3253 11.3466 16.4676C10.8023 17.7016 10.5 19.0662 10.5 20.5C10.5 20.976 10.5333 21.4442 10.5976 21.9024C5.7387 21.2205 2 17.0469 2 12C2 6.47715 6.47715 2 12 2C17.0469 2 21.2205 5.7387 21.9024 10.5976ZM21.8707 12.617C21.4254 12.5401 20.9674 12.5 20.5 12.5C17.7656 12.5 15.3512 13.8709 13.9068 15.9675C13.0194 17.2556 12.5 18.8156 12.5 20.5C12.5 20.9674 12.5401 21.4254 12.617 21.8707L21.8707 12.617ZM8.5 11.5C9.32843 11.5 10 10.8284 10 10C10 9.17157 9.32843 8.5 8.5 8.5C7.67157 8.5 7 9.17157 7 10C7 10.8284 7.67157 11.5 8.5 11.5ZM15.5 11.5C16.3284 11.5 17 10.8284 17 10C17 9.17157 16.3284 8.5 15.5 8.5C14.6716 8.5 14 9.17157 14 10C14 10.8284 14.6716 11.5 15.5 11.5Z"/>--%>
		<%--					</svg>--%>
		<%--				</div>--%>
		<%--				<div class="checkdown-text">--%>
		<%--					<div class="label">스티커 불법 사용</div>--%>
		<%--					<div class="value"><span id="eventCount3">0</span>건</div>--%>
		<%--				</div>--%>
		<%--			</li>--%>
		<li>
			<div class="ico-checkdown warning">
				<svg viewBox="0 0 24 24" fill="currentColor">
					<path d="M4.00001 20V14C4.00001 9.58172 7.58173 6 12 6C16.4183 6 20 9.58172 20 14V20H21V22H3.00001V20H4.00001ZM6.00001 14H8.00001C8.00001 11.7909 9.79087 10 12 10V8C8.6863 8 6.00001 10.6863 6.00001 14ZM11 2H13V5H11V2ZM19.7782 4.80761L21.1924 6.22183L19.0711 8.34315L17.6569 6.92893L19.7782 4.80761ZM2.80762 6.22183L4.22183 4.80761L6.34315 6.92893L4.92894 8.34315L2.80762 6.22183Z"/>
				</svg>
			</div>
			<div class="checkdown-text">
				<div class="label">위험상황</div>
				<div class="value"><span id="eventCount4">0</span>건</div>
			</div>
		</li>
		<li>
			<div class="ico-checkdown carrying">
				<svg viewBox="0 0 24 24" fill="currentColor">
					<path d="M12 1L21.5 6.5V17.5L12 23L2.5 17.5V6.5L12 1ZM6.49896 9.97089L11 12.5768V17.6252H13V12.5768L17.501 9.9709L16.499 8.24005L12 10.8447L7.50104 8.24004L6.49896 9.97089Z"/>
				</svg>
			</div>
			<div class="checkdown-text">
				<div class="label">물건적재</div>
				<div class="value"><span id="eventCount5">0</span>건</div>
			</div>
		</li>
		<li>
			<div class="ico-checkdown doubleParking">
				<svg viewBox="0 0 24 24" viewBox="0 0 24 24" fill="currentColor">
					<path d="M19 21H5V22C5 22.5523 4.55228 23 4 23H3C2.44772 23 2 22.5523 2 22V13L4.4174 8.97099C4.77884 8.36858 5.42986 7.99998 6.13238 7.99998H17.8676C18.5701 7.99998 19.2212 8.36858 19.5826 8.97099L22 13V22C22 22.5523 21.5523 23 21 23H20C19.4477 23 19 22.5523 19 22V21ZM4.33238 13H19.6676L17.8676 9.99998H6.13238L4.33238 13ZM6.5 18C7.32843 18 8 17.3284 8 16.5C8 15.6716 7.32843 15 6.5 15C5.67157 15 5 15.6716 5 16.5C5 17.3284 5.67157 18 6.5 18ZM17.5 18C18.3284 18 19 17.3284 19 16.5C19 15.6716 18.3284 15 17.5 15C16.6716 15 16 15.6716 16 16.5C16 17.3284 16.6716 18 17.5 18ZM5.43934 3.43932L6.5 2.37866L7.56066 3.43932C7.83211 3.71077 8 4.08577 8 4.49998C8 5.32841 7.32843 5.99998 6.5 5.99998C5.67157 5.99998 5 5.32841 5 4.49998C5 4.08577 5.16789 3.71077 5.43934 3.43932ZM10.9393 3.43932L12 2.37866L13.0607 3.43932C13.3321 3.71077 13.5 4.08577 13.5 4.49998C13.5 5.32841 12.8284 5.99998 12 5.99998C11.1716 5.99998 10.5 5.32841 10.5 4.49998C10.5 4.08577 10.6679 3.71077 10.9393 3.43932ZM16.4393 3.43932L17.5 2.37866L18.5607 3.43932C18.8321 3.71077 19 4.08577 19 4.49998C19 5.32841 18.3284 5.99998 17.5 5.99998C16.6716 5.99998 16 5.32841 16 4.49998C16 4.08577 16.1679 3.71077 16.4393 3.43932Z"/>
				</svg>
			</div>
			<div class="checkdown-text">
				<div class="label">이중주차</div>
				<div class="value"><span id="eventCount6">0</span>건</div>
			</div>
		</li>
	</ul>

	<div class=page-wrapper>
		<!-- 헤더 -->
		
		
			
			
				<div class="device-top">
					<div class="top-row">
						<form id="eventListSearchForm" class="filter-form">
							<div class="filter-input-group">
								<input type="date" name="startDate" value="${startDate}" />
							</div>
							<p class="date-contect">~</p>
							<div class="filter-input-group">
								<input type="date" name="endDate" value="${endDate}" />
							</div>
							<div class="filter-input-group">
								<select name="evCd" class="selectOption">
									<option value="" ${evCd == null ? 'selected' : '' }>유형</option>
									<option value="1" ${evCd == 1 ? 'selected' : ''}>미등록차량</option>
									<option value="4" ${evCd == 4 ? 'selected' : ''}>위험상황</option>
									<option value="5" ${evCd == 5 ? 'selected' : ''}>물건적재</option>
									<option value="6" ${evCd == 6 ? 'selected' : ''}>이중주차</option>
								</select>
							</div>
							<%-- patches 13: 처리상태(evAction) 필터. 대시보드 계도/단속 카드 링크와 동일 파라미터 --%>
							<div class="filter-input-group">
								<select name="evAction" class="selectOption">
									<option value="" ${evAction == null ? 'selected' : ''}>처리 상태</option>
									<option value="0" ${evAction == 0 ? 'selected' : ''}>계도</option>
									<option value="1" ${evAction == 1 ? 'selected' : ''}>단속</option>
									<option value="2" ${evAction == 2 ? 'selected' : ''}>과태료 부과</option>
								</select>
							</div>
							<div class="search-box">
								<svg width="20" height="20" viewBox="0 0 20 20" fill="none"
									xmlns="http://www.w3.org/2000/svg">
                        			<path
										d="M8.75065 14.1673C11.7422 14.1673 14.1673 11.7422 14.1673 8.75065C14.1673 5.75911 11.7422 3.33398 8.75065 3.33398C5.75911 3.33398 3.33398 5.75911 3.33398 8.75065C3.33398 11.7422 5.75911 14.1673 8.75065 14.1673Z"
										stroke="#767676" stroke-width="1.5" stroke-miterlimit="10" />
                        			<path
										d="M16.1363 17.197C16.4292 17.4899 16.9041 17.4899 17.197 17.197C17.4899 16.9041 17.4899 16.4292 17.197 16.1363L16.6667 16.6667L16.1363 17.197ZM12.5 12.5L11.9697 13.0303L16.1363 17.197L16.6667 16.6667L17.197 16.1363L13.0303 11.9697L12.5 12.5Z"
										fill="#767676" />
                    			</svg>
								<input type="text" name="searchKeyword" value="${searchKeyword}"
									placeholder="디바이스명 및 주소 검색" maxlength="100" />
							</div>
							<button type="button" class="search-btn"
								onclick="searchEventList('${paginationInfo.currentPageNo != null ? paginationInfo.currentPageNo : 1}')">조회</button>
						</form>

						<div class="filter-input-group">
							<select id="pageSize" name="pageSize"
								onchange="searchEventList()" class="select-box">
								<option value="10" ${pageSize == 10 ? 'selected' : ''}>10개씩
									보기</option>
								<option value="20" ${pageSize == 20 ? 'selected' : ''}>20개씩
									보기</option>
								<option value="30" ${pageSize == 30 ? 'selected' : ''}>30개씩
									보기</option>
							</select>
						</div>
					</div>

					<div class="bulk-actions">
						<svg width="16" height="16" viewBox="0 0 16 16" fill="none"
							xmlns="http://www.w3.org/2000/svg">
                <rect width="16" height="16" rx="4" fill="#6955A2" />
                <path d="M4 9V7H12V9H4Z" fill="white" />
            </svg>

						<span class="selected-text">0개 선택됨</span>

						<button type="button" class="delete-btn"
							onclick="viewDeleteDevicePopup()" title="삭제">
							<svg width="20" height="20" viewBox="0 0 20 20" fill="none"
								xmlns="http://www.w3.org/2000/svg">
                    <path
									d="M11.75 9.11111V14.4444M8.25 9.11111V14.4444M4.75 5.55556V16.2222C4.75 16.6937 4.93437 17.1459 5.26256 17.4793C5.59075 17.8127 6.03587 18 6.5 18H13.5C13.9641 18 14.4092 17.8127 14.7374 17.4793C15.0656 17.1459 15.25 16.6937 15.25 16.2222V5.55556M3 5.55556H17M5.625 5.55556L7.375 2H12.625L14.375 5.55556"
									stroke="black" stroke-width="1.4" stroke-linecap="round"
									stroke-linejoin="round" />
                </svg>
						</button>
						<button id="btnExcel" type="button" class="delete-btn" onclick="excelDownload()"
							title="엑셀 다운로드">
							<img
								src="${pageContext.request.contextPath}/resources/images/icon_excel.svg"
								alt="엑셀 다운로드">
						</button>
					</div>
				</div>

				<c:choose>
					<c:when test="${empty eventList}">
						<div class="empty-state">
							<img
								src="${pageContext.request.contextPath}/resources/images/result-icon.svg"
								class="result-icon">
							<p class="result-text">검색 결과가 없습니다.</p>
						</div>
					</c:when>

					<c:otherwise>
						<table class="event-table">
							<thead>
								<tr>
									<th><input type="checkbox" id="checkAll"
										class="table-checkBox" /></th>
									<th>번호</th>
									<th>날짜
										<button class="sort-btn" data-column="ev_date">
											<img
												src="${pageContext.request.contextPath}/resources/images/icon_arrow_up.svg">
										</button>
									</th>
									<th>유형
										<button class="sort-btn" data-column="ev_cd">
											<img
												src="${pageContext.request.contextPath}/resources/images/icon_arrow_up.svg">
										</button>
									</th>
									<th>디바이스명
										<button class="sort-btn" data-column="dv_name">
											<img
												src="${pageContext.request.contextPath}/resources/images/icon_arrow_up.svg">
										</button>
									</th>
									<th>디바이스주소
										<button class="sort-btn" data-column="dv_addr">
											<img
												src="${pageContext.request.contextPath}/resources/images/icon_arrow_up.svg">
										</button>
									</th>
									<th>차량번호
										<button class="sort-btn" data-column="ev_car_num">
											<img
												src="${pageContext.request.contextPath}/resources/images/icon_arrow_up.svg">
										</button>
									</th>
									<th>상세</th>
								</tr>
							</thead>
							<tbody>
								<c:forEach var="item" items="${eventList}">
									<tr>
										<td><input type="checkbox" class="row-check" /></td>
										<td><c:out value="${totalRecordCount - item.rn + 1}"
												escapeXml="true" /></td>
										<td><span class="cell-ellipsis ev-date"
											title="${fn:escapeXml(item.ev_reg_date)}"> <c:out
													value="${item.ev_reg_date}" />
										</span></td>
										<td class="td-category"><c:choose>
												<c:when test="${item.ev_cd eq 1}">
													<div class="ico-checkdown unregistered">
														<svg viewBox="0 0 24 24" fill="currentColor">
															<path d="M22.207 20.793L20.793 22.207L19.5859 21H16V17.4141L15 16.4141V21H9V10.4141L1.79297 3.20703L3.20703 1.79297L22.207 20.793ZM8 21H2V13H8V21ZM4 19H6V15H4V19ZM11 19H13V14.4141L11 12.4141V19ZM22 17.7578L20 15.7578V5H18V13.7578L16 11.7578V3H22V17.7578ZM15 10.7578L12.2422 8H15V10.7578Z"/>
														</svg>
													</div>
													미등록차량
												</c:when>
												<c:when test="${item.ev_cd eq 4}">
													<div class="ico-checkdown warning">
														<svg viewBox="0 0 24 24" fill="currentColor">
															<path d="M4.00001 20V14C4.00001 9.58172 7.58173 6 12 6C16.4183 6 20 9.58172 20 14V20H21V22H3.00001V20H4.00001ZM6.00001 14H8.00001C8.00001 11.7909 9.79087 10 12 10V8C8.6863 8 6.00001 10.6863 6.00001 14ZM11 2H13V5H11V2ZM19.7782 4.80761L21.1924 6.22183L19.0711 8.34315L17.6569 6.92893L19.7782 4.80761ZM2.80762 6.22183L4.22183 4.80761L6.34315 6.92893L4.92894 8.34315L2.80762 6.22183Z"/>
														</svg>
													</div>
													위험상황
												</c:when>
												<c:when test="${item.ev_cd eq 5}">
													<div class="ico-checkdown carrying">
														<svg viewBox="0 0 24 24" fill="currentColor">
															<path d="M12 1L21.5 6.5V17.5L12 23L2.5 17.5V6.5L12 1ZM6.49896 9.97089L11 12.5768V17.6252H13V12.5768L17.501 9.9709L16.499 8.24005L12 10.8447L7.50104 8.24004L6.49896 9.97089Z"/>
														</svg>
													</div>
													물건적재
												</c:when>
												<c:when test="${item.ev_cd eq 6}">
													<div class="ico-checkdown doubleParking">
														<svg viewBox="0 0 24 24" viewBox="0 0 24 24" fill="currentColor">
															<path d="M19 21H5V22C5 22.5523 4.55228 23 4 23H3C2.44772 23 2 22.5523 2 22V13L4.4174 8.97099C4.77884 8.36858 5.42986 7.99998 6.13238 7.99998H17.8676C18.5701 7.99998 19.2212 8.36858 19.5826 8.97099L22 13V22C22 22.5523 21.5523 23 21 23H20C19.4477 23 19 22.5523 19 22V21ZM4.33238 13H19.6676L17.8676 9.99998H6.13238L4.33238 13ZM6.5 18C7.32843 18 8 17.3284 8 16.5C8 15.6716 7.32843 15 6.5 15C5.67157 15 5 15.6716 5 16.5C5 17.3284 5.67157 18 6.5 18ZM17.5 18C18.3284 18 19 17.3284 19 16.5C19 15.6716 18.3284 15 17.5 15C16.6716 15 16 15.6716 16 16.5C16 17.3284 16.6716 18 17.5 18ZM5.43934 3.43932L6.5 2.37866L7.56066 3.43932C7.83211 3.71077 8 4.08577 8 4.49998C8 5.32841 7.32843 5.99998 6.5 5.99998C5.67157 5.99998 5 5.32841 5 4.49998C5 4.08577 5.16789 3.71077 5.43934 3.43932ZM10.9393 3.43932L12 2.37866L13.0607 3.43932C13.3321 3.71077 13.5 4.08577 13.5 4.49998C13.5 5.32841 12.8284 5.99998 12 5.99998C11.1716 5.99998 10.5 5.32841 10.5 4.49998C10.5 4.08577 10.6679 3.71077 10.9393 3.43932ZM16.4393 3.43932L17.5 2.37866L18.5607 3.43932C18.8321 3.71077 19 4.08577 19 4.49998C19 5.32841 18.3284 5.99998 17.5 5.99998C16.6716 5.99998 16 5.32841 16 4.49998C16 4.08577 16.1679 3.71077 16.4393 3.43932Z"/>
														</svg>
													</div>
													이중주차
												</c:when>
												<c:otherwise>기타</c:otherwise>
											</c:choose></td>
										<td><span class="cell-ellipsis"
											title="${fn:escapeXml(item.ev_dv_name)}"> <c:out
													value="${item.ev_dv_name}" escapeXml="true" />
										</span></td>
										<td><span class="cell-ellipsis"
											title="${fn:escapeXml(item.ev_dv_addr)}"> <c:out
													value="${item.ev_dv_addr}" escapeXml="true" />
										</span></td>
										<td><span class="cell-ellipsis"
											title="${fn:escapeXml(item.ev_car_num)}"> <c:out
													value="${item.ev_car_num}" escapeXml="true" />
										</span></td>
										<%-- patches 2026-07-09(8): 인라인 onclick 에 EL 직접 삽입 시 dv_id 가 null 이면
										     eventListDetail(,82,'..') 형태로 JS SyntaxError, 주소에 따옴표 있으면 문자열 깨짐.
										     → 대시보드와 동일하게 data 속성 + 이벤트 위임(아래 JS)으로 안전 처리. --%>
										<td><button type="button" class="detailButton"
												data-dv-id="${item.dv_id}"
												data-ev-id="${item.ev_id}"
												data-dv-addr="${fn:escapeXml(item.dv_addr)}">상세보기</button></td>
									</tr>
								</c:forEach>
							</tbody>
						</table>

						<div class="pagination">
							<ui:pagination paginationInfo="${paginationInfo}" type="text"
								jsFunction="goPage" />
						</div>
					</c:otherwise>
				</c:choose>
			</div>
		</div>

	</div>
	<!-- ADR-008 로딩/메시지 오버레이 (목록 페이지 위) -->
	<div id="h100Overlay" class="h100-overlay" role="status" aria-live="polite">
		<div class="h100-overlay-box">
			<div id="h100OverlaySpinner" class="h100-overlay-spinner" aria-hidden="true"></div>
			<div id="h100OverlayMsg" class="h100-overlay-msg">처리 중...</div>
			<button type="button" id="h100OverlayClose" class="h100-overlay-close" onclick="hideLoadingOverlay()">닫기</button>
		</div>
	</div>