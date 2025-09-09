<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/eventList.css">
<title>eventList</title>
<script>
	  
	// 상세보기 클릭시 불법주차 상세 화면으로 이동
	function eventListDetail(evId){
		let startDate = encodeURIComponent('${startDate != null ? startDate : ""}');
	    let endDate   = encodeURIComponent('${endDate != null ? endDate : ""}');
	    let keyword   = encodeURIComponent('${searchKeyword != null ? searchKeyword : ""}');
		location.href = 'eventListDetail?evId='+ evId + "&page=${page}&startDate=" + startDate + "&endDate=" + endDate + "&searchKeyword=" + searchKeyword";
	}
	
	// pagination 객체를 활용한 페이지 이동
	function goPage(pageNo){
		let startDate = encodeURIComponent('${startDate != null ? startDate : ""}');
	    let endDate   = encodeURIComponent('${endDate != null ? endDate : ""}');
	    let keyword   = encodeURIComponent('${searchKeyword != null ? searchKeyword : ""}');
		location.href = "viewEventList.do?page=" + pageNo + "&startDate=" + startDate + "&endDate=" + endDate + "&searchKeyword=" + searchKeyword;
	}
	
	// 검색 조건에 따른 검색
	function searchEventList(pageNo){
		
		console.log(pageNo);
		
		let form = document.getElementById('eventListSearchForm');
	  	const startDate = form.elements['startDate'].value; // 'yyyy-MM-dd'
	  	const endDate   = form.elements['endDate'].value;
	  	const keyword   = form.elements['searchKeyword'].value;
	  	
	  	if( keyword.length >= 100 ){
	  		alert("검색어는 100자를 넘을 수 없습니다.");
	  		return;
	  	}
		
		if( startDate > endDate ){
			alert("날짜를 확인해주세요.");
			return;
		}
		
		location.href = "viewEventList.do?page=" + pageNo + "&startDate=" + startDate + "&endDate=" + endDate + "&searchKeyword=" + searchKeyword;
		
	}
	
</script>
</head>
<body>
	<!-- 헤더 -->
    <header class="header">
        <div class="logo">
        	<img src="${pageContext.request.contextPath}/resources/images/지아이랩-로고.png" alt="GAILAB" class="header-icon">
        </div>
        <div class="user">
        	<img src="${pageContext.request.contextPath}/resources/images/user.png" alt="유저" class="user-image">
        	<span class="user-name">hskim</span>
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
				<ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="goPage"/>
			</div>
        </div>  
    </div>
</body>
</html>