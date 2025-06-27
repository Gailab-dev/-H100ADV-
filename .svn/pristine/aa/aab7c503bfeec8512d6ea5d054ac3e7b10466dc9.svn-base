<%@page import="com.gpki.gpkiapi.GpkiApi"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.io.*, java.net.*, java.util.*"%>
<%@ include file="/gpkisecureweb/jsp/gpkisecureweb.jsp"%>

<%@ page import="com.gpki.servlet.GPKIHttpServletResponse"%>
<%@ page import="com.gpki.gpkiapi.exception.GpkiApiException"%>
<%@ page import="java.util.Enumeration"%>
<%@ page import="com.gpki.gpkiapi.cert.*"%>
<%@ page import="com.gpki.gpkiapi.cms.*"%>
<%@ page import="com.gpki.gpkiapi.util.*"%>
<%@ page import="com.dsjdf.jdf.Logger"%>
<%@ page import="java.net.URLDecoder"%>
<%@ page import="java.sql.*"%>
<%
String challenge = gpkiresponse.getChallenge();
String sessionid = "bb";
String url = javax.servlet.http.HttpUtils.getRequestURL(request).toString();
session.setAttribute("currentpage", url);
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>동구 종합민원이력관리시스템</title>
<link type="image/x-icon" rel="shortcut icon"
	href="${path}/resources/images/favicon.ico">
<%@ include file="../include/lib.jsp"%>
<jsp:include page="/gpkisecureweb/jsp/header.jsp"></jsp:include>
</head>
<body>
	<div class="login-page">
		<div class="login-form">
			<img src="${path}/resources/images/login.png" width="625px" />
			<div class="">
				<div class="border px-3 py-3 bg-light" style="width: 310px;">
					<img src="${path}/resources/images/footer_logo.png"
						class="mb-3 d-block" width="250px" />
					<form action="/main/registerCertificate.do" method="post"
						name="popForm" id="popForm">
						<input type="hidden" name="sessionid" id="sessionid"
							value="<%=sessionid%>" /> <input type="hidden" name="challenge"
							value="<%=challenge%>" />
						<button type="button" class="btn btn-bule btn-block mb-4"
							onclick="return Login(this,popForm)">인증서 등록</button>
					</form>
				</div>
			</div>
		</div>
	</div>
</body>
</html>