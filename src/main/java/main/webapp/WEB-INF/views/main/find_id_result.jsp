<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!DOCTYPE html>
<html lang="kr">
<head>
<meta charset="UTF-8">
<title>동구 종합민원이력관리시스템</title>
<link type="image/x-icon" rel="shortcut icon"
	href="${path}/resources/images/favicon.ico">
<%@ include file="../include/main_lib.jsp"%>
</head>
<body>
	<div class="login-page justify-content-center">
            <body>

                <div class="input-form-backgroud row">
                    <div class="input-form col-md-12 mx-auto">
                        <h4 class="mb-4 text-center">결과</h4>
                        <p class="text-center">${result }</p>
                    <hr>
                    <div class="mb-4"></div>
                    <div class="row">
                        <div class="col-md-6 mb-5 m-auto text-sm-center">
                            <button class="btn btn-bule btn-lg btn-block m-auto" onclick="location.href='login.do'">로그인페이지로 이동</button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
</body>
</html>