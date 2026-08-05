<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>

<%-- [Tiles fragment] 공용 chrome(헤더/사이드바/푸터)은 defaultLayout 제공. 이하 이 페이지 전용 CSS/JS/콘텐츠 --%>
<meta charset="UTF-8">
<title>단속 장비 현황</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/deviceList.css?v=20260707">
<%-- patches 2026-07-07: 외부 CSS 배포/캐시 지연 대비 — 테이블 열너비를 JSP 인라인으로 직접 지정.
     #deviceTable(ID) 선택자 + !important 로 옛 외부 CSS(.device-table nth-child width:359/440px)를 확실히 무력화.
     1 체크박스40 / 2 이름100 / 3 주소 잔여폭 / 4 등록날짜150 / 5~9 상태 통일70 / 10 수정90 --%>
<style>
	.device-table-scroll { width: 100%; overflow-x: auto; }
	#deviceTable { table-layout: fixed; width: 100%; min-width: 900px; }
	/* patches 2026-07-07: 주소 auto(잔여폭 전부) → 균형 %. 화면폭에 비례 유지, 주소 과대 완화 */
	/* (긴급복구 2026-07-16) 실시간 영상 열 복원으로 10 → 11열. 합계 100% 유지되도록 재배분 */
	#deviceTable th:nth-child(1),  #deviceTable td:nth-child(1)  { width: 3%  !important; } /* 체크박스 */
	#deviceTable th:nth-child(2),  #deviceTable td:nth-child(2)  { width: 12% !important; } /* 디바이스명 */
	#deviceTable th:nth-child(3),  #deviceTable td:nth-child(3)  { width: 23% !important; } /* 주소 (15번: 관리열 확장분 흡수) */
	#deviceTable th:nth-child(4),  #deviceTable td:nth-child(4)  { width: 12% !important; } /* 등록날짜 */
	#deviceTable th:nth-child(5),  #deviceTable td:nth-child(5),
	#deviceTable th:nth-child(6),  #deviceTable td:nth-child(6),
	#deviceTable th:nth-child(7),  #deviceTable td:nth-child(7),
	#deviceTable th:nth-child(8),  #deviceTable td:nth-child(8),
	#deviceTable th:nth-child(9),  #deviceTable td:nth-child(9)  { width: 6%  !important; } /* 상태 5종 */
	#deviceTable th:nth-child(10), #deviceTable td:nth-child(10) { width: 8%  !important; } /* 실시간 영상 */
	#deviceTable th:nth-child(11), #deviceTable td:nth-child(11) { width: 12% !important; } /* 관리(수정·로그) */
	#deviceTable td .video-btn { background: none; border: none; cursor: pointer; padding: 2px 4px; line-height: 0; }
	#deviceTable td .video-btn:hover { background: #f1edff; border-radius: 4px; }
	/* (15번 4-5) 이상 로그 버튼 — 수정 버튼과 나란히, 크기 통일 */
	#deviceTable td .err-log-btn { margin-left: 4px; padding: 3px 8px; font-size: 12px; cursor: pointer;
		background: #fff; color: #6955A2; border: 1px solid #cfc6ea; border-radius: 4px; }
	#deviceTable td .err-log-btn:hover { background: #ece7fb; }

	/* ===== (15번 4-5) 디바이스 이상 로그 slide-in 패널 ===== */
	.err-log-panel { position: fixed; top: 0; right: -420px; width: 420px; max-width: 92vw; height: 100vh;
		background: #fff; box-shadow: -2px 0 12px rgba(0,0,0,0.2); transition: right .3s ease; z-index: 2000;
		display: flex; flex-direction: column; }
	.err-log-panel.open { right: 0; }
	.err-log-panel .panel-header { display: flex; align-items: center; justify-content: space-between;
		padding: 14px 18px; background: #6955A2; color: #fff; }
	.err-log-panel .panel-header .panel-title { font-size: 14px; font-weight: 700; word-break: break-all; }
	.err-log-panel .panel-header .panel-close { background: none; border: none; color: #fff; font-size: 20px;
		line-height: 1; cursor: pointer; padding: 2px 6px; }
	.err-log-panel .panel-body { flex: 1; overflow-y: auto; padding: 10px 14px; }
	.err-log-item { padding: 9px 4px; border-bottom: 1px solid #eee; font-size: 13px; }
	.err-log-item .time { color: #999; font-size: 12px; margin-right: 8px; }
	.err-log-item .type-tag { display: inline-block; margin-right: 6px; padding: 1px 6px; border-radius: 3px;
		font-size: 11px; color: #fff; background: #8a7fb8; }
	.err-log-item .change { color: #383351; }
	.err-log-item .change .to-error  { color: #dc3545; font-weight: 700; }
	.err-log-item .change .to-normal { color: #28a745; font-weight: 700; }
	.err-log-empty { padding: 24px 4px; text-align: center; color: #999; font-size: 13px; }
	.err-log-backdrop { position: fixed; inset: 0; background: rgba(0,0,0,0.15); z-index: 1999; display: none; }
	.err-log-backdrop.open { display: block; }

	/* (19번 이슈B) 응급콜 알림 클릭 → 실시간 영상 자동실행 대신 유도 UX.
	   자동실행에 의존하지 않고, 해당 행의 "실시간 영상" 버튼을 짧게 강조해 사용자의 클릭을 유도한다. */
	@keyframes triggerGuideGlow {
		0%, 100% { box-shadow: 0 0 0 0 rgba(105,85,162,0.55); }
		50%      { box-shadow: 0 0 0 8px rgba(105,85,162,0); }
	}
	#deviceTable td .video-btn.trigger-guide-flash {
		border-radius: 6px;
		animation: triggerGuideGlow 1s ease-out 4;
	}
	.trigger-guide-tooltip {
		position: absolute; z-index: 2100; transform: translate(-50%, -100%);
		margin-top: -8px; padding: 6px 10px; background: #383351; color: #fff;
		font-size: 12px; border-radius: 4px; white-space: nowrap;
		box-shadow: 0 2px 8px rgba(0,0,0,0.2);
		opacity: 0; transition: opacity .25s ease;
	}
	.trigger-guide-tooltip::after {
		content: ''; position: absolute; top: 100%; left: 50%; transform: translateX(-50%);
		border: 5px solid transparent; border-top-color: #383351;
	}
	.trigger-guide-tooltip.show { opacity: 1; }
	/* patches 2026-07-09(3): 10건 조회 시 오른쪽 스크롤 없이 한 화면에 꽉 차도록 세로 여백 미세 축소 */
	.content { padding: 16px 24px 12px 24px !important; }        /* 상/하 32·29 → 16·12 */
	.device-top { margin-bottom: 8px !important; }               /* 12 → 8 */
	#deviceTable th, #deviceTable td { padding: 7px 0 !important; }  /* 9 → 7 (행당 -4px) */
	.pagination { margin-top: 12px !important; }                 /* 20 → 12 */
</style>
<%-- patches 2026-07-07: Daum(Kakao) 우편번호 서비스(주소 검색) + Kakao 지도 SDK(services=주소→좌표 지오코딩) --%>
<script src="//t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
<script src="//dapi.kakao.com/v2/maps/sdk.js?appkey=${kakaoMapJsKey}&libraries=services"></script>
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/pagination.css">
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/popup/deleteDevicePopup.css">
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/popup/deviceInfoPopup.css">
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/popup/realTimeVideoPopup.css">
<script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
<script>
	  src="https://code.jquery.com/jquery-3.7.1.js"
	  integrity="sha256-eKhayi8LEQwp4NKxN+CfCh+3qOVUtJn3QNZ0TciWLP4="
	  crossorigin="anonymous"
	</script>

	<script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
	<script src="${pageContext.request.contextPath}/resources/js/common/excelDownload.js"></script>
	<%-- 개인정보 수정 버튼 클릭시 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
	<script>
	  <c:if test="${not empty errorMsg}">
	    alert('<c:out value="${errorMsg}" />');
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
<script
	src="${pageContext.request.contextPath}/resources/js/interceptor/sessionManager.js"></script>
<%--  web.xml의 session time out 전역 변수, session time out 함수 --%>
<script>
	 // -------------------------------- pagination 활용한 페이지 이동 ----------------------------
	 
 		// 검색 input에서 100자 이상 입력시 알림 출력
	 	document.addEventListener('DOMContentLoaded', function () {
		  const MAX_LEN = 100;
		
		  // 1) 폼 찾기
		  const searchForm = document.getElementById('deviceListSearchForm');
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
	 
		// 디바이스 및 주소 검색
		window.searchDeviceList = function(pageNo){
			
			let form = document.getElementById('deviceListSearchForm');
		  	let val1 = form.elements['searchKeyword']?.value;
		  	let searchKeyword = encodeURIComponent(val1);
		  	let val2 = form.elements['startDate']?.value;
		  	let startDate = encodeURIComponent(val2);
		  	let val3 = form.elements['endDate']?.value;
		  	let endDate = encodeURIComponent(val3);
		  	let pageSize = document.getElementById('pageSize')?.value;
		  	
		  	if( searchKeyword.length >= 100 ){
		  		alert("검색어는 100자를 넘을 수 없습니다. \n 모든 문자 입력 가능합니다.");
		  		return;
		  	}
		  	if(startDate > endDate){ 
				alert("날짜를 확인해주세요.");
				return;
		  	}
		  	
		  	// 검색 파라미터 변경으로 인한 페이지 번호 1로 변경
		  	pageNo = Math.max(1, Number.isFinite(+pageNo) ? Math.trunc(+pageNo) : 0);
			
			location.href = "viewDeviceList.do?page=" + pageNo +"&startDate=" +startDate +"&endDate="+ endDate + "&searchKeyword=" + searchKeyword+"&pageSize="+pageSize;
			
		}
		
		// pagination 객체를 활용한 페이지 이동
		window.goPage = function(pageNo){
			let form = document.getElementById('deviceListSearchForm');
		  	let val1 = form.elements['searchKeyword']?.value;
		  	let searchKeyword = encodeURIComponent(val1);
		  	let val2 = form.elements['startDate']?.value;
		  	let startDate = encodeURIComponent(val2);
		  	let val3 = form.elements['endDate']?.value;
		  	let endDate = encodeURIComponent(val3);
		  	let pageSize = document.getElementById('pageSize')?.value;

			location.href = "viewDeviceList.do?page=" + pageNo + "&startDate=" +startDate+ "&endDate=" +endDate+"&searchKeyword=" + searchKeyword+"&pageSize="+pageSize;
		}
		
		//  Pagination 
		document.addEventListener('DOMContentLoaded', function () {
			  const $wrap = document.querySelector('.pagination');
			  if (!$wrap) return;

			  const links = Array.from($wrap.querySelectorAll('a'));
			  const current = $wrap.querySelector('strong'); 
			  const curPage = current ? parseInt(current.textContent.trim(), 10) : NaN;

			  // 유틸: goPage(숫자)에서 숫자만 뽑기
			  const getPageFromHref = (a) => {
			      const href = a.getAttribute('href') || '';
			      const m = href.match(/goPage\(\s*'?(\d+)'?\s*\)/);
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
		
		// -------------------------------- pagination 활용한 페이지 이동 ----------------------------
		

	    
		// -----------------------------  디바이스 삭제 팝업 ------------------------------------------
		function viewDeleteDevicePopup() {
		  // 1️⃣ 선택된 디바이스 확인
		  const checkedRows = document.querySelectorAll(".row-check:checked");
		  if (checkedRows.length === 0) {
		    alert("삭제할 디바이스를 선택하세요.");
		    return;
		  }
		
		  // 2️⃣ 선택된 디바이스 ID 모으기
		  const dvIds = Array.from(checkedRows).map(cb =>
		    cb.closest("tr").getAttribute("data-dv-id")
		  );
		
		  // 3️⃣ 서버에서 삭제 팝업 JSP 가져오기
		  axios
		    .post("${pageContext.request.contextPath}/deviceList/viewDeleteDevicePopup", { dvIds })
		    .then(function (r) {
		      
		      const popupDiv = document.getElementById("deleteDevicePopup");
		      popupDiv.innerHTML = r.data;
		      popupDiv.style.display = "block";
		    })
		    .catch(function (e) {
		      
		    });
		}		

		
	    // 삭제 버튼 클릭 
		function deleteSelectedRows() {
		  const table = document.getElementById("deviceTable");
		  const checkedRows = Array.from(table.querySelectorAll("tbody .row-check:checked"))
		    .map(cb => cb.closest("tr"));
		
		  if (checkedRows.length === 0) {
		    alert("삭제할 디바이스를 선택하세요.");
		    return;
		  }
		
		  const dvIds = checkedRows.map(tr => tr.getAttribute("data-dv-id"));
		  
		
		  axios.post("${pageContext.request.contextPath}/deviceList/deleteDeviceInfo", {
		      dvIds: dvIds
		    })
		    .then(function (r) {
		      
		
		      if (r.data?.ok) {
		        alert("삭제가 완료되었습니다.");
		        removeDeletePopup(); // 팝업 닫기
		        window.location.href = "${pageContext.request.contextPath}/deviceList/viewDeviceList.do";   // 리스트 갱신
		      } else {
		        alert(r.data?.msg || "삭제 중 오류가 발생했습니다.");
		      }
		    })
		    .catch(function (e) {
		      
		      alert("서버 통신 오류가 발생했습니다.");
		    });
		}
	    
	    // 삭제 팝업 삭제
	    function removeDeletePopup() {
	    	const popupDiv = document.getElementById("deleteDevicePopup");
	    	popupDiv.innerHTML = ""; 
	    	popupDiv.style.display = "none";
	    }
	    
	 // ------------------------------------- 디바이스 삭제 팝업 ------------------------------------------

	    
	    // -------------------------------- 디바이스 등록, 수정 ------------------------------

   	    // 디바이스 등록, 수정 화면에서 한계 값 이상 초과 입력 시도시 오류
		const INPUT_LIMITS = {
		  dvName: {
		    max: 100,
		    message: "디바이스명은 100자를 넘을 수 없습니다. \n 모든 문자 입력 가능합니다."
		  },
		  serialNumber: {
		    max: 15,
		    message: "시리얼 넘버는 15자를 넘을 수 없습니다. \n 한글을 제외한 모든 문자 입력 가능합니다."
		  },
		  dvAddr: {
		    max: 200,
		    message: "주소는 200자를 넘을 수 없습니다. \n 모든 문자 입력 가능합니다."
		  },
		  dvIp: {
		    max: 30,
		    message: "도메인은 30자를 넘을 수 없습니다. \n 숫자, '.' 이외의 문자(예: 한글, 영문 등)를 최소 1자 이상 포함한 값만 입력 가능합니다."
		  }
		};
	    
	    document.addEventListener('DOMContentLoaded', function(){
			
			let dvNameWarnedOnce = false; // 계속 알람 뜨는 것 방지용
			document.addEventListener('input', function (e) {
		    
			const el = e.target;
			if(!el.id) return;
				
		    const config = INPUT_LIMITS[el.id];
		    if (!config) return;   // 우리가 관리하는 필드가 아니면 무시
			
		    const max = config.max;
		    const val = el.value || "";
	
		    if (val.length > max) {
			      // 1) 초과 입력 취소 (초과분 잘라내기)
			      el.value = val.slice(0, max-1);
			      alert(config.message);
			     }
			  }); 
		});
	    
	    // 디바이스 등록 수정시 디바이스명과 주소 중복 체크
	    async function duplicatedNameAndAddr(dvId,dvName,dvAddr ){
		    
		 	const body = {
		 		dvId : dvId,	
		 		dvName : dvName,
		 		dvAddr : dvAddr
		 	}
		 	
		 	const res = await fetch('${pageContext.request.contextPath}/deviceList/duplicatedNameAndAddr',{
		    	method : 'POST',
		    	headers : {
		    		'Content-Type' : 'application/json'
		    	},
				credentials : 'same-origin',
				cache: 'no-store',
				body : JSON.stringify(body)
		    });

		 	if(!res.ok){
    			return false;
    		}
		 	
		 	const result = await res.json();
		 	if(!result.ok){
		 		alert(result.msg);
		 		return false;
		 	}else{
		 		return true;
		 	}
		 	
	 	}
	 
	 	// 디바이스 등록, 수정시 중복 체크
	 	async function validateDeviceInfo(dvId,dvName,dvAddr,dvIp,dvSerialNumber){
	  		
    		if(!dvName){
    			alert("디바이스명은 필수입니다.");
    			return false;
    		}
    		if(dvName.length > 100){
    			alert("디바이스명은 100자를 넘을 수 없습니다. \n 모든 문자 입력 가능합니다.");
    			return false;
    		}
    		
    		if(!dvAddr){
    			alert("주소는 필수입니다.");
    			return false;
    		}
    		if(dvAddr.length > 200){
    			alert("주소는 200자를 넘을 수 없습니다. \n 모든 문자 입력 가능합니다.");
    			return false;
    		}
    		const isDuplicatedNameAndAddr = await duplicatedNameAndAddr(dvId,dvName,dvAddr);
    		if(!isDuplicatedNameAndAddr){
    			return false;
    		}
    		if(!dvIp){
    			alert("도메인은 필수입니다.");
    			return false;
    		}
    		if(dvIp.length > 30){
    			alert("도메인은 30자를 넘을 수 없습니다. \n 숫자, '.' 이외의 문자(예: 한글, 영문 등)를 최소 1자 이상 포함한 값만 입력 가능합니다");
    			return false;
    		}
    		/*
    		if (/^[0-9.]+$/.test(dvIp)) {
    			alert("도메인에는 '.'과 숫자만으로 이루어진 값을 넣을 수 없습니다. \n 숫자, '.' 이외의 문자(예: 한글, 영문 등)를 최소 1자 이상 포함해 주세요.");
    			return false;
    		}
    		*/
    		if(!dvSerialNumber){
    			alert("시리얼 넘버는 필수입니다.");
    			return false;
    		}
    		if(dvSerialNumber.lengh > 15){
    			alert("시리얼 넘버는 15자를 넘을 수 없습니다. \n 한글을 제외한 모든 문자 입력 가능합니다.");

    			return false;
    		}
    		if (/[ㄱ-ㅎ가-힣]/.test(dvSerialNumber)) {
    			alert("시리얼 넘버는 15자를 넘을 수 없습니다. \n 한글을 제외한 모든 문자 입력 가능합니다.");

    			return false;
    		}
    		return true;
	 	}   
	 
	    // patches 2026-07-07: Daum 우편번호 서비스로 디바이스 주소 검색 (팝업 버튼 onclick 에서 호출)
	    function searchDeviceAddress(){
	        if (typeof daum === 'undefined' || !daum.Postcode) {
	            alert('주소 검색 스크립트를 불러오지 못했습니다. 새로고침 후 다시 시도해주세요.');
	            return;
	        }
	        new daum.Postcode({
	            oncomplete: function(data){
	                var addr = data.roadAddress || data.jibunAddress; // 도로명 우선, 없으면 지번
	                var addrEl = document.getElementById('dvAddr');
	                if (addrEl) addrEl.value = addr;

	                // patches 2026-07-07: 지오코딩 — 주소 → 좌표(lat/lng). 대시보드 지도 마커 자동생성용.
	                geocodeDeviceAddress(addr);

	                var detailEl = document.getElementById('dvAddrDetail');
	                if (detailEl) detailEl.focus(); // 상세주소 입력으로 포커스 이동
	            }
	        }).open();
	    }

	    // 주소 → 좌표 변환(Kakao Geocoder). 성공 시 hidden dvLat/dvLng 채움, 실패/미로드 시 0(지도 미표시).
	    function geocodeDeviceAddress(addr){
	        var latEl = document.getElementById('dvLat');
	        var lngEl = document.getElementById('dvLng');
	        if (!latEl || !lngEl) return;
	        if (typeof kakao === 'undefined' || !kakao.maps || !kakao.maps.services) {
	            // SDK 미로드(키 미설정 등) → 좌표 0 유지
	            latEl.value = '0'; lngEl.value = '0';
	            return;
	        }
	        var geocoder = new kakao.maps.services.Geocoder();
	        geocoder.addressSearch(addr, function(result, status){
	            if (status === kakao.maps.services.Status.OK && result && result[0]) {
	                latEl.value = result[0].y; // 위도
	                lngEl.value = result[0].x; // 경도
	            } else {
	                latEl.value = '0'; lngEl.value = '0'; // 변환 실패 → 지도 미표시
	            }
	        });
	    }

	    // 디바이스 정보 팝업 열기
		function viewDeviceInfoPopup(dvId){
			axios.get('${pageContext.request.contextPath}/deviceList/viewDeviceInfoPopup', { params : {dvId} })
			.then(function(r) {
			  const riDiv = document.getElementById("deviceInfoPopup");
			  riDiv.innerHTML = r.data;
			  riDiv.style.display = "block";
			  document.getElementById('dvName').focus();
			})
			.catch(function(e) {
			  
			});
	    }
	 
    	// 디바이스 수정
    	async function updateDeviceInfo(dvId){
    		
    		let dvName = document.getElementById("dvName").value;
    		let dvAddr = document.getElementById("dvAddr").value;
    		let dvAddrDetail = document.getElementById("dvAddrDetail").value.trim();
    		let dvLat = (document.getElementById("dvLat").value || '0').trim();
    		let dvLng = (document.getElementById("dvLng").value || '0').trim();
    		let dvIp = document.getElementById("dvIp").value;
    		let dvSerialNumber = document.getElementById("serialNumber").value.trim();

    		const validateCheck = await validateDeviceInfo(dvId,dvName,dvAddr,dvIp,dvSerialNumber);
    		if(!validateCheck){
    			return;
    		}

    		axios.post('${pageContext.request.contextPath}/deviceList/updateDeviceInfo',
  			    new URLSearchParams({
  			        dvId: dvId,
  			        dvName: dvName,
  			        dvAddr: dvAddr,
  			        dvAddrDetail: dvAddrDetail,
  			        dvLat: dvLat,
  			        dvLng: dvLng,
  			        dvIp: dvIp,
    			    dvSerialNumber : dvSerialNumber
  			    })
  			)
    		.then(function(r){
    			
    			if(r.data?.ok){
    		        alert("디바이스가 수정되었습니다.");
    		        closeDeviceInfoPopup();
    		        window.location.href = "${pageContext.request.contextPath}/deviceList/viewDeviceList.do";
    			}else{
    				alert(r.data?.msg);
    			}
    			
    		})
    		.error(function(e){
    			
    			alert("수정 중 오류가 발생했습니다.");
    		});
    	}
    	
    	// 디바이스 등록
		async function insertDeviceInfo() {
		  let dvName = document.getElementById("dvName").value.trim();
		  let dvAddr = document.getElementById("dvAddr").value.trim();
		  let dvAddrDetail = document.getElementById("dvAddrDetail").value.trim();
		  let dvLat = (document.getElementById("dvLat").value || '0').trim();
		  let dvLng = (document.getElementById("dvLng").value || '0').trim();
		  let dvIp = document.getElementById("dvIp").value.trim();
		  let dvSerialNumber = document.getElementById("serialNumber").value.trim();

  		  const validateCheck = await validateDeviceInfo(null,dvName,dvAddr,dvIp,dvSerialNumber);
		  if(!validateCheck){
			  return;
		  }

		  axios.post("${pageContext.request.contextPath}/deviceList/insertDeviceInfo",
		      new URLSearchParams({
		        dvName: dvName,
		        dvAddr: dvAddr,
		        dvAddrDetail: dvAddrDetail,
		        dvLat: dvLat,
		        dvLng: dvLng,
		        dvIp: dvIp,
		        dvSerialNumber : dvSerialNumber
		      })
		    )
		    .then(function(r) {
		      if (r.data?.ok) {
		        alert("디바이스가 등록되었습니다.");
		        closeDeviceInfoPopup();
		        window.location.href = "${pageContext.request.contextPath}/deviceList/viewDeviceList.do";
		      } else {
		        alert(r.data?.msg || "등록 중 오류가 발생했습니다.");
		      }
		    })
		    .catch(function(e) {
		      
		      alert("서버 통신 오류가 발생했습니다.");
		    });
		}
    	
    	// 디바이스 등록, 수정 팝업창 닫기
		function closeDeviceInfoPopup(){
			const popup = document.getElementById("deviceInfoPopup");
			popup.innerHTML = "";
			popup.style.display = "none";
		}
	    	
    	// -------------------------------- 디바이스 등록, 수정 ------------------------------
    	
	 	    
	    // ---------------------------- 실시간 영상 팝업 -------------------------------
	    
	    // 실시간 영상 팝업
		async function viewRealTimeVideoPopup(dvId){
			
			// URLSearchParams를 사용하여 form data로 전송
			const formData = new URLSearchParams();
			formData.append('dvId', dvId);
    		
    		axios.post('${pageContext.request.contextPath}/deviceList/viewRealTimeVideoPopup', formData)
			.then(function(r){
				
				let rtDiv = document.getElementById("realTimeVideoPopup");
				
				rtDiv.innerHTML = r.data;
				
				rtDiv.style.display = 'block';
				
				// 팝업창 실행시 자동 시작
			    setTimeout(() => {
					    deviceBtnClick('start', dvId);
			    }, 0);
				
			})
			.catch(function(e) {
				
			})
		}
		
		// 현재 스트리밍 중인 deviceId
		let deviceId = null;
		
		// 현재 스트리밍중인지 아닌지 여부
		let isStreamingActive = false;
		
		// ?
		let teardownSent = false;
		
		// 전역 토큰 ID
		let tokenId  = null;
		
		// 전역 hls
		let hls = null;
		
		// video source tag id
		let video = null;
		
		
		/*
		* 1~2초 대기
		*/
		function sleep(ms) { return new Promise(r => setTimeout(r,ms));}

		/*
		 * (긴급복구 2026-07-22) HLS 플레이리스트(index.m3u8)가 실제로 생성될 때까지 대기.
		 *  - 404  : ffmpeg 이 아직 첫 세그먼트를 못 만든 상태 → 계속 재시도
		 *  - 예외 : TLS 인증서 미승인·디바이스 연결 불가 → 'NETWORK' 로 구분해 사용자 안내
		 *  @return {ok:true} | {ok:false, reason:'HTTP 404'|'NETWORK'|'TIMEOUT'}
		 */
		async function waitForManifest(url, timeoutMs) {
			const deadline = Date.now() + (timeoutMs || 25000);
			let lastReason = 'TIMEOUT';
			while (Date.now() < deadline) {
				try {
					const r = await fetch(url, { method: 'GET', cache: 'no-store', mode: 'cors' });
					if (r.ok) return { ok: true };
					lastReason = 'HTTP ' + r.status;   // 준비 전(404) — 재시도
				} catch (e) {
					lastReason = 'NETWORK';            // TLS 미승인/연결 불가 — 재시도해도 대개 동일
				}
				await sleep(1000);
			}
			return { ok: false, reason: lastReason };
		}
		
		/*
		* 실시간 스트리밍 실행
		*/
		async function playVideo(playUrl){
			

			video = document.getElementById('video');
			// jetson : 192.168.0.31, 개발 : 192.18.0.15
			// ccty : 192.168.0.39
			// 운영 = 'https://www.geyeparking.shop/index.m3u8';
			
			// 네이티브 로드를 차단
			  try { video.pause(); } catch(_) {}
			  video.removeAttribute('src');   // ★ 네이티브 로드를 먼저 차단
			  video.load();
			  if (hls) { try { hls.destroy(); } catch(_){} hls = null; }
			
			if(Hls.isSupported()){

				/*
				 * (긴급복구 2026-07-22) 고정 대기(3초) → 플레이리스트 준비 확인으로 변경.
				 *   ffmpeg 은 시작 시 기존 index.m3u8 을 삭제하고, '첫 세그먼트가 완성된 뒤'에야 플레이리스트를 쓴다.
				 *   (초기화 ~2초 + hls_time 3초 ≈ 5~6초) → 고정 대기로는 경계에 걸려 404 가 났다.
				 *   준비될 때까지 1초 간격으로 확인하고, 네트워크/인증서 오류는 구분해 안내한다.
				 */
				const ready = await waitForManifest(playUrl, 25000);
				if (!ready.ok) {
					if (ready.reason === 'NETWORK') {
						alert("디바이스에 연결할 수 없습니다.\n새 탭에서 아래 주소에 접속해 인증서 예외를 1회 허용한 뒤 다시 시도해 주세요.\n\n" + playUrl);
					} else {
						alert("영상 준비가 지연되고 있습니다. 잠시 후 다시 시도해 주세요. (" + ready.reason + ")");
					}
					return;
				}

				hls = new Hls({
					autoStartLoad:false
					, maxBufferLength:10
					, maxBufferSize: 60 * 1000 * 1000
					, liveSyncDuration: 2            // or liveSyncDurationCount: 2~3
					, liveMaxLatencyDuration: 5     // or liveMaxLatencyDurationCount: 8~10
					, maxLiveSyncPlaybackRate: 1.5    // 살짝 가속해 엣지 추격
				});
				
				hls.attachMedia(video);
				
			  hls.on(Hls.Events.MEDIA_ATTACHED, async () => {
			    hls.loadSource(playUrl);        // 소스만 로드
			    // (2026-07-22) 위에서 플레이리스트 준비를 이미 확인했으므로 추가 대기 불필요
			    hls.startLoad(-1);               // ★ 실제 로드 시작(라이브 엣지)
			  });

				
				hls.on(Hls.Events.ERROR,function(event,data){
					  /*
					  * Hls.Events.ERROR 발생시 자세한 에러 로그 확인하는 코드, 오류 발생시에만 주석 풀어서 디버깅
						console.log('HLS ERROR', {
						    type: data.type,
						    details: data.details,
						    code: data.response?.code,
						    url: data.response?.url
						  });
					  */
				      if (data.fatal) {
				        switch (data.type) {
				          // 네트워크 오류인 경우
				          case Hls.ErrorTypes.NETWORK_ERROR:
				            hls.startLoad();
				            alert("⚠️ 네트워크 오류");
				            break;
				          // 미디어 오류인 경우
				          case Hls.ErrorTypes.MEDIA_ERROR:
				            hls.recoverMediaError();
				            alert("⚠️ 미디어 오류");
				            break;
				          // 그 외 오류, 스트리밍 중단
				          default:
				            hls.destroy();
				            alert("❌ 복구 불가, 스트리밍 중단");
				            break;
				        }
				      }
				});
			} else if(video.canPlayType('application/vnd.apple.mpegurl')){
				// video 타입이 hls가 아닌 경우 mpegurl 타입으로 video 실행
				video.src = playUrl;
				video.addEventListener('loadedmetadata',() => {
					
					video.muted = true;
					video.play().catch(err => {
						alert("비디오 플레이 중 오류 : " + err);
					});
				});
			} else {
				alert('HLS를 지원하지 않는 브라우저입니다.')
			}
		}
		
		function stopVideo(){
			
			video = document.getElementById('video');
			
			if(hls){
				hls.destroy();
				hls = null;
			}
			
			video.pause();
			video.load();
			video.removeAttribute('src');
		}
		
		/*
		* 디바이스 컨트롤러 버튼을 화면에 display 할 지 여부 설정, 
		* @param
		*  - display: 컨트롤러 div를 화면에 display하는 설정값(boolean) true면 display
		*/
		/*
	    function displayController(display) {
	        const controller = document.getElementsByClassName("controller")[0].children;
	        for (let btn of controller) {
	            btn.style.display = display;
	        }
	    }
		*/
		
	    /*
	    * 디바이스에 명령어를 보내 기능 수행
	    * @param
	    *  - command : 명령어(string)
	    *  - deviceId : 명령어를 보낼 device의 id
	    * @return : "error" | "end" | playUrl(String)
	    */
		async function sendCommand(command,deviceId) {
	    	
			const body = {
				'type': command,
				'id': tokenId,
				'deviceId':deviceId
			};
			
			try{
		    	const response = await fetch('${pageContext.request.contextPath}/deviceList/sendCommandToJSON', {
		      		method: 'POST'
		      		, headers: { 'Content-Type': 'application/json' }
		      		, body: JSON.stringify(body)
		      		, keepalive: command === 'end'
		      		, credentials : 'same-origin'
		      		, cache:'no-store'
		    		});
		    	
		    	// fetch는 항상 response 객체로 리턴
		    	if (!response.ok) return "error";
				
		    	// response에서 json값 가져오기
		    	let data = await response.json();
		    	await sleep(2000);
		    	
		    	// start면 tokenId, playUrl 추가
		    	if(command === 'start'){ 
		    		tokenId = data.result || data.id || null;
		    		let playUrl = data.playUrl || null;
		    		return playUrl;
	    		}
		    	
		    	// end면 tokenId 초기화
		    	if(command === 'end'){ 
		    		tokenId = null; 
		    		return "end";	
		    	}
		    	
		    	// 화각변환 ('H' = 중앙 복귀. 15번 4-4 이전에는 누락돼 항상 "틸팅 실패" 로 처리됐음)
		    	if(command === 'U' || command === 'D' || command === 'L' || command === 'R' || command === 'H'){
		    		return "ok";
		    	}
		    	
		    	// 줌 인, 줌 아웃
		    	if(command === 'zoomIn' || command === 'zoomOut'){
		    		return "ok";
		    	}
		    	
		    	
		    	return "error";
			}catch(e){
				return "error";
			}

	  	}
	    
	    // 페이지 종료되었을 때 종료 처리 함수
	    function sendEndBeaconOnce(){
	    	
		 	if(teardownSent) return;
		 	if(!isStreamingActive || !deviceId) return;
			 
		 	teardownSent = true;
		    	
    		// 보낼 데이터
    	    const body = JSON.stringify({ type: 'end', id: tokenId, deviceId: deviceId });
	    	
	    	// 실시간 스트리밍 종료 요청
    	    try {
    	    	// 1) sendBeacon 방식으로 브라우저 중도 요청 취소 방지
    	        const ok = navigator.sendBeacon(
    	          '${pageContext.request.contextPath}/deviceList/sendCommandToJSON',
    	          new Blob([body], { type: 'application/json' })
    	        );
    	    	
    	        if (!ok) {
    	          // 2) sendBeacon 실패시 fetch에 keepalive true 속성 사용하여 실시간 스트리밍 종료 요청
    	          fetch('${pageContext.request.contextPath}/deviceList/sendCommandToJSON', {
    	            method: 'POST',
    	            headers: { 'Content-Type': 'application/json' },
    	            body,
    	            keepalive: true
    	          });
    	        }
    	      
    	      // 페이지 밖으로 벗어남으로 에러 처리 없음
    	      } catch (_) {}
    	      
    	      // 로컬 플레이어는 즉시 정리 (네트워크 요청과 별개)
    	      try { if (hls) { hls.destroy(); hls = null; } } catch(_){}
    	      try {
    	        const v = document.getElementById('video');
    	        if (v) { v.pause(); v.removeAttribute('src'); v.load(); }
    	      } catch(_){}
    	      isStreamingActive = false;

	    }

	  	// 디바이스 리스트 버튼 클릭시 조건에 따라 start, stop 명령어 실행
	  	async function deviceBtnClick(command,newDeviceId){
	  		
	  		let result = "error";
	  		
	  		// 이미 다른 디바이스 실행되고 있는 경우 먼저 end command 보냄
	  		if(isStreamingActive && deviceId){
	  			
	  			result = await sendCommand('end',deviceId);
	  			
	  			if(result === "error"){
	  				alert("기존 디바이스와 통신 오류");
	  				return;
	  			}

  				stopVideo();
  				deviceId = null;
	  			isStreamingActive = false;
	  			tokenId = null;
	  			
	  			// 기존 디바이스 종료 명령이라면 여기에서 return
	  			if(command === 'end'){
	  				return;
	  			}
	  			
	  		}
	  		
	  		// 새로운 디바이스와 통신
	  		deviceId = newDeviceId;
	  		result = await sendCommand(command,deviceId);
	  		
	  		// 새로운 디바이스와 통신 중 오류 처리
	  		if(result === "error"){
	  			alert("새 디바이스와 통신 오류");
	  			isStreamingActive = false;
	  			deviceId = null;
	  			return;
	  			
  			// 새로운 디바이스와 연결 시 요청에 따른 videoPlayer 처리
	  		}else{
	  			if(command === 'start'){
	  				if (hls) { try{ hls.destroy(); }catch(_){} hls = null; } // 기존에 hls가 남아 있다면 제거
	  				playVideo(result); //playUrl
	  				isStreamingActive = true;
	  			}else if(command === 'end'){
	  				stopVideo();
	  				isStreamingActive = false;
	  			}
	  		}
	  		
	  		
	  	}
	  	
	  	
	  	// 페이지 시작시 자동 실행
	    document.addEventListener('DOMContentLoaded', function() {
	    	
	    	// deviceBtnClick('start','${deviceId}');
	    	
	    });
	  	

	 	// 페이지 종료 전 이벤트 처리
		 window.addEventListener('beforeunload', () => {
			 sendEndBeaconOnce();
			 
			 });
		 window.addEventListener('pagehide', () => { sendEndBeaconOnce(); }, { capture: true });
		 document.addEventListener('visibilitychange', () => {
			 
		     if (document.visibilityState === 'hidden') sendEndBeaconOnce();
		 });
		 window.addEventListener('unload', () => { 
			 sendEndBeaconOnce(); 
			  
		 });
		
		 
		 // 틸팅 관련 버튼 클릭시 명령어 디바이스에 송신
		 async function tiltingBtnClick(command){
			 
			 // 디바이스에 실시간 송출이 되고 있지 않다면 return
			 if(deviceId == null || deviceId == undefined || deviceId == ""){
				 alert("먼저 디바이스부터 실행해주세요.");
				 return;
			 }
			 
			 result = await sendCommand(command,deviceId);
			 
		  		// 새로운 디바이스와 통신 중 오류 처리
		  		if(result === "error"){
		  			alert("틸팅 실패");
		  			return;
		  		}
		  	
		  		await sleep(3000);
		  		
		 }
		 
		 // 팝업창 닫기
		 function closeRealTimeVideoPopup(){
			 if(isStreamingActive == true) stopVideo();
			 
			 let realTimeVideoPopup = document.getElementById("realTimeVideoPopup");
			 realTimeVideoPopup.innerHTML = "";
			 realTimeVideoPopup.style.display = 'none';
			 // location.reload();
			 
		 }
		
		// ---------------------------- 실시간 영상 팝업 -------------------------------   
		
		
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
					endpoint:'/deviceList/excelDownload',
					formSelector:'#deviceListSearchForm',
					mapping: {
						startDate:'startDate',
						endDate:'endDate',
						searchKeyword:'searchKeyword'
					},
					responseType:'blob',
					downloadFilename:'디바이스_리스트.xlsx'
				}).catch(function(e){alert(e.message);});
			})
		});

		/*
		async function excelDownload(){
			
			let form = document.getElementById('deviceListSearchForm');
		  	let val1 = form.elements['searchKeyword']?.value;
		  	let searchKeyword = encodeURIComponent(val1);
		  	let val2 = form.elements['startDate']?.value;
		  	let startDate = encodeURIComponent(val2);
		  	let val3 = form.elements['endDate']?.value;
		  	let endDate = encodeURIComponent(val3);
			
			const body = {
				'startDate': startDate,
				'endDate': endDate,
				'searchKeyword':searchKeyword
			};
				
			try{
		    	const response = await fetch('${pageContext.request.contextPath}/deviceList/excelDownload', {
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
		
		
	  // --------- 각 컬럼별 정렬 버튼 클릭시 데이터 정렬 ---------
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
		// --------- 각 컬럼별 정렬 버튼 클릭시 데이터 정렬 ---------
		
    </script>

	
		<!-- 헤더 -->
		
		<!-- 사이드바 -->
		
			<!-- 사이드바 -->
			
			<!-- 메인 콘텐츠 -->
			
					<div class="buttonBox">
						<!-- 첫 번째 줄: 등록 버튼 / 두 번째 줄 : 날짜, 검색, 조회버튼 - 10개씩 보기 -->
						<button class="add-btn" onclick="viewDeviceInfoPopup()">+
							디바이스 등록</button>
					</div>
					<div class="device-top">
						<div class="top-row">

							<form id="deviceListSearchForm" class="filter-form"
								onsubmit="searchDeviceList('${page}'); return false;">
								<div class="filter-input-group">
									<input type="date" name="startDate" value="${startDate}" />
								</div>
								<p class="date-contect">~</p>
								<div class="filter-input-group">
									<input type="date" name="endDate" value="${endDate}" />
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
									<input type="text" name="searchKeyword"
										value="<c:out value='${searchKeyword}'/>"
										placeholder="디바이스명 및 주소 검색"
										maxlength="100">
								</div>
								<button type="submit" class="search-btn" title="검색">조회</button>
							</form>
							
							<select id="pageSize" name="pageSize" class="select-box"
								onChange="searchDeviceList()">
								<option value="10" ${pageSize == 10 ? 'selected' : ''}>10개씩
									보기</option>
								<option value="20" ${pageSize == 20 ? 'selected' : ''}>20개씩
									보기</option>
								<option value="30" ${pageSize == 30 ? 'selected' : ''}>30개씩
									보기</option>
							</select>
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
							<button id="btnExcel" type="button" class="delete-btn"
								onclick="excelDownload()" title="엑셀 다운로드">
								<img
									src="${pageContext.request.contextPath}/resources/images/icon_excel.svg"
									alt="엑셀 다운로드">
							</button>
						</div>
					</div>

					<!-- patches 2026-07-07: 가로 스크롤 안전망 — 열이 넘쳐도 잘리지 않고 스크롤 -->
					<div class="device-table-scroll">
					<table id="deviceTable" class="device-table">
						<thead>
							<tr>
								<th><input type="checkbox" id="checkAll"
									class="table-checkBox" /></th>
								<th>디바이스명
									<button class="sort-btn" data-column="dv_name">
										<img
											src="${pageContext.request.contextPath}/resources/images/icon_arrow_up.svg">
									</button>
								</th>
								<th>디바이스 주소
									<button class="sort-btn" data-column="dv_addr">
										<img
											src="${pageContext.request.contextPath}/resources/images/icon_arrow_up.svg">
									</button>
								</th>
								<th>등록날짜
									<button class="sort-btn" data-column="dv_reg_date">
										<img
											src="${pageContext.request.contextPath}/resources/images/icon_arrow_up.svg">
									</button>
								</th>
								<!-- 디바이스 상태 5종 실시간 표시 -->
								<th>PC</th>
								<th>CCTV</th>
								<th>렌즈</th>
								<th>스피커</th>
								<th>SIP</th>
								<%-- (긴급복구 2026-07-16) 실시간 영상 열 복원 --%>
								<th>실시간 영상</th>
								<%-- (15번 4-5) 열 추가 없이 관리 열에 '이상 로그' 버튼을 함께 배치 --%>
								<th>관리</th>
							</tr>
						</thead>
						<tbody>
							<c:choose>
								<c:when test="${empty deviceList}">
									<tr>
										<td colspan="11"
											style="text-align: center; padding: 40px 0; color: #777;">
											조회된 디바이스가 없습니다.</td>
									</tr>
								</c:when>
								<c:otherwise>
									<c:forEach var="item" items="${deviceList}">
										<tr id="device-${item.dv_id}"
											data-dv-id="<c:out value='${item.dv_id}' escapeXml ='true'/>"
											data-serial="<c:out value='${item.dv_serial_number}' escapeXml='true'/>">
											<td><input type="checkbox" class="row-check" /></td>
											<td><span class="cell-ellipsis"
												title="${fn:escapeXml(item.dv_name)}"> <c:out
														value="${item.dv_name}" escapeXml="true" />
											</span></td>
											<%-- 주소 + 상세주소 (상세주소 null/공백이면 '' 처리, 공백 구분자도 그때만) --%>
											<c:set var="addrFull" value="${item.dv_addr}${empty item.dv_addr_detail ? '' : ' '}${item.dv_addr_detail}" />
											<td><span class="cell-ellipsis"
												title="${fn:escapeXml(addrFull)}"> <c:out
														value="${addrFull}" escapeXml="true" />
											</span></td>
											<td><span class="cell-ellipsis ev-date"
												title="${fn:escapeXml(item.dv_reg_date)}"> <c:out
														value="${item.dv_reg_date}" escapeXml="true" />
											</span></td>
					          
					          <!--
							  <td>
								<c:choose>
									<c:when test="${item.dv_status eq 0}">OFF</c:when>
									<c:when test="${item.dv_status eq 1}">ON</c:when>
								</c:choose>
							  </td>	
																				
								<td>
									<c:choose>
										<c:when test="${item.dv_status eq 0}">Jetson 통신 불가</c:when>
										<c:when test="${item.dv_status eq 1}">정상 </c:when>
										<c:when test="${item.dv_status eq 2}">CCTV 통신 불가</c:when>
										<c:when test="${item.dv_status eq 3}">전광판 통신 불가</c:when>
										<c:when test="${item.dv_status eq 4}">알림소리 통신 불가</c:when>
										<c:when test="${item.dv_status eq 5}">안전버튼 통신 불가</c:when>
									</c:choose>
								</td>
								 
					          <td>
						        <c:choose>
					        		<c:when test="${item.dv_status eq 1}">
					            		<button type="button" class="video-btn" onclick="viewRealTimeVideoPopup(${item.dv_id})">
				              			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
					                		<path d="M17 12V8C17 7.47 16.79 6.96 16.41 6.59C16.04 6.21 15.53 6 15 6H5C4.47 6 3.96 6.21 3.59 6.59C3.21 6.96 3 7.47 3 8V16C3 16.53 3.21 17.04 3.59 17.41C3.96 17.79 4.47 18 5 18H15C15.53 18 16.04 17.79 16.41 17.41C16.79 17.04 17 16.53 17 16V12ZM17 12L21 8V16L17 12Z"
					                      stroke="black" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
					              		</svg>
					            		</button>
				            		</c:when>
								</c:choose>	
					          </td>
					          -->
											<!-- (작업계획서 04) 상태 5종 — 값 없으면 '이상'(정상 확인 전 보수적). AJAX 폴링으로 갱신 -->
											<td class="status-pc status-error" data-value="">이상</td>
											<td class="status-cctv status-error" data-value="">이상</td>
											<td class="status-lens status-error" data-value="">이상</td>
											<td class="status-speaker status-error" data-value="">이상</td>
											<td class="status-sip status-error" data-value="">이상</td>
											<%-- (긴급복구 2026-07-16) 실시간 영상 버튼 복원.
											     기존에는 구 dv_status(=1)일 때만 노출되도록 주석 블록 안에 있었으나,
											     상태 5종 체계로 바뀐 현재는 조건 없이 항상 클릭 가능하도록 복원(요청). --%>
											<td>
												<button type="button" class="video-btn" title="실시간 영상"
													onclick="viewRealTimeVideoPopup(${item.dv_id})">
													<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
														<path d="M17 12V8C17 7.47 16.79 6.96 16.41 6.59C16.04 6.21 15.53 6 15 6H5C4.47 6 3.96 6.21 3.59 6.59C3.21 6.96 3 7.47 3 8V16C3 16.53 3.21 17.04 3.59 17.41C3.96 17.79 4.47 18 5 18H15C15.53 18 16.04 17.79 16.41 17.41C16.79 17.04 17 16.53 17 16V12ZM17 12L21 8V16L17 12Z"
															stroke="black" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
													</svg>
												</button>
											</td>
											<td>
												<button class="edit-btn" type="button"
													onclick="viewDeviceInfoPopup(${item.dv_id})">수정</button>
												<%-- (15번 4-5) 이상 로그 slide-in 패널 열기. dv_name 은 패널 제목용 --%>
												<button class="err-log-btn" type="button"
													data-dv-id="${item.dv_id}"
													data-dv-name="<c:out value='${item.dv_name}' escapeXml='true'/>">로그</button>
											</td>
										</tr>
									</c:forEach>
								</c:otherwise>
							</c:choose>
						</tbody>
					</table>
					</div><!-- /.device-table-scroll -->

					<div class="pagination">
						<ui:pagination paginationInfo="${paginationInfo}" type="text"
							jsFunction="goPage" />
					</div>

					<!-- 팝업 placeholder -->
					<div id="realTimeVideoPopup" style="display: none;"></div>
					<div id="deviceInfoPopup" style="display: none;"></div>
					<div id="deleteDevicePopup" style="display: none;"></div>

					<%-- (15번 4-5) 디바이스 이상 로그 slide-in 패널 --%>
					<div class="err-log-backdrop" id="errLogBackdrop"></div>
					<div class="err-log-panel" id="errLogPanel" role="dialog" aria-modal="true" aria-label="디바이스 이상 로그">
						<div class="panel-header">
							<span class="panel-title" id="errLogTitle">디바이스 이상 로그</span>
							<button type="button" class="panel-close" id="errLogClose" aria-label="닫기">&times;</button>
						</div>
						<div class="panel-body" id="errLogBody"></div>
					</div>
				
			
		
	

	<!-- (작업계획서 04) 디바이스 상태 실시간 폴링 — 변경된 셀만 부분 갱신 (jQuery 미로드 → vanilla fetch) -->
	<script>
	(function(){
	  var STATUS_KEYS = [
	    { cls: 'status-pc',      field: 'dv_status_pc' },
	    { cls: 'status-cctv',    field: 'dv_status_cctv' },
	    { cls: 'status-lens',    field: 'dv_lens' },
	    { cls: 'status-speaker', field: 'dv_status_speaker' },
	    { cls: 'status-sip',     field: 'dv_status_sip' }
	  ];

	  function updateDeviceRow(device){
	    var row = document.getElementById('device-' + device.dv_id);
	    if(!row) return;
	    STATUS_KEYS.forEach(function(k){
	      var cell = row.querySelector('.' + k.cls);
	      if(!cell) return;
	      var v = device[k.field];
	      var s = (v === null || v === undefined) ? 'null' : String(v); // null 은 초기 ''(data-value)와 구분 → '이상'으로 갱신
	      if(cell.getAttribute('data-value') === s) return; // 변경 없으면 부분 갱신 skip
	      cell.style.transition = 'opacity .2s';
	      cell.style.opacity = '0';
	      setTimeout(function(){
	        cell.textContent = (v === 1 ? '정상' : '이상');
	        cell.classList.remove('status-normal', 'status-error');
	        cell.classList.add(v === 1 ? 'status-normal' : 'status-error');
	        cell.setAttribute('data-value', s);
	        cell.style.opacity = '1';
	      }, 200);
	    });
	  }

	  function pollDeviceStatus(){
	    fetch(CONTEXT_PATH + '/deviceList/status',
	          { headers: { 'X-Requested-With': 'XMLHttpRequest' }, credentials: 'same-origin', cache: 'no-store' })
	      .then(function(r){ if(!r.ok) throw new Error('http ' + r.status); return r.json(); })
	      .then(function(list){ (list || []).forEach(updateDeviceRow); })
	      .catch(function(e){ console.error('디바이스 상태 폴링 실패', e); });
	  }

	  document.addEventListener('DOMContentLoaded', function(){
	    pollDeviceStatus();                   // 즉시 1회(초기 '-' 채움)
	    setInterval(pollDeviceStatus, 5000);  // 5초 주기 폴링
	  });
	})();
	</script>

	<%-- (15번 4-5·4-2) 이상 로그 slide-in 패널 + 알림 클릭 이동 수신 처리.
	     상태 폴링과 동일하게 vanilla JS + fetch 로 작성(이 페이지는 jQuery 비의존 정책). --%>
	<script>
	(function(){
	  // 상태 5종 한글 라벨 — module_c 가 넣는 del_status_type(pc·cctv·lens·speaker·sip) 과 1:1
	  var STATUS_LABEL = { pc: 'PC', cctv: 'CCTV', lens: '렌즈', speaker: '스피커', sip: 'SIP' };

	  function esc(s){
	    return String(s == null ? '' : s)
	      .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
	      .replace(/"/g,'&quot;').replace(/'/g,'&#39;');
	  }
	  // 1=정상, 그 외=이상. 값 자체도 함께 보여줘 담당자가 원본을 확인할 수 있게 한다.
	  function valLabel(v){ return (String(v) === '1') ? '정상' : '이상'; }
	  function valClass(v){ return (String(v) === '1') ? 'to-normal' : 'to-error'; }

	  var panel    = document.getElementById('errLogPanel');
	  var backdrop = document.getElementById('errLogBackdrop');
	  var titleEl  = document.getElementById('errLogTitle');
	  var bodyEl   = document.getElementById('errLogBody');

	  function openPanel(){ panel.classList.add('open'); backdrop.classList.add('open'); }
	  function closePanel(){ panel.classList.remove('open'); backdrop.classList.remove('open'); }

	  function renderLogs(list){
	    if(!list || !list.length){
	      bodyEl.innerHTML = '<div class="err-log-empty">이상 로그가 없습니다.</div>';
	      return;
	    }
	    var html = '';
	    list.forEach(function(it){
	      var typeLabel = STATUS_LABEL[it.del_status_type] || esc(it.del_status_type);
	      html += '<div class="err-log-item">'
	            +   '<div>'
	            +     '<span class="time">' + esc(it.del_reg_date) + '</span>'
	            +     '<span class="type-tag">' + typeLabel + '</span>'
	            +   '</div>'
	            +   '<div class="change">'
	            +     '<span class="' + valClass(it.del_old_value) + '">' + valLabel(it.del_old_value) + '</span>'
	            +     ' &rarr; '
	            +     '<span class="' + valClass(it.del_new_value) + '">' + valLabel(it.del_new_value) + '</span>'
	            +     ' <span style="color:#aaa;">(' + esc(it.del_old_value) + '→' + esc(it.del_new_value) + ')</span>'
	            +   '</div>'
	            + '</div>';
	    });
	    bodyEl.innerHTML = html;
	  }

	  function loadErrorLog(dvId, dvName){
	    titleEl.textContent = (dvName ? dvName : '디바이스') + ' 이상 로그';
	    bodyEl.innerHTML = '<div class="err-log-empty">불러오는 중...</div>';
	    openPanel();

	    fetch(CONTEXT_PATH + '/deviceErrorLog/list?dvId=' + encodeURIComponent(dvId) + '&limit=30',
	          { headers: { 'X-Requested-With': 'XMLHttpRequest' }, credentials: 'same-origin', cache: 'no-store' })
	      .then(function(r){ if(!r.ok) throw new Error('http ' + r.status); return r.json(); })
	      .then(renderLogs)
	      .catch(function(e){
	        console.error('이상 로그 조회 실패', e);
	        bodyEl.innerHTML = '<div class="err-log-empty">이상 로그를 불러오지 못했습니다.</div>';
	      });
	  }

	  document.addEventListener('DOMContentLoaded', function(){
	    // 로그 버튼(이벤트 위임 — 페이지 재조회 후에도 유지)
	    document.querySelector('#deviceTable').addEventListener('click', function(e){
	      var btn = e.target.closest('.err-log-btn');
	      if(!btn) return;
	      loadErrorLog(btn.getAttribute('data-dv-id'), btn.getAttribute('data-dv-name'));
	    });
	    document.getElementById('errLogClose').addEventListener('click', closePanel);
	    backdrop.addEventListener('click', closePanel);
	    document.addEventListener('keydown', function(e){
	      if(e.key === 'Escape' && panel.classList.contains('open')) closePanel();
	    });

	    // ===== 알림 클릭 이동 수신 처리 (15번 4-2) =====
	    var params = new URLSearchParams(window.location.search);

	    // (A) 장비이상 알림 → 해당 디바이스 이상 로그 패널 자동 열기
	    if(params.get('openErrorLog') === 'true'){
	      var dvId = params.get('dvId');
	      if(dvId){
	        var row = document.getElementById('device-' + dvId);
	        var nameCell = row ? row.querySelector('.cell-ellipsis') : null;
	        var dvName = nameCell ? nameCell.textContent.trim() : '';
	        loadErrorLog(dvId, dvName);
	        if(row){ row.scrollIntoView({ behavior: 'smooth', block: 'center' }); }
	      }
	    }

	    // (B, 19번 이슈B) 응급콜 알림 → 시리얼로 행 자동 선택 + 실시간 영상 버튼 강조(유도 UX).
	    //   기존에는 "현재 렌더된 페이지"에서만 행을 찾아, 페이지네이션·정렬로 대상 디바이스가
	    //   1페이지에 없으면 조용히 실패했다. 이제는 못 찾으면 기존 디바이스 검색 기능을
	    //   시리얼 값으로 자동 실행해 1건으로 좁힌 뒤 다시 확인한다.
	    var triggerSerial = params.get('triggerSerial');
	    if(triggerSerial){
	      var esc = (window.CSS && CSS.escape) ? CSS.escape(triggerSerial) : triggerSerial;
	      var trow = document.querySelector('#deviceTable tr[data-serial="' + esc + '"]');

	      if(!trow && params.get('searchKeyword') !== triggerSerial){
	        // 현재 페이지에 없고, 아직 이 시리얼로 검색해보지 않았다면 → 검색 자동 실행(1건으로 좁혀서 확실히 찾기)
	        location.href = CONTEXT_PATH + '/deviceList/viewDeviceList.do?page=1&searchKeyword='
	          + encodeURIComponent(triggerSerial) + '&triggerSerial=' + encodeURIComponent(triggerSerial);
	        return;
	      }

	      if(trow){
	        trow.style.transition = 'background .3s';
	        trow.style.background = 'rgba(236,231,251,0.95)';
	        trow.scrollIntoView({ behavior: 'smooth', block: 'center' });

	        // 실시간 영상 버튼 시각적 강조 + 안내 툴팁으로 클릭 유도(자동실행 미보장 대비)
	        var videoBtn = trow.querySelector('.video-btn');
	        if(videoBtn){
	          videoBtn.classList.add('trigger-guide-flash');
	          var tip = document.createElement('div');
	          tip.className = 'trigger-guide-tooltip';
	          tip.textContent = '응급콜 발생 — 여기를 눌러 실시간 영상을 확인하세요';
	          document.body.appendChild(tip);
	          var positionTip = function(){
	            var r = videoBtn.getBoundingClientRect();
	            tip.style.left = (r.left + r.width / 2 + window.scrollX) + 'px';
	            tip.style.top = (r.top + window.scrollY) + 'px';
	          };
	          positionTip();
	          requestAnimationFrame(function(){ tip.classList.add('show'); });
	          setTimeout(function(){
	            tip.classList.remove('show');
	            setTimeout(function(){ tip.remove(); }, 300);
	          }, 6000);
	          videoBtn.addEventListener('click', function(){ tip.remove(); }, { once: true });
	        }

	        // (참고, 19번 §3-4) 기존 자동실행 시도는 안전망으로 남겨둠 — 성공하면 위 유도 UX가
	        // 무의미해지고, 브라우저 정책 등으로 실패해도 유도 UX가 있어 문제 없음.
	        var dvId2 = trow.getAttribute('data-dv-id');
	        if(dvId2 && typeof viewRealTimeVideoPopup === 'function'){
	          setTimeout(function(){ viewRealTimeVideoPopup(dvId2); }, 400);
	        }
	      } else {
	        console.warn('triggerSerial 에 해당하는 디바이스를 찾지 못했습니다(검색 후에도 없음):', triggerSerial);
	      }
	    }
	  });
	})();
	</script>

