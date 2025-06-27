<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>동구 종합민원이력관리시스템</title>
<link type="image/x-icon" rel="shortcut icon"
	href="${path}/resources/images/favicon.ico">
<%@ include file="../include/lib.jsp" %>
<script>
	$(document).ready(function() {
		$('#btnLogin').click(function() {
			var adminId = $("#adminId").val();
			var adminPw = $("#adminPw").val();
			if (adminId == "") {
				alert("아이디를 입력하세요.");
				$("#adminId").focus();
				return;
			}
			if (adminPw == "") {
				alert("비밀번호를 입력하세요.");
				$("#adminPw").focus();
				return;
			}
			document.form1.action = "${path}/admin/loginCheck.do";
			document.form1.submit();
		});
	});
</script>
</head>
<body>
	<!-- 
	<h2>로그인</h2>
	<form name="form1" method="post">
		<table border="1" width="400px">
			<tr>
				<td>아이디</td>
				<td><input name="adminId" id="adminId"></td>
			</tr>
			<tr>
				<td>비밀번호</td>
				<td><input type="password" name="adminPw" id="adminPw"></td>
			</tr>
			<tr>
				<td colspan="2" align="center">
					<button type="button" id="btnLogin">로그인</button>
					<c:if test="${msg == 'failure' }">
						<div style="color: red">
							아이디 또는 비밀번호가 일치하지 않습니다.
						</div>
					</c:if>
					<c:if test="${msg == 'logout' }">
						<div style="color: red">
							로그아웃되었습니다.
						</div>
					</c:if>
				</td>
			</tr>
		</table>
	</form>
	 -->
	<div class="login-page">
      <div class="login-form">
      <img src="${path}/resources/images/login.png" width="625px"  />
        <div class="border px-4 py-4  bg-light">
          <img src="${path}/resources/images/footer_logo.png" class="mb-5 d-block" />
          <form id="form1" name="form1" method="post">
          	<input
            type="text"
            class="form-control mb-3 border"
            id="adminId"
            name="adminId"
            placeholder="아이디"
          />
          <input
            type="password"
            class="form-control mb-5 border"
            id="adminPw"
            name="adminPw"
            placeholder="비밀번호"
          />
          </form>
          
          <div class="mb-5 d-flex justify-content-between">
            <button type="button" class="btn btn-bule btn-block" id="btnLogin">로그인</button>
          </div>
          <c:if test="${msg == 'failure' }">
				<div style="color: red">
					입력하신정보가 일치하지 않습니다.
				</div>
			</c:if>
			<c:if test="${msg == 'logout' }">
				<div style="color: red">
					로그아웃되었습니다.
				</div>
			</c:if>
        </div>
    </div>
    
    </div>
    
</body>
</html>