<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%-- 공용 헤더 (Tiles defaultLayout). deviceList 하드코딩 헤더를 공유 레이아웃으로 이관 --%>
<header class="header">
	<div class="logo">
		<img src="${pageContext.request.contextPath}/resources/images/지아이랩-로고.png" alt="GAILAB" class="header-icon">
	</div>
	<div class="right-group">
		<c:if test="${useTblLog eq false}">
			<div class="alert alert-warning">현재 로그 데이터 저장 공간이 매우 부족합니다. 관리자에게 문의해주세요.</div>
		</c:if>
		<div class="user">
			<span class="user-name"><c:out value="${uName}" escapeXml="true" /></span>
		</div>
		<div class="logout">
			<button onclick="location.href='${pageContext.request.contextPath}/user/logout'">로그아웃</button>
		</div>
	</div>
</header>
