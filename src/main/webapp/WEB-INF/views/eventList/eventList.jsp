<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
<script>
	  
	// 상세보기 클릭시 불법주차 상세 화면으로 이동
	function eventListDetail(evId){
		location.href = 'eventListDetail?evId='+ evId + "&page=${page}&startDate=${startDate}&endDate=${endDate}&searchKeyword=${searchKeyword}";
	}
	
	// pagination 객체를 활용한 페이지 이동
	function goPage(pageNo){
		location.href = "viewEventList.do?page=" + pageNo + "&startDate=${startDate}&endDate=${endDate}&searchKeyword=${searchKeyword}";
	}
	
</script>
</head>
<body>
	<div>
		<div>
			<form action="/eventList/viewEventList.do">
				<input type="date" value="${startDate}"/>
				<input type="date" value="${endDate}"/>
				<input type="text" value="${searchKeyword}"/>
				<input type="submit"/>
			</form>
		</div>
		<div>
			<table>
				<thead>
					<th>
						<td> <img src="" > </td>
						<td> 날짜 </td>
						<td> 위치 </td>
						<td> 차량번호 </td>
						<td> 내용 </td>
						<td>  </td>
					</th>
				</thead>
				<tbody>
					<c:forEach var="item" items="${ eventList }">
						<tr>
							<td> <input type="checkbox" alt="불법주차 리스트 선택 체크박스"/> </td>
							<td> ${item.ev_date } </td>
							<td> ${item.dv_addr } </td>
							<td> ${item.ev_car_num } </td>
							<td> ${item.ev_cd } </td>
							<td> <button onclick="eventListDetail(${item.ev_id})">상세보기</button> </td>
						</tr>
					</c:forEach>
				
				</tbody>
			</table>
		
		</div>
			<ui:pagination paginationInfo="${paginationInfo}" type="image" jsFunction="goPage"/>
		
	</div>
</body>
</html>