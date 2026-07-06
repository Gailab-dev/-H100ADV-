<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="tiles" uri="http://tiles.apache.org/tags-tiles" %>
<!DOCTYPE html>
<!-- 템플릿 파일에서부터 시작합니다. -->
<html lang="ko">
<head>
	<!-- ---------------------- 공통 meta 설정----------------------------- -->
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
	<!-- ---------------------- 공통 라이브러리 ---------------------------- -->
	<script src="${pageContext.request.contextPath}/resources/js/jquery-3.3.1.min.js"></script>
	<script src="${pageContext.request.contextPath}/resources/js/c3.min.js"></script>
	<!-- ----------------------- 공통 스타일 ------------------------------- -->
	<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/common.css" />
	<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/pagination.css" />
	<!-- 공용 레이아웃(chrome) 스타일 -->
	<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/layout.css" />
	<!-- ---------------------- 공통 자바스크립트 함수 ---------------------- -->
	<script src="${pageContext.request.contextPath}/resources/js/common.js"></script>
	<!-- 화면별 추가 head (선택) -->
	<tiles:insertAttribute name="head" ignore="true"/>
</head>
<body>
	<div class="page-wrapper">
		<%-- 상단 헤더 --%>
		<tiles:insertAttribute name="header"/>
		<div class="container">
			<%-- 좌측 사이드바 --%>
			<tiles:insertAttribute name="left"/>
			<%-- 본문 --%>
			<div class="content">
				<tiles:insertAttribute name="body"/>
			</div>
		</div>
		<%-- 푸터 --%>
		<tiles:insertAttribute name="footer"/>
	</div>
</body>
</html>
