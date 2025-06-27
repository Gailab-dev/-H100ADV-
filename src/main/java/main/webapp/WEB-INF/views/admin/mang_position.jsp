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
<style>

</style>
</head>

<body>
	<%@ include file="../include/header.jsp"%>

	<div class="container-fluid">
		<div class="row">
			<%@ include file="../include/nav.jsp"%>

			<main role="main"
				class="col-md-9 ml-sm-auto col-lg-10 d-flex flex-column"
				style="height: calc(100vh - 70px);">
				<div class="container">
					<div
						class=" d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3">
						<h1 class="h2">직급 등록</h1>
					</div>
					<div class="row">
						<div class="col-md-4 mb-4">
						<div  id="position_list">
						  <div class="list-group">
								<a class="list-group-item list-group-item-action active">부서명1</a>
								<a class="list-group-item list-group-item-action">부서명</a> <a
									class="list-group-item list-group-item-action">부서명</a> <a
									class="list-group-item list-group-item-action">부서명</a>
							</div>
							</div>
						</div>
						<div class="col-md-8">
							<div id="title_alert" class="alert alert-secondary d-flex align-items-center"
								role="alert">신규 등급 등록중입니다.</div>
							<div class="tab-content" id="nav-tabContent">
								<div class="tab-pane fade show active" id="list-home"
									role="tabpanel" aria-labelledby="list-home-list">
									<div class=" order-md-1">
										<div class="mb-3">
											<label for="id">부서명<span class="text-muted"></span></label> <input
												type="id" class="form-control" id="posit_name"
												placeholder="부서명을 입력해 주세요.">
										</div>
										<div class="row">
											<div class="col-md-5 mb-3">
												<label for="country">출력 순서</label> <input type="number"
													class="form-control" placeholder="숫자" id="posit_rank" value="1" >
											</div>
										</div>
										<hr class="mb-4">
									</div>
									<div class="alert alert-danger" role="alert">-</div>
									<div class="row">
										<div class="col-md-4 mb-3">
											<button class="btn btn-primary btn-block" type="submit"
												id="new">신규</button>
										</div>
										<div class="col-md-4 mb-3">
											<button class="btn btn-success btn-block" type="submit"
												id="save">저장</button>
										</div>
										<div class="col-md-4 mb-3">
											<button class="btn btn-outline-danger btn-block"
												type="submit" id="delete">삭제</button>
										</div>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
				<!-- footer start -->
				<%@ include file="../include/footer.jsp"%>
		</div>
		</main>
	</div>
	</div>
	<input type="hidden" id="h_new_check" value="new">
	<input type="hidden" id="h_ps_id">
	<script>
		$(document).ready(function() {
			$.ajax({
				type : "POST",
				url : "/positionList.do",
				contentType : "application/json; charset=utf-8",
				dataType : "json",
				success : function(response) {
					console.log(response);
					var fragment = "";
					fragment += "<div class='list-group'>";
		            $.each(response, function (idx, item) {
		                fragment += "<a class='list-group-item list-group-item-action active' onclick='javascript:PositionLoad("+item.ps_id+");return false; '>" + item.ps_name + "</a>";
		            });
		            fragment += "</div>";
		            $("#position_list").html(fragment);	
				}
			});
		});
		
		function PositionLoad(ps_id){
			$.ajax({
				type : "GET",
				url : "/positionView.do",
				data : {
					"ps_id" : ps_id
				},
				contentType : "application/json; charset=utf-8",
				dataType : "json",
				success : function(response) {
					console.log(response);
					
					$('#h_new_check').val("modi");
					$('#title_alert').html("{"+response.ps_name+"} 등급 수정중 입니다.");
					$('#h_ps_id').val(response.ps_id);
					$('#posit_name').val(response.ps_name);
					$('#posit_rank').val(response.ps_rank);
				}
			});
		}
		

		function NewData(){
			$('#title_alert').html("신규 등급 등록중입니다.");
			$('#h_new_check').attr("value", "new");
			$('#h_ps_id').val("");
			$('#posit_name').val("");
			$('#posit_rank').val("1");
		}
		
		
		$("#new").click(function() {
			NewData();
			
		});
		
		function positionFind(ps_name) {
			var position = "";
			$.ajax({
				type : "GET",
				url : "/positionFind.do",
				data : {
					"ps_name" : ps_name,
				},
				async : false,
				dataType : "text",
				contentType : "application/json; charset=utf-8",
				success : function(response) {
					console.log(response);
					position = response;
				}
			});
			
			return position;
		}
		
		$("#save").click(function() {
			var ps_name = $('#posit_name').val();
			
			if (positionFind(ps_name)) {
				alert("동일한 직급명을 등록할 수 없습니다.");
				return;
			}
			
			if($('#posit_name').val()=="") {
				alert("직급을 작성해주세요.");
				$('#posit_name').focus();
				return;
			}
			if($('#posit_rank').val()=="") {
				alert("출력순서를 숫자로 적어주세요.");
				$('#posit_rank').focus();
				return;
			}
			if(!confirm("저장 하시겠습니까?")) return;
			var ps_id = $('#h_ps_id').val();
			
			var ps_rank = $('#posit_rank').val();
			if($('#h_new_check').val()=="new"){  //신규 저장
				$.ajax({
					type : "GET",
					url : "/positonInsert.do",
					data : {
						"ps_name" : ps_name,
						"ps_rank" : ps_rank
					},
					dataType : "text",
					success : function(response) {
						alert("등록하였습니다.");
						window.location.reload() ;
					}
				});
			}
			if($('#h_new_check').val()=="modi"){ //업데이트
				$.ajax({
					type : "GET",
					url : "/positionUpdate.do",
					data : {
						"ps_id" : ps_id,
						"ps_name" : ps_name,
						"ps_rank" : ps_rank
					},
					dataType : "text",
					success : function(response) {
						alert("업데이트 하였습니다.");
						window.location.reload(); 
					}
				});
			}
			
		});
		$("#delete").click(function() {
			if($('#h_new_check').val() !="modi"){
				alert("대상을 선택해주세요");
				return;
			} 
			if(!confirm("삭제 하시겠습니까?")) return;
			var ps_id = $('#h_ps_id').val();
			$.ajax({
				type : "GET",
				url : "/positionDelete.do",
				data : {
					"ps_id" : ps_id
				},
				dataType : "text",
				success : function(response) {
					if (response == "OK") {
						alert("삭제 했습니다.");
					} else {
						alert("삭제할 수 없습니다.")
					}
					window.location.reload(); 
				}
			});
		});
	</script>
</body>
</html>
