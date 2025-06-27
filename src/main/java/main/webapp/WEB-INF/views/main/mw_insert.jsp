<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
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
		<div class="container">
			<div class="row">
				<h3 class="col-md-4">개별등록</h3>
			</div>

			<table
				class="table table-input table-pc table-sm table-bordered mt-4">
				<form id="insertForm" method="post">
					<input type="hidden" id="uId" name="uId"
						value="${sessionScope.userId }"> <input type="hidden"
						id="dpId" name="dpId" value="${sessionScope.userDpId }"> <input
						type="hidden" id="cDepartment" name="cDepartment"
						value="${department }"> 
					 <input type="hidden"
						name="cAdminNum" id="cAdminNum"
						value="${sessionScope.userAdminNum }">
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
							<th class="bg-light"><span style="color: red;">*</span> 분류 유형</th>
							<td><select name="cSeparationType" id="cSeparationType">
									<option>선택</option>
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
							<th class="bg-light"><span style="color: red;">*</span> 처리 구분</th>
							<td><select name="cProcessClass" id="cProcessClass">
									<option>선택</option>
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
									placeholder="제목(200자 이내)"></textarea></td>
							<th class="bg-light" colspan="2">일련번호</th>
						</tr>
						<tr>
							<td colspan="2">-</td>
						</tr>
						<tr>
							<th class="point" rowspan="2"><span style="color: red;">*</span> 위치</th>
							<td rowspan="2" colspan="3"><textarea name="cAddress"
									id="cAddress" wrap=on width="100%" hight="100%"
									placeholder="위치(100자 이내)"></textarea></td>
							<th class="bg-light"><span style="color: red;">*</span> 행정동</th>

						</tr>
						<tr>
							<td><select name="cDistrict" id="cDistrict">	
									<option>선택</option>
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
							<th class="bg-light">성명</th>
							<th class="bg-light">연락처</th>
							<th class="bg-light">주소</th>
							<th class="bg-light">특이사항</th>
						</tr>
						<tr>
							<td><input name="cPetitioner" id="cPetitioner" type="text"
								placeholder="성명(20자 이내)"></td>
							<td><input name="cPetitionerPhone" id="cPetitionerPhone"
								type="text" placeholder="연락처(20자 이내)"></td>
							<td><textarea name="cPetitionerAddress"
									id="cPetitionerAddress" wrap=on width="100%" hight="100%"
									placeholder="주소(150자 이내)"></textarea></td>
							<td><input name="cPetitionerSpecific"
								id="cPetitionerSpecific" type="text" placeholder="특이사항(20자 이내)"></td>
						</tr>
						<tr>
							<th class="point" rowspan="2">민원 신청 및 접수</th>
							<th class="bg-light"><span style="color: red;">*</span> 신청접수일</th>
							<th class="bg-light"><span style="color: red;">*</span> 신청방법</th>
							<th class="bg-light">제기횟수(중복)</th>
							<th class="bg-light">최초제기일</th>
						</tr>
						<tr>
							<td><input name="cReceiptDate" id="cReceiptDate" type="date" max="9999-12-31"></td>
							<td><select name="cReceiptWay" id="cReceiptWay">
									<option>선택</option>
									<option>국민신문고</option>
									<option>주민과의대화</option>
									<option>부서방문</option>
									<option>조기순찰</option>
									<option>의회</option>
									<option>기타</option>
							</select></td>
							<td><input name="cRaiseCount" id="cRaiseCount" type="number"
								min="0" value="0"></td>
							<td><input name="cRaiseDate" id="cRaiseDate" type="date" max="9999-12-31"></td>
						</tr>
						<tr>
							<th class="point" rowspan="2">처리자</th>
							<th class="bg-light">담당부서</th>
							<th class="bg-light"><span style="color: red;">*</span> 과장</th>
							<th class="bg-light"><span style="color: red;">*</span> 계장</th>
							<th class="bg-light">담당자</th>
						</tr>
						<tr>
							<td><input name="cDepartment" id="cDepartment"
								value="${department }" disabled></td>
							<td><input name="cOfficer01" id="cOfficer01" placeholder="과장명 입력"></td>
							<td><input name="cOfficer02" id="cOfficer02" placeholder="계장명 입력"></td>
							<td><input name="cOfficer03" id="cOfficer03" placeholder="담당자명 입력"></td>
						</tr>
						<tr>
							<th class="point" rowspan="2">연관부서(계)</th>
							<th class="bg-light">연관부서(계)1</th>
							<th class="bg-light">연관부서(계)2</th>
							<th class="bg-light">연관부서(계)3</th>
							<th class="bg-light">연관부서(계)4</th>
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
							<th class="point"><span style="color: red;">*</span> 민원요지</th>
							<td colspan="5"><textarea name="cKeyPoint" id="cKeyPoint"
									wrap=on width="100%" hight="100%" placeholder="민원요지(200자 이내)"></textarea></td>
						</tr>
						<tr>
							<th class="point"><span style="color: red;">*</span> 민원내용</th>
							<td colspan="5"><textarea name="cContent" id="cContent"
									wrap=on width="100%" hight="100%" placeholder="민원내용 (2000자 이내)"></textarea></td>
						</tr>
						<tr>
							<th class="point"><span style="color: red;">*</span> 처리계획</th>
							<td colspan="5"><textarea name="cPlan" id="cPlan" wrap=on
									width="100%" hight="100%" placeholder="처리계획 (1000자 이내)"></textarea></td>
						</tr>
					</tbody>
				</form>
			</table>


			<table
				class="table table-input table-phone table-sm table-bordered mt-4">
				<form id="insertForm" method="post">
					<input type="hidden" id="uId" name="uId"
						value="${sessionScope.userId }"> <input type="hidden"
						id="dpId" name="dpId" value="${sessionScope.userDpId }"> <input
						type="hidden" id="cDepartment" name="cDepartment"
						value="${department }"> 
					
					<colgroup>
						<col width="50%" />
						<col width="50%" />
					</colgroup>
					<tbody>
						<tr>
							<th class="point" colspan="2">유형등록</th>

						</tr>
						<tr>
							<th class="bg-light"><span style="color: red;">*</span> 분류 유형</th>

							<th class="bg-light"><span style="color: red;">*</span> 처리 구분</th>
						</tr>
						<tr>
							<td><select name="cSeparationType" id="cSeparationType">
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
									<option>처리중</option>
									<option>중장기검토</option>
									<option>일부처리중</option>
									<option>타기관협조</option>
									<option>처리불가</option>
									<option>기타</option>
							</select></td>
						</tr>
						<tr>
							<th class="border-blue point" colspan="2"><span style="color: red;">*</span> 제목</th>
						</tr>
						<tr>
							<td colspan="2"><textarea name="cTitle" id="cTitle" wrap=on
									width="100%" hight="100%" placeholder="제목(200자 이내)"></textarea>
							</td>
						</tr>
						<tr>
							<th class="bg-light">일련번호</th>
							<td>-</td>
						</tr>
						<tr>
							<th class="point" colspan="2"><span style="color: red;">*</span> 위치</th>
						</tr>
						<tr>
							<td colspan="2"><textarea name="cAddress" id="cAddress"
									wrap=on width="100%" hight="100%" placeholder="위치(100자 이내)"></textarea></td>
						</tr>
						<tr>
							<th class="bg-light"><span style="color: red;">*</span> 행정동</th>
							<td><input name="cDistrict" id="cDistrict" type="text"
								placeholder="행정동(20자 이내)"></td>
						</tr>
						<tr>
							<th class="point" colspan="2">민원인</th>
						</tr>
						<tr>
							<th class="bg-light">성명</th>
							<th class="bg-light">연락처</th>
						</tr>
						<tr>
							<td><input name="cPetitioner" id="cPetitioner" type="text"
								placeholder="성명(20자 이내)"></td>
							<td><input name="cPetitionerPhone" id="cPetitionerPhone"
								type="text" placeholder="연락처(20자 이내)"></td>
						</tr>
						<tr>
							<th class="bg-light" colspan="2">주소</th>
						</tr>
						<tr>
							<td colspan="2"><textarea name="cPetitionerAddress"
									id="cPetitionerAddress" wrap=on width="100%" hight="100%"
									placeholder="주소(150자 이내)"></textarea></td>

						</tr>
						<tr>
							<th class="bg-light" colspan="2">특이사항</th>
						</tr>
						<tr>
							<td colspan="2"><input name="cPetitionerSpecific"
								id="cPetitionerSpecific" type="text" placeholder="특이사항(20자 이내)"></td>
						</tr>
						<tr>
							<th class="point" colspan="2">민원 신청 및 접수</th>
						</tr>
						<tr>
							<th class="bg-light"><span style="color: red;">*</span> 신청접수일</th>
							<th class="bg-light"><span style="color: red;">*</span> 신청방법</th>
						</tr>
						<tr>
							<td><input name="cReceiptDate" id="cReceiptDate" type="date"></td>
							<td><input name="cReceiptWay" id="cReceiptWay" type="text"
								placeholder="신청방법(20자 이내)"></td>
						</tr>
						<tr>
							<th class="bg-light">제기횟수</th>
							<th class="bg-light">최초제기일</th>
						</tr>
						<tr>
							<td><input name="cRaiseCount" id="cRaiseCount" type="number"></td>
							<td><input name="cRaiseDate" id="cRaiseDate" type="date"></td>
						</tr>
						<tr>
							<th class="point" colspan="2">처리자</th>
						</tr>
						<tr>
							<th class="bg-light">담당부서</th>
							<th class="bg-light"><span style="color: red;">*</span> 과장</th>
						</tr>
						<tr>
							<td><input name="cDepartment" id="cDepartment"
								value="${department }" disabled></td>
							<td><input name="cOfficer01" id="cOfficer01" placeholder="과장명 입력"></td>
						</tr>
						<tr>
							<th class="bg-light"><span style="color: red;">*</span> 계장</th>
							<th class="bg-light">담당자</th>
						</tr>
						<tr>
							<td><input name="cOfficer02" id="cOfficer02" placeholder="계장명 입력"></td>
							<td><input name="cOfficer03" id="cOfficer03" placeholder="담당자명 입력"></td>
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
							<th class="point" colspan="2"><span style="color: red;">*</span> 민원요지</th>
						</tr>
						<tr>
							<td colspan="2"><textarea name="cKeyPoint" id="cKeyPoint"
									wrap=on width="100%" hight="100%" placeholder="민원요지(200자 이내)"></textarea></td>
						</tr>
						<tr>
							<th class="point" colspan="2"><span style="color: red;">*</span> 민원내용</th>
						</tr>
						<tr>
							<td colspan="2"><textarea name="cContent" id="cContent"
									wrap=on width="100%" hight="100%" placeholder="민원내용 (2000자 이내)"></textarea></td>
						</tr>
						<tr>
							<th class="point" colspan="2"><span style="color: red;">*</span> 처리계획</th>
						</tr>
						<tr>
							<td colspan="2"><textarea name="cPlan" id="cPlan" wrap=on
									width="100%" hight="100%" placeholder="처리계획 (1000자 이내)"></textarea></td>
						</tr>
					</tbody>
				</form>
			</table>
			<div class="button-wrapper">
				<button type="button" class="btn btn-secondary" id="imsi">임시
					저장</button>
				<button type="button" class="btn btn-bule" id="register" onclick="register()">등록
					확정</button>
			</div>
		</div>
	</div>
	<%@ include file="../include/main_footer.jsp"%>

	<script>
		$(document).ready(function() {
			$("#imsi").click(function() {
				var separationType = $("#cSeparationType").val();
				if (separationType == "선택") {
					alert("분류유형을 선택해주세요.");
					return;
				}
				var processClass = $("#cProcessClass").val();
				if (processClass == "선택") {
					alert("처리구분을 선택해주세요.");
					return;
				}
				var district = $("#cDistrict").val();
				if (district == '선택') {
					alert("행정동을 선택해주세요.");
					return;
				}
				var receiptWay = $("#cReceiptWay").val();
				if (receiptWay == '선택') {
					alert("신청방법을 선택해주세요.");
					return;
				}
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
				var petitioner = $("#cPetitioner").val();
				if (petitioner == '') {
					$("#cPetitioner").val("-");
				}
				var petitionerPhone = $("#cPetitionerPhone").val();
				if (petitionerPhone == '') {
					$("#cPetitionerPhone").val("-");
				}
				var petitionerAddress = $("#cPetitionerAddress").val();
				if (petitionerAddress == '') {
					$("#cPetitionerAddress").val("-");
				}
				var petitionerSpecific = $("#cPetitionerSpecific").val();
				if (petitionerSpecific == '') {
					$("#cPetitionerSpecific").val("-");
				}
				var receiptDate = $("#cReceiptDate").val();
				if (receiptDate == '') {
					alert("신청접수일을 입력해주세요.");
					return;
				}
				
				var raiseDate = $("#cRaiseDate").val();
				if (raiseDate == '') {
					$("#cRaiseDate").val(receiptDate);
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
				$("#insertForm").attr("action", "/main/insert_complaint.do");
				$("#insertForm").submit();
			});
		});
		
		function register() {
			var separationType = $("#cSeparationType").val();
			if (separationType == "선택") {
				alert("분류유형을 선택해주세요.");
				return;
			}
			var processClass = $("#cProcessClass").val();
			if (processClass == "선택") {
				alert("처리구분을 선택해주세요.");
				return;
			}
			var district = $("#cDistrict").val();
			if (district == '선택') {
				alert("행정동을 선택해주세요.");
				return;
			}
			var receiptWay = $("#cReceiptWay").val();
			if (receiptWay == '선택') {
				alert("신청방법을 선택해주세요.");
				return;
			}
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
			var petitioner = $("#cPetitioner").val();
			if (petitioner == '') {
				$("#cPetitioner").val("-");
			}
			var petitionerPhone = $("#cPetitionerPhone").val();
			if (petitionerPhone == '') {
				$("#cPetitionerPhone").val("-");
			}
			var petitionerAddress = $("#cPetitionerAddress").val();
			if (petitionerAddress == '') {
				$("#cPetitionerAddress").val("-");
			}
			var petitionerSpecific = $("#cPetitionerSpecific").val();
			if (petitionerSpecific == '') {
				$("#cPetitionerSpecific").val("-");
			}
			var receiptDate = $("#cReceiptDate").val();
			if (receiptDate == '') {
				alert("신청접수일을 입력해주세요.");
				return;
			}
			var raiseDate = $("#cRaiseDate").val();
			if (raiseDate == '') {
				$("#cRaiseDate").val(receiptDate);
			}
			var officer1 = $("#cOfficer01").val();
			console.log(officer1);
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
			$("#insertForm").attr("action", "/main/register_complaint.do");
			$("#insertForm").submit();
		}
	</script>
</body>
</html>
