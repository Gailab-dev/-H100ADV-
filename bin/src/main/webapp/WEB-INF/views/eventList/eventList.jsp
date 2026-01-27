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
		
		location.href = "viewEventList.do?page=" + pageNo + "&startDate=" + startDate + "&endDate=" + endDate + "&searchKeyword=" + searchKeyword +"&pageSize="+pageSize;
		
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
</script>
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
			<table class="event-table">
				<thead>
					<tr>
						<th></th>
						<th>날짜</th>
						<th>위치</th>
						<th>차량번호</th>
						<th>유형</th>
						<th></th>
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
								<span class="cell-ellipsis" title="${fn:escapeXml(item.dv_addr)}">
									<c:out value="${item.dv_addr}" escapeXml ="true"/>
								</span>
							</td>
							<td>
								<span class="cell-ellipsis" title="${fn:escapeXml(item.ev_car_num)}">
									<c:out value="${item.ev_car_num}" escapeXml ="true"/>
								</span>
							</td>
							<td>
								<!-- 2025. 10. 28. 장애인 미탑승, 스티커 불법 사용 식별 불가 -->
								<c:choose>
									<c:when test="${item.ev_cd eq 1}">미등록차량</c:when>
									<%-- 
									<c:when test="${item.ev_cd == 2}">불법주차(장애인미탑승)</c:when>
									<c:when test="${item.ev_cd == 3}">스티커 불법 사용</c:when>
									--%>
									<c:when test="${item.ev_cd eq 4}">위험상황</c:when>
									<c:when test="${item.ev_cd eq 5}">물건적재</c:when>
									<c:when test="${item.ev_cd eq 6}">이중주차</c:when>
									<c:otherwise>기타</c:otherwise>
								</c:choose>
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
</body>
</html>