<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="tiles" uri="http://tiles.apache.org/tags-tiles" %>
<!DOCTYPE html>
<!-- 템플릿 파일에서부터 시작합니다. -->
<html lang="ko">
<head>
	<!-- ---------------------- 공통 meta 설정----------------------------- -->
	<meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  	<!-- ---------------------- 공통 meta 설정----------------------------- -->
  	<!-- ---------------------- 공통 라이브러리 ---------------------------- -->
  	<script src="/resources/js/jquery-3.3.1.min.js"></script>
  	<script src="/resources/js/c3.min.js"></script>
  	<!-- ---------------------- 공통 라이브러리 ---------------------------- -->
  	<!-- ----------------------- 공통 스타일 ------------------------------- -->
  	<link rel="stylesheet" href="/resources/css/common.css" />
	<!-- ----------------------- 공통 스타일 ------------------------------- -->
  	<!-- ---------------------- 공통 자바스크립트 함수 ---------------------- -->
  	<script src="/resources/js/common.js"></script>
	<!-- ---------------------- 공통 자바스크립트 함수 ---------------------- -->
	<tiles:insertAttribute name="header"/>
</head>
<body>
	<tiles:insertAttribute name="left"/>
	<tiles:insertAttribute name="body"/>
	<footer>
		<tiles:insertAttribute name="footer"/>
	</footer>
</body>		
</html>