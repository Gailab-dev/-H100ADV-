<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="ui" uri="http://egovframework.gov/ctl/ui"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/stats.css">

<title>Insert title here</title>
</head>
<script src="https://code.jquery.com/jquery-3.3.1.min.js"></script>
<script src="https://d3js.org/d3.v5.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/c3/0.7.8/c3.min.js"></script>
	<!-- 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 -->
	<script>
	  <c:if test="${not empty errorMsg}">
	    alert('<c:out value="${errorMsg}" />');
	  </c:if>
	</script>
	<!-- 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 -->
<body>
	<div>
		<div>
			<input type="date" id="startDate" value="${startDate }">
			<input type="date" id="endDate" value="${endDate }">
			<select>
				<option checked>유형</option>
			</select>
			<input type="text" id="searchKeyword" placeholder="디바이스 명 및 주소 검색" value="${searchKeyword }">
		</div>
		
		<div>
			<c:choose>
				<c:when test="">
					<table>
						<thead>
							<tr>
								<td>번호</td>
								<td>아이디</td>
								<td>가입일자</td>
								<td>허용권한</td>
								<td>회원권한 수정</td>
								<td>회원 삭제</td>
							</tr>
						</thead>
						<tbody>
							<c:forEach var="item" items="${userManageList}" varStatus="varStatus">
								<tr>
									<td></td>
									<td>${item.u_login_id }</td>
									<td>${item.u_reg_user }</td>
									<td>${item.u_org }</td>
									<td>
										<input type = "checkbox" name="updateAuth">
										<input type = "checkbox" name="updateAuth">
									</td> 
									<td>
										<button type="button" onclick="viewDeleteUserPopup(${item.u_id})"> 삭제</button>
									</td>
								</tr>
							</c:forEach>
						</tbody>
					</table>
					<div class="pagination">
						<ui:pagination paginationInfo="${paginationInfo}" type="text" jsFunction="goPage"/>
					</div>
				</c:when>
				<c:otherwise>
					<p> 검색 결과가 없습니다. </p>
				</c:otherwise>
			</c:choose>
		</div>
		
		<!-- 삭제 팝업 -->
		<div id="removeUserPopupDIv">
			
		</div>
	</div>		
    <footer class="footer">
        <p>&copy; 2025 GAILAB</p>
    </footer>
</body>
<script>
	
	// pagination 객체를 활용한 페이지 이동
	window.goPage = function(pageNo){
    	
		let startDate = encodeURIComponent('${startDate != null ? startDate : ""}');
		let endDate = encodeURIComponent('${endDate != null ? endDate : ""}');
		let searchKeyword   = encodeURIComponent('${searchKeyword != null ? searchKeyword : ""}');
		
    	location.href = "viewDeviceList.do?page=" + pageNo + "&searchKeyword=" + startDate + "&startDate=" + searchKeyword + "&endDate=" + endDate;
	}
	
	// 회원관리 api 모듈
	async function apiService(url,options = {},body){
		
		const fetchOptions = {
			method : options.method || 'GET',
				headers : options.headers || {
					'Content-Type':'application/x-www-form-urlencoded'
				},
				credentials : options.credentials || 'same-origin',
				cache: options.cache || 'no-store',	
			};
		
			// GET이 아니라면 body 추가
			if(fetchOptions.method !== 'GET' && body != null){
				fetchOptions.body = body;
			}
			
			const res = await fetch("${pageContext.request.contextPath}"+url,fetchOptions);
	
			if(!res.ok){
				
				return null;
			}
			
			return res;
	}
	
	// 삭제 팝업
	async function viewDeleteUserPopup(uId){
		
		const res = await 
		
	}
	
	
</script>

</html>