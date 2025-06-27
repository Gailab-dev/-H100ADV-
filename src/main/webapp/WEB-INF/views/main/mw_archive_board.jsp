<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<%
application.setAttribute("page", "mw_archive");
%>
<!DOCTYPE html>
<html lang="kr">
<head>
<meta charset="UTF-8">
<title>동구 종합민원이력관리시스템</title>
<link type="image/x-icon" rel="shortcut icon"
	href="${path}/resources/images/favicon.ico">
<%@ include file="../include/main_lib.jsp"%>
<style>
/* 노트 : css 폴더로 이동 부탁드립니다  */
.list-wrapper {
	min-height: 510px;
}

.table-list td.notice-file, .table-list td.notice-tag {
	padding: 0;
}

.notice-tag span {
	display: inline-block;
	background-color: #0066b3;
	padding: 4px 6px;
	border-radius: 5%;
	font-size: 12px;
	font-weight: 500;
	color: #fff;
}
</style>
</head>
<body>
	<%@ include file="../include/main_header.jsp"%>
	<div class="wrapper main-page">
		<div class="container position-relative">
			<div class="d-flex">
				<h3 class="col-md-4">자료실</h3>
			</div>
			<div class="border px-3 pt-3 pb-1 my-3 bg-light">
				<div class="row mx-1">
					<div class="col-lg-2 pb-2">
						<select class="custom-select d-block w-100" id="searchType" name="searchType"
							required="">
							<option value="title">제목</option>
							<option value="content">내용</option>
							<option value="writer">작성자</option>
						</select>
					</div>
					<div class="col-lg-4 pb-2">
						<input type="text" class="form-control" id="keyword" name="keyword" />
					</div>
					<div class="col-md-2 pb-2">
						<button class="btn btn-block btn-bule" id="btnSearch" name="btnSearch">검색</button>
					</div>
				</div>

			</div>
			<div class="list-wrapper">
				<table class="table table-list table-lg border-bottom mt-4 w-100">
					<colgroup>
						<col width="10%" />
						<col width="40%" />
						<col width="10%" />
						<col width="20%" />
						<col width="20%" />
						<col width="10%" />
					</colgroup>
					<thead>
						<tr class="bg-light">
							<th>No.</th>
							<th>제목</th>
							<th></th>
							<th>[작성부서]작성자</th>
							<th>작성일</th>
							<th>조회수</th>
						</tr>
					</thead>
					<tbody>
						<c:forEach items="${archiveList }" var="archive">
							<tr>
								<td data-label="No." class="notice-tag">${archive.a_id }</td>
								<td data-label="제목"><a
									href="/main/mw_archive_view.do?id=${archive.a_id }"><p
											class="text-left text-truncate">${archive.a_title }</p></a></td>
								<td data-label="파일첨부" class="notice-file"></td>
								<td data-label="[작성부서]작성자">[${archive.dp_name }]${archive.u_name }</td>
								<td data-label="작성일">${archive.date }</td>
								<td data-label="조회수">${archive.a_count }</td>

							</tr>
						</c:forEach>
						<!-- 
						

						<tr>
							<td data-label="No.">2</td>
							<td data-label="제목">
								<p class="text-left text-truncate">제목이 길떄 표기되는 방법 확인 중입니다
									제목이 길떄 표기되는 방법 확인 중입니다 제목이 길떄 표기되는 방법 확인 중입니다 제목이 길떄 표기되는 방법 확인
									중입니</p>
							</td>
							<td data-label="파일첨부" class="notice-file"></td>
							<td data-label="[작성부서]작성자">[작성부서]작성자</td>
							<td data-label="작성일">2020/05/17 10:52</td>
							<td data-label="조회수">10</td>
						</tr>
						 -->

					</tbody>
				</table>
				<c:if test="${fn:length(archiveList) == 0}">
					<div class="d-flex justify-content-center">해당 항목이 존재하지 않습니다.</div>
				</c:if>
			</div>
			<!-- /* 노트 페이지네이션 이쪽으로 넣어주세요 */ -->
			<!-- pagenation -->
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
			<div class="d-flex">
				<button class="btn ml-auto btn-bule"
					onclick='location.href="/main/mw_archive_insert.do"'>
					작성</button>
			</div>
		</div>
	</div>
	<%@ include file="../include/main_footer.jsp"%>
	<script>
		$('#keyword').on('keypress', function(e) {
			if (e.keyCode == '13') {
				$('#btnSearch').click();
			}
		});
		function fn_prev(page, range, rangeSize, listSize, searchType, keyword) {

			var page = ((range - 2) * rangeSize) + 1;
			var range = range - 1;

			var url = "/main/mw_archive_board.do";
			url += "?page=" + page;
			url += "&range=" + range;
			url += "&listSize=" + listSize;
			url += "&searchType=" + searchType;
			url += "&keyword=" + keyword;
			location.href = url;
		}

		//페이지 번호 클릭
		function fn_pagination(page, range, rangeSize, listSize, searchType,
				keyword) {

			var url = "/main/mw_archive_board.do";
			url += "?page=" + page;
			url += "&range=" + range;
			url += "&listSize=" + listSize;
			url += "&searchType=" + searchType;
			url += "&keyword=" + keyword;

			location.href = url;
			console.log(url);
		}

		//다음 버튼 이벤트
		//다음 페이지 범위의 가장 앞 페이지로 이동
		function fn_next(page, range, rangeSize, listSize, searchType, keyword) {
			var page = parseInt((range * rangeSize)) + 1;
			var range = parseInt(range) + 1;
			var url = "/main/mw_archive_board.do";
			url += "?page=" + page;
			url += "&range=" + range;
			url += "&listSize=" + listSize;
			url += "&searchType=" + searchType;
			url += "&keyword=" + keyword;
			location.href = url;
		}

		// 검색
		$(document).on('click', '#btnSearch', function(e) {
			e.preventDefault();
			var url = "/main/mw_archive_board.do";
			url += "?searchType=" + $('#searchType').val();
			url += "&keyword=" + $('#keyword').val();
			location.href = url;
			console.log(url);

		});
		;
	</script>
</body>
</html>
