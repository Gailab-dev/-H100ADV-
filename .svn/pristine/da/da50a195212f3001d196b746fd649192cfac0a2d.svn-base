<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<c:set var="userGrade" value="${sessionScope.userGrade }" />
<c:set var="userDepartment" value="${sessionScope.userDepartment }" />
<%
application.setAttribute("page", "");
%>
<!DOCTYPE html>
<html lang="kr">
<head>
<meta charset="UTF-8">
<title>동구 종합민원이력관리시스템</title>
<link type="image/x-icon" rel="shortcut icon"
	href="${path}/resources/images/favicon.ico">
<%@ include file="../include/main_lib.jsp"%>
<script src="${path}/resources/js/not_capture.js"></script>
<style type="text/css">
.tg {
	border-collapse: collapse;
	border-spacing: 0;
}

.tg td {
	border-color: black;
	border-style: solid;
	border-width: 1px;
	font-family: Arial, sans-serif;
	font-size: 14px;
	overflow: hidden;
	padding: 10px 5px;
	word-break: normal;
}

.tg th {
	border-color: black;
	border-style: solid;
	border-width: 1px;
	font-family: Arial, sans-serif;
	font-size: 14px;
	font-weight: normal;
	overflow: hidden;
	padding: 10px 5px;
	word-break: normal;
}

.tg .tg-0lax {
	text-align: left;
	vertical-align: top
}
</style>
</head>
<body>
	<%@ include file="../include/main_header.jsp"%>
	<c:set var="sum1" value="0" />
	<c:set var="sum2" value="0" />
	<c:set var="sum3" value="0" />
	<c:set var="sum4" value="0" />
	<c:forEach items="${minwonType }" var="type">
		<c:set var="flag" value="false" />
		<c:forEach items="${getGroupedSeparationType }" var="separationType">
			<c:if
				test="${separationType.c_separation_type eq type and separationType.c_notificated eq 2 }">
				<c:set var="flag" value="true" />
				<c:set var="sum1" value="${sum1 + separationType.cstcount }" />
			</c:if>
		</c:forEach>
		<c:if test="${flag ne 'true'}"></c:if>
	</c:forEach>
	<c:forEach items="${minwonType }" var="type">
		<c:set var="flag" value="false" />
		<c:forEach items="${getGroupedSeparationType }" var="separationType">
			<c:if
				test="${separationType.c_separation_type eq type and separationType.c_notificated eq 9 }">
				<c:set var="flag" value="true" />
				<c:set var="sum2" value="${sum2 + separationType.cstcount }" />
			</c:if>
		</c:forEach>
		<c:if test="${flag ne 'true'}"></c:if>
	</c:forEach>
	<c:forEach items="${districts }" var="district">
		<c:set var="flag" value="false" />
		<c:forEach items="${getGroupedDistrict }" var="districtInfo">
			<c:if
				test="${districtInfo.c_district eq district and districtInfo.c_notificated eq 2 }">
				<c:set var="flag" value="true" />
				<c:set var="sum3" value="${sum3 + districtInfo.cdcount }" />
			</c:if>
		</c:forEach>
		<c:if test="${flag ne 'true'}"></c:if>
	</c:forEach>
	<c:forEach items="${districts }" var="district">
		<c:set var="flag" value="false" />
		<c:forEach items="${getGroupedDistrict }" var="districtInfo">
			<c:if
				test="${districtInfo.c_district eq district and districtInfo.c_notificated eq 9 }">
				<c:set var="flag" value="true" />
				<c:set var="sum4" value="${sum4 + districtInfo.cdcount }" />
			</c:if>
		</c:forEach>
		<c:if test="${flag ne 'true'}"></c:if>
	</c:forEach>
	<div class="wrapper main-page">
		<div class="container">
			<div class="summary row justify-content-center">
				<div class="summary-item today col-sm-2">
					<p class="bold mb-2">금일등록</p>
					<a href="mw_all_list.do?searchType=serial&keyword=${today }"><h5
							class="bold">${todayComplaintsCount }건</h5></a>
				</div>
				<div class="summary-item charge col-sm-2">
					<p class="bold mb-2">담당민원</p>
					<a href="mw_all_list.do"><h5 class="bold">${chargeOfComplaintsCount }건</h5></a>
				</div>
				<div class="summary-item progressing col-sm-2">
					<p class="bold mb-2">처리진행</p>
					<a href="mw_not_completed_list.do"><h5 class="bold">${processComplaintsCount }건</h5></a>
				</div>
				<div class="summary-item col-sm-2">
					<p class="bold mb-2">처리완료</p>
					<a href="mw_completed_list.do"><h5 class="bold">${completedComplaintsCount }건</h5></a>
				</div>
				<div class="summary-item relation col-sm-2">
					<p class="bold mb-2">연관민원</p>
					<a
						href="mw_all_list.do?searchType=department&keyword=${userDepartment }"><h5
							class="bold">${relatedComplaintsCount }건</h5></a>
				</div>
				
			</div>
			<h4>분야별 현황</h4>
			<div class="summary overflow-auto mb-2 ">
				<table
					class="table summary-table table-input table-sm table-bordered mt-1">
					<thead>
						<tr style="background-color: #eaf4fb;">
							<th class="tg-0lax  border-blue">분야별</th>
							<th class="tg-0lax border-blue">합계</th>
							<th class="tg-0lax  border-blue">도로교통</th>
							<th class="tg-0lax  border-blue">보행환경</th>
							<th class="tg-0lax  border-blue">생활안전</th>
							<th class="tg-0lax  border-blue">주차환경</th>
							<th class="tg-0lax border-blue">빈집관리</th>
							<th class="tg-0lax border-blue">하수정비</th>
							<th class="tg-0lax border-blue">청소환경</th>
							<th class="tg-0lax border-blue">공원관리</th>
							<th class="tg-0lax border-blue">체육시설</th>
							<th class="tg-0lax border-blue">보건복지</th>
							<th class="tg-0lax border-blue">문화경제</th>
							<th class="tg-0lax border-blue">기타</th>
						</tr>
					</thead>
					<tbody>
						<tr style="background-color: #f8fffb; color: #178c40;">
							<td class="tg-0lax progressing">처리진행</td>

							<td class="tg-0lax"><a style="color: #178c40;" href="mw_not_completed_list.do">${sum1 }</a></td>
							<c:forEach items="${minwonType }" var="type">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedSeparationType }" var="separationType">

										<c:if
											test="${separationType.c_separation_type eq type and separationType.c_notificated eq 2 }">
											<a style="color: #178c40;"
												href="mw_not_completed_list.do?searchType=separation&keyword=${separationType.c_separation_type }">${separationType.cstcount }</a>

											<c:set var="flag" value="true" />
											<c:set var="sum1" value="${sum1 + separationType.cstcount }" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>
						</tr>
						<tr style="background-color: #f7faff; color: #4651c5;">
							<td class="tg-0lax finished">처리 완료</td>
							<td class="tg-0lax"><a style="color: #4651c5;" href="mw_completed_list.do">${sum2 }</a></td>
							<c:forEach items="${minwonType }" var="type">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedSeparationType }" var="separationType">
										<c:if
											test="${separationType.c_separation_type eq type and separationType.c_notificated eq 9 }">
											<a style="color: #4651c5;"
												href="mw_completed_list.do?searchType=separation&keyword=${separationType.c_separation_type }">
												${separationType.cstcount }</a>
											<c:set var="flag" value="true" />
											<c:set var="sum2" value="${sum2 + separationType.cstcount }" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>
						</tr>
					</tbody>
				</table>
			</div>
			<h4>동별 현황</h4>
			<div class="summary overflow-auto">

				<table
					class="table summary-table table-input table-sm table-bordered">
					<thead>
						<tr style="background-color: #eaf4fb;">
							<th class="tg-0lax border-blue ">동별</th>
							<th class="tg-0lax border-blue">합계</th>
							<th class="tg-0lax border-blue ">충장동</th>
							<th class="tg-0lax border-blue">동명동</th>
							<th class="tg-0lax border-blue">계림1동</th>
							<th class="tg-0lax border-blue">계림2동</th>
							<th class="tg-0lax border-blue">산수1동</th>
							<th class="tg-0lax border-blue ">산수2동</th>
							<th class="tg-0lax border-blue">지산1동</th>
							<th class="tg-0lax border-blue">지산2동</th>
							<th class="tg-0lax border-blue">서남동</th>
							<th class="tg-0lax border-blue">학동</th>
							<th class="tg-0lax border-blue">학운동</th>
							<th class="tg-0lax border-blue ">지원1동</th>
							<th class="tg-0lax border-blue ">지원2동</th>
							<th class="tg-0lax border-blue ">기타</th>
						</tr>
					</thead>
					<tbody>
						<tr style="background-color: #f8fffb; color: #178c40;">
							<td class="tg-0lax progressing">처리진행</td>
							<td class="tg-0lax"><a style="color: #178c40;" href="mw_not_completed_list.do">${sum3 }</a></td>
							<c:forEach items="${districts }" var="district">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDistrict }" var="districtInfo">
										<c:if
											test="${districtInfo.c_district eq district and districtInfo.c_notificated eq 2 }">
											<a style="color: #178c40;"
												href="mw_not_completed_list.do?searchType=district&keyword=${districtInfo.c_district }">
											${districtInfo.cdcount }</a>
											<c:set var="flag" value="true" />
											<c:set var="sum3" value="${sum3 + districtInfo.cdcount }" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>

						</tr>
						<tr style="background-color: #f7faff; color: #4651c5;">
							<td class="tg-0lax finished">처리 완료</td>
							<td class="tg-0lax"><a style="color: #4651c5;" href="mw_completed_list.do">${sum4 }</a></td>
							<c:forEach items="${districts }" var="district">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDistrict }" var="districtInfo">
										<c:if
											test="${districtInfo.c_district eq district and districtInfo.c_notificated eq 9 }">
											<a style="color: #4651c5;"
												href="mw_completed_list.do?searchType=district&keyword=${districtInfo.c_district }">
											${districtInfo.cdcount }</a>
											<c:set var="sum4" value="${sum4 + districtInfo.cdcount }" />
											<c:set var="flag" value="true" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>

						</tr>
					</tbody>
				</table>
			</div>

			<div class="card-deck mb-3">
				<div class="card">
					<div
						class="card-header progressing p-2 d-flex w-100 align-items-center justify-content-between">
						<span>
							<h5 class="title">처리중 민원</h5>
						</span> <a style="color: #178c40;" href="mw_not_completed_list.do" class="more-icon"><i
							class="bi bi-plus" style="font-size: 1.75rem"></i></a>
					</div>
					<div class="card-body">
						<div class="list-group list-group-flush">
							<c:if test="${fn:length(recentNonCompletedComplaints) == 0}">
              		해당 항목이 존재하지 않습니다.
              	</c:if>
							<c:forEach var="recentNonCompletedComplaint"
								items="${recentNonCompletedComplaints }">
								<a 
									href="mw_not_completed_view.do?id=${recentNonCompletedComplaint.cId }"
									class="list-group-item list-group-item-action lh-sm d-flex align-items-center">
									<span class="mr-2 point">${recentNonCompletedComplaint.cDepartment }</span>
									<p class="text-nowrap">${recentNonCompletedComplaint.cWriteDate }</p>
									<p
										class="text-left d-block text-truncate flex-grow-1 ml-2 mr-1"
										style="width: calc(100% - 230px)">
										${recentNonCompletedComplaint.cTitle }</p>
								</a>
							</c:forEach>
						</div>
					</div>
				</div>

				<div class="card">
					<div
						class="card-header progressing-reply p-2 d-flex w-100 align-items-center justify-content-between">
						<span>
							<h5 class="title">처리중 민원 댓글</h5>
						</span> <a href="mw_reply_list.do" class="more-icon"> <i
							class="bi bi-plus" style="font-size: 1.75rem"></i>
						</a>
					</div>
					<div class="card-body">
						<div class="list-group list-group-flush">
							<c:if test="${fn:length(recentNotCompletedReplies) == 0}">
	           	  해당 항목이 존재하지 않습니다.
	            </c:if>
							<c:forEach var="recentNotCompletedReply"
								items="${recentNotCompletedReplies }">

								<c:forEach var="a" items="${recentNotCompletedReply.replies }">
									<a
										href="mw_not_completed_view.do?id=${recentNotCompletedReply.cId }#div5"
										class="list-group-item list-group-item-action lh-sm d-flex align-items-center">
										<span class="mr-2 point">${recentNotCompletedReply.cDepartment }</span>
										<p class="text-nowrap">${a.crDate }</p>
										<p
											class="text-left d-block text-truncate flex-grow-1 ml-2 mr-1"
											style="width: calc(100% - 230px)">${a.crContent }</p>
									</a>
								</c:forEach>
							</c:forEach>
						</div>
					</div>
				</div>
			</div>
			<div class="card-deck">
				<div class="card">
					<div
						class="card-header finished p-2 d-flex w-100 align-items-center justify-content-between">
						<span>
							<h5 class="title">완료 민원</h5>
						</span> <a href="mw_completed_list.do" class="more-icon"><i
							class="bi bi-plus" style="font-size: 1.75rem"></i></a>
					</div>
					<div class="card-body">
						<div class="list-group list-group-flush">
							<c:if test="${fn:length(recentCompletedComplaints) == 0}">
              		해당 항목이 존재하지 않습니다.
              	</c:if>
							<c:forEach var="recentCompletedComplaint"
								items="${recentCompletedComplaints }">
								<a
									href="mw_completed_view.do?id=${recentCompletedComplaint.cId }"
									class="list-group-item list-group-item-action lh-sm d-flex align-items-center">
									<span class="mr-2 point">${recentCompletedComplaint.cDepartment }</span>
									<p class="text-nowrap">${recentCompletedComplaint.cWriteDate }</p>
									<p
										class="text-left d-block text-truncate flex-grow-1 ml-2 mr-1"
										style="width: calc(100% - 230px)">
										${recentCompletedComplaint.cTitle}</p>
								</a>
							</c:forEach>
						</div>
					</div>
				</div>
				<div class="card">
					<div
						class="card-header finished-reply p-2 d-flex w-100 align-items-center justify-content-between">
						<span>
							<h5 class="title">완료 민원 댓글</h5>
						</span> <a href="mw_reply_list.do" class="more-icon"><i
							class="bi bi-plus" style="font-size: 1.75rem"></i></a>
					</div>
					<div class="card-body">
						<div class="list-group list-group-flush">
							<c:if test="${fn:length(recentCompletedReplies) == 0}">
              		해당 항목이 존재하지 않습니다.
              	</c:if>
							<c:forEach var="recentCompletedReply"
								items="${recentCompletedReplies }">
								<c:forEach var="a" items="${recentCompletedReply.replies }">
									<a
										href="mw_completed_view.do?id=${recentCompletedReply.cId }#div5"
										class="list-group-item list-group-item-action lh-sm d-flex align-items-center">
										<span class="mr-2 point">
											${recentCompletedReply.cDepartment } </span>
										<p class="text-nowrap">${a.crDate }</p>
										<p
											class="text-left d-block text-truncate flex-grow-1 ml-2 mr-1"
											style="width: calc(100% - 230px)">${a.crContent }</p>
									</a>
								</c:forEach>
							</c:forEach>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
	<%@ include file="../include/main_footer.jsp"%>
	<script>
		ObjectWrite();
		StartGuard(2);
	</script>
</body>
</html>
