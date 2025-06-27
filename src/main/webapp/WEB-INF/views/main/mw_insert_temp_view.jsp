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

		<div class="container">
			<h3 class="col-md-4">임시 저장 내용</h3>
			<form id="updateForm" method="post">
				<input type="hidden" id="cId" name="cId" value="${complaintId }">
				<input type="hidden" id="dpId" name="dpId"
					value="${sessionScope.userDpId }"> <input type="hidden"
					id="uId" name="uId" value="${sessionScope.userId }"> <input
					type="hidden" name="cAdminNum" id="cAdminNum"
					value="${sessionScope.userAdminNum }">
				<table
					class="table table-input table-pc table-sm table-bordered mt-4">
					<colgroup>
						<col width="20%" />
						<col width="20%" />
						<col width="20%" />
						<col width="20%" />
						<col width="20%" />
					</colgroup>
					<tbody>
						<tr>
							<th class="point">유형등록</th>
							<th class="bg-light">분류 유형</th>
							<td><select name="cSeparationType" id="cSeparationType">
									<option>${tempComplaint.cSeparationType }</option>
									<option>도로교통</option>
									<option>보행환경</option>
									<option>생활안전</option>
									<option>주차환경</option>
									<option>빈집관리</option>
									<option>하수정비</option>
									<option>청소환경</option>
									<option>공원관리</option>
									<option>체육시설</option>
									<option>보건복지</option>
									<option>문화경제</option>
									<option>기타</option>
							</select></td>
							<th class="bg-light">처리 구분</th>
							<td><select name="cProcessClass" id="cProcessClass">
									<option>${tempComplaint.cProcessClass }</option>
									<option>처리중</option>
									<!-- 
									<option>처리완료</option>
									 -->
									<option>중장기검토</option>
									<option>타기관협조</option>
									<option>처리불가</option>

							</select></td>
						</tr>
						<tr>
							<th class="border-blue point" rowspan="2"><span
								style="color: red;">*</span> 제목</th>
							<td rowspan="2" colspan="3"><textarea name="cTitle"
									id="cTitle" wrap=on width="100%" hight="100%"
									placeholder="제목(200자 이내)">${tempComplaint.cTitle }</textarea></td>
							<th class="bg-light" colspan="2">등록일자</th>
						</tr>
						<tr>
							<td colspan="2">${tempComplaint.cWriteDate }</td>
						</tr>
						<tr>
							<th class="point" rowspan="2"><span style="color: red;">*</span>
								위치</th>
							<td colspan="3" rowspan="2"><textarea name="cAddress"
									id="cAddress" wrap=on width="100%" hight="100%"
									placeholder="위치(100자 이내)">${tempComplaint.cAddress }</textarea></td>
							<th class="bg-light">행정동</th>

						</tr>
						<tr>
							<td><select name="cDistrict" id="cDistrict">
									<option>${tempComplaint.cDistrict }</option>
									<option>충장동</option>
									<option>동명동</option>
									<option>계림1동</option>
									<option>계림2동</option>
									<option>산수1동</option>
									<option>산수2동</option>
									<option>지산1동</option>
									<option>지산2동</option>
									<option>서남동</option>
									<option>학동</option>
									<option>학운동</option>
									<option>지원1동</option>
									<option>지원2동</option>
									<option>기타</option>
							</select></td>
						</tr>
						<tr>
							<th class="point" rowspan="2">민원인</th>
							<th class="bg-light"><span style="color: red;">*</span> 성명</th>
							<th class="bg-light"><span style="color: red;">*</span> 연락처</th>
							<th class="bg-light"><span style="color: red;">*</span> 주소</th>
							<th class="bg-light"><span style="color: red;">*</span> 특이사항</th>
						</tr>
						<tr>
							<td><input type="text" id="cPetitioner" name="cPetitioner"
								placeholder="성명(20자 이내)" value="${tempComplaint.cPetitioner }"></td>
							<td><input type="text" id="cPetitionerPhone"
								name="cPetitionerPhone" placeholder="연락처(20자 이내)"
								value="${tempComplaint.cPetitionerPhone }"></td>
							<td><textarea name="cPetitionerAddress"
									id="cPetitionerAddress" wrap=on width="100%" hight="100%"
									placeholder="주소(150자 이내)">${tempComplaint.cPetitionerAddress }</textarea></td>
							<td><input type="text" id="cPetitionerSpecific"
								name="cPetitionerSpecific" placeholder="특이사항(20자 이내)"
								value="${tempComplaint.cPetitionerSpecific }"></td>
						</tr>
						<tr>
							<th class="point" rowspan="2">민원 신청 및 접수</th>
							<th class="bg-light"><span style="color: red;">*</span>
								신청접수일</th>
							<th class="bg-light">신청방법</th>
							<th class="bg-light">제기횟수(중복)</th>
							<th class="bg-light">최초제기일</th>

						</tr>
						<tr>
							<td><input type="date" id="cReceiptDate" name="cReceiptDate"
								value="${tempComplaint.cReceiptDate }" max="9999-12-31"></td>
							<td><select name="cReceiptWay" id="cReceiptWay">
									<option>${tempComplaint.cReceiptWay }</option>
									<option>국민신문고</option>
									<option>주민과의대화</option>
									<option>부서방문</option>
									<option>조기순찰</option>
									<option>의회</option>
									<option>기타</option>
							</select></td>
							<td><input type="number" id="cRaiseCount" name="cRaiseCount"
								value="${tempComplaint.cRaiseCount }" min="0"></td>
							<td><input type="date" id="cRaiseDate" name="cRaiseDate"
								value="${tempComplaint.cRaiseDate }" max="9999-12-31"></td>
						</tr>
						<tr>
							<th class="point" rowspan="2">처리자</th>
							<th class="bg-light"><span style="color: red;">*</span> 담당부서</th>
							<th class="bg-light"><span style="color: red;">*</span> 과장</th>
							<th class="bg-light"><span style="color: red;">*</span> 계장</th>
							<th class="bg-light"><span style="color: red;">*</span> 담당자</th>
						</tr>
						<tr>
							<td><select name="cDepartment" id="cDepartment">
											<option>${tempComplaint.cDepartment }</option>
											<option>없음</option>
											<c:forEach var="department" items="${relatedDepartments }">
												<option>${department }</option>
											</c:forEach>
										</select></td>
							<td><input type="text" id="cOfficer01" name="cOfficer01"
								value="${tempComplaint.cOfficer01 }" placeholder="과장명 입력"></td>
							<td><input type="text" id="cOfficer02" name="cOfficer02"
								value="${tempComplaint.cOfficer02 }" placeholder="계장명 입력"></td>
							<td><input type="text" id="cOfficer03" name="cOfficer03"
								value="${tempComplaint.cOfficer03 }" placeholder="담당자명 입력"></td>
						</tr>
						<tr>
							<th class="point" rowspan="2">연관부서(팀)</th>
							<th class="bg-light">연관부서1(팀)</th>
							<th class="bg-light">연관부서2(팀)</th>
							<th class="bg-light">연관부서3(팀)</th>
							<th class="bg-light">연관부서4(팀)</th>
						</tr>
						<tr>
							<td><select name="dpName01" id="dpName01">
									<option>${tempComplaint.dpName01 }</option>
									<option>없음</option>
									<c:forEach var="department" items="${relatedDepartments2 }">
										<option>${department }</option>
									</c:forEach>
							</select></td>
							<td><select name="dpName02" id="dpName02">
									<option>${tempComplaint.dpName02 }</option>
									<option>없음</option>
									<c:forEach var="department" items="${relatedDepartments2 }">
										<option>${department }</option>
									</c:forEach>
							</select></td>
							<td><select name="dpName03" id="dpName03">
									<option>${tempComplaint.dpName03 }</option>
									<option>없음</option>
									<c:forEach var="department" items="${relatedDepartments2 }">
										<option>${department }</option>
									</c:forEach>
							</select></td>
							<td><select name="dpName04" id="dpName04">
									<option>${tempComplaint.dpName04 }</option>
									<option>없음</option>
									<c:forEach var="department" items="${relatedDepartments2 }">
										<option>${department }</option>
									</c:forEach>
							</select></td>
						</tr>
						<!-- 
						<tr>
							<th class="point"><span style="color: red;">*</span> 민원요지</th>
							<td colspan="5"><textarea name="cKeyPoint" id="cKeyPoint"
									wrap=on width="100%" hight="100%" placeholder="민원요지(200자 이내)">${tempComplaint.cKeyPoint }</textarea></td>
						</tr>
						 -->
						<tr>
							<th class="point"><span style="color: red;">*</span> 민원내용</th>
							<td colspan="5"><textarea name="cContent" id="cContent"
									wrap=on width="100%" hight="100%" placeholder="민원내용 (2000자 이내)">${tempComplaint.cContent }</textarea></td>
						</tr>
						<tr>
							<th class="point"><span style="color: red;">*</span> 처리계획</th>
							<td colspan="5"><textarea name="cPlan" id="cPlan" wrap=on
									width="100%" hight="100%" placeholder="처리계획 (1000자 이내)">${tempComplaint.cPlan }</textarea></td>
						</tr>
					</tbody>
				</table>
			</form>

			<div id="div3">
				<h4>처리이력등록</h4>
				<div class="border p-3 my-3 bg-light d-flex">
					<div class="mr-2" style="width: calc(100% - 87px)">
						<form id="insertSettleForm" method="post">
							<div class="d-flex">
								<input type="hidden" id="cId" name="cId"
									value="${tempComplaint.cId }"> <input type="hidden"
									id="uId" name="uId" value="${sessionScope.userId }"> <input
									type="hidden" id="dpName" name="dpName"
									value="${tempComplaint.cDepartment }"> <input
									type="hidden" id="uName" name="uName"
									value="${tempComplaint.cOfficer03 }"> <input
									type="hidden" id="psName" name="psName" value="#"> <input
									type="date" id="csDate" name="csDate" placeholder="날짜"
									class="border" width="150px" max="9999-12-31" /> <input
									type="hidden" name="viewName" value="mw_insert_temp_view" />
								<textarea name="csContent" id="csContent" wrap="on"
									class="w-100 border" placeholder="처리내용"></textarea>
							</div>
						</form>
					</div>
					<button type="button" class="btn btn-bule" id="btnInsertProcess"
						name="btnInsertProcess">저장</button>
				</div>
				<table class="table table-input table-sm table-bordered">
					<colgroup>
						<col width="30%" />
						<col width="60%" />
						<col width="5%" />
						<col width="5%" />
					</colgroup>
					<thead>
						<tr>
							<th colspan="4" class="border-blue point">처리 진행 내용</th>
						</tr>
					</thead>
					<tbody>
						<tr>
							<th class="bg-light">일자별</th>
							<th class="bg-light">처리내용</th>
							<th class="bg-light">수정</th>
							<th class="bg-light">삭제</th>
						</tr>
						<c:forEach var="settle" items="${complaintSettles }">
							<tr>
								<c:choose>
									<c:when test="${sessionScope.userId == settle.uId }">
										<form id="settleUpdate${settle.csId }" name="settleUpdate">
											<input type="hidden" id="cId" name="cId"
												value="${tempComplaint.cId }"> <input type="hidden"
												id="csId" name="csId" value="${settle.csId }" /> <input
												type="hidden" name="viewName" value="mw_insert_temp_view" />
											<td><input type="date" id="csDate1" name="csDate1"
												placeholder="날짜" class="border" width="150px"
												value="${settle.csDate }" max="9999-12-31" /></td>
											<td style="white-space: inherit"><textarea
													name="csContent1" id="csContent1" wrap="on"
													class="w-100 border" placeholder="처리내용">${settle.csContent }</textarea></td>
											<td><img src="${path}/resources/images/edit.png"
												onclick="updateSettle(${settle.csId})"
												style="cursor: pointer" /></td>
											<td><img src="${path}/resources/images/trash.png"
												onclick="deleteSettle(${settle.csId})"
												style="cursor: pointer" /></td>
											</td>
										</form>

									</c:when>
									<c:otherwise>
										<td>${settle.csDate }</td>
										<td style="white-space: inherit"><textarea
												name="csContent1" id="csContent1" wrap="on" disabled
												class="w-100 border" placeholder="처리내용">${settle.csContent }</textarea></td>
									</c:otherwise>
								</c:choose>
							</tr>
						</c:forEach>
					</tbody>
				</table>
				<c:if test="${fn:length(complaintSettles) == 0}">
					<div class="d-flex justify-content-center mb-3">해당 항목이 존재하지
						않습니다.</div>
				</c:if>
			</div>

			<div id="div4">
				<h4>사진등록 (위치도, 현장사진 등)</h4>
				<form id="insertImageForm" method="post"
					encType="multipart/form-data">
					<div class="border p-3 my-3 bg-light d-flex">

						<input type="hidden" id="cId" name="cId"
							value="${tempComplaint.cId }"> <input type="hidden"
							id="uId" name="uId" value="${sessionScope.userId }"> <input
							type="hidden" id="dpName" name="dpName"
							value="${tempComplaint.cDepartment }"> <input
							type="hidden" id="uName" name="uName"
							value="${tempComplaint.cOfficer03 }"> <input
							type="hidden" id="psName" name="psName" value="#"> <input
							type="hidden" name="viewName" value="mw_insert_temp_view" />
						<div class="mr-2" style="width: calc(100% - 74px)">
							<div class="input-group">
								<div class="custom-file">
									<!-- 
	                  <input
	                    type="file"
	                    class="custom-file-input"
	                    id="ciImage"
	                    name="ciImage"
	                    aria-describedby="inputGroupFileAddon04"
	                  />
	                  <label class="custom-file-label" for="inputGroupFile04"
	                    >파일 선택...</label
	                  >
	                   -->
									<input type="file" id="imageFile" name="imageFile"
										multiple="multiple" accept=".png,.jpg,.jpeg">
								</div>
							</div>
							<textarea name="ciContent" id="ciContent"
								class="w-100 border mt-2" wrap="on" placeholder="이미지 설명"></textarea>
						</div>

						<button type="button" class="btn btn-bule" id="btnInsertImage"
							name="btnInsertImage">저장</button>
				</form>
			</div>
			<div class='bigPictureWrapper'>
				<div class='bigPicture' style='width: 1200px'></div>
			</div>
			<div class="row row-cols-1 row-cols-md-4 mb-3 text-center">
				<c:forEach var="image" items="${complaintImages }"
					varStatus="status">
					<div class="col-md-3 py-2">
						<div class="card">
							<!--
							<img src="${path}/resources/images/view-city-street-with-trees.jpg" class="card-img-top imgSelect" />
							  -->
							<img src="/static/images/${image.ciImage }"
								class="card-img-top imgSelect" alt="..." />


							<!-- 
							 <img src="${image.ciImage }" class="card-img-top"
								alt="..." />
							  -->
							<div class="card-body">
								<p class="card-text">${image.ciContent }</p>
								<c:if test="${sessionScope.userId == image.uId }">
									<img src="${path}/resources/images/trash.png"
										onclick="deleteImage(${image.ciId})" style="cursor: pointer" />
								</c:if>
							</div>
						</div>

					</div>
				</c:forEach>
			</div>
			<c:if test="${fn:length(complaintImages) == 0}">
				<div class="d-flex justify-content-center mb-3">해당 항목이 존재하지
					않습니다.</div>
			</c:if>
		</div>

		<div id="div5">
			<h4>파일등록 (민원관련 서류 등)</h4>
			<form id="insertFileForm" method="post" encType="multipart/form-data">
				<div class="border p-3 my-3 bg-light d-flex">
					<input type="hidden" id="cId" name="cId"
						value="${tempComplaint.cId }"> <input type="hidden"
						id="uId" name="uId" value="${sessionScope.userId }"><input
						type="hidden" id="uName" name="uName"
						value="${tempComplaint.cOfficer03 }"> <input type="hidden"
						name="viewName" value="mw_insert_temp_view" />
					<div class="mr-2" style="width: calc(100% - 74px)">
						<div class="input-group">
							<div class="custom-file">
								<input type="file" id="textFile" name="textFile">
								<textarea name="cfContent" id="cfContent"
									class="w-100 border mt-2" wrap="on" placeholder="파일 설명"></textarea>
							</div>
						</div>
					</div>

					<button type="button" class="btn btn-bule" id="btnInsertFile"
						name="btnInsertFile">저장</button>
			</form>
		</div>
		<table class="table table-input table-sm table-bordered">
			<colgroup>
				<col width="15%" />
				<col width="15%" />
				<col width="70%" />
			</colgroup>

			<tbody>
				<tr>
					<th class="bg-light">담당자</th>
					<th class="bg-light">파일명</th>
					<th class="bg-light">내용</th>
					<th class="bg-light">삭제</th>
				</tr>
				<c:forEach var="file" items="${complaintFiles }">
					<tr>
						<td>${file.uName }</td>

						<td>
							<!-- 
							<a href="${path }/resources/upload/files/${file.cfFileLogic }">${file.cfFileLogic }</a>
							 --> <a href="/static/files/${file.cfFileLogic }" download>${file.cfFileLogic }</a>
						</td>

						<td style="white-space: inherit">${file.cfContent }</td>
						<c:if test="${sessionScope.userId == file.uId }">
							<td><img src="${path}/resources/images/trash.png"
								onclick="deleteFile(${file.cfId})" style="cursor: pointer" /></td>
						</c:if>

					</tr>
				</c:forEach>
			</tbody>
		</table>
		<c:if test="${fn:length(complaintFiles) == 0}">
			<div class="d-flex justify-content-center mb-3">해당 항목이 존재하지
				않습니다.</div>
		</c:if>
	</div>

	<div id="div6">
		<h4>댓글등록</h4>
		<form id="insertReplyForm" method="post">
			<input type="hidden" id="cId" name="cId"
				value="${tempComplaint.cId }"> <input type="hidden" id="uId"
				name="uId" value="${sessionScope.userId }"> <input
				type="hidden" id="dpName" name="dpName"
				value="${tempComplaint.cDepartment }"> <input type="hidden"
				id="uName" name="uName" value="${sessionScope.userName }"> <input
				type="hidden" id="psName" name="psName" value="#"> <input
				type="hidden" name="viewName" value="mw_insert_temp_view" />
			<div class="border p-3 my-3 bg-light d-flex">
				<div class="mr-2" style="width: calc(100% - 90px)">
					<div class="d-flex">
						<textarea name="crContent" id="crContent" wrap="on"
							class="w-100 border" placeholder="댓글 등록"></textarea>
					</div>
				</div>
				<button type="button" class="btn btn-bule" id="btnInsertReply"
					name="btnInsertReply">저장</button>
			</div>
		</form>

		<table class="table table-input table-sm table-bordered">
			<colgroup>
				<col width="15%" />
				<col width="15%" />
				<col width="70%" />
			</colgroup>

			<tbody>
				<tr>
					<th class="bg-light">날짜</th>
					<th class="bg-light">담당자</th>
					<th class="bg-light">내용</th>
					<th class="bg-light">삭제</th>
				</tr>
				<c:forEach var="reply" items="${complaintReplies }">
					<tr>
						<td>${reply.crDate }</td>
						<td>${reply.uName }</td>
						<td style="white-space: inherit">${reply.crContent }</td>
						<c:if test="${sessionScope.userId == reply.uId }">
							<td><img src="${path}/resources/images/trash.png"
								onclick="deleteReply(${reply.crId})" style="cursor: pointer" /></td>
						</c:if>
					</tr>
				</c:forEach>
			</tbody>
		</table>
		<c:if test="${fn:length(complaintReplies) == 0}">
			<div class="d-flex justify-content-center mb-3">해당 항목이 존재하지
				않습니다.</div>
		</c:if>
	</div>

	<div id="div2" style="background: #f3f7fa; padding: 10px;">
		<h4>처리완료등록</h4>
		<form id="updateProcessForm" method="post">
			<input type="hidden" id="cId" name="cId"
				value="${tempComplaint.cId }"> <input type="hidden"
				id="cNotificated" name="cNotificated"
				value="${tempComplaint.cNotificated }"> <input type="hidden"
				name="viewName" value="mw_insert_temp_view" />
			<table class="table table-pc table-input table-sm table-bordered">
				<colgroup>
					<col width="20%" />
					<col width="20%" />
					<col width="20%" />
					<col width="20%" />
					<col width="20%" />
				</colgroup>
				<tbody>
					<tr>
						<th class="border-blue point"><span style="color: red;">*</span>
							조치내용(민원답변)</th>
						<td colspan="4" class="bg-white"><textarea name="cAnswer"
								id="cAnswer" wrap="on" rows="5" placeholder="조치내용(민원답변)">${tempComplaint.cAnswer}</textarea>
						</td>
					</tr>

					<tr>
						<th class="point" rowspan="3">처리완료</th>

					</tr>
					<tr>
						<th class="bg-light"><span style="color: red;">*</span>
							완료(예정)일</th>
						<th class="bg-light"><span style="color: red;">*</span>
							민원답변완료</th>
						<th class="bg-light"><span style="color: red;">*</span> 민원
							만족도</th>
						<th class="bg-light" colspan="2"><span style="color: red;">*</span>
							비고</th>
					</tr>
					<tr>
						<td class="bg-white"><input type="date" id="cDeadline"
							name="cDeadline" value="${tempComplaint.cDeadline }"
							max="9999-12-31"></td>

						<td class="bg-white"><select name="cComplete" id="cComplete">
								<option>${tempComplaint.cComplete }</option>
								<option>통보완료</option>
								<option>통보미완료</option>
						</select></td>
						<!-- 
	                <td><input type="text" id="cSatisfiction" name="cSatisfiction" value="${tempComplaint.cSatisfiction }"></td>
	                 -->
						<td class="bg-white"><select name="cSatisfiction"
							id="cSatisfiction">
								<option>${tempComplaint.cSatisfiction }</option>
								<option>매우만족</option>
								<option>만족</option>
								<option>보통</option>
								<option>불만</option>
								<option>매우불만</option>
						</select></td>

						<td class="bg-white"><input type="text" id="cClient"
							name="cClient" value="${tempComplaint.cClient }"></td>
					</tr>
					<tr>
						<th class="point">참고사항</th>
						<td colspan="4" class="bg-white"><input type="text"
							id="cReference" name="cReference"
							value="${tempComplaint.cReference }"></td>
					</tr>
				</tbody>
			</table>
		</form>

		<table class="table table-input table-phone table-sm table-bordered">
			<colgroup>
				<col width="50%" />
				<col width="50%" />
			</colgroup>
			<tbody>
				<tr>
					<th colspan="2" class="border-blue point">조치내용(민원답변)</th>
				</tr>
				<tr>
					<td colspan="2"><textarea name="cAnswer" id="cAnswer"
							wrap="on" rows="5" placeholder="조치내용(민원답변)">${tempComplaint.cAnswer }</textarea>
					</td>
				</tr>
				<tr>
					<th class="point" colspan="2">처리완료</th>
				</tr>

				<tr>
					<th class="bg-light">완료(예정)일</th>
					<th class="bg-light">민원답변완료</th>
				</tr>
				<tr>
					<td><input type="date" id="cDeadline" name="cDeadline"
						value="${tempComplaint.cDeadline }" max="9999-12-31"></td>
					<td><select name="cComplete" id="cComplete">
							<option>선택</option>
							<option>통보완료</option>
							<option>통보미완료</option>
					</select></td>
				</tr>
				<tr>
					<th class="bg-light">민원 만족도</th>
					<th class="bg-light" colspan="2">민원유형</th>
				</tr>
				<tr>
					<!-- 
              	<td><input type="text" id="cSatisfiction" name="cSatisfiction" value="${tempComplaint.cSatisfiction }"></td>
              	 -->
					<td><select name="cSatisfiction" id="cSatisfiction">
							<option>선택</option>
							<option>매우만족</option>
							<option>만족</option>
							<option>보통</option>
							<option>불만</option>
							<option>매우불만</option>
					</select></td>

					<td><input type="text" id="cClient" name="cClient"
						value="${tempComplaint.cClient }"></td>
				</tr>
				<tr>
					<th colspan="2" class="point">참고사항</th>
				</tr>
				<tr>
					<td colspan="2"><input type="text" id="cClient" name="cClient"
						value="${tempComplaint.cClient }"></td>
				</tr>
			</tbody>
		</table>
		<div class="button-wrapper">
			<!-- 
		<button type="button" class="btn btn-secondary" id="imsi" name="imsi">임시
				저장</button>
		 -->

			<button type="button" class="btn btn-bule" id="complete"
				name="complete" onclick="updateComplete()">저장</button>
		</div>
	</div>


	<table
		class="table table-input table-phone table-sm table-bordered mt-4">
		<colgroup>
			<col width="50%" />
			<col width="50%" />
		</colgroup>
		<tbody>
			<tr>
				<th class="point" colspan="2">유형등록</th>

			</tr>
			<tr>
				<th class="bg-light">분류 유형</th>

				<th class="bg-light">처리 구분</th>
			</tr>
			<tr>
				<td><select name="cSeparationType" id="cSeparationType">
						<option>${tempComplaint.cSeparationType }</option>
						<option>도로교통</option>
						<option>보행환경</option>
						<option>생활안전</option>
						<option>주차환경</option>
						<option>빈집관리</option>
						<option>하수정비</option>
						<option>청소환경</option>
						<option>공원관리</option>
						<option>체육시설</option>
						<option>보건복지</option>
						<option>문화경제</option>
						<option>기타</option>
				</select></td>
				<td><select name="cProcessClass" id="cProcessClass">
						<option>${tempComplaint.cProcessClass }</option>
						<option>처리중</option>
						<option>처리완료</option>
						<option>중장기검토</option>
						<option>타기관협조</option>
						<option>처리불가</option>
						<option>기타</option>
				</select></td>
			</tr>
			<tr>
				<th colspan="2" class="border-blue point">제목</th>
			</tr>
			<tr>
				<td colspan="2"><textarea name="cTitle" id="cTitle" wrap=on
						width="100%" hight="100%" placeholder="제목(200자 이내)">${tempComplaint.cTitle }</textarea>
				</td>
			</tr>
			<tr>
				<th class="bg-light">일련번호</th>
				<td>-</td>
			</tr>
			<tr>
				<th class="point" colspan="2">위치</th>
			</tr>
			<tr>
				<td colspan="2"><textarea name="cAddress" id="cAddress" wrap=on
						width="100%" hight="100%" placeholder="위치(100자 이내)">${tempComplaint.cAddress }</textarea></td>
			</tr>
			<tr>
				<th class="bg-light">행정동</th>
				<td><input type="text" id="cDistrict" name="cDistrict"
					placeholder="행정동(20자 이내)" value="${tempComplaint.cDistrict }"></td>
			</tr>
			<tr>
				<th class="point" colspan="2">민원인</th>
			</tr>
			<tr>
				<th class="bg-light">성명</th>
				<th class="bg-light">연락처</th>
			</tr>
			<tr>
				<td><input type="text" id="cPetitioner" name="cPetitioner"
					placeholder="성명(20자 이내)" value="${tempComplaint.cPetitioner }"></td>
				<td><input type="text" id="cPetitionerPhone"
					name="cPetitionerPhone" placeholder="연락처(20자 이내)"
					value="${tempComplaint.cPetitionerPhone }"></td>
			</tr>
			<tr>
				<th class="bg-light" colspan="2">주소</th>
			</tr>
			<tr>
				<td colspan="2"><textarea name="cPetitionerAddress"
						id="cPetitionerAddress" wrap=on width="100%" hight="100%"
						placeholder="주소(150자 이내)">${tempComplaint.cPetitionerAddress }</textarea></td>

			</tr>
			<tr>
				<th class="bg-light" colspan="2">특이사항</th>
			</tr>
			<tr>
				<td colspan="2"><input type="text" id="cPetitionerSpecific"
					name="cPetitionerSpecific" placeholder="특이사항(20자 이내)"
					value="${tempComplaint.cPetitionerSpecific }"></td>
			</tr>
			<tr>
				<th class="point" colspan="2">민원 신청 및 접수</th>
			</tr>
			<tr>
				<th class="bg-light">신청접수일</th>
				<th class="bg-light">신청방법</th>
			</tr>
			<tr>
				<td><input type="date" id="cReceiptDate" name="cReceiptDate"
					value="${tempComplaint.cReceiptDate }" max="9999-12-31"></td>
				<td><input type="text" id="cReceiptWay" name="cReceiptWay"
					placeholder="신청방법(20자 이내)" value="${tempComplaint.cReceiptWay }"></td>
			</tr>
			<tr>
				<th class="bg-light">제기횟수(중복)</th>
				<th class="bg-light">최초제기일</th>
			</tr>
			<tr>
				<td><input type="number" id="cRaiseCount" name="cRaiseCount"
					value="${tempComplaint.cRaiseCount }"></td>
				<td><input type="date" id="cRaiseDate" name="cRaiseDate"
					value="${tempComplaint.cRaiseDate }" max="9999-12-31"></td>
			</tr>
			<tr>
				<th class="point" colspan="2">처리자</th>
			</tr>
			<tr>
				<th class="bg-light">담당부서</th>
				<th class="bg-light">과장</th>
			</tr>
			<tr>
				<td>${tempComplaint.cDepartment }</td>
				<td><input type="text" id="cOfficer01" name="cOfficer01"
					value="${tempComplaint.cOfficer01 }" placeholder="과장명 입력"></td>
			</tr>
			<tr>
				<th class="bg-light">계장</th>
				<th class="bg-light">담당자</th>
			</tr>
			<tr>
				<td><input type="text" id="cOfficer02" name="cOfficer02"
					value="${tempComplaint.cOfficer02 }" placeholder="계장명 입력"></td>
				<td><input type="text" id="cOfficer03" name="cOfficer03"
					value="${tempComplaint.cOfficer03 }" placeholder="담당자명 입력"></td>
			</tr>
			<tr>
				<th class="point" colspan="2">연관부서(계)</th>
			</tr>
			<tr>
				<th class="bg-light">연관부서(계)1</th>
				<th class="bg-light">연관부서(계)2</th>
			</tr>
			<tr>
				<td><select name="dpName01" id="dpName01">
						<option>없음</option>
						<c:forEach var="department" items="${relatedDepartments }">
							<option>${department }</option>
						</c:forEach>
				</select></td>
				<td><select name="dpName02" id="dpName02">
						<option>없음</option>
						<c:forEach var="department" items="${relatedDepartments }">
							<option>${department }</option>
						</c:forEach>
				</select></td>
			</tr>
			<tr>
				<th class="bg-light">연관부서(계)3</th>
				<th class="bg-light">연관부서(계)4</th>
			</tr>
			<tr>
				<td><select name="dpName03" id="dpName03">
						<option>없음</option>
						<c:forEach var="department" items="${relatedDepartments }">
							<option>${department }</option>
						</c:forEach>
				</select></td>
				<td><select name="dpName04" id="dpName04">
						<option>없음</option>
						<c:forEach var="department" items="${relatedDepartments }">
							<option>${department }</option>
						</c:forEach>
				</select></td>
			</tr>
			<!-- 
					<tr>
						<th class="point" colspan="2">민원요지</th>
					</tr>
					<tr>
						<td colspan="2"><textarea name="cKeyPoint" id="cKeyPoint"
								wrap=on placeholder="민원요지(200자 이내)">${tempComplaint.cKeyPoint }</textarea></td>
					</tr>
					 -->
			<tr>
				<th class="point" colspan="2">민원내용</th>
			</tr>
			<tr>
				<td colspan="2"><textarea name="cContent" id="cContent" wrap=on
						rows="5" placeholder="민원내용 (2000자 이내)">${tempComplaint.cContent }</textarea></td>
			</tr>
			<tr>
				<th class="point" colspan="2">처리계획</th>
			</tr>
			<tr>
				<td colspan="2"><textarea name="cPlan" id="cPlan" wrap=on
						rows="5" placeholder="처리계획 (1000자 이내)">${tempComplaint.cPlan }</textarea></td>
			</tr>
		</tbody>
	</table>
	<div class="button-wrapper">
		<button type="button" id="imsi" class="btn btn-secondary">전체저장</button>
		<button type="button" id="process" class="btn btn-bule"
			onclick="location.href='process_complaint.do?id=${complaintId}'">등록
			확정</button>
		<button type="button" class="btn btn-secondary ml-5"
			onclick="location.href='mw_insert_temp_list.do'">목록</button>
	</div>
	</div>
	</div>
	<%@ include file="../include/main_footer.jsp"%>
	<script>
	
		$(document).ready(
				function() {
					$("#imsi").click(
							function() {
								console.log($("#cDepartment").val());
								var title = $("#cTitle").val();
								if (title == '') {
									alert("제목을 입력해주세요.");
									return;
								}
								var address = $("#cAddress").val();
								if (address == '') {
									alert("위치를 입력해주세요.");
									return;
								}
								var district = $("#cDistrict").val();
								if (district == '') {
									alert("행정동을 입력해주세요.");
									return;
								}
								var petitioner = $("#cPetitioner").val();
								if (petitioner == '') {
									alert("민원인 성명을 입력해주세요.");
									return;
								}
								var petitionerPhone = $("#cPetitionerPhone")
										.val();
								if (petitionerPhone == '') {
									alert("민원인 연락처를 입력해주세요.");
									return;
								}
								var petitionerAddress = $("#cPetitionerAddress").val();
								if (petitionerAddress == '') {
									alert("민원인 주소를 입력해주세요.");
									return;
								}
								var petitionerSpecific = $(
										"#cPetitionerSpecific").val();
								if (petitionerSpecific == '') {
									alert("민원인 특이사항을 입력해주세요.");
									return;
								}
								var receiptDate = $("#cReceiptDate").val();
								if (receiptDate == '') {
									alert("신청접수일을 입력해주세요.");
									return;
								}
								var receiptWay = $("#cReceiptWay").val();
								if (receiptWay == '') {
									alert("신청방법을 입력해주세요.");
									return;
								}
								var raiseDate = $("#cRaiseDate").val();
								if (raiseDate == '') {
									alert("최초제기일을 입력해주세요.");
									return;
								}
								var department = $("#cDepartment").val();
								if (department == '없음') {
									alert("담당부서를 입력해주세요.");
									return;
								}
								var officer1 = $("#cOfficer01").val();
								if (officer1 == '') {
									alert("과장명을 입력해주세요.");
									return;
								}
								var officer2 = $("#cOfficer02").val();
								if (officer2 == '') {
									alert("계장명을 입력해주세요.");
									return;
								}
								var officer3 = $("#cOfficer03").val();
								if (officer3 == '') {
									alert("담당자명을 입력해주세요.");
									return;
								}
								/*
								var keyPoint = $("#cKeyPoint").val();
								if (keyPoint == '') {
									alert("민원요지를 입력해주세요.");
									return;
								}
								*/
								var content = $("#cContent").val();
								if (content == '') {
									alert("민원내용을 입력해주세요.");
									return;
								}
								var plan = $("#cPlan").val();
								if (plan == '') {
									alert("민원처리계획을 입력해주세요.");
									return;
								}
								$("#updateForm").attr("action",
										"/main/update_temp_complaint.do");
								$("#updateForm").submit();
							});
					
					$("#btnInsertProcess")
					.click(
							function() {
								var csDate = $('#csDate').val();
								if (csDate === '') {
									alert("처리이력등록 날짜를 입력해주세요.");
									return;
								}
								var csContent = $('#csContent')
										.val();
								if (csContent === '') {
									alert("처리이력등록 내용을 입력해주세요.");
									return;
								}
								$("#insertSettleForm")
										.attr("action",
												"/main/insert_complaint_settle.do");
								$("#insertSettleForm").submit();
							});
					
					$("#btnInsertImage")
					.click(
							function() {
								alert("테스트");
								console.log($("#insertImageForm")[0][6]);
								let size = $("#insertImageForm")[0][6].files[0].size;
								let type = $("#insertImageForm")[0][6].files[0].type;
								

								if (!(type == "image/jpeg" || type == "image/png")) {
									alert("이미지 파일만 등록 가능합니다.");
									return;
								}

								if (size < 50000000) {
									$("#insertImageForm")
											.attr("action",
													"/main/insert_complaint_image.do");
									$("#insertImageForm")
											.submit();
								} else {
									alert("파일의 용량이 50MB 초과하였습니다.");
									return;
								}

							});
					
					$("#btnInsertFile")
					.click(
							function() {
								let size = $("#insertFileForm")[0][4].files[0].size;

								if (size < 50000000) {
									$("#insertFileForm")
											.attr("action",
													"/main/insert_complaint_file.do");
									$("#insertFileForm")
											.submit();
								} else {
									alert("파일의 용량이 50MB 초과하였습니다.");
								}

							});
					
					$("#btnInsertReply")
					.click(
							function() {
								$("#insertReplyForm")
										.attr("action",
												"/main/insert_complaint_reply.do");
								$("#insertReplyForm").submit();
							});
				});
	
	function updateComplete() {
		var answer = $('#cAnswer').val();
		if (answer == '') {
			alert("조치내용(민원답변)을 입력해주세요.");
			return;
		}
		var deadline = $("#cDeadline").val();
		if (deadline == '') {
			alert("완료(예정)일을 입력해주세요.");
			return;
		}
		var complete = $("#cComplete").val();
		if (complete == '선택') {
			alert("민원답변완료 여부를 선택해주세요.");
			return;
		}
		var satisfiction = $("#cSatisfiction").val();
		if (satisfiction == '선택') {
			alert("민원 만족도를 선택해주세요.");
			return;
		}
		var client = $("#cClient").val();
		if (client == '') {
			alert("비고란을 입력해주세요.");
			return;
		}
		if (confirm("민원 처리가 완료된 내용을 작성하시겠습니까?")) {
			$("#updateProcessForm").attr("action",
			"update_process_complaint.do");
			$("#updateProcessForm").submit();
		}
	}
		
		function updateSettle(csId) {
			if (confirm("수정하시겠습니까?")) {
				$("#settleUpdate" + csId).attr("action", "update_settle.do");
				$("#settleUpdate" + csId).submit();
			} else {
				return;
			}
		}
		
		function deleteSettle(csId) {
			if (confirm("삭제하시겠습니까?")) {
				$("#settleUpdate" + csId).attr("action", "delete_settle.do");
				$("#settleUpdate" + csId).submit();
			} else {
				return;
			}
		}
		
		function deleteImage(ciId) {
			if (confirm("삭제하시겠습니까?")) {
				location.href="/main/delete_temp_image.do?id=" + ciId + "&cId=" + ${tempComplaint.cId}; 
			}
		}
		
		function deleteFile(cfId) {
			if (confirm("삭제하시겠습니까?")) {
				location.href="/main/delete_temp_file.do?id=" + cfId + "&cId=" + ${tempComplaint.cId}; 
			}
		}
		
		function deleteReply(crId) {
			if (confirm("삭제하시겠습니까?")) {
				location.href="/main/delete_temp_reply.do?id=" + crId + "&cId=" + ${tempComplaint.cId}; 
			}
		}
	</script>

</body>
</html>
