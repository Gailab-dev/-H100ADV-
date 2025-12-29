<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Home</title>
<%@ include file="include/lib.jsp" %>
</head>
<body>
<c:if test="${msg == 'success' }">
	<h2>${sessionScope.adminName }님 환영합니다.</h2>
</c:if>

</body>
</html>