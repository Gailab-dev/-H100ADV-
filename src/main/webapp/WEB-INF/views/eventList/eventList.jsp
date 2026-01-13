<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %> 

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/eventList.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/pagination.css">
<title>eventList</title>

<%-- 상세 보기 버튼 클릭시 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
<c:if test="${not empty param.errorMsg}">
<script>
	alert('<c:out value="${param.errorMsg}" />');
</script>
</c:if>
<%-- 상세 보기 버튼 클릭시 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
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
<%--  web.xml의 session time out 전역 변수, session time out 함수 --%>
<script>
   	window.SESSION_TIMEOUT_SECONDS = <%= session.getMaxInactiveInterval() %>;
   	const CONTEXT_PATH = "${pageContext.request.contextPath}";
</script>
<script src="${pageContext.request.contextPath}/resources/js/interceptor/sessionManager.js"></script>
<%--  web.xml의 session time out 전역 변수, session time out 함수 --%>
<script>
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
	});
	 
	// pagination 객체를 활용한 페이지 이동
	window.goPage = function(pageNo){
		let startDate = encodeURIComponent('${startDate != null ? startDate : ""}');
    	let endDate   = encodeURIComponent('${endDate != null ? endDate : ""}');
    	let searchKeyword   = encodeURIComponent('${searchKeyword != null ? searchKeyword : ""}');
		let pageSize = encodeURIComponent('${pageSize != null ? pageSize : ""}');
    	location.href = "viewEventList.do?page=" + pageNo + "&startDate=" + startDate + "&endDate=" + endDate + "&searchKeyword=" + searchKeyword +"&pageSize="+pageSize;
	}
		
	// 상세보기 클릭시 불법주차 상세 화면으로 이동
	window.eventListDetail = function(evId){
		let startDate = encodeURIComponent('${startDate != null ? startDate : ""}');
	    let endDate   = encodeURIComponent('${endDate != null ? endDate : ""}');
	    let searchKeyword   = encodeURIComponent('${searchKeyword != null ? searchKeyword : ""}');
	    let pageSize = encodeURIComponent('${pageSize != null ? pageSize : ""}');
	    location.href = 'eventListDetail?dvId='+dvId+'&evId='+ evId + "&page=${page}&startDate=" + startDate + "&endDate=" + endDate + "&searchKeyword=" + searchKeyword +"&dvAddr="+dvAddr+"&pageSize="+pageSize;
	}
	
	// 검색 조건에 따른 검색
	window.searchEventList = function(pageNo){
		
		let form = document.getElementById('eventListSearchForm');
	  	const startDate = form.elements['startDate'].value; // 'yyyy-MM-dd'
	  	const endDate   = form.elements['endDate'].value;
	  	const evCd = form.elements['evCd'].value;
	  	const searchKeyword   = form.elements['searchKeyword'].value;
	 	const pageSize = document.getElementById('pageSize')?.value;
	  	
	  	if( searchKeyword.length >= 100 ){
	  		alert("검색어는 100자를 넘을 수 없습니다. \n 모든 문자 입력 가능합니다.");
	  		return;
	  	}
		
		if( startDate > endDate ){
			alert("날짜를 확인해주세요.");
			return;
		}
		
	  	// 검색 파라미터 변경으로 인한 페이지 번호 1로 변경
	  	pageNo = Math.max(1, Number.isFinite(+pageNo) ? Math.trunc(+pageNo) : 0);
		
		location.href = "viewEventList.do?page=" + pageNo + "&startDate=" + startDate + "&endDate=" + endDate + "$evCd=" + evCd + "&searchKeyword=" + searchKeyword +"&pageSize="+pageSize;
		
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
				  
		    // 현재 정렬 상태 (Controller에서 model로 내려준 값 사용)
		    let currentSortCol = '${sortCol != null ? sortCol : "ev_id"}';
		    let currentSortDir = '${sortDir != null ? sortDir : "DESC"}';
			
		    //각 정렬 버튼 별 이벤트 추가
		    document.querySelectorAll('.sort-btn').forEach(btn => {
		        
		    	// 정렬 대상이 되는 컬럼
		    	const col = btn.dataset.column;

		        // 🔹 현재 정렬 컬럼 표시
		        if (col === currentSortCol) {
		            btn.classList.add('active');
		            if (currentSortDir === 'ASC') {
		                btn.classList.add('asc');
		            }
		        }

		        btn.addEventListener('click', function () {
		            let nextDir = 'DESC';

		            // 같은 컬럼 클릭 → ASC / DESC 토글
		            if (currentSortCol === col) {
		                nextDir = (currentSortDir === 'DESC') ? 'ASC' : 'DESC';
		            }

		            // 🔹 기존 파라미터 유지
		            const url = new URL(window.location.href);
					
		            // 정렬 컬럼, 정렬 방법 파라미터 추가
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
		
		async function excelDownload(){
			
			let form = document.getElementById('deviceListSearchForm');
		  	let val1 = form.elements['searchKeyword'].value;
		  	let searchKeyword = encodeURIComponent(val);
		  	let val2 = form.elements['startDate'].value;
		  	let startDate = encodeURIComponent(val2);
		  	let val3 = form.elemntes['endDate'].vlaue;
		  	let endDate = encodeURIComponet(val3);
		  	let pageSize = document.getElementById('pageSize')?.value;
			
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
		// --------------------------- 엑셀 다운로드 -----------------------------

	
</script>
</head>
<body>
	<div class=page-wrapper>
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
            	<li><a href="${pageContext.request.contextPath}/eventList/viewEventList.do"><img src="${pageContext.request.contextPath}/resources/images/icon_parking.png" alt="불법주차" class="menu-icon">불법주차 리스트</a></li>
                <li><a href="${pageContext.request.contextPath}/stats/viewStat.do"><img src="${pageContext.request.contextPath}/resources/images/icon_home.png" alt="홈" class="menu-icon">통계</a></li>
                <li><a href="${pageContext.request.contextPath}/deviceList/viewDeviceList.do"><img src="${pageContext.request.contextPath}/resources/images/icon_device.png" alt="디바이스" class="menu-icon">디바이스 리스트</a></li>
                <!-- 
                <li><a href="${pageContext.request.contextPath}/local/viewLocalManage.do"><img src="${pageContext.request.contextPath}/resources/images/icon_parking.png" alt="불법주차" class="menu-icon">지역 관리</a></li>
            	 -->
            </ul>
        </aside>
        <div class="content">
			<form id="eventListSearchForm" action="/gov-disabled-web-gs/eventList/viewEventList.do" class="filter-form">
				<div class="filter-input-group">
					<input type="date" name="startDate" value="${startDate}" />
				</div>
				<div class="filter-input-group">
					<input type="date" name="endDate" value="${endDate}" />
				</div>
				<div class="filter-input-group">
					<select name="evCd">
						<option ${evCd == null ? 'selected' : '' }>유형</option>
						<option value="1" ${evCd == 1 ? 'selected' : ''}>미등록차량</option>
						<%-- 2025. 10. 28. 장애인 미탑승, 스티커 불법 사용 식별 불가 --%>
						<%-- 
						<option value="2" ${evCd == 2 ? 'selected' : ''}>불법주차(장애인미탑승)</option>
						<option value="3" ${evCd == 3 ? 'selected' : ''}>스티커 불법 사용</option>
						 --%>
						<option value="4" ${evCd == 4 ? 'selected' : ''}>위험상황</option>
						<option value="5" ${evCd == 5 ? 'selected' : ''}>물건적재</option>
						<option value="6" ${evCd == 6 ? 'selected' : ''}>이중주차</option>
					</select>
				</div>
				<div class="filter-input-group search-field">
					<input type="text" name="searchKeyword" value="${searchKeyword}" placeholder="검색어" maxlength="100"/>
				</div>

				<div class="filter-input-group">
					<select id="pageSize" name="pageSize" onchange="searchEventList()">
        				<option value="10" ${pageSize == 10 ? 'selected' : ''}>10개씩 보기</option>
        				<option value="20" ${pageSize == 20 ? 'selected' : ''}>20개씩 보기</option>
        				<option value="30" ${pageSize == 30 ? 'selected' : ''}>30개씩 보기</option>
    				</select>
				</div>
				<button type="button" class="search-btn" onclick="searchEventList('${paginationInfo.currentPageNo != null ? paginationInfo.currentPageNo : 1}')">조회</button>
			</form>
		  	<div class="bulk-actions">
		    	<svg width="16" height="16" viewBox="0 0 16 16" fill="none"
		         xmlns="http://www.w3.org/2000/svg">
		      		<rect width="16" height="16" rx="4" fill="#6955A2"/>
		      		<path d="M4 9V7H12V9H4Z" fill="white"/>
		    	</svg>
		    
		    	<span class="selected-text">0개 선택됨</span>
		    
		    	<button type="button" class="delete-btn" onclick="viewDeleteDevicePopup()" title="삭제">
			      	<svg width="20" height="20" viewBox="0 0 20 20" fill="none"
			           xmlns="http://www.w3.org/2000/svg">
			        	<path d="M11.75 9.11111V14.4444M8.25 9.11111V14.4444M4.75 5.55556V16.2222C4.75 16.6937 4.93437 17.1459 5.26256 17.4793C5.59075 17.8127 6.03587 18 6.5 18H13.5C13.9641 18 14.4092 17.8127 14.7374 17.4793C15.0656 17.1459 15.25 16.6937 15.25 16.2222V5.55556M3 5.55556H17M5.625 5.55556L7.375 2H12.625L14.375 5.55556"
			              stroke="black" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
			      	</svg>
		    	</button>
	    		<button type="button" class="excel-btn" onclick="excelDownload()" title="엑셀 다운로드">
					<img src="${pageContext.request.contextPath}/resources/images/icon_excel.png" alt="엑셀 다운로드">
	    		</button>
			</div>
			<table class="event-table">
				<thead>
					<tr>
						<th><input type="checkbox" id="checkAll" /></th>
						<th>번호</th>
						<th>
							날짜
							<button class="sort-btn" data-column="ev_date"></button>
						</th>
						<th>
							유형
							<button class="sort-btn" data-column="ev_cd"></button>
						</th>
						<th>
							디바이스명
							<button class="sort-btn" data-column="dv_name"></button>
						</th>
						<th>
							디바이스주소
							<button class="sort-btn" data-column="dv_addr"></button>
						</th>
						<th>
							차량번호
							<button class="sort-btn" data-column="ev_car_num"></button>
						</th>
						<th>상세</th>
					</tr>
				</thead>
				<tbody>
					<c:if test="${empty eventList}">
						<tr>
							<td colspan="6" style="text-align:center;">조회된 불법주차 내역이 없습니다.</td>
						</tr>
					</c:if>
			
					<c:forEach var="item" items="${eventList}">
						<tr>
							<td>
								<c:out value="${totalRecordCount - item.rn + 1}" escapeXml ="true"/>						
							</td>
							<td>
								<span class="cell-ellipsis" title="${fn:escapeXml(item.ev_date)}">
									<c:out value="${item.ev_date}" escapeXml ="true"/>
								</span>
							</td>
							<td>
								<%--  2025. 10. 28. 장애인 미탑승, 스티커 불법 사용 식별 불가 --%>
								<c:choose>
									<c:when test="${item.ev_cd eq 1}">미등록차량</c:when>
									<%-- 
									<c:when test="${item.ev_cd eq 2}">불법주차(장애인미탑승)</c:when>
									<c:when test="${item.ev_cd eq 3}">스티커 불법 사용</c:when>
									--%>
									<c:when test="${item.ev_cd eq 4}">위험상황</c:when>
									<c:when test="${item.ev_cd eq 5}">물건적재</c:when>
									<c:when test="${item.ev_cd eq 6}">이중주차</c:when>
									<c:otherwise>기타</c:otherwise>
								</c:choose>
							</td>
							<td>
								<span class="cell-ellipsis" title="${fn:escapeXml(item.dv_name)}">
									<c:out value="${item.dv_name}" escapeXml ="true"/>
								</span>
							</td>
							<td>
								<span class="cell-ellipsis" title="${fn:escapeXml(item.dv_addr)}">
									<c:out value="${item.dv_addr}" escapeXml ="true"/>
								</span>
							</td>
							<td>
								<span class="cell-ellipsis" title="${fn:escapeXml(item.ev_car_num)}">
									<c:out value="${item.ev_car_num}" escapeXml ="true"/>
								</span>
							</td>
							
							<td><button onclick="eventListDetail(${item.dv_id},${item.ev_id},'${item.dv_addr }')">상세보기</button></td>
						</tr>
					</c:forEach>
				</tbody>
			</table>
			<div class="pagination">
				<ui:pagination paginationInfo="${paginationInfo}" type="text" jsFunction="goPage"/>
			</div>
        </div>  
    </div>
	<</div>
</body>
</html>