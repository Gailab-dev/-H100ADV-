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

<!-- 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 -->
<c:if test="${not empty param.errorMsg}">
<script>
	alert('<c:out value="${param.errorMsg}" />');
</script>
</c:if>
<!-- 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 -->
<script>
	 
	// pagination 객체를 활용한 페이지 이동
	window.goPage = function(pageNo){
		let startDate = encodeURIComponent('${startDate != null ? startDate : ""}');
    	let endDate   = encodeURIComponent('${endDate != null ? endDate : ""}');
    	let searchKeyword   = encodeURIComponent('${searchKeyword != null ? searchKeyword : ""}');
		location.href = "viewEventList.do?page=" + pageNo + "&startDate=" + startDate + "&endDate=" + endDate + "&searchKeyword=" + searchKeyword;
	}
	 
	
		
	// 상세보기 클릭시 불법주차 상세 화면으로 이동
	window.eventListDetail = function(evId){
		let startDate = encodeURIComponent('${startDate != null ? startDate : ""}');
	    let endDate   = encodeURIComponent('${endDate != null ? endDate : ""}');
	    let searchKeyword   = encodeURIComponent('${searchKeyword != null ? searchKeyword : ""}');
		location.href = 'eventListDetail?evId='+ evId + "&page=${page}&startDate=" + startDate + "&endDate=" + endDate + "&searchKeyword=" + searchKeyword;
	}
	
	// 검색 조건에 따른 검색
	window.searchEventList = function(pageNo){
		
		let form = document.getElementById('eventListSearchForm');
	  	const startDate = form.elements['startDate'].value; // 'yyyy-MM-dd'
	  	const endDate   = form.elements['endDate'].value;
	  	const searchKeyword   = form.elements['searchKeyword'].value;
	  	
	  	if( searchKeyword.length >= 100 ){
	  		alert("검색어는 100자를 넘을 수 없습니다.");
	  		return;
	  	}
		
		if( startDate > endDate ){
			alert("날짜를 확인해주세요.");
			return;
		}
		
		location.href = "viewEventList.do?page=" + pageNo + "&startDate=" + startDate + "&endDate=" + endDate + "&searchKeyword=" + searchKeyword;
		
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
	    <div class="user">
	      <img src="${pageContext.request.contextPath}/resources/images/user.png"
	           alt="유저" class="user-image">
	      <span class="user-name">hskim</span>
	    </div>
	    <div class="logout">
	      <button onclick="location.href='/gov-disabled-web-gs/stats/logout'">로그아웃</button>
	    </div>
	  </div>
	</header>
    <div class="container">
		<aside class="sidebar">
            <ul class="menu">
                <li><a href="/gov-disabled-web-gs/stats/viewStat.do"><img src="${pageContext.request.contextPath}/resources/images/icon_home.png" alt="홈" class="menu-icon">홈</a></li>
                <li><a href="/gov-disabled-web-gs/deviceList/viewDeviceList.do"><img src="${pageContext.request.contextPath}/resources/images/icon_device.png" alt="디바이스" class="menu-icon">디바이스 리스트</a></li>
                <li><a href="/gov-disabled-web-gs/eventList/viewEventList.do"><img src="${pageContext.request.contextPath}/resources/images/icon_parking.png" alt="불법주차" class="menu-icon">불법주차 리스트</a></li>
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
					<input type="text" name="searchKeyword" value="${searchKeyword}" placeholder="검색어" />
				</div>
				<button type="button" class="search-btn" onclick="searchEventList('${paginationInfo.currentPageNo != null ? paginationInfo.currentPageNo : 1}')">조회</button>
			</form>
			<table class="event-table">
				<thead>
					<tr>
						<th>  </th>
						<th>날짜</th>
						<th>위치</th>
						<th>차량번호</th>
						<th>유형</th>
						<th></th>
					</tr>
				</thead>
				<tbody>
					<c:forEach var="item" items="${eventList}">
						<tr>
							<td>${item.ev_id}</td>
							<td>${item.ev_date}</td>
							<td>${item.dv_addr}</td>
							<td>${item.ev_car_num}</td>
							<td>
								<c:choose>
									<c:when test="${item.ev_cd == 1}">비장애인 주차</c:when>
									<c:when test="${item.ev_cd == 2}">장애인 미등록차량</c:when>
									<c:when test="${item.ev_cd == 3}">스티커 불법 사용</c:when>
									<c:when test="${item.ev_cd == 4}">위험상황</c:when>
									<c:when test="${item.ev_cd == 5}">물건적재</c:when>
									<c:when test="${item.ev_cd == 6}">이중주차</c:when>
									<c:otherwise>기타</c:otherwise>
								</c:choose>
							</td>
							<td><button onclick="eventListDetail(${item.ev_id})">상세보기</button></td>
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