<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ page import="java.sql.*,
java.io.*, java.net.*, java.util.*"%>
<%@ include file="/gpkisecureweb/jsp/gpkisecureweb.jsp"%>
<%@ page import="com.gpki.servlet.GPKIHttpServletResponse"%>
<%
/*
String challenge = gpkiresponse.getChallenge();
String sessionid = gpkirequest.getSession().getId();
String url = javax.servlet.http.HttpUtils.getRequestURL(request).toString();
session.setAttribute("currentpage", url);
*/
%>
<!DOCTYPE html>
<html lang="kr">
<head>
<meta charset="UTF-8" />
<title>동구 종합민원이력관리시스템</title>
<link type="image/x-icon" rel="shortcut icon"
	href="${path}/resources/images/favicon.ico" />
<%@ include file="../include/lib.jsp"%>
<jsp:include page="/gpkisecureweb/jsp/header.jsp"></jsp:include>
</head>
<body>
	<div class="login-page">
		<div class="input-form-backgroud row">
			<div class="input-form col-md-12 mx-auto">
				<h4 class="mb-3">회원가입</h4>
				<!-- 
				<form action="/gpkisecureweb/jsp/insertUser.jsp" class="validation-form" name="form1" method="post" id="form1">
				-->
				<form class="validation-form" name="form1" id="form1" method="post">
				<%-- <input type="hidden" name="sessionid" id="sessionid"
						value="<%=sessionid%>" /> <input type="hidden" name="challenge"
						value="<%=challenge%>" /> --%>
					 <input type="hidden" name="department"
						id="department" value="" /> <input type="hidden" name="passed"
						id="passed" value="false" />
					<div class="row">
						<div class="col-md-6 mb-3">
							<label for="member_id">아이디</label>
							<div class="d-flex">
								<input type="text" class="form-control" id="member_id"
									name="u_login_id" placeholder="아이디" value="" required />
								<div class="invalid-feedback">아이디를 입력해주세요.</div>

								<button type="button" class="btn btn-secondary text-nowrap ml-2"
									id="checkId" name="checkId">중복찾기</button>
							</div>
						</div>
					</div>
					<div class="row">
						<div class="col-md-6 mb-3">
							<label for="password">비밀번호</label> <input type="password"
								class="form-control" id="password" name="u_login_pwd"
								placeholder="비밀번호" required onchange="onChange()" />
							<div class="invalid-feedback">비밀번호을 입력해주세요.</div>
						</div>
						<div class="col-md-6 mb-3">
							<label for="re-password">비밀번호 확인</label> <input type="password"
								class="form-control" id="re-password" placeholder="비밀번호 확인"
								name="re-password" required />
							<div class="invalid-feedback">비밀번호을 재 입력해주세요.</div>
						</div>
					</div>
					<span class="mb-3 d-block" style="color: red;">비밀번호를 8자 이상
						입력해주세요.</span>
					<div class="row">
						<div class="col-md-6 mb-3">
							<label for="email">이메일</label> <input type="email"
								class="form-control" id="email" name="u_email"
								placeholder="you@example.com" required />
							<div class="invalid-feedback">이메일을 입력해주세요.</div>
						</div>
						<div class="col-md-6 mb-3">
							<label for="u_name">이름</label> <input type="text"
								class="form-control" id="u_name" name="u_name"
								placeholder="이름을 입력해주세요." />
						</div>
					</div>
					<div class="mb-3">
						<label for="u_admin_num">행정번호 4자리</label> <input type="text"
							class="form-control" id="u_admin_num" name="u_admin_num"
							placeholder="행정번호 뒷번호 4자리를 입력해주세요." />
					</div>

					<div class="row">
						<div class="col-md-4 mb-3">
							<label for="code">국·소·실·관·단</label> <select name="department1"
								id="department1" class="form-control">
								<c:forEach var="department" items="${allDepartments }">
									<option>${department }</option>
								</c:forEach>
							</select>
						</div>
						<div class="col-md-4 mb-3">
							<label for="code">부서</label> <select name="department2"
								id="department2" class="form-control"></select>
						</div>
						<div class="col-md-4 mb-3">
							<label for="code">계(팀)</label> <select name="department3"
								id="department3" class="form-control"></select>
						</div>
					</div>
					<div class="row">
						<div class="col-md-8 mb-3">
							<label for="code">선택된 부서</label> <input type="text"
								class="form-control" id="selectedDepartment" placeholder=""
								disabled />
						</div>
						<div class="col-md-4 mb-3">
							<label for="code">직급</label> <select name="position"
								id="position" class="form-control">
								<c:forEach var="position" items="${allPositions }">
									<option>${position }</option>
								</c:forEach>
							</select>
						</div>
					</div>
					<div class="row">
						<div class="col-md-4 mb-3 ml-auto">
							<button class="btn btn-bule btn-lg btn-block" id="register"
								name="register">사용자 신청</button>
						</div>
					</div>
				</form>
			</div>
		</div>
	</div>
	<script>
	  function onChange() {
		  let password = document.getElementById("password").value;
		  console.log(password);
	  }
      $(document).on("click", "#checkId", function () {
        let member_id = $("#member_id").val();
        if (member_id == "") {
          alert("아이디를 입력해주세요.");
          return;
        }
        console.log(member_id);
        $.ajax({
          type: "post",
          url: "/main/checkId.do",
          data: { member_id: member_id },
          success: function (data) {
            if (data == "N") {
              result = "사용 가능한 아이디입니다.";
              alert(result);
              $("#passed").val("true");
              $("#member_pw").trigger("focus");
            } else {
              result = "이미 사용중인 아이디입니다.";
              alert(result);
              $("#passed").val("false");
              $("#member_id").val("").trigger("focus");
            }
          },
          error: function (error) {
            alert(error);
          },
        });
      });
      $(document).on("click", "#register", function () {
        let member_id = $("#member_id").val();
        if (member_id == "") {
        	alert("ID를 입력해 주세요.");
          return false;
        }
        let password = $("#password").val();
        if (password == "") {
        	alert("비밀번호를 입력해 주세요.");
          return false;
        }
        if (password.length < 8) {
        	alert("비밀번호를 8자 이상 입력해 주세요.");
        	return false;
        }
        let re_password = $("#re-password").val();
        if (re_password == "") {
        	alert("비밀번호를 8자 이상 입력해 주세요.");
          return false;
        }
        if (password != re_password) {
          alert("동일한 비밀번호를 입력해주세요.");
          $("#password").focus();
          return false;
        }
        let email = $("#email").val();
        if (email == "") {
        	alert("이메일을 입력해 주세요.");
          return false;
        }
        let u_name = $("#u_name").val();
        if (u_name == "") {
        	alert("이름을 입력해 주세요.");
          return false;
        }
        let u_admin_num = $("#u_admin_num").val();
        if (u_admin_num.length != 4) {
        	alert("행정번호 4자리를 입력해주세요.");
        	return false;
        }
        let selectedDepartment = $("#selectedDepartment").val();
        if (selectedDepartment == "") {
          alert("부서를 입력해주세요.");
          return false;
        }
        alert("회원가입이 완료되었습니다.");
        // return Login(this, form1);

        $("#form1").attr("action", "/main/memberRequest.do");
        $("#form1").submit();
      });

      $(function () {
        $("#department1").change(function () {
          var department = $("#department1").val();
          $("#department").val(department);
          $("#selectedDepartment").attr("value", department);
          console.log(department);
          $.ajax({
            type: "GET",
            url: "/departmentListDepth2.do",
            data: {
              depth1Name: $("#department1").val(),
            },
            dataType: "json",
            success: function (response) {
            	console.log(response);
              $("#department2").empty();
              $("#department3").empty();
              $("#department2").append(
                      "<option>선택</option>"
                    );
              for (const department of response) {
                $("#department2").append(
                  "<option>" + department + "</option>"
                );
              }
            },
          });
        });

        $("#department2").change(function () {
          var department = $("#department2").val();
          if (department != "선택") {
        	  $("#department").val(department);
              $("#selectedDepartment").attr("value", "");
              $("#selectedDepartment").attr(
                "value",
                $("#department1").val() + " / " + department
              );
              $.ajax({
                type: "GET",
                url: "/departmentListDepth3.do",
                data: {
                  depth2Name: $("#department2").val(),
                },
                dataType: "json",
                success: function (response) {
                  $("#department3").empty();
                  $("#department3").append(
                          "<option>선택</option>"
                        );
                  for (const department of response) {
                    $("#department3").append(
                      "<option>" + department + "</option>"
                    );
                  }
                },
              });
          } else {
        	  $("#department3").empty();
        	  $("#department").val($("#department1").val());
        	  $("#selectedDepartment").attr(
                      "value",
                      $("#department1").val()
                    );
          }
        });

        $("#department3").change(function () {
          var department = $("#department3").val();
          if (department != "선택") {
        	  $("#department").val(department);
              $("#selectedDepartment").attr("value", "");
              $("#selectedDepartment").attr(
                "value",
                $("#department1").val() +
                  " / " +
                  $("#department2").val() +
                  " / " +
                  department
              );
          } else {
        	  $("#department").val($("#department2").val());
        	  $("#selectedDepartment").attr(
                      "value",
                      $("#department1").val() + " / " + $("#department2").val()
                    );
          }
        });
      });
    </script>
</body>
</html>
