<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
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
			<h3>민원 목록</h3>
			<div class="border px-3 pt-3 pb-1 my-3 bg-light">
				<div class="row mx-1">
					<div class="col-lg-2 col-sm-6  pb-2">
						<select class="custom-select d-block w-100" id="searchType"
							name="searchType">
							<option value="title">제목</option>
							<option value="district">행정동</option>
							<option value="petitioner">민원인</option>
							<option value="department">부서</option>
							<option value="officer">담당자</option>
						</select>
					</div>
					<div class="col-lg-4 col-sm-6  pb-2">
						<input type="text" class="form-control" id="keyword"
							name="keyword" />
					</div>
					<div class="col-lg-2 pb-2"></div>
					<div class="col-lg-2 col-md-6 pb-2">
						<button class="btn btn-block btn-bule" name="btnSearch"
							id="btnSearch">검색</button>
					</div>
					<div class="col-lg-2 col-md-6 pb-2 ml-auto text-right">총 완료
						민원 : ${allComplaintCnt }건</div>
				</div>
			</div>
			<table class="table table-list table-lg border-bottom mt-4 w-100">
				<colgroup>
					<col width="10%" />
					<col width="10%" />
					<col width="40%" />
					<col width="10%" />
					<col width="10%" />
					<col width="10%" />
					<col width="10%" />
				</colgroup>
				<thead>
					<tr class="bg-light">
						<th>민원등록일</th>
						<th>신청접수일</th>
						<th>제목</th>
						<th>담당부서</th>
						<th>행정동</th>
						<th>분류유형</th>
						<th>처리구분</th>
					</tr>
				</thead>
				<tbody>
					<c:forEach var="complaint" items="${allList }">
						<tr>
							<td data-label="민원등록일">${complaint.cWriteDate }</td>
							<td data-label="신청접수일">${complaint.cReceiptDate }</td>
							<td data-label="제목">
								<p class="text-left text-truncate">
									<a href="mw_process_view.do?id=${complaint.cId }">${complaint.cTitle }</a>
								</p>
							</td>
							<td data-label="담당부서">${complaint.dpMasterName }</td>
							<td data-label="행정동">${complaint.cDistrict }</td>
							<td data-label="분류유형">${complaint.cSeparationType }</td>
							<td data-label="처리구분">${complaint.cProcessClass }</td>
						</tr>
					</c:forEach>
				</tbody>
			</table>
			<c:if test="${fn:length(allList) == 0}">
				<div class="d-flex justify-content-center">해당 항목이 존재하지 않습니다.</div>
			</c:if>
			<!-- pagination start -->
			<div id="paginationBox" class="pagination1">
				<ul class="pagination" style="justify-content: center;">

					<c:if test="${pagination.prev}">
						<li class="page-item"><a class="page-link" href="#"
							onClick="fn_prev('${pagination.page}', '${pagination.range}', '${pagination.rangeSize}', '${pagination.listSize}'
                    ,'${search.searchType}', '${search.keyword}', '${search.searchType2}', '${search.keyword2}')">이전</a></li>
					</c:if>

					<c:forEach begin="${pagination.startPage}"
						end="${pagination.endPage}" var="testId">
						<li
							class="page-item <c:out value="${pagination.page == testId ? 'active' : ''}"/> ">
							<a class="page-link" href="#"
							onClick="fn_pagination('${testId}', '${pagination.range}', '${pagination.rangeSize}', '${pagination.listSize}'
                     ,'${search.searchType}', '${search.keyword}', '${search.searchType2}', '${search.keyword2}')">
								${testId} </a>
						</li>
					</c:forEach>

					<c:if test="${pagination.next}">
						<li class="page-item"><a class="page-link" href="#"
							onClick="fn_next('${pagination.range}', '${pagination.range}', '${pagination.rangeSize}', '${pagination.listSize}'
                    ,'${search.searchType}', '${search.keyword}', '${search.searchType2}', '${search.keyword2}')">다음</a></li>
					</c:if>
				</ul>
			</div>
			<!-- pagination end -->
			<button id="excel">엑셀 다운로드</button>
		</div>
	</div>
	<%@ include file="../include/main_footer.jsp"%>
	<script>
		$('#keyword').on('keypress', function(e) {
			if (e.keyCode == '13') {
				$('#btnSearch').click();
			}
		});
		function fn_prev(page, range, rangeSize, listSize, searchType, keyword, searchType2, keyword2) {

			var page = ((range - 2) * rangeSize) + 1;
			var range = range - 1;

			var url = "/main/mw_all_list.do";
			url += "?page=" + page;
			url += "&range=" + range;
			url += "&listSize=" + listSize;
			url += "&searchType=" + searchType;
			url += "&keyword=" + keyword;
			url += "&searchType2=" + searchType2;
			url += "&keyword2=" + keyword2;
			location.href = url;
		}

		//페이지 번호 클릭
		function fn_pagination(page, range, rangeSize, listSize, searchType,
				keyword, searchType2, keyword2) {

			var url = "/main/mw_all_list.do";
			url += "?page=" + page;
			url += "&range=" + range;
			url += "&listSize=" + listSize;
			url += "&searchType=" + searchType;
			url += "&keyword=" + keyword;
			url += "&searchType2=" + searchType2;
			url += "&keyword2=" + keyword2;
			location.href = url;
			console.log(url);
		}

		//다음 버튼 이벤트
		//다음 페이지 범위의 가장 앞 페이지로 이동
		function fn_next(page, range, rangeSize, listSize, searchType, keyword, searchType2, keyword2) {
			var page = parseInt((range * rangeSize)) + 1;
			var range = parseInt(range) + 1;
			var url = "/main/mw_all_list.do";
			url += "?page=" + page;
			url += "&range=" + range;
			url += "&listSize=" + listSize;
			url += "&searchType=" + searchType;
			url += "&keyword=" + keyword;
			url += "&searchType2=" + searchType2;
			url += "&keyword2=" + keyword2;
			location.href = url;
		}

		// 검색
		$(document).on('click', '#btnSearch', function(e) {
			e.preventDefault();
			var url = "/main/mw_all_list.do";
			url += "?searchType=" + $('#searchType').val();
			url += "&keyword=" + $('#keyword').val();
			location.href = url;
			console.log(url);

		});

		$(document).on('click', '#excel', function(e) {
			e.preventDefault();
			var url = "/main/excel_all.do";
			url += "?searchType=" + "${pagination.searchType}"
			url += "&keyword=" + "${pagination.keyword}"
			location.href = url;
			console.log(url);

		});
	</script>
</body>
</html>
