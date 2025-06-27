<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>

<html lang="kr">
<head>
<meta charset="utf-8">
<meta name="viewport"
	content="width=device-width, initial-scale=1, shrink-to-fit=no">
<meta name="description" content="">

<title>동구 종합민원이력관리시스템</title>
<link type="image/x-icon" rel="shortcut icon"
	href="${path}/resources/images/favicon.ico">
<%@ include file="../include/lib.jsp"%>

</head>

<body>
	<%@ include file="../include/header.jsp"%>

	<div class="container-fluid">
		<div class="row">
			<%@ include file="../include/nav.jsp"%>

			<main role="main"
				class="col-md-9 ml-sm-auto col-lg-10 d-flex flex-column"
				style="height: calc(100vh - 91px)">
				<div class="container px-md-4">
					<div
						class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3">
						<h1 class="h2">비밀번호 재설정</h1>
					</div>
					<div class="row justify-content-center">
						<div class="col-md-4">
							<form method="post" id="form1" name="form1">
								<div class="mb-3">
									<label for="id">비밀번호<span class="text-muted"></span></label> <input
										type="password" class="form-control" id="password" name="password"
										placeholder="재설정할 비밀번호를 입력해 주세요.">
								</div>
								<div class="mb-3">
									<label for="id">비밀번호 확인<span class="text-muted"></span></label>
									<input type="password" class="form-control" id="re_password" name="re_password"
										placeholder="재설정할 비밀번호를 한번더 입력해 주세요.">
								</div>
								<div class="row">
									<div class="col-md-6 mb-3">
										<button class="btn btn-success btn-block" type="button"
											id="btnChange" id="save">비밀번호 수정</button>
									</div>

								</div>
							</form>

						</div>
					</div>
				</div>
				<%@ include file="../include/footer.jsp"%>
			</main>
		</div>
	</div>
	<script>
		$(document).on('click', '#btnChange', function() {
			let password = $("#password").val();
			if (password == "") {
				alert("비밀번호를 입력해주세요.");
				return;
			}
			let re_password = $("#re_password").val();
			if (re_password == "") {
				alert("비밀번호를 입력해주세요.");
				return;
			}
			if (password != re_password) {
				alert("동일한 비밀번호를 입력해주세요.");
				return;
			}
			document.form1.action = "${path}/admin/changePassword.do";
			document.form1.submit();
		});
	</script>
</body>
</html>
