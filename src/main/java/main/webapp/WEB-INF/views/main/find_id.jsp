<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
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
String sessionid = gpkirequest.getSession().getId();
String url = javax.servlet.http.HttpUtils.getRequestURL(request).toString();
session.setAttribute("currentpage", url);
%>
<!DOCTYPE html>
<html lang="kr">
<head>
<meta charset="UTF-8">
<title>아이디/비밀번호 변경</title>
<link type="image/x-icon" rel="shortcut icon"
	href="${path}/resources/images/favicon.ico">
<style>
html, body {
	height: 100%;
}
</style>
<%@ include file="../include/lib.jsp"%>
<jsp:include page="/gpkisecureweb/jsp/header.jsp"></jsp:include>
</head>
<body>
	<div class="login-page">
		<div
			class="row d-flex justify-content-center align-items-center w-100">
			<div class="col-2"></div>
			<div class="col-4 text-center">
				<form action="/main/certFindId.do" method="post"
					class="validation-form" name="popForm" id="popForm">
					<input type="hidden" name="sessionid" id="sessionid"
						value="<%=sessionid%>" /> <input type="hidden" name="challenge"
						value="<%=challenge%>" />
					<div class="id-card">
						<h4 class=" my-2">아이디 찾기</h4>

						<button style="margin: 8px" class="btn btn-bule btn-lg "
							name="button" onclick="return Login(this,popForm)">인증서로
							아이디 찾기</button>
					</div>
				</form>
			</div>
			<!--end of col-4 -->
			<!-- <div class="col-2"></div> -->
			<div class="col-4 text-center">
				<form class="validation-form" action="/main/changePassword.do" method="post"
					name="popForm1" id="popForm1">
					<input type="hidden" name="sessionid" id="sessionid"
						value="<%=sessionid%>" /> <input type="hidden" name="challenge"
						value="<%=challenge%>" />
					<div class="id-card">
						<h4 class=" my-2">비밀번호 변경</h4>
						<div class="input-group flex-nowrap" style="padding: 8px">
							<div class="input-group-prepend">
								<span class="input-group-text text-sm-center"
									id="addon-wrapping">비밀번호</span>
							</div>
							<input type="password" name="password" id="password"
								class="form-control">
						</div>
						<div class="input-group flex-nowrap" style="padding: 8px">
							<div class="input-group-prepend">
								<span class="input-group-text text-sm-center"
									id="addon-wrapping">확인</span>
							</div>
							<input type="password" name="re_password" id="re_password"
								class="form-control">
						</div>
						<button type="button" id="btnChange" style="margin: 8px"
							class="btn btn-bule btn-lg " name="btnChange">인증서로 비밀번호 변경</button>
					</div>
				</form>
			</div>

			<div class="col-2"></div>
		</div>
		<!-- END OF ROW -->
	</div>
<script>
$(document).on('click', '#btnChange', function(){
    let password = $("#password").val();
    if (password == "") {
    	return;
    }
    let re_password = $("#re_password").val();
    if (re_password == "") {
    	return;
    }
    if (password != re_password) {
    	alert("동일한 비밀번호를 입력해주세요.");
    	return;
    }
    return Login(this, popForm1);
});
</script>
</body>
</html>