<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<%
application.setAttribute("page", "mw_completed");
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
<script>
	$(function() {
		//input을 datepicker로 선언
		$("#startDate, #endDate")
				.datepicker(
						{
							dateFormat : 'yy-mm-dd' //달력 날짜 형태
							,
							showOtherMonths : true //빈 공간에 현재월의 앞뒤월의 날짜를 표시
							,
							showMonthAfterYear : true // 월- 년 순서가아닌 년도 - 월 순서
							,
							changeYear : true //option값 년 선택 가능
							,
							changeMonth : true //option값  월 선택 가능                
							,
							showOn : "both" //button:버튼을 표시하고,버튼을 눌러야만 달력 표시 ^ both:버튼을 표시하고,버튼을 누르거나 input을 클릭하면 달력 표시  
							,
							buttonImage : "http://jqueryui.com/resources/demos/datepicker/images/calendar.gif" //버튼 이미지 경로
							,
							buttonImageOnly : true //버튼 이미지만 깔끔하게 보이게함
							,
							buttonText : "선택" //버튼 호버 텍스트              
							,
							yearSuffix : "년" //달력의 년도 부분 뒤 텍스트
							,
							monthNamesShort : [ '1월', '2월', '3월', '4월', '5월',
									'6월', '7월', '8월', '9월', '10월', '11월', '12월' ] //달력의 월 부분 텍스트
							,
							monthNames : [ '1월', '2월', '3월', '4월', '5월', '6월',
									'7월', '8월', '9월', '10월', '11월', '12월' ] //달력의 월 부분 Tooltip
							,
							dayNamesMin : [ '일', '월', '화', '수', '목', '금', '토' ] //달력의 요일 텍스트
							,
							dayNames : [ '일요일', '월요일', '화요일', '수요일', '목요일',
									'금요일', '토요일' ] //달력의 요일 Tooltip
							,
							minDate : "-5Y" //최소 선택일자(-1D:하루전, -1M:한달전, -1Y:일년전)
							,
							maxDate : "+5y" //최대 선택일자(+1D:하루후, -1M:한달후, -1Y:일년후)  
						});

	});
</script>
<body>
	<%@ include file="../include/main_header.jsp"%>
	<div class="wrapper main-page">
		<div class="container position-relative">
			<h3>처리완료</h3>
			<div class="border px-3 pt-3 pb-1 my-3 bg-light">
				<div class="row mx-1">
					<div class="col-lg-2 col-sm-6  pb-2">
						<select class="custom-select d-block w-100" id="searchType"
							name="searchType">
							<option value="title">제목</option>
							<option value="content">내용</option>
							<option value="petitioner">민원인</option>
							<option value="officer">처리자</option>
							<option value="serial">일렬번호</option>
							<option value="district">행정동</option>
							<option value="department">부서</option>
							<option value="separation">분류유형</option>
							<option value="process">처리구분</option>
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
						민원 : ${complaintCnt }건</div>
				</div>
				<div class="row mx-1 align-items-center">
					<div class="date-picker-wapper col-md-auto">
						<input type="text" class="form-control" id="startDate"
							name="startDate" placeholder="날짜를 입력해주세요."> ~ <input
							type="text" class="form-control" id="endDate" name="endDate"
							placeholder="날짜를 입력해주세요.">
					</div>
				</div>
			</div>
			<table class="table table-list table-lg border-bottom mt-4 w-100">
				<colgroup>
					<col width="15%" />
					<col width="35%" />
					<col width="10%" />
					<col width="10%" />
					<col width="15%" />
					<col width="15%" />
				</colgroup>
				<thead>
					<tr class="bg-light">
						<th>신청접수일</th>
						<th>제목</th>
						<th>담당부서</th>
						<th>행정동</th>
						<th>분류유형</th>
						<th>처리구분</th>
					</tr>
				</thead>
				<tbody>
					<c:forEach var="completedComplaint" items="${completedList }">
						<tr>
							<td data-label="신청접수일">${completedComplaint.cReceiptDate }</td>
							<td data-label="제목">
								<p class="text-left text-truncate">
									<a href="mw_completed_view.do?id=${completedComplaint.cId }">${completedComplaint.cTitle }</a>
								</p>
							</td>
							<td data-label="담당부서">${completedComplaint.dpMasterName }</td>
							<td data-label="행정동">${completedComplaint.cDistrict }</td>
							<td data-label="분류유형">${completedComplaint.cSeparationType }</td>
							<td data-label="처리구분">${completedComplaint.cProcessClass }</td>
						</tr>
					</c:forEach>
				</tbody>
			</table>
			<c:if test="${fn:length(completedList) == 0}">
				<div class="d-flex justify-content-center">해당 항목이 존재하지 않습니다.</div>
			</c:if>
			<!-- pagination start -->
			<div id="paginationBox" class="pagination1">
				<ul class="pagination" style="justify-content: center;">

					<c:if test="${pagination.prev}">
						<li class="page-item"><a class="page-link" href="#"
							onClick="fn_prev('${pagination.page}', '${pagination.range}', '${pagination.rangeSize}', '${pagination.listSize}'
                    ,'${search.searchType}', '${search.keyword}', '${search.startDate }', '${search.endDate }')">이전</a></li>
					</c:if>

					<c:forEach begin="${pagination.startPage}"
						end="${pagination.endPage}" var="testId">
						<li
							class="page-item <c:out value="${pagination.page == testId ? 'active' : ''}"/> ">
							<a class="page-link" href="#"
							onClick="fn_pagination('${testId}', '${pagination.range}', '${pagination.rangeSize}', '${pagination.listSize}'
                     ,'${search.searchType}', '${search.keyword}', '${search.startDate }', '${search.endDate }')">
								${testId} </a>
						</li>
					</c:forEach>

					<c:if test="${pagination.next}">
						<li class="page-item"><a class="page-link" href="#"
							onClick="fn_next('${pagination.range}', '${pagination.range}', '${pagination.rangeSize}', '${pagination.listSize}'
                    ,'${search.searchType}', '${search.keyword}', '${search.startDate }', '${search.endDate }')">다음</a></li>
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
		function fn_prev(page, range, rangeSize, listSize, searchType, keyword,
				startDate, endDate) {

			var page = ((range - 2) * rangeSize) + 1;
			var range = range - 1;

			var url = "/main/mw_completed_list.do";
			url += "?page=" + page;
			url += "&range=" + range;
			url += "&listSize=" + listSize;
			url += "&searchType=" + searchType;
			url += "&keyword=" + keyword;
			url += "&startDate=" + startDate;
			url += "&endDate=" + endDate;
			location.href = url;
		}

		//페이지 번호 클릭
		function fn_pagination(page, range, rangeSize, listSize, searchType,
				keyword, startDate, endDate) {

			var url = "/main/mw_completed_list.do";
			url += "?page=" + page;
			url += "&range=" + range;
			url += "&listSize=" + listSize;
			url += "&searchType=" + searchType;
			url += "&keyword=" + keyword;
			url += "&startDate=" + startDate;
			url += "&endDate=" + endDate;
			location.href = url;
			console.log(url);
		}

		//다음 버튼 이벤트
		//다음 페이지 범위의 가장 앞 페이지로 이동
		function fn_next(page, range, rangeSize, listSize, searchType, keyword,
				startDate, endDate) {
			var page = parseInt((range * rangeSize)) + 1;
			var range = parseInt(range) + 1;
			var url = "/main/mw_completed_list.do";
			url += "?page=" + page;
			url += "&range=" + range;
			url += "&listSize=" + listSize;
			url += "&searchType=" + searchType;
			url += "&keyword=" + keyword;
			url += "&startDate=" + startDate;
			url += "&endDate=" + endDate;
			location.href = url;
		}

		// 검색
		$(document).on('click', '#btnSearch', function(e) {
			e.preventDefault();
			var url = "/main/mw_completed_list.do";
			url += "?searchType=" + $('#searchType').val();
			url += "&keyword=" + $('#keyword').val();
			url += "&startDate=" + $('#startDate').val();
			url += "&endDate=" + $('#endDate').val();
			location.href = url;
			console.log(url);

		});

		$(document).on('click', '#excel', function(e) {
			e.preventDefault();
			var url = "/main/excel_completed.do";
			url += "?searchType=" + "${pagination.searchType}"
			url += "&keyword=" + "${pagination.keyword}"
			url += "&startDate=" + "${search.startDate}"
			url += "&endDate=" + "${search.endDate}"
			location.href = url;
			console.log(url);

		});
	</script>
</body>
</html>
