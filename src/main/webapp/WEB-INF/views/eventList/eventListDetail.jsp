<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
<script>
	
	// 불법 주차 리스트 화면으로 이동
	function goToEventList(){
		location.href ="viewEventList.do?&page=${page}&startDate=${startDate}&endDate=${endDate}&searchKeyword=${searchKeyword}";
	}
</script>
</head>
<body>
	<div>
		<div>
			<h3>불법 주차 리스트 상세</h3>
		</div>
		<div>
			<img src="" alt="불법주차 리스트 상세 이미지">
		</div>
		<div>
			<table>
				<tr>
					<th> 날짜 </th>
					<td> ${eventListDetail.ev_date} </td>
				</tr>
				<tr>
					<th> 위치 </th>
					<td> ${eventListDetail.dv_addr} </td>
				</tr>
				<tr>
					<th> 차량번호 </th>
					<td> ${eventListDetail.ev_car_num} </td>
				</tr>
				<tr>
					<th> 내용 </th>
					<td>
						<c:choose>
							<c:when test="${eventListDetail.ev_cd == 1}">불법주차(미등록차량)</c:when>
							<c:when test="${eventListDetail.ev_cd == 2}">불법주차(장애인미탑승)</c:when>
							<c:when test="${eventListDetail.ev_cd == 3}">스티커 불법 사용</c:when>
							<c:when test="${eventListDetail.ev_cd == 4}">위험상황</c:when>
							<c:when test="${eventListDetail.ev_cd == 5}">물건적재</c:when>
							<c:otherwise> 기타 </c:otherwise>
						</c:choose>
					</td>
				</tr>
			</table>
		</div>
		<div>
			<button onclick="goToEventList()"> 돌아가기 </button>
		</div>
	</div>
</body>
</html>