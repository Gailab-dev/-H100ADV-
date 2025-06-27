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
				style="height: calc(100vh - 70px);">
				<div class="container px-md-4">
					<div
						class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3">
						<h1 class="h2">사용자 관리</h1>
					</div>

					<!-- 이름 검색 부분 -->
					<div class="row">
						<div class="col-md-6">
							<div class="row">
								<div class="col-md-12 mb-4"
									style="height: 20%; background-color: #ffffff;">
									<!-- 첫 번째 위쪽 컬럼의 상단 영역 -->

									<div class="row align-items-center h-100"
										style="padding-left: 15px;">
										<div class="col-md-2"
											style="padding-right: 1rem; font-size: 16px; font-weight: 700; font-family: 'Noto Sans KR', sans-serif; color: #333; border: 1px solid #333; text-align: center; height: 33.8px;">
											<div class="align-items-center justify-content-center h-100"
												style="margin-top: 3;">이름</div>
										</div>
										<div class="col-md-8" style="padding-right: 1;">
											<div class="d-flex align-items-center">
												<input type="text" class="form-control"
													placeholder="이름을 입력하세요" id="name_input">
											</div>
										</div>
										<div class="col-md-2">
											<div class="d-flex align-items-center">
												<button type="button" class="btn btn-primary w-100"
													id="search">검색</button>
											</div>
										</div>
									</div>

								</div>
							</div>

							<div class="row">

								<h5
									style="font-family: 'Noto Sans KR', sans-serif; color: #333; font-size: 16px; font-weight: 700; padding-left: 15px">검색
									결과</h5>
								<!-- 첫 번째 위쪽 컬럼의 하단 영역 -->
								<div class="col-md-12 mb-4"
									style="height: 80%; background-color: #ffffff;">

									<div id="searchResults"
										style="max-height: 100%; overflow-y: auto;">
										<div style="text-align: center; padding: 20px;">
											<p>사용자 이름을 입력해주세요.</p>
										</div>
									</div>

								</div>
							</div>
							<div class="row">
								<!-- 아래쪽 왼쪽 컬럼 -->
								<div class="col-md-6 mb-4"
									style="height: 100%; background-color: #ffffff;">
									<h5>조직도</h5>
									<div class="border">
										<div id="tree"></div>
									</div>

								</div>
								<!-- 아래쪽 오른쪽 컬럼 -->
								<div class="col-md-6 mb-4"
									style="height: 100%; background-color: #ffffff;">
									<h5 id="p_name">부서 조직 :</h5>
									<div id="part_list"></div>
								</div>
							</div>
						</div>
						<div class="col-md-6">
							<!-- 두 번째 컬럼 -->
							<div id="user_info"
								class="alert alert-secondary d-flex align-items-center"
								role="alert">사용자를 선택해주세요.</div>
							<div class="tab-content" id="nav-tabContent">
								<div class="tab-pane fade show active" id="list-home"
									role="tabpanel" aria-labelledby="list-home-list">
									<div class=" order-md-1">
										<div class="mb-3">
											<label for="name">성명<span class="text-muted"></span></label>
											<input type="name" class="form-control" id="name"
												placeholder="이름을 입력해 주세요." disabled>
										</div>
										<div class="mb-3">
											<label for="id">아이디<span class="text-muted"></span></label> <input
												type="id" class="form-control" id="id"
												placeholder="아이디를 입력해 주세요." disabled>
										</div>
										<div class="mb-3">
											<label for="id">패스워드<span class="text-muted"></span></label>
											<input type="password" class="form-control" id="password"
												placeholder="8자리 이상 입력해주세요.">
										</div>
										<div class="mb-3">
											<label for="email">이메일</label> <input type="email"
												class="form-control" id="email"
												placeholder="you@example.com">
										</div>
										<div class="mb-3">
											<label for="u_admin_num">행정번호 뒷번호 4자리</label> <input
												type="email" class="form-control" id="u_admin_num"
												placeholder="행정번호 4자리를 입력해주세요.">
										</div>
										<div class="mb-3">
											<label for="grade">접근 등급</label> <select id="grade"
												class="form-control">
												<option value="1">일반</option>
												<option value="9">총괄</option>
											</select>
										</div>
										<div class="row">
											<div class="col-md-5 mb-3">
												<label for="country">부서</label> <select id="sele_part"
													class="form-control"></select>
											</div>
											<div class="col-md-4 mb-3">
												<label for="state">직급</label> <select id="sele_position"
													class="form-control"></select>
											</div>
										</div>
										<hr class="mb-4">
									</div>
									<div class="alert alert-danger" role="alert" id="alert">
										-</div>
									<div class="row">
										<div class="col-md-6 mb-3">
											<button class="btn btn-success btn-block" type="submit"
												id="save">사용자 수정</button>
										</div>
										<div class="col-md-6 mb-3">
											<button class="btn btn-outline-danger btn-block"
												type="submit" id="delete">사용자 삭제</button>
										</div>
										<div class="col-md-6 mb-3">
											<button class="btn btn-success btn-block" type="submit"
												id="excel" onclick="location.href='/deptUserList.do'">엑셀
												출력</button>
										</div>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
				<%@ include file="../include/footer.jsp"%>
			</main>
		</div>
	</div>
	<input type="hidden" id="h_new_check" value="new">
	<input type="hidden" id="h_u_id">
	<input type="hidden" id="h_login_pwd">
	<script>
		$(document).ready(function() {
			$.ajax({
				type : "POST",
				url : "/departmentList.do",
				contentType : "application/json; charset=utf-8",
				dataType : "json",
				success : function(response) {

					var datas = new Array(); //jstree 용
					datas[0] = {
						id : 0,
						parent : '#',
						text : "동구청",
						depth : 0,
						rank : 1,
						state : {
							opened : true
						}
					};
					$.each(response, function(idx, item) {
						datas[idx + 1] = {
							id : item.dp_id,
							parent : item.dp_pid,
							text : item.dp_name,
							depth : item.dp_depth,
							rank : item.dp_rank,
							state : {
								opened : false
							}
						};
					});
					
					$('#tree').jstree({
						'core' : {
							'check_callback' : true,
							'data' : datas
						},
						'types' : {
							'root' : "/resources/images/mark.png"
						}
					}).bind("select_node.jstree", function(event, data) {
						var tree = $('#tree').jstree(true);
						
						userPartList(data.node.id);
						 $("#p_name").html("부서 조직 : "+data.node.original.text);
						 
						
					});
					//부서 셀렉트 바에 넣기
					var data_sele = datas.slice();  //객체 복사
					data_sele.sort((x,y)=>x.text.localeCompare(y.text));  //이름순 정렬
					//console.log(data_sele);
					data_sele.forEach(function (element, index, array) {
						if(element.depth!="0"){
							var option = $("<option value=" + element.id + ">" + element.text+"</option>");
				            $('#sele_part').append(option);
						}
					});	
				}
			});		
		});
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
						$('#sele_position').append(option);
					});
				}
			});
		});
	</script>
	<script>
	function userPartList(ps_id){
		$.ajax({
			type : "GET",
			url : "/userPartList.do",
			data : {
				"ps_id" : ps_id
			},
			contentType : "application/json; charset=utf-8",
			dataType : "json",
			success : function(response) {
				console.log(response);
				var fragment = "";
				fragment += "<div class='list-group'>";
	            $.each(response, function (idx, item) {
	                fragment += "<a class='list-group-item list-group-item-action active' onclick='javascript:userLoad("+item.u_id+");return false; '>" + item.u_name + "</a>";
	            });
	            fragment += "</div>";
	            $("#part_list").html(fragment);	
			}
		});	
	}	
	function userInfoByName(u_name) {
		$.ajax({
			type : "GET",
			url : "/userNameList.do",
			data: {
				"u_name" : u_name
			},
			contentType : "application/json; charset=utf-8",
			dataType : "json",
			success : function(response) {
				console.log(response.length);
				if (response.length === 0) {
					$("#searchResults").html('<div style="text-align: center; padding: 20px;"><p>검색 결과가 없습니다.</p></div>');
				} else {
					var fragment = "";
					fragment += '<table class="table table-bordered"><thead><tr><th scope="col">이름</th><th scope="col">부서명</th><th scope="col">직급명</th></tr></thead><tbody>';
					$.each(response, function (idx, item) {
						fragment += "<tr onclick='javascript:userLoad(" + item.u_id + ")'><td>" + item.u_name + "</td><td>" + item.dp_name + "</td><td>" + item.ps_name + "</td></tr>";
					});
					fragment += '</tbody></table>';
					$("#searchResults").html(fragment);
				}
			}
		})
	}
	function userLoad(u_id){
		$.ajax({
			type : "GET",
			url : "/userView.do",
			data : {
				"u_id" : u_id
			},
			contentType : "application/json; charset=utf-8",
			dataType : "json",
			success : function(response) {
				$('#user_info').html( response.u_name+"님 정보를 수정 중입니다.");
				$('#h_new_check').val("modi");
				$('#h_u_id').val(response.u_id);
				$('#name').val(response.u_name);
				$('#id').val(response.u_login_id);
				$('#password').val(response.u_login_pwd);
				$('#h_login_pwd').val(response.u_login_pwd);
				$('#email').val(response.u_email);
				$('#u_admin_num').val(response.u_admin_num);
				$("#grade").val(response.u_grade).prop("selected", true);
				$("#sele_part").val(response.dp_id).prop("selected", true); 
				$("#sele_position").val(response.ps_id).prop("selected", true);
			}
		});	
	}
	
	$("#save").click(function() {
		if($('#h_new_check').val()=="new"){
			$('#alert').html("사용자를 선택해주세요.");
			return;
		}
		
		if ($('#password').val().length < 8) {
			$('#alert').html("비밀번호를 8자 이상 입력해주세요.");
			return;
		}
		if(!confirm("저장 하시겠습니까?")) return;
		
		var u_id = $('#h_u_id').val();
		var u_name = $('#name').val();
		var u_login_id = $('#id').val();
		var u_login_pwd = $('#password').val();
		var u_email = $('#email').val();
		var u_admin_num = $('#u_admin_num').val();
		var u_grade = $("#grade option:selected").val();
		var dp_id = $("#sele_part option:selected").val();
		var ps_id = $("#sele_position option:selected").val();
		
		$.ajax({
			type : "GET",
			url : "/userUpdate.do",
			data : {
				"u_id" : u_id,
				"u_name" : u_name,
				"u_login_id" : u_login_id,
				"u_login_pwd" : u_login_pwd,
				"u_email" : u_email,
				"u_admin_num" : u_admin_num,
				"u_grade" : u_grade,
				"dp_id" : dp_id,
				"ps_id" : ps_id				
			},
			dataType : "text",
			success : function(response) {
				alert("수정하였습니다.");
				window.location.reload() ;
			}
		});
	});
	$("#delete").click(function() {
		if($('#h_new_check').val()=="new"){
			$('#alert').html("사용자를 선택해주세요.");
			return;
		}
		if(!confirm("삭제 하시겠습니까?")) return;
		
		var u_id = $('#h_u_id').val();
		var u_name = $('#name').val();
		
		$.ajax({
			type : "GET",
			url : "/userDelete.do",
			data : {
				"u_id" : u_id,			
			},
			dataType : "text",
			success : function(response) {
				alert(u_name+"님 삭제 하였습니다.");
				window.location.reload() ;
			}
		});
		
	});
	$("#search").click(function() {
		var u_name = $("#name_input").val();
		if (u_name === "") {
			alert("사용자 이름을 입력해주세요.");
			return;
		}
		userInfoByName(u_name);
	})
	
	// 검색어 입력 후 엔터키 입력하면 검색 버튼 클릭
	$("#name_input").on('keypress', function(e){
		
		if(e.keyCode == '13'){
			$('#search').click();
		}
	
	})
	

	
	</script>
</body>
</html>
