<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %> 
<%
application.setAttribute("page", "mw_insert");
%>
<html lang="kr">
<head>
<meta charset="UTF-8">
<title>동구 종합민원이력관리시스템</title>
<link type="image/x-icon" rel="shortcut icon"
	href="${path}/resources/images/favicon.ico">
<%@ include file="../include/main_lib.jsp"%>
</head>
<body>
	<%@ include file="../include/main_header.jsp"%>
	<input type="hidden" id="uId" name="uId"
		value="${sessionScope.userId }">

	<div class="wrapper main-page">
		<div class="container position-relative">
			<div class="row">
				<h3 class="col-md-4">임시저장 목록</h3>
			</div>

			<table class="table table-list table-lg border-bottom mt-4 w-100">
				<colgroup>
					<col width="11%" />
					<col width="11%" />
					<col width="11%" />
					<col width="21%" />
					<col width="11%" />
					<col width="11%" />
					<col width="11%" />
					<col width="11%" />
				</colgroup>
				<thead>
					<tr class="bg-light">
						<!-- 
            	<th><input class="form-check-input" type="checkbox" value="" name="check" onclick="selectAll(this)">
                <label class="form-check-label" for="flexCheckChecked">
                  전체 선택
                </label></th>
            	 -->
						<th>선택</th>
						<th>접수날짜</th>
						<th>행정동</th>
						<th>제목</th>
						<th>연관1</th>
						<th>연관2</th>
						<th>연관3</th>
						<th>연관4</th>
					</tr>
					
				</thead>
				
				<tbody>
					
					<form id="form" method="post">
						
						<input type="hidden" id="arrayParam" name="arrayParam">
						<c:forEach var="tempComplaint" items="${tempComplaints }">
							
							<tr>
								<td><input type="checkbox" value=${tempComplaint.cId }
									name="check"></td>
								<td data-label="접수날짜">${tempComplaint.cReceiptDate }</td>
								<td data-label="행정동">${tempComplaint.cDistrict }</td>
								<td data-label="제목"><p class="text-left text-truncate">
										<a href="mw_insert_temp_view.do?id=${tempComplaint.cId}">${tempComplaint.cTitle }</a>
									</p></td>
								<td data-label="연관부서1">${tempComplaint.dpName01 }</td>
								<td data-label="연관부서2">${tempComplaint.dpName02 }</td>
								<td data-label="연관부서3">${tempComplaint.dpName03 }</td>
								<td data-label="연관부서3">${tempComplaint.dpName04 }</td>
							</tr>
						</c:forEach>
					</form>
					
				</tbody>
				
			</table>
			<c:if test="${fn:length(tempComplaints) == 0}">
				<div class="d-flex justify-content-center">해당 항목이 존재하지 않습니다.</div>
			</c:if>
			<div class="d-flex justify-content-between mt-4">
				<button type="button" class="btn btn-outline-danger" id="delete"
					onclick="deleteComplaints()">민원 삭제</button>
				<!-- 
				<button type="button" class="btn btn-secondary"
					onclick="processComplaints()">민원 등록 확정</button>
				 -->
			</div>
		</div>
	</div>
	<%@ include file="../include/main_footer.jsp"%>
	<script>
		function deleteComplaints() {
			if (confirm("삭제하시겠습니까?")) {
				var checkArr = []; // 배열 초기화
				$("input[name='check']:checked").each(function(i) {
					checkArr.push($(this).val()); // 체크된 것만 값을 뽑아서 배열에 push
				})

				console.log(checkArr);
				if (checkArr.length == 0) {
					console.log(checkArr.length);
					alert("민원을 선택해주세요");
					return;
				}
				$("#arrayParam").val(checkArr);

				$("#form").attr("action", "delete_complaint.do");
				$("#form").submit();
			}
		}

		function processComplaints() {
			var checkArr = [];
			$("input[name='check']:checked").each(function(i) {
				checkArr.push($(this).val()); // 체크된 것만 값을 뽑아서 배열에 push
			})

			console.log(checkArr);
			if (checkArr.length == 0) {
				console.log(checkArr.length);
				alert("민원을 선택해주세요");
				return;
			}
			$("#arrayParam").val(checkArr);

			$("#form").attr("action", "process_complaints.do");
			$("#form").submit();
		}
	</script>
</body>
</html>
