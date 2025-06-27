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
		<div class="container position-relative mb-5">
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
							name="keyword" placeholder="검색어를 입력해 주세요" />
					</div>
					<div class="col-lg-2 pb-2"></div>
					<div class="col-lg-2 col-md-6 pb-2">
						<button class="btn btn-block btn-bule" name="btnSearch"
							id="btnSearch">검색</button>
					</div>
					<div class="row mx-1 align-items-center">
						<div class="date-picker-wapper col-md-auto">
							<input type="text" class="form-control" id="startDate" name="startDate" placeholder="날짜를 입력해주세요.">
							~ <input type="text" class="form-control" id="endDate" name="endDate" placeholder="날짜를 입력해주세요.">
						</div>
					</div>
				</div>
			</div>
			<c:choose>
				<c:when test="${keyword ne null}">
					<div class=" p-2">
						<div class="row justify-content-center pb-3 ">
							<div class="search-item finished col-sm-3 mr-3 "
								onclick="location.href='/main/mw_completed_list.do?searchType=${searchType }&keyword=${keyword}'">
								<p class="bold mb-2">처리완료</p>
								<h5 class="bold">${completeComplaintList}건</h5>
							</div>
							<div class="search-item progressing  col-sm-3"
								onclick="location.href='/main/mw_not_completed_list.do?searchType=${searchType }&keyword=${keyword}'">
								<p class="bold mb-2">처리중인 민원</p>
								<h5 class="bold">${processComplaintList }건</h5>
							</div>
						</div>
						<h4 class="py-2  text-center">"${keyword }"에 대한 전체 총
							${completeComplaintList + processComplaintList } 건의 민원을 찾았습니다.</h4>
					</div>
				</c:when>
			</c:choose>
			<div class="p-4 border mb-2 ">
				<c:forEach var="item" items="${lists}" varStatus="status">
					<c:if test="${fn:length(item) != 0 }">
						<c:forEach var="type" items="${minwonType[status.index] }">
							<h4 class="mt-2 mb-4 serch-list-title">${type }</h4>

							<c:forEach items="${item }" var="minwon">
								<div class="p-2 border-bottom">
									<div class="d-flex ">
										<c:choose>
											<c:when test="${minwon.cNotificated == 9}">
												<h5 class="text-left text-truncate">
													<a href="mw_completed_view.do?id=${minwon.cId }">${minwon.cTitle }</a>
												</h5>
											</c:when>
											<c:otherwise>
												<h5 class="text-left text-truncate">
													<a href="mw_not_completed_view.do?id=${minwon.cId }">${minwon.cTitle }</a>
												</h5>
											</c:otherwise>
										</c:choose>
										<p class="px-2">${minwon.cDistrict }</p>
										<p class="px-2">${minwon.cWriteDate }</p>
									</div>
									<div class="민원내용">
										<p class="text-left text-truncate">${minwon.cContent }</p>
									</div>
								</div>
							</c:forEach>
							<c:choose>
								<c:when test="${keyword ne null and keyword ne '' }">
									<div class="more-btn-wrapper mb-5">
										<p class="more-btn"
											onclick="location.href='/main/mw_all_list.do?searchType=${searchType }&keyword=${keyword}&startDate=${startDate}&endDate=${endDate}'">+
											더보기</p>
									</div>
								</c:when>
								<c:otherwise>
									<div class="more-btn-wrapper mb-5">
										<p class="more-btn"
											onclick="location.href='/main/mw_all_list.do?searchType=type&keyword=${type}'">+
											더보기</p>
									</div>
								</c:otherwise>
							</c:choose>
						</c:forEach>

					</c:if>
				</c:forEach>
			</div>
		</div>
		<%@ include file="../include/main_footer.jsp"%>
		<script>
			$('#keyword').on('keypress', function(e) {
				if (e.keyCode == '13') {
					$('#btnSearch').click();
				}
			});
			$(document).on('click', '#btnSearch', function(e) {
				e.preventDefault();
				var url = "/main/mw_search_list.do";
				url += "?searchType=" + $('#searchType').val();
				url += "&keyword=" + $('#keyword').val();
				url += "&startDate=" + $('#startDate').val();
				url += "&endDate=" + $('#endDate').val();
				location.href = url;
				console.log(url);

			});
		</script>
</body>
</html>

