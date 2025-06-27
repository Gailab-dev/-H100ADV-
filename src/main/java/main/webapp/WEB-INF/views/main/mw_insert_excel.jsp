<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %> 
<%
application.setAttribute("page", "mw_insert");
%>
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
	<%@ include file="../include/main_header.jsp"%>
	<div class="wrapper main-page">
		<div class="container position-relative">
			<div class="row">
				<h3 class="col-md-4">일괄등록(엑셀)</h3>
			</div>
			<div class="border p-3 my-3 bg-light">
				<div class="input-group justify-content-between">
					<form id="readExcelForm" method="post"
						encType="multipart/form-data">
						<div class="custom-file">
							<input type="file" id="excelFile" name="excelFile"
								accept=".xls,.xlsx">
						</div>

					</form>
					<div class="input-group-append">
						<button class="btn btn-outline-secondary" type="button"
							id="readExcel">가져오기</button>
					</div>
				</div>
				<!-- 
          <div class="alert-wrapper d-flex align-items-center mt-2 ml-2">
            <embed src="${path}/resources/images/exclamation-circle.svg" type="image/svg+xml" aria-label="info">
            <p class="ml-1"> 가져올 수 없는 파일 입니다.</p>
          </div>
           -->


			</div>
			<table class="table table-list table-sm border-bottom mt-4 w-100">
				<colgroup>
					<col width="20%" />
					<col width="50%" />
					<col width="20%" />
					<col width="20%" />
					<col width="20%" />
				</colgroup>
				<thead>
					<tr class="bg-light">
						<th>선택</th>
						<th>제목</th>
						<th>위치</th>
						<th>행정동</th>
						<th>민원인</th>
					</tr>
				</thead>
				<tbody>
					<form id="form" method="post">
					    <input type="hidden" id="arrayParam" name="arrayParam">
						<c:forEach var="excelComplaint" items="${excelComplaints }">
							<tr>
								<td data-label="선택"><input type="checkbox" name="check" value="${excelComplaint.cId }"></td>
								<td data-label="제목">
									<p class="text-left text-truncate">${excelComplaint.cTitle }
									</p>
								</td>
								<td data-label="위치">${excelComplaint.cAddress }</td>
								<td data-label="행정동">${excelComplaint.cDistrict }</td>
								<td data-label="민원인">${excelComplaint.cPetitioner }</td>
							</tr>
						</c:forEach>
					</form>
				</tbody>
			</table>
			<c:if test="${fn:length(excelComplaints) == 0}">
				<div class="d-flex justify-content-center">해당 항목이 존재하지 않습니다.</div>
			</c:if>
			<!-- pagination start -->
			<div id="paginationBox" class="pagination1">
				<ul class="pagination" style="justify-content: center;">

					<c:if test="${pagination.prev}">
						<li class="page-item"><a class="page-link" href="#"
							onClick="fn_prev('${pagination.page}', '${pagination.range}', '${pagination.rangeSize}', '${pagination.listSize}'
	                    ,'${search.searchType}', '${search.keyword}')">이전</a></li>
					</c:if>

					<c:forEach begin="${pagination.startPage}"
						end="${pagination.endPage}" var="testId">
						<li
							class="page-item <c:out value="${pagination.page == testId ? 'active' : ''}"/> ">
							<a class="page-link" href="#"
							onClick="fn_pagination('${testId}', '${pagination.range}', '${pagination.rangeSize}', '${pagination.listSize}'
	                     ,'${search.searchType}', '${search.keyword}')">
								${testId} </a>
						</li>
					</c:forEach>

					<c:if test="${pagination.next}">
						<li class="page-item"><a class="page-link" href="#"
							onClick="fn_next('${pagination.range}', '${pagination.range}', '${pagination.rangeSize}', '${pagination.listSize}'
	                    ,'${search.searchType}', '${search.keyword}')">다음</a></li>
					</c:if>
				</ul>
			</div>
			<!-- pagination end -->

			<div class="button-wrapper justify-content-between mt-4">
				<div>
					<button type="button" class="btn btn-success"
					onclick="location.href='${path}/resources/민원양식.xlsx'">양식
					다운로드</button>
					<button type="button" class="btn btn-outline-danger" onclick="deleteComplaints()">삭제</button>
				</div>
				<button type="button" class="btn btn-secondary" onclick="processComplaints()">임시 저장</button>
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
		
				$("#form").attr("action", "delete_excel_complaint.do");
				$("#form").submit();
			}
		}
	
		function processComplaints() {
			if (confirm("임시저장 하시겠습니까?")) {
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
		
				$("#form").attr("action", "process_excel_complaints.do");
				$("#form").submit();
			}
		}
		
		$(document).ready(
				function() {
					$("#readExcel").click(
							function() {
								let type = $("#readExcelForm")[0][0].files[0].type;
								console.log(type);
								if (type == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" || type == "application/haansoftxlsx") {
									$("#readExcelForm").attr("action",
									"/main/insert_complaint_excel.do");
									$("#readExcelForm").submit();
								} else {
									alert("게시된 양식 파일만 업로드 가능합니다.");
								}
							});
				});

		function fn_prev(page, range, rangeSize, listSize, searchType, keyword) {

			var page = ((range - 2) * rangeSize) + 1;
			var range = range - 1;

			var url = "/main/mw_insert_excel.do";
			url += "?page=" + page;
			url += "&range=" + range;
			url += "&listSize=" + listSize;
			location.href = url;
		}

		//페이지 번호 클릭
		function fn_pagination(page, range, rangeSize, listSize, searchType,
				keyword) {

			var url = "/main/mw_insert_excel.do";
			url += "?page=" + page;
			url += "&range=" + range;
			url += "&listSize=" + listSize;
			location.href = url;
			console.log(url);
		}

		//다음 버튼 이벤트
		//다음 페이지 범위의 가장 앞 페이지로 이동
		function fn_next(page, range, rangeSize, listSize, searchType, keyword) {
			var page = parseInt((range * rangeSize)) + 1;
			var range = parseInt(range) + 1;
			var url = "/main/mw_insert_excel.do";
			url += "?page=" + page;
			url += "&range=" + range;
			url += "&listSize=" + listSize;
			location.href = url;
		}
	</script>
</body>
</html>
