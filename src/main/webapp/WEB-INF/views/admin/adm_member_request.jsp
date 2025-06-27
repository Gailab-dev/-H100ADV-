<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<html lang="kr">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="description" content="">
    
    <title>동구 종합민원이력관리시스템</title>
<link type="image/x-icon" rel="shortcut icon"
	href="${path}/resources/images/favicon.ico">
    <%@ include file="../include/lib.jsp" %>
    
  </head>
 
  <body>   
	<%@ include file="../include/header.jsp" %>

	<div class="container-fluid">
	  <div class="row">
	    <%@ include file="../include/nav.jsp" %>
	
	  <main role="main" class="col-md-9 ml-sm-auto col-lg-10 d-flex flex-column" style="height: calc(100vh - 70px);">
      <div class="container px-md-4">
      <div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3">
        <h1 class="h2">회원가입관리</h1>
      </div>
      <div class="row">
        
        <div class="col-md-4 mb-4" id="member_list">
        </div>
        <div class="col-md-8">
          <div class="tab-content" id="nav-tabContent">
            <div class="tab-pane fade show active" id="list-home" role="tabpanel" aria-labelledby="list-home-list">
              <div class=" order-md-1">
                <form class="needs-validation" novalidate="">
                  <input type="hidden" id="u_id" value="">
                  <input type="hidden" id="u_login_pwd" value="">
                  <input type="hidden" id="u_gpki_dn" value="">
                  <div class="mb-3">
                    <label for="id">아이디<span class="text-muted"></span></label>
                    <input type="id" class="form-control" id="u_login_id" placeholder="아이디를 입력해 주세요.">
                  </div>
                  <div class="mb-3">
                    <label for="email">이메일</span></label>
                    <input type="email" class="form-control" id="u_email" placeholder="you@example.com">
                  </div>
                  <div class="mb-3">
                    <label for="name">성명<span class="text-muted"></span></label>
                    <input type="text" class="form-control" id="u_name" placeholder="이름을 입력해 주세요.">
                  </div>
                  <div class="mb-3">
                    <label for="u_admin_num">행정번호<span class="text-muted"></span></label>
                    <input type="text" class="form-control" id="u_admin_num" placeholder="행정번호 4자리를 입력해주세요.">
                  </div>
                  <div class="row">
                    <div class="col-md-5 mb-3">
                      <label for="department">부서</label>
                      <select class="custom-select d-block w-100" id="department" required="">
                        
                      </select>
                    </div>
                    <div class="col-md-4 mb-3">
                      <label for="position">직급</label>
                      <select class="custom-select d-block w-100" id="position" required="">
                      </select>
                    </div>
                  </div>
                  <hr class="mb-4">
                  </div>
                </form>
                <div class="alert alert-danger" role="alert" id="alert">
                  -
                </div>
                <div class="row">
                  <div class="col-md-6 mb-3">
                    <button class="btn btn-success btn-block" id="save">회원승인</button>
                  </div>
                  <div class="col-md-6 mb-3">
                    <button class="btn btn-outline-danger btn-block" id="delete">삭제</button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
     <%@ include file="../include/footer.jsp" %>
    </main>
	  </div>
	</div>
	<script>
		$(document).ready(function() {
			$.ajax({
				type : "POST",
				url : "/memberList.do",
				contentType : "application/json; charset=utf-8",
				dataType : "json",
				success : function(response) {
					console.log(response);
					var fragment = "";
					fragment += "<div class='list-group'>";
		            $.each(response, function (idx, item) {
		            	console.log(item.u_login_id);
		                fragment += "<a class='list-group-item list-group-item-action active' onclick='javascript:PositionLoad("+item.u_id+");return false; '>" + item.u_login_id +" | "+ item.u_name + "</a>";
		            });
		            fragment += "</div>";
		            $("#member_list").html(fragment);	
				}
			});
		});
		
		function PositionLoad(u_id){
			$.ajax({
				type : "GET",
				url : "/memberView.do",
				data : {
					"u_id" : u_id
				},
				contentType : "application/json; charset=utf-8",
				dataType : "json",
				success : function(response) {
					console.log(response);
					$('#u_id').val(response.u_id);
					$('#u_login_id').val(response.u_login_id);
					$('#u_login_pwd').val(response.u_login_pwd);
					$('#u_gpki_dn').val(response.u_gpki_dn);
					$('#u_email').val(response.u_email);
					$('#u_name').val(response.u_name);
					$('#u_admin_num').val(response.u_admin_num);
					$('#department').val(response.dp_id).prop('select', true);
					$('#position').val(response.ps_id).prop('select', true);
				}
			});
		}
		
		$(document).ready(function() {
			$.ajax({
				type : "POST",
				url : "/positionList.do",
				contentType : "application/json; charset=utf-8",
				dataType : "json",
				success : function(response) {
					var option;
					$.each(response, function(idx,item){
						var option = $("<option value=" + item.ps_id + ">" + item.ps_name+"</option>");
						$('#position').append(option);
					});
				}
			});
		});
		
		$(document).ready(function() {
			$.ajax({
				type : "POST",
				url : "/departmentList.do",
				contentType : "application/json; charset=utf-8",
				dataType : "json",
				success : function(response) {
					var option;
					$.each(response, function(idx,item){
						var option = $("<option value=" + item.dp_id + ">" + item.dp_name+"</option>");
						$('#department').append(option);
					});
				}
			});
		});
		function userFind(u_login_id) {
			var result = "";
			$.ajax({
				type : "GET",
				url : "/userFind.do",
				async : false,
				data : {
					"u_login_id" : u_login_id
				},
				contentType : "application/json; charset=utf-8",
				dataType : "json",
				success : function(response) {
					if (response) {
						result = response;
					} 
				}
			});	
			return result;
		}
		$("#save").click(function() {
			var u_login_id = $('#u_login_id').val();
			if (u_login_id === "") {
				$('#alert').html('사용자를 선택해주세요.');
				return;
			}
			if (userFind(u_login_id)) {
				$('#alert').html('동일한 ID가 존재합니다.');
				return;
			}
			var u_admin_num = $('#u_admin_num').val();
			if (u_admin_num.length != 4) {
				$('#alert').html('행정번호 뒷자리 4번호를 입력해주세요.');
			}
			
			if(!confirm("저장 하시겠습니까?")) return;
			var u_id = $('#u_id').val();
			var u_login_pwd = $('#u_login_pwd').val();
			var u_name = $('#u_name').val();
			var u_email = $('#u_email').val();
			
			var dp_id = $("#department option:selected").val();
			var ps_id = $("#position option:selected").val();
			var u_gpki_dn = $('#u_gpki_dn').val();
				
			$.ajax({
				type : "GET",
				url : "/memberInsert.do",
				data : {
					"u_id" : u_id,
					"u_login_id" : u_login_id,
					"u_login_pwd" : u_login_pwd,
					"u_name" : u_name,
					"u_email" : u_email,
					"u_admin_num" : u_admin_num,
					"dp_id" : dp_id,
					"ps_id" : ps_id,
					"u_gpki_dn" : u_gpki_dn
				},
				dataType : "text",
				success : function(response) {
					alert("등록되었습니다.");
					window.location.reload() ;
				}
			});
			
		});
		
		$("#delete").click(function() {
			if(!confirm("삭제 하시겠습니까?")) return;
			var u_login_id = $('#u_login_id').val();
			var u_id = $('#u_id').val();
			$.ajax({
				type : "GET",
				url : "/memberDelete.do",
				data : {
					"u_id" : u_id
				},
				dataType : "text",
				success : function(response) {
					if (response == "OK") {
						alert("삭제 했습니다.");
					} 
					window.location.reload(); 
				}
			});
		});
	</script>
  </body>
</html>
