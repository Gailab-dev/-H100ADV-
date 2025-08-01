<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>eventDetail</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/eventDetail.css">
<script>
	
	// 불법 주차 리스트 화면으로 이동
	function goToEventList(){
		location.href ="viewEventList.do?&page=${page}&startDate=${startDate}&endDate=${endDate}&searchKeyword=${searchKeyword}";
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
			<h3 class="detail-title">불법주차 리스트 상세</h3>
			
			<!-- 상세 이미지 -->
			<div class="image-wrapper">
				<img src="/gov-disabled-web-gs/eventList/imageView.do?filePath=${eventListDetail.ev_img_path}" alt="불법주차 리스트 상세 이미지" class="detail-image">
			</div>
			<!-- 상세 정보 -->
			<div class="detail-table-wrapper">
				<table class="detail-table">
					<tr>
						<th>날짜</th>
						<td>${eventListDetail.ev_date}</td>
					</tr>
					<tr>
						<th>위치</th>
						<td>${eventListDetail.dv_addr}</td>
					</tr>
					<tr>
						<th>차량번호</th>
						<td>${eventListDetail.ev_car_num}</td>
					</tr>
					<tr>
						<th>유형</th>
						<td>
							<c:choose>
								<c:when test="${eventListDetail.ev_cd == 1}">비장애인 주차 🚫</c:when>
								<c:when test="${eventListDetail.ev_cd == 2}">장애인 미등록차량 🚫</c:when>
								<c:when test="${eventListDetail.ev_cd == 3}">스티커 불법 사용</c:when>
								<c:when test="${eventListDetail.ev_cd == 4}">위험상황</c:when>
								<c:when test="${eventListDetail.ev_cd == 5}">물건적재</c:when>
								<c:otherwise>기타</c:otherwise>
							</c:choose>
						</td>
					</tr>
				</table>
			</div>
		
			<!-- 돌아가기 버튼 -->
			<div class="back-btn-wrapper">
				<button onclick="goToEventList()" class="back-btn">← 돌아가기</button>
			</div>   
        </div>    
    </div>    
    <footer class="footer">
        <p>&copy; 2025 GAILAB</p>
    </footer>
</body>
</html>