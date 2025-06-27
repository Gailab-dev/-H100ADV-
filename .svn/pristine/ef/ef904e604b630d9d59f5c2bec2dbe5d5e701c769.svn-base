<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
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
					type="hidden" id="cDepartment" name="cDepartment"
					value="${department }"> 
				 <input type="hidden"
					name="cAdminNum" id="cAdminNum"
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
									<option>처리완료</option>
									<option>중장기검토</option>
									<option>일부처리중</option>
									<option>타기관협조</option>
									<option>처리불가</option>
									
							</select></td>
						</tr>
						<tr>
							<th class="border-blue point" rowspan="2"><span style="color: red;">*</span> 제목</th>
							<td rowspan="2" colspan="3"><textarea name="cTitle"
									id="cTitle" wrap=on width="100%" hight="100%"
									placeholder="제목(200자 이내)">${tempComplaint.cTitle }</textarea></td>
							<th class="bg-light" colspan="2">일련번호</th>
						</tr>
						<tr>
							<td colspan="2">${tempComplaint.cWriteDateCount }</td>
						</tr>
						<tr>
							<th class="point" rowspan="2"><span style="color: red;">*</span> 위치</th>
							<td colspan="3"  rowspan="2"><textarea name="cAddress" id="cAddress"
									wrap=on width="100%" hight="100%" placeholder="위치(100자 이내)">${tempComplaint.cAddress }</textarea></td>
							<th class="bg-light">행정동</th>
							
						</tr>
						<tr><td><select name="cDistrict" id="cDistrict">
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
							</select></td></tr>
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
							<td ><textarea name="cPetitionerAddress"
									id="cPetitionerAddress" wrap=on width="100%" hight="100%"
									placeholder="주소(150자 이내)">${tempComplaint.cPetitionerAddress }</textarea></td>
							<td><input type="text" id="cPetitionerSpecific"
								name="cPetitionerSpecific" placeholder="특이사항(20자 이내)"
								value="${tempComplaint.cPetitionerSpecific }"></td>
						</tr>
						<tr>
							<th class="point" rowspan="2">민원 신청 및 접수</th>
							<th class="bg-light"><span style="color: red;">*</span> 신청접수일</th>
							<th class="bg-light">신청방법</th>
							<th class="bg-light" >제기횟수(중복)</th>
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
							<td><input type="number" id="cRaiseCount"
								name="cRaiseCount" value="${tempComplaint.cRaiseCount }" min="0"></td>
							<td><input type="date" id="cRaiseDate" name="cRaiseDate"
								value="${tempComplaint.cRaiseDate }" max="9999-12-31"></td>
						</tr>
						<tr>
							<th class="point" rowspan="2">처리자</th>
							<th class="bg-light">담당부서</th>
							<th class="bg-light"><span style="color: red;">*</span> 과장</th>
							<th class="bg-light"><span style="color: red;">*</span> 계장</th>
							<th class="bg-light">담당자</th>
						</tr>
						<tr>
							<td>${tempComplaint.cDepartment }</td>
							<td><input type="text" id="cOfficer01"
								name="cOfficer01" value="${tempComplaint.cOfficer01 }" placeholder="과장명 입력"></td>
							<td><input type="text" id="cOfficer02"
								name="cOfficer02" value="${tempComplaint.cOfficer02 }" placeholder="계장명 입력"></td>
							<td><input type="text" id="cOfficer03"
								name="cOfficer03" value="${tempComplaint.cOfficer03 }" placeholder="담당자명 입력"></td>
						</tr>
						<tr>
							<th class="point" rowspan="2">연관부서(계)</th>
							<th class="bg-light">연관부서1(계)</th>
							<th class="bg-light">연관부서2(계)</th>
							<th class="bg-light">연관부서3(계)</th>
							<th class="bg-light">연관부서4(계)</th>
						</tr>
						<tr>
							<td><select name="dpName01" id="dpName01">
									<option>${tempComplaint.dpName01 }</option>
									<option>없음</option>
									<c:forEach var="department" items="${relatedDepartments }">
										<option>${department }</option>
									</c:forEach>
							</select></td>
							<td><select name="dpName02" id="dpName02">
									<option>${tempComplaint.dpName02 }</option>
									<option>없음</option>
									<c:forEach var="department" items="${relatedDepartments }">
										<option>${department }</option>
									</c:forEach>
							</select></td>
							<td><select name="dpName03" id="dpName03">
									<option>${tempComplaint.dpName03 }</option>
									<option>없음</option>
									<c:forEach var="department" items="${relatedDepartments }">
										<option>${department }</option>
									</c:forEach>
							</select></td>
							<td><select name="dpName04" id="dpName04">
									<option>${tempComplaint.dpName04 }</option>
									<option>없음</option>
									<c:forEach var="department" items="${relatedDepartments }">
										<option>${department }</option>
									</c:forEach>
							</select></td>
						</tr>
						<tr>
							<th class="point"><span style="color: red;">*</span> 민원요지</th>
							<td colspan="5"><textarea name="cKeyPoint" id="cKeyPoint"
									wrap=on width="100%" hight="100%" placeholder="민원요지(200자 이내)">${tempComplaint.cKeyPoint }</textarea></td>
						</tr>
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
									<option>중장기검토</option>
									<option>일부처리중</option>
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
						<td colspan="2"><textarea name="cAddress" id="cAddress"
								wrap=on width="100%" hight="100%" placeholder="위치(100자 이내)">${tempComplaint.cAddress }</textarea></td>
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
						<td><input type="text" id="cOfficer01"
								name="cOfficer01" value="${tempComplaint.cOfficer01 }" placeholder="과장명 입력"></td>
					</tr>
					<tr>
						<th class="bg-light">계장</th>
						<th class="bg-light">담당자</th>
					</tr>
					<tr>
						<td><input type="text" id="cOfficer02"
								name="cOfficer02" value="${tempComplaint.cOfficer02 }" placeholder="계장명 입력"></td>
						<td><input type="text" id="cOfficer03"
								name="cOfficer03" value="${tempComplaint.cOfficer03 }" placeholder="담당자명 입력"></td>
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
					<tr>
						<th class="point" colspan="2">민원요지</th>
					</tr>
					<tr>
						<td colspan="2"><textarea name="cKeyPoint" id="cKeyPoint"
								wrap=on placeholder="민원요지(200자 이내)">${tempComplaint.cKeyPoint }</textarea></td>
					</tr>
					<tr>
						<th class="point" colspan="2">민원내용</th>
					</tr>
					<tr>
						<td colspan="2"><textarea name="cContent" id="cContent"
								wrap=on rows="5" placeholder="민원내용 (2000자 이내)">${tempComplaint.cContent }</textarea></td>
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
				<button type="button" id="imsi" class="btn btn-secondary">임시
					저장</button>
				<button type="button" id="process" class="btn btn-bule"
					onclick="location.href='process_complaint.do?id=${complaintId}'">등록 확정</button>
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
								var petitionerSpecific = $(
										"#cPetitionerSpecific").val();
								if (petitionerSpecific == '') {
									alert("민원인 연락처를 입력해주세요.");
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
								var keyPoint = $("#cKeyPoint").val();
								if (keyPoint == '') {
									alert("민원요지를 입력해주세요.");
									return;
								}
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
				});
	</script>
</body>
</html>
