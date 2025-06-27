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
	<c:set var="sum5" value="0" />
	<c:set var="sum6" value="0" />
	<c:set var="sum7" value="0" />
	<c:set var="sum8" value="0" />
	<c:set var="sum9" value="0" />
	<c:set var="sum10" value="0" />
	<c:set var="sum11" value="0" />
	<c:set var="sum12" value="0" />
	<c:set var="sum13" value="0" />
	<c:set var="sum14" value="0" />
	<c:set var="sum15" value="0" />
	<c:forEach items="${minwonType }" var="type">
		<c:set var="flag" value="false" />
		<c:forEach items="${getGroupedSeparationType }" var="separationType">
			<c:if
				test="${separationType.c_separation_type eq type and separationType.c_process_class eq '처리중' }">
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
				test="${separationType.c_separation_type eq type and separationType.c_process_class eq '처리완료' }">
				<c:set var="flag" value="true" />
				<c:set var="sum2" value="${sum2 + separationType.cstcount }" />
			</c:if>
		</c:forEach>
		<c:if test="${flag ne 'true'}"></c:if>
	</c:forEach>
	<c:forEach items="${minwonType }" var="type">
		<c:set var="flag" value="false" />
		<c:forEach items="${getGroupedSeparationType }" var="separationType">
			<c:if
				test="${separationType.c_separation_type eq type and separationType.c_process_class eq '중장기검토' }">
				<c:set var="flag" value="true" />
				<c:set var="sum3" value="${sum3 + separationType.cstcount }" />
			</c:if>
		</c:forEach>
		<c:if test="${flag ne 'true'}"></c:if>
	</c:forEach>
	<c:forEach items="${minwonType }" var="type">
		<c:set var="flag" value="false" />
		<c:forEach items="${getGroupedSeparationType }" var="separationType">
			<c:if
				test="${separationType.c_separation_type eq type and separationType.c_process_class eq '타기관협조' }">
				<c:set var="flag" value="true" />
				<c:set var="sum4" value="${sum4 + separationType.cstcount }" />
			</c:if>
		</c:forEach>
		<c:if test="${flag ne 'true'}"></c:if>
	</c:forEach>
	<c:forEach items="${minwonType }" var="type">
		<c:set var="flag" value="false" />
		<c:forEach items="${getGroupedSeparationType }" var="separationType">
			<c:if
				test="${separationType.c_separation_type eq type and separationType.c_process_class eq '처리불가' }">
				<c:set var="flag" value="true" />
				<c:set var="sum5" value="${sum5 + separationType.cstcount }" />
			</c:if>
		</c:forEach>
		<c:if test="${flag ne 'true'}"></c:if>
	</c:forEach>
	<c:forEach items="${districts }" var="district">
		<c:set var="flag" value="false" />
		<c:forEach items="${getGroupedDistrict }" var="districtInfo">
			<c:if
				test="${districtInfo.c_district eq district and districtInfo.c_process_class eq '처리중' }">
				<c:set var="flag" value="true" />
				<c:set var="sum6" value="${sum6 + districtInfo.cdcount }" />
			</c:if>
		</c:forEach>
		<c:if test="${flag ne 'true'}"></c:if>
	</c:forEach>
	<c:forEach items="${districts }" var="district">
		<c:set var="flag" value="false" />
		<c:forEach items="${getGroupedDistrict }" var="districtInfo">
			<c:if
				test="${districtInfo.c_district eq district and districtInfo.c_process_class eq '처리완료' }">
				<c:set var="flag" value="true" />
				<c:set var="sum7" value="${sum7 + districtInfo.cdcount }" />
			</c:if>
		</c:forEach>
		<c:if test="${flag ne 'true'}"></c:if>
	</c:forEach>
	<c:forEach items="${districts }" var="district">
		<c:set var="flag" value="false" />
		<c:forEach items="${getGroupedDistrict }" var="districtInfo">
			<c:if
				test="${districtInfo.c_district eq district and districtInfo.c_process_class eq '중장기검토' }">
				<c:set var="flag" value="true" />
				<c:set var="sum8" value="${sum8 + districtInfo.cdcount }" />
			</c:if>
		</c:forEach>
		<c:if test="${flag ne 'true'}"></c:if>
	</c:forEach>
	<c:forEach items="${districts }" var="district">
		<c:set var="flag" value="false" />
		<c:forEach items="${getGroupedDistrict }" var="districtInfo">
			<c:if
				test="${districtInfo.c_district eq district and districtInfo.c_process_class eq '타기관협조' }">
				<c:set var="flag" value="true" />
				<c:set var="sum9" value="${sum9 + districtInfo.cdcount }" />
			</c:if>
		</c:forEach>
		<c:if test="${flag ne 'true'}"></c:if>
	</c:forEach>
	<c:forEach items="${districts }" var="district">
		<c:set var="flag" value="false" />
		<c:forEach items="${getGroupedDistrict }" var="districtInfo">
			<c:if
				test="${districtInfo.c_district eq district and districtInfo.c_process_class eq '처리불가' }">
				<c:set var="flag" value="true" />
				<c:set var="sum10" value="${sum10 + districtInfo.cdcount }" />
			</c:if>
		</c:forEach>
		<c:if test="${flag ne 'true'}"></c:if>
	</c:forEach>
	<c:forEach items="${departments }" var="department">
		<c:set var="flag" value="false" />
		<c:forEach items="${getGroupedDepartment }" var="departmentInfo">
			<c:if
				test="${departmentInfo.dpname eq department and departmentInfo.c_process_class eq '처리중' }">
				<c:set var="flag" value="true" />
				<c:set var="sum11" value="${sum11 + departmentInfo.cdpcount }" />
			</c:if>
		</c:forEach>
		<c:if test="${flag ne 'true'}"></c:if>
	</c:forEach>
	<c:forEach items="${departments }" var="department">
		<c:set var="flag" value="false" />
		<c:forEach items="${getGroupedDepartment }" var="departmentInfo">
			<c:if
				test="${departmentInfo.dpname eq department and departmentInfo.c_process_class eq '처리완료' }">
				<c:set var="flag" value="true" />
				<c:set var="sum12" value="${sum12 + departmentInfo.cdpcount }" />
			</c:if>
		</c:forEach>
		<c:if test="${flag ne 'true'}"></c:if>
	</c:forEach>
	<c:forEach items="${departments }" var="department">
		<c:set var="flag" value="false" />
		<c:forEach items="${getGroupedDepartment }" var="departmentInfo">
			<c:if
				test="${departmentInfo.dpname eq department and departmentInfo.c_process_class eq '중장기검토' }">
				<c:set var="flag" value="true" />
				<c:set var="sum13" value="${sum13 + departmentInfo.cdpcount }" />
			</c:if>
		</c:forEach>
		<c:if test="${flag ne 'true'}"></c:if>
	</c:forEach>
	<c:forEach items="${departments }" var="department">
		<c:set var="flag" value="false" />
		<c:forEach items="${getGroupedDepartment }" var="departmentInfo">
			<c:if
				test="${departmentInfo.dpname eq department and departmentInfo.c_process_class eq '타기관협조' }">
				<c:set var="flag" value="true" />
				<c:set var="sum14" value="${sum14 + departmentInfo.cdpcount }" />
			</c:if>
		</c:forEach>
		<c:if test="${flag ne 'true'}"></c:if>
	</c:forEach>
	<c:forEach items="${departments }" var="department">
		<c:set var="flag" value="false" />
		<c:forEach items="${getGroupedDepartment }" var="departmentInfo">
			<c:if
				test="${departmentInfo.dpname eq department and departmentInfo.c_process_class eq '처리불가' }">
				<c:set var="flag" value="true" />
				<c:set var="sum15" value="${sum15 + departmentInfo.cdpcount }" />
			</c:if>
		</c:forEach>
		<c:if test="${flag ne 'true'}"></c:if>
	</c:forEach>
	<div class="wrapper main-page">
		<div class="container-xl">
			<div class="summary row justify-content-center">
				<div class="summary-item col-sm-2">
					<p class="bold mb-2" style="background-color: #0066b3">총민원건수</p>
					<a href="mw_all_list.do"><h5 class="bold">${sum1 + sum2 + sum3 + sum4 + sum5 }건</h5></a>
				</div>
				<div class="summary-item today col-sm-2">
					<p class="bold mb-2">처리중</p>
					<a href="mw_all_list.do?searchType=process&keyword=처리중"><h5
							class="bold">${processingComplaintsCount }건</h5></a>
				</div>
				<div class="summary-item charge col-sm-2">
					<p class="bold mb-2">처리완료</p>
					<a href="mw_all_list.do?searchType=process&keyword=처리완료"><h5
							class="bold">${finishedComplaintsCount }건</h5></a>
				</div>
				<div class="summary-item progressing col-sm-2">
					<p class="bold mb-2">중장기검토</p>
					<a href="mw_all_list.do?searchType=process&keyword=중장기검토"><h5
							class="bold">${reviewingComplaintsCount }건</h5></a>
				</div>
				<div class="summary-item col-sm-2">
					<p class="bold mb-2">타기관협조</p>
					<a href="mw_all_list.do?searchType=process&keyword=타기관협조"><h5
							class="bold">${cooperateComplaintsCount }건</h5></a>
				</div>
				<div class="summary-item relation col-sm-2">
					<p class="bold mb-2">처리불가</p>
					<a href="mw_all_list.do?searchType=process&keyword=처리불가"><h5
							class="bold">${impossibleComplaintsCount }건</h5></a>
				</div>

			</div>
			<div class="sub-title">분야별 현황</div>
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
						<tr style="background-color: #dce8ea; color: #4651c5;">
							<td class="tg-0lax total">합계</td>

							<td class="tg-0lax"><a style="color: #4651c5;"
								href="mw_all_list.do">${sum1 + sum2 + sum3 + sum4 + sum5 }</a></td>
							<c:forEach items="${minwonType }" var="type">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedSeparationTypeSum }" var="separationType">

										<c:if test="${separationType.c_separation_type eq type }">
											<a style="color: #4651c5;"
												href="mw_all_list.do?searchType=separation&keyword=${separationType.c_separation_type }">${separationType.cstcount }</a>

											<c:set var="flag" value="true" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>
						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax progressing">처리중</td>

							<td class="tg-0lax"><a style="color: #4651c5;"
								href="mw_all_list.do?searchType=process&keyword=처리중">${sum1 }</a></td>
							<c:forEach items="${minwonType }" var="type">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedSeparationType }" var="separationType">

										<c:if
											test="${separationType.c_separation_type eq type and separationType.c_process_class eq '처리중' }">
											<a style="color: #4651c5;"
												href="mw_all_list.do?searchType=separation&keyword=${separationType.c_separation_type }&searchType2=process&keyword2=처리중">${separationType.cstcount }</a>

											<c:set var="flag" value="true" />
											<c:set var="sum1" value="${sum1 + separationType.cstcount }" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>
						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax finished">처리 완료</td>
							<td class="tg-0lax"><a style="color: #4651c5;"
								href="mw_all_list.do?searchType=process&keyword=처리완료">${sum2 }</a></td>
							<c:forEach items="${minwonType }" var="type">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedSeparationType }" var="separationType">
										<c:if
											test="${separationType.c_separation_type eq type and separationType.c_process_class eq '처리완료' }">
											<a style="color: #4651c5;"
												href="mw_all_list.do?searchType=separation&keyword=${separationType.c_separation_type }&searchType2=process&keyword2=처리완료">
												${separationType.cstcount }</a>
											<c:set var="flag" value="true" />
											<c:set var="sum2" value="${sum2 + separationType.cstcount }" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>
						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax reviewing">중장기검토</td>
							<td class="tg-0lax"><a style="color: #4651c5;"
								href="mw_all_list.do?searchType=process&keyword=중장기검토">${sum3 }</a></td>
							<c:forEach items="${minwonType }" var="type">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedSeparationType }" var="separationType">
										<c:if
											test="${separationType.c_separation_type eq type and separationType.c_process_class eq '중장기검토' }">
											<a style="color: #4651c5;"
												href="mw_all_list.do?searchType=separation&keyword=${separationType.c_separation_type }&searchType2=process&keyword2=중장기검토">
												${separationType.cstcount }</a>
											<c:set var="flag" value="true" />
											<c:set var="sum3" value="${sum3 + separationType.cstcount }" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>
						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax cooperate">타기관협조</td>
							<td class="tg-0lax"><a style="color: #4651c5;"
								href="mw_all_list.do?searchType=process&keyword=타기관협조">${sum4 }</a></td>
							<c:forEach items="${minwonType }" var="type">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedSeparationType }" var="separationType">
										<c:if
											test="${separationType.c_separation_type eq type and separationType.c_process_class eq '타기관협조' }">
											<a style="color: #4651c5;"
												href="mw_all_list.do?searchType=separation&keyword=${separationType.c_separation_type }&searchType2=process&keyword2=타기관협조">
												${separationType.cstcount }</a>
											<c:set var="flag" value="true" />
											<c:set var="sum4" value="${sum4 + separationType.cstcount }" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>
						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax impossible">처리불가</td>
							<td class="tg-0lax"><a style="color: #4651c5;"
								href="mw_all_list.do?searchType=process&keyword=처리불가">${sum5 }</a></td>
							<c:forEach items="${minwonType }" var="type">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedSeparationType }" var="separationType">
										<c:if
											test="${separationType.c_separation_type eq type and separationType.c_process_class eq '처리불가' }">
											<a style="color: #4651c5;"
												href="mw_all_list.do?searchType=separation&keyword=${separationType.c_separation_type }&searchType2=process&keyword2=처리불가">
												${separationType.cstcount }</a>
											<c:set var="flag" value="true" />
											<c:set var="sum5" value="${sum5 + separationType.cstcount }" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>
						</tr>
					</tbody>
				</table>
			</div>
			<div class="sub-title">부서별 현황</div>
			<div class="summary overflow-auto">

				<table
					class="table summary-table table-input table-sm table-bordered">
					<thead>
						<tr style="background-color: #eaf4fb; vertical-align: middle;">
							<th class="tg-0lax border-blue" style="vertical-align: middle;">부서별</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">합계</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">기획예산실</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">주민안전<br>담당관
							</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">홍보<br>미디어실</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">청렴감사관</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">인문도시<br>정책과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">문화예술<br>체육과
							</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">지속가능<br>관광과
							</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">인구청년<br>정책과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">복지정책과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">통합돌봄과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">노인장애인<br>복지과
							</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">양성평등<br>아동과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">일자리<br>경제과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">기후환경과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">자원순환과</th>
						</tr>
					</thead>
					<tbody>
						<tr style="background-color: #dce8ea; color: #4651c5;">
							<td class="tg-0lax total">합계</td>
							<td class="tg-0lax"><a style="color: #4651c5;"
								href="mw_all_list.do">${sum11 + sum12 + sum13 + sum14 + sum15 }</a></td>
							<c:forEach items="${departments1 }" var="department">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDepartmentSum }" var="departmentInfo">

										<c:if test="${departmentInfo.dpname eq department }">
											<a style="color: #4651c5;"
												href="mw_all_list.do?searchType=department&keyword=${departmentInfo.dpname}">${departmentInfo.cdpcount }</a>
											<c:set var="flag" value="true" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>
						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax progressing">처리중</td>
							<td class="tg-0lax"><a style="color: #4651c5;"
								href="mw_all_list.do?searchType=process&keyword=처리중">${sum11 }</a></td>
							<c:forEach items="${departments1 }" var="department">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDepartment }" var="departmentInfo">
										<c:if
											test="${departmentInfo.dpname eq department and departmentInfo.c_process_class eq '처리중' }">
											<a style="color: #4651c5;"
												href="mw_all_list.do?searchType=department&keyword=${departmentInfo.dpname}&searchType2=process&keyword2=처리중">
												${departmentInfo.cdpcount }</a>
											<c:set var="flag" value="true" />
											<c:set var="sum11"
												value="${sum11 + departmentInfo.cdpcount }" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>

						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax finished">처리완료</td>
							<td class="tg-0lax"><a style="color: #4651c5;"
								href="mw_all_list.do?searchType=process&keyword=처리완료">${sum12 }</a></td>
							<c:forEach items="${departments1 }" var="department">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDepartment }" var="departmentInfo">
										<c:if
											test="${departmentInfo.dpname eq department and departmentInfo.c_process_class eq '처리완료' }">
											<a style="color: #4651c5;"
												href="mw_all_list.do?searchType=department&keyword=${departmentInfo.dpname}&searchType2=process&keyword2=처리완료">
												${departmentInfo.cdpcount }</a>
											<c:set var="sum12"
												value="${sum12 + departmentInfo.cdpcount }" />
											<c:set var="flag" value="true" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>

						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax reviewing">중장기검토</td>
							<td class="tg-0lax"><a style="color: #4651c5;"
								href="mw_all_list.do?searchType=process&keyword=중장기검토">${sum13 }</a></td>
							<c:forEach items="${departments1 }" var="department">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDepartment }" var="departmentInfo">
										<c:if
											test="${departmentInfo.dpname eq department and departmentInfo.c_process_class eq '중장기검토' }">
											<a style="color: #4651c5;"
												href="mw_all_list.do?searchType=department&keyword=${departmentInfo.dpname}&searchType2=process&keyword2=중장기검토">
												${departmentInfo.cdpcount }</a>
											<c:set var="sum13"
												value="${sum13 + departmentInfo.cdpcount }" />
											<c:set var="flag" value="true" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>

						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax cooperate">타기관협조</td>
							<td class="tg-0lax"><a style="color: #4651c5;"
								href="mw_all_list.do?searchType=process&keyword=타기관협조">${sum14 }</a></td>
							<c:forEach items="${departments1 }" var="department">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDepartment }" var="departmentInfo">
										<c:if
											test="${departmentInfo.dpname eq department and departmentInfo.c_process_class eq '타기관협조' }">
											<a style="color: #4651c5;"
												href="mw_all_list.do?searchType=department&keyword=${departmentInfo.dpname}&searchType2=process&keyword2=타기관협조">
												${departmentInfo.cdpcount }</a>
											<c:set var="sum14"
												value="${sum14 + departmentInfo.cdpcount }" />
											<c:set var="flag" value="true" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>

						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax impossible">처리불가</td>
							<td class="tg-0lax"><a style="color: #4651c5;"
								href="mw_all_list.do?searchType=process&keyword=처리불가">${sum15 }</a></td>
							<c:forEach items="${departments1 }" var="department">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDepartment }" var="departmentInfo">
										<c:if
											test="${departmentInfo.dpname eq department and departmentInfo.c_process_class eq '처리불가' }">
											<a style="color: #4651c5;"
												href="mw_all_list.do?searchType=department&keyword=${departmentInfo.dpname}&searchType2=process&keyword2=처리불가">
												${departmentInfo.cdpcount }</a>
											<c:set var="sum15"
												value="${sum15 + departmentInfo.cdpcount }" />
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
			<div class="summary overflow-auto">

				<table
					class="table summary-table table-input table-sm table-bordered">
					<thead>
						<tr style="background-color: #eaf4fb; vertical-align: middle;">
							<th class="tg-0lax border-blue" style="vertical-align: middle;">부서별</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">푸른도시과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">도시공간<br>계획과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">주거정책과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">건설과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">건축과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">보행교통<br>정책과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">마을자치과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">행정지원과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">회계과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">세무1과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">세무2과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">민원토지과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">건강정책과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">보건사업과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">위생과</th>
							<th class="tg-0lax border-blue" style="vertical-align: middle;">동(洞)
							</th>
						</tr>
					</thead>
					<tbody>
						<tr style="background-color: #dce8ea; color: #4651c5;">
							<td class="tg-0lax total">합계</td>
							<c:forEach items="${departments2 }" var="department">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDepartmentSum }" var="departmentInfo">
										<c:choose>
											<c:when
												test="${departmentInfo.dpname eq department and departmentInfo.dpname eq '기타' }">
												<a style="color: #4651c5;"
													href="mw_all_list.do?searchType=dong&keyword=기타">${departmentInfo.cdpcount }</a>
												<c:set var="flag" value="true" />
											</c:when>
											<c:when test="${departmentInfo.dpname eq department }">
												<a style="color: #4651c5;"
													href="mw_all_list.do?searchType=department&keyword=${departmentInfo.dpname}">${departmentInfo.cdpcount }</a>
												<c:set var="flag" value="true" />
											</c:when>
										</c:choose>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>
						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax progressing">처리중</td>
							<c:forEach items="${departments2 }" var="department">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDepartment }" var="departmentInfo">
										<c:choose>
											<c:when
												test="${departmentInfo.dpname eq department and departmentInfo.dpname eq '기타' and departmentInfo.c_process_class eq '처리중' }">
												<a style="color: #4651c5;"
													href="mw_all_list.do?searchType=dong&keyword=기타&searchType2=process&keyword2=처리중">
													${departmentInfo.cdpcount }</a>
												<c:set var="flag" value="true" />
												<c:set var="sum11"
													value="${sum11 + departmentInfo.cdpcount }" />
											</c:when>
											<c:when
												test="${departmentInfo.dpname eq department and departmentInfo.c_process_class eq '처리중' }">
												<a style="color: #4651c5;"
													href="mw_all_list.do?searchType=department&keyword=${departmentInfo.dpname}&searchType2=process&keyword2=처리중">
													${departmentInfo.cdpcount }</a>
												<c:set var="flag" value="true" />
												<c:set var="sum11"
													value="${sum11 + departmentInfo.cdpcount }" />
											</c:when>
										</c:choose>

									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>

						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax finished">처리완료</td>
							<c:forEach items="${departments2 }" var="department">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDepartment }" var="departmentInfo">
										<c:choose>
											<c:when
												test="${departmentInfo.dpname eq department and departmentInfo.dpname eq '기타' and departmentInfo.c_process_class eq '처리완료' }">
												<a style="color: #4651c5;"
													href="mw_all_list.do?searchType=dong&keyword=기타&searchType2=process&keyword2=처리완료">
													${departmentInfo.cdpcount }</a>
												<c:set var="sum12"
													value="${sum12 + departmentInfo.cdpcount }" />
												<c:set var="flag" value="true" />
											</c:when>
											<c:when
												test="${departmentInfo.dpname eq department and departmentInfo.c_process_class eq '처리완료' }">
												<a style="color: #4651c5;"
													href="mw_all_list.do?searchType=department&keyword=${departmentInfo.dpname}&searchType2=process&keyword2=처리완료">
													${departmentInfo.cdpcount }</a>
												<c:set var="sum12"
													value="${sum12 + departmentInfo.cdpcount }" />
												<c:set var="flag" value="true" />
											</c:when>
										</c:choose>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>

						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax reviewing">중장기검토</td>
							<c:forEach items="${departments2 }" var="department">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDepartment }" var="departmentInfo">
										<c:choose>
											<c:when
												test="${departmentInfo.dpname eq department and departmentInfo.dpname eq '기타' and departmentInfo.c_process_class eq '중장기검토' }">
												<a style="color: #4651c5;"
													href="mw_all_list.do?searchType=dong&keyword=기타&searchType2=process&keyword2=중장기검토">
													${departmentInfo.cdpcount }</a>
												<c:set var="sum13"
													value="${sum13 + departmentInfo.cdpcount }" />
												<c:set var="flag" value="true" />
											</c:when>
											<c:when
												test="${departmentInfo.dpname eq department and departmentInfo.c_process_class eq '중장기검토' }">
												<a style="color: #4651c5;"
													href="mw_all_list.do?searchType=department&keyword=${departmentInfo.dpname}&searchType2=process&keyword2=중장기검토">
													${departmentInfo.cdpcount }</a>
												<c:set var="sum13"
													value="${sum13 + departmentInfo.cdpcount }" />
												<c:set var="flag" value="true" />
											</c:when>
										</c:choose>

									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>

						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax cooperate">타기관협조</td>
							<c:forEach items="${departments2 }" var="department">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDepartment }" var="departmentInfo">
										<c:choose>
											<c:when
												test="${departmentInfo.dpname eq department and departmentInfo.dpname eq '기타' and departmentInfo.c_process_class eq '타기관협조' }">
												<a style="color: #4651c5;"
													href="mw_all_list.do?searchType=dong&keyword=기타&searchType2=process&keyword2=타기관협조">
													${departmentInfo.cdpcount }</a>
												<c:set var="sum14"
													value="${sum14 + departmentInfo.cdpcount }" />
												<c:set var="flag" value="true" />
											</c:when>
											<c:when
												test="${departmentInfo.dpname eq department and departmentInfo.c_process_class eq '타기관협조' }">
												<a style="color: #4651c5;"
													href="mw_all_list.do?searchType=department&keyword=${departmentInfo.dpname}&searchType2=process&keyword2=타기관협조">
													${departmentInfo.cdpcount }</a>
												<c:set var="sum14"
													value="${sum14 + departmentInfo.cdpcount }" />
												<c:set var="flag" value="true" />
											</c:when>
										</c:choose>

									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>

						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax impossible">처리불가</td>
							<c:forEach items="${departments2 }" var="department">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDepartment }" var="departmentInfo">
										<c:choose>
											<c:when
												test="${departmentInfo.dpname eq department and departmentInfo.dpname eq '기타' and departmentInfo.c_process_class eq '처리불가' }">
												<a style="color: #4651c5;"
													href="mw_all_list.do?searchType=dong&keyword=기타&searchType2=process&keyword2=처리불가">
													${departmentInfo.cdpcount }</a>
												<c:set var="sum15"
													value="${sum15 + departmentInfo.cdpcount }" />
												<c:set var="flag" value="true" />
											</c:when>
											<c:when
												test="${departmentInfo.dpname eq department and departmentInfo.c_process_class eq '처리불가' }">
												<a style="color: #4651c5;"
													href="mw_all_list.do?searchType=department&keyword=${departmentInfo.dpname}&searchType2=process&keyword2=처리불가">
													${departmentInfo.cdpcount }</a>
												<c:set var="sum15"
													value="${sum15 + departmentInfo.cdpcount }" />
												<c:set var="flag" value="true" />
											</c:when>
										</c:choose>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>

						</tr>
					</tbody>
				</table>
			</div>

			<div class="sub-title">동별 현황</div>
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
						<tr style="background-color: #dce8ea; color: #4651c5;">
							<td class="tg-0lax total">합계</td>

							<td class="tg-0lax"><a style="color: #4651c5;"
								href="mw_all_list.do">${sum6 + sum7 + sum8 + sum9 + sum10 }</a></td>
							<c:forEach items="${districts }" var="district">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDistrictSum }" var="districtInfo">

										<c:if test="${districtInfo.c_district eq district }">
											<a style="color: #4651c5;"
												href="mw_all_list.do?searchType=district&keyword=${districtInfo.c_district }">${districtInfo.cdcount }</a>
											<c:set var="flag" value="true" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>
						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax progressing">처리중</td>
							<td class="tg-0lax"><a style="color: #4651c5;"
								href="mw_all_list.do?searchType=process&keyword=처리중">${sum6 }</a></td>
							<c:forEach items="${districts }" var="district">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDistrict }" var="districtInfo">
										<c:if
											test="${districtInfo.c_district eq district and districtInfo.c_process_class eq '처리중' }">
											<a style="color: #4651c5;"
												href="mw_all_list.do?searchType=district&keyword=${districtInfo.c_district }&searchType2=process&keyword2=처리중">
												${districtInfo.cdcount }</a>
											<c:set var="flag" value="true" />
											<c:set var="sum6" value="${sum6 + districtInfo.cdcount }" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>

						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax finished">처리완료</td>
							<td class="tg-0lax"><a style="color: #4651c5;"
								href="mw_all_list.do?searchType=process&keyword=처리완료">${sum7 }</a></td>
							<c:forEach items="${districts }" var="district">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDistrict }" var="districtInfo">
										<c:if
											test="${districtInfo.c_district eq district and districtInfo.c_process_class eq '처리완료' }">
											<a style="color: #4651c5;"
												href="mw_all_list.do?searchType=district&keyword=${districtInfo.c_district }&searchType2=process&keyword2=처리완료">
												${districtInfo.cdcount }</a>
											<c:set var="sum7" value="${sum7 + districtInfo.cdcount }" />
											<c:set var="flag" value="true" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>

						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax reviewing">중장기검토</td>
							<td class="tg-0lax"><a style="color: #4651c5;"
								href="mw_all_list.do?searchType=process&keyword=중장기검토">${sum8 }</a></td>
							<c:forEach items="${districts }" var="district">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDistrict }" var="districtInfo">
										<c:if
											test="${districtInfo.c_district eq district and districtInfo.c_process_class eq '중장기검토' }">
											<a style="color: #4651c5;"
												href="mw_all_list.do?searchType=district&keyword=${districtInfo.c_district }&searchType2=process&keyword2=중장기검토">
												${districtInfo.cdcount }</a>
											<c:set var="sum8" value="${sum8 + districtInfo.cdcount }" />
											<c:set var="flag" value="true" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>

						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax cooperate">타기관협조</td>
							<td class="tg-0lax"><a style="color: #4651c5;"
								href="mw_all_list.do?searchType=process&keyword=타기관협조">${sum9 }</a></td>
							<c:forEach items="${districts }" var="district">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDistrict }" var="districtInfo">
										<c:if
											test="${districtInfo.c_district eq district and districtInfo.c_process_class eq '타기관협조' }">
											<a style="color: #4651c5;"
												href="mw_all_list.do?searchType=district&keyword=${districtInfo.c_district }&searchType2=process&keyword2=타기관협조">
												${districtInfo.cdcount }</a>
											<c:set var="sum9" value="${sum9 + districtInfo.cdcount }" />
											<c:set var="flag" value="true" />
										</c:if>
									</c:forEach> <c:if test="${flag ne 'true'}">
										0
								</c:if></td>
							</c:forEach>

						</tr>
						<tr style="background-color: #f8fffb; color: #4651c5;">
							<td class="tg-0lax impossible">처리불가</td>
							<td class="tg-0lax"><a style="color: #4651c5;"
								href="mw_all_list.do?searchType=process&keyword=처리불가">${sum10 }</a></td>
							<c:forEach items="${districts }" var="district">
								<c:set var="flag" value="false" />
								<td class="tg-0lax"><c:forEach
										items="${getGroupedDistrict }" var="districtInfo">
										<c:if
											test="${districtInfo.c_district eq district and districtInfo.c_process_class eq '처리불가' }">
											<a style="color: #4651c5;"
												href="mw_all_list.do?searchType=district&keyword=${districtInfo.c_district }&searchType2=process&keyword2=처리불가">
												${districtInfo.cdcount }</a>
											<c:set var="sum10" value="${sum10 + districtInfo.cdcount }" />
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
							<h5 class="title">처리중</h5>
						</span> <a style="color: #178c40;" href="mw_process_list.do?searchType=process&keyword=처리중"
							class="more-icon"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="#fff" class="bi bi-plus" viewBox="0 0 16 16">
  <path d="M8 4a.5.5 0 0 1 .5.5v3h3a.5.5 0 0 1 0 1h-3v3a.5.5 0 0 1-1 0v-3h-3a.5.5 0 0 1 0-1h3v-3A.5.5 0 0 1 8 4"/>
</svg></a>
					</div>
					<div class="card-body">
						<div class="list-group list-group-flush">
							<c:if test="${fn:length(recentNonCompletedComplaints) == 0}">
              		해당 항목이 존재하지 않습니다.
              	</c:if>
							<c:forEach var="recentNonCompletedComplaint"
								items="${recentNonCompletedComplaints }">
								<a
									href="mw_process_view.do?id=${recentNonCompletedComplaint.cId }"
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
						class="card-header finished p-2 d-flex w-100 align-items-center justify-content-between">
						<span>
							<h5 class="title">처리완료</h5>
						</span> <a href="mw_process_list.do?searchType=process&keyword=처리완료" class="more-icon"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="#fff" class="bi bi-plus" viewBox="0 0 16 16">
  <path d="M8 4a.5.5 0 0 1 .5.5v3h3a.5.5 0 0 1 0 1h-3v3a.5.5 0 0 1-1 0v-3h-3a.5.5 0 0 1 0-1h3v-3A.5.5 0 0 1 8 4"/>
</svg></a>
					</div>
					<div class="card-body">
						<div class="list-group list-group-flush">
							<c:if test="${fn:length(recentCompletedComplaints) == 0}">
              		해당 항목이 존재하지 않습니다.
              	</c:if>
							<c:forEach var="recentCompletedComplaint"
								items="${recentCompletedComplaints }">
								<a
									href="mw_process_view.do?id=${recentCompletedComplaint.cId }"
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


			</div>
			<div class="card-deck">

				<div class="card">
					<div
						class="card-header reviewing p-2 d-flex w-100 align-items-center justify-content-between">
						<span>
							<h5 class="title">중장기검토</h5>
						</span> <a href="mw_process_list.do?searchType=process&keyword=중장기검토" class="more-icon"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="#fff" class="bi bi-plus" viewBox="0 0 16 16">
  <path d="M8 4a.5.5 0 0 1 .5.5v3h3a.5.5 0 0 1 0 1h-3v3a.5.5 0 0 1-1 0v-3h-3a.5.5 0 0 1 0-1h3v-3A.5.5 0 0 1 8 4"/>
</svg></a>
					</div>
					<div class="card-body">
						<div class="list-group list-group-flush">
							<c:if test="${fn:length(recentReviewingComplaints) == 0}">
              		해당 항목이 존재하지 않습니다.
              	</c:if>
							<c:forEach var="recentReviewingComplaint"
								items="${recentReviewingComplaints }">
								<a
									href="mw_process_view.do?id=${recentReviewingComplaint.cId }"
									class="list-group-item list-group-item-action lh-sm d-flex align-items-center">
									<span class="mr-2 point">${recentReviewingComplaint.cDepartment }</span>
									<p class="text-nowrap">${recentReviewingComplaint.cWriteDate }</p>
									<p
										class="text-left d-block text-truncate flex-grow-1 ml-2 mr-1"
										style="width: calc(100% - 230px)">
										${recentReviewingComplaint.cTitle}</p>
								</a>
							</c:forEach>
						</div>
					</div>
				</div>

				<div class="card">
					<div
						class="card-header cooperate p-2 d-flex w-100 align-items-center justify-content-between">
						<span>
							<h5 class="title">타기관협조</h5>
						</span> <a href="mw_process_list.do?searchType=process&keyword=타기관협조" class="more-icon"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="#fff" class="bi bi-plus" viewBox="0 0 16 16">
  <path d="M8 4a.5.5 0 0 1 .5.5v3h3a.5.5 0 0 1 0 1h-3v3a.5.5 0 0 1-1 0v-3h-3a.5.5 0 0 1 0-1h3v-3A.5.5 0 0 1 8 4"/>
</svg></a>
					</div>
					<div class="card-body">
						<div class="list-group list-group-flush">
							<c:if test="${fn:length(recentCooperateComplaints) == 0}">
              		해당 항목이 존재하지 않습니다.
              	</c:if>
							<c:forEach var="recentCooperateComplaint"
								items="${recentCooperateComplaints }">
								<a
									href="mw_process_view.do?id=${recentCooperateComplaint.cId }"
									class="list-group-item list-group-item-action lh-sm d-flex align-items-center">
									<span class="mr-2 point">${recentCooperateComplaint.cDepartment }</span>
									<p class="text-nowrap">${recentCooperateComplaint.cWriteDate }</p>
									<p
										class="text-left d-block text-truncate flex-grow-1 ml-2 mr-1"
										style="width: calc(100% - 230px)">
										${recentCooperateComplaint.cTitle}</p>
								</a>
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
