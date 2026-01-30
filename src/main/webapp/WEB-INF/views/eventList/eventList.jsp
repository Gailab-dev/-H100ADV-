<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/eventList.css">
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/pagination.css">
<title>eventList</title>

<%-- 상세 보기 버튼 클릭시 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
<c:if test="${not empty param.errorMsg}">
	<script>
	alert('<c:out value="${param.errorMsg}" />');
	
    // ✅ URL에서 errorMsg 제거, 새로고침 등으로 오류 메시지 재출력 방지
    const url = new URL(window.location.href);
    url.searchParams.delete('errorMsg');
    history.replaceState(null, '', url.toString());
</script>
</c:if>
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
	    
	    
	    location.href = 'eventListDetail?dvId='+dvId+'&evId='+ evId + "&page=${page}&startDate=" + startDate + "&endDate=" + endDate + "&searchKeyword=" + searchKeyword +"&dvAddr="+dvAddr+"&pageSize="+pageSize;
	}
	
	// 검색 조건에 따른 검색
	window.searchEventList = function(pageNo){
		
		let form = document.getElementById('eventListSearchForm');
	  	const startDate = form.elements['startDate']?.value; // 'yyyy-MM-dd'
	  	const endDate   = form.elements['endDate']?.value;
	  	const evCd = form.elements['evCd']?.value;
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
		
		location.href = "viewEventList.do?page=" + pageNo + "&startDate=" + startDate + "&endDate=" + endDate + "&evCd=" + evCd + "&searchKeyword=" + searchKeyword +"&pageSize="+pageSize;
		
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
</head>
<body>
	<div class=page-wrapper>
		<!-- 헤더 -->
		<header class="header">
			<div class="logo">
				<img
					src="${pageContext.request.contextPath}/resources/images/지아이랩-로고.png"
					alt="GAILAB" class="header-icon">
			</div>

			<div class="right-group">
				<c:if test="${useTblLog == false}">
					<div class="alert alert-warning">현재 로그 데이터 저장 공간이 매우 부족합니다.
						관리자에게 문의해주세요.</div>
				</c:if>
				<div class="user">
					<span class="user-name">
						<c:out value="${uName}" escapeXml="true" />
					</span>
				</div>
				<div class="logout">
					<button
						onclick="location.href='${pageContext.request.contextPath}/user/logout'">로그아웃</button>
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
						href="${pageContext.request.contextPath}/myInfo/viewMyInfo.do">
							<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M9.99998 3.33325C10.884 3.33325 11.7319 3.68444 12.357 4.30956C12.9821 4.93468 13.3333 5.78253 13.3333 6.66659C13.3333 7.55064 12.9821 8.39849 12.357 9.02361C11.7319 9.64873 10.884 9.99992 9.99998 9.99992C9.11592 9.99992 8.26808 9.64873 7.64296 9.02361C7.01784 8.39849 6.66665 7.55064 6.66665 6.66659C6.66665 5.78253 7.01784 4.93468 7.64296 4.30956C8.26808 3.68444 9.11592 3.33325 9.99998 3.33325ZM9.99998 4.99992C9.55795 4.99992 9.13403 5.17551 8.82147 5.48807C8.50891 5.80063 8.33331 6.22456 8.33331 6.66659C8.33331 7.10861 8.50891 7.53254 8.82147 7.8451C9.13403 8.15766 9.55795 8.33325 9.99998 8.33325C10.442 8.33325 10.8659 8.15766 11.1785 7.8451C11.4911 7.53254 11.6666 7.10861 11.6666 6.66659C11.6666 6.22456 11.4911 5.80063 11.1785 5.48807C10.8659 5.17551 10.442 4.99992 9.99998 4.99992ZM9.99998 10.8333C12.225 10.8333 16.6666 11.9416 16.6666 14.1666V16.6666H3.33331V14.1666C3.33331 11.9416 7.77498 10.8333 9.99998 10.8333ZM9.99998 12.4166C7.52498 12.4166 4.91665 13.6333 4.91665 14.1666V15.0833H15.0833V14.1666C15.0833 13.6333 12.475 12.4166 9.99998 12.4166Z"
 fill="currentColor"/>
</svg>내 정보
					</a></li>




					<!-- 
                <li><a href="${pageContext.request.contextPath}/local/viewLocalManage.do"><img src="${pageContext.request.contextPath}/resources/images/icon_parking.png" alt="불법주차" class="menu-icon">지역 관리</a></li>
            	 -->
				</ul>
			</aside>
			<div class="content">
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
										<td><span class="cell-ellipsis"
											title="${fn:escapeXml(item.ev_date)}"> <c:out
													value="${item.ev_date}" escapeXml="true" />
										</span></td>
										<td><c:choose>
												<c:when test="${item.ev_cd eq 1}">미등록차량</c:when>
												<c:when test="${item.ev_cd eq 4}">위험상황</c:when>
												<c:when test="${item.ev_cd eq 5}">물건적재</c:when>
												<c:when test="${item.ev_cd eq 6}">이중주차</c:when>
												<c:otherwise>기타</c:otherwise>
											</c:choose></td>
										<td><span class="cell-ellipsis"
											title="${fn:escapeXml(item.dv_name)}"> <c:out
													value="${item.dv_name}" escapeXml="true" />
										</span></td>
										<td><span class="cell-ellipsis"
											title="${fn:escapeXml(item.dv_addr)}"> <c:out
													value="${item.dv_addr}" escapeXml="true" />
										</span></td>
										<td><span class="cell-ellipsis"
											title="${fn:escapeXml(item.ev_car_num)}"> <c:out
													value="${item.ev_car_num}" escapeXml="true" />
										</span></td>
										<td><button
												onclick="eventListDetail(${item.dv_id},${item.ev_id},'${item.dv_addr}')"
												class="detailButton">상세보기</button></td>
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
</body>
</html>