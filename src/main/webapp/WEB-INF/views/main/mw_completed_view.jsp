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
<style>
.bigPictureWrapper {
	position: absolute;
	display: none;
	justify-content: center;
	align-items: center;
	top: 900px; /*시작위치*/
	width: 100%;
	height: 100%;
	background-color: gray;
	z-index: 100;
	background: rgba(255, 255, 255, 0.5);
}

.bigPicture {
	position: relative;
	display: flex;
	justify-content: center;
	align-items: center;
}
</style>
</head>
<body>
	<%@ include file="../include/main_header.jsp"%>
	<div class="wrapper main-page">

		<div class="container">
			<h3>완료민원</h3>

			<div id="div1">
				<h4>등록내용</h4>
				<table
					class="table table-input table-td-break table-pc table-sm table-bordered">
					<colgroup>
						<col width="20%">
						<col width="20%">
						<col width="20%">
						<col width="20%">
						<col width="20%">
					</colgroup>
					<tbody>
						<tr>
							<th class="border-blue point">분류 유형</th>
							<td>${processComplaint.cSeparationType }</td>
							<th class="border-blue point">처리 구분</th>
							<c:choose>
								<c:when test="${sessionScope.userId == processComplaint.uId }">
									<td><select name="cProcessClass" id="cProcessClass">
											<option>${processComplaint.cProcessClass }</option>
											<option>처리중</option>
											<option>처리완료</option>
											<option>중장기검토</option>
											<option>타기관협조</option>
											<option>처리불가</option>
											<option>기타</option>
									</select></td>
									<td><button class="btn btn-bule" id="btnChange" onclick={changeProcess()}>변경</button></td>
								</c:when>
								<c:otherwise>
									<td>${processComplaint.cProcessClass }</td>
								</c:otherwise>
							</c:choose>
						</tr>
						<tr>
							<th class="border-blue point" rowspan="2">제목</th>
							<td rowspan="2" colspan="3">${processComplaint.cTitle }</td>
							<th class="bg-light">일련번호</th>
						</tr>
						<tr>
							<td>${processComplaint.cWriteDateCount }</td>
						</tr>
						<tr>
							<th class="point" rowspan="2">위치</th>
							<td rowspan="2" colspan="3">${processComplaint.cAddress }</td>
							<th class="bg-light">행정동</th>

						</tr>
						<tr>
							<td>${processComplaint.cDistrict }</td>
						</tr>
						<tr>
							<th class="point" rowspan="2">민원인</th>
							<th class="bg-light">성명</th>
							<th class="bg-light">연락처</th>
							<th class="bg-light">주소</th>
							<th class="bg-light">특이사항</th>
						</tr>
						<tr>
							<td>${processComplaint.cPetitioner }</td>
							<td>${processComplaint.cPetitionerPhone }</td>
							<td>${processComplaint.cPetitionerAddress }</td>
							<td>${processComplaint.cPetitionerSpecific }</td>
						</tr>
						<tr>
							<th class="point" rowspan="2">민원 신청 및 접수</th>
							<th class="bg-light">신청접수일</th>
							<th class="bg-light">신청방법</th>
							<th class="bg-light">최초제기일</th>
							<th class="bg-light">제기횟수</th>
						</tr>
						<tr>
							<td>${processComplaint.cReceiptDate }</td>
							<td>${processComplaint.cReceiptWay }</td>
							<td>${processComplaint.cRaiseDate }</td>
							<td colspan="2">${processComplaint.cRaiseCount }</td>
						</tr>
						<tr>
							<th class="point" rowspan="2">처리자</th>
							<th class="bg-light">담당부서</th>
							<th class="bg-light">과장</th>
							<th class="bg-light">계장</th>
							<th class="bg-light">담당자</th>
						</tr>
						<tr>
							<td>${processComplaint.cDepartment }</td>
							<td>${processComplaint.cOfficer01 }</td>
							<td>${processComplaint.cOfficer02 }</td>
							<td><a href='tel:062-608-${processComplaint.cAdminNum }'>${processComplaint.cOfficer03 }</a></td>
						</tr>
						<tr>
							<th class="point" rowspan="2">연관부서(계)</th>
							<th class="bg-light">연관부서(계)1</th>
							<th class="bg-light">연관부서(계)2</th>
							<th class="bg-light">연관부서(계)3</th>
							<th class="bg-light">연관부서(계)4</th>
						</tr>
						<tr>
							<td>${processComplaint.dpName01 }</td>
							<td>${processComplaint.dpName02 }</td>
							<td>${processComplaint.dpName03 }</td>
							<td>${processComplaint.dpName04 }</td>
						</tr>
						<!-- 
						<tr>
							<th class="point">민원요지</th>
							<td colspan="5">${processComplaint.cKeyPoint }</td>
						</tr>
						 -->
						<tr>
							<th class="point">민원내용</th>
							<td colspan="5"><textarea rows="5" disabled>${processComplaint.cContent }</textarea>
							</td>
						</tr>
						<tr>
							<th class="point">처리계획</th>
							<td colspan="5"><textarea rows="5">${processComplaint.cPlan }</textarea></td>
							</td>
						</tr>
					</tbody>
				</table>
				<table class="table table-input table-phone table-sm table-bordered">
					<colgroup>
						<col width="50%" />
						<col width="50%" />
					</colgroup>
					<tbody>
						<tr>
							<th colspan="2" class="border-blue point">제목</th>
						</tr>
						<tr>
							<td colspan="2">${processComplaint.cTitle }</td>
						</tr>
						<tr>
							<th class="bg-light">일련번호</th>
							<td>${processComplaint.cWriteDateCount }</td>
						</tr>
						<tr>
							<th class="point" colspan="2">위치</th>
						</tr>
						<tr>
							<td colspan="2">${processComplaint.cAddress }</td>
						</tr>
						<tr>
							<th class="bg-light">행정동</th>
							<td>${processComplaint.cDistrict }</td>
						</tr>
						<tr>
							<th class="point" colspan="2">민원인</th>
						</tr>
						<tr>
							<th class="bg-light">성명</th>
							<th class="bg-light">연락처</th>
						</tr>
						<tr>
							<td>${processComplaint.cPetitioner }</td>
							<td>${processComplaint.cPetitionerPhone }</td>
						</tr>
						<tr>
							<th class="bg-light" colspan="2">주소</th>
						</tr>
						<tr>
							<td colspan="2">${processComplaint.cPetitionerAddress }</td>
						</tr>
						<tr>
							<th class="bg-light" colspan="2">특이사항</th>
						</tr>
						<tr>
							<td colspan="2">${processComplaint.cPetitionerSpecific }</td>
						</tr>
						<tr>
							<th class="point" colspan="2">민원 신청 및 접수</th>
						</tr>
						<tr>
							<th class="bg-light">신청접수일</th>
							<th class="bg-light">신청방법</th>
						</tr>
						<tr>
							<td>${processComplaint.cReceiptDate }</td>
							<td>${processComplaint.cReceiptWay }</td>
						</tr>
						<tr>
							<th class="bg-light">최초제기일</th>
							<th class="bg-light">제기횟수</th>
						</tr>
						<tr>
							<td>${processComplaint.cRaiseDate }</td>
							<td>${processComplaint.cRaiseCount }</td>
						</tr>
						<tr>
							<th class="point" colspan="2">처리자</th>
						</tr>
						<tr>
							<th class="bg-light">담당부서</th>
							<th class="bg-light">과장</th>
						</tr>
						<tr>
							<td>${processComplaint.cDepartment }</td>
							<td>${processComplaint.cOfficer01 }</td>
						</tr>
						<tr>
							<th class="bg-light">계장</th>
							<th class="bg-light">담당자</th>
						</tr>
						<tr>
							<td>${processComplaint.cOfficer02 }</td>
							<td>${processComplaint.cOfficer03 }</td>
						</tr>
						<tr>
							<th class="point" colspan="2">연관부서(계)</th>
						</tr>
						<tr>
							<th class="bg-light">연관부서(계)1</th>
							<th class="bg-light">연관부서(계)2</th>
						</tr>
						<tr>
							<td>${processComplaint.dpName01 }</td>
							<td>${processComplaint.dpName02 }</td>
						</tr>
						<tr>
							<th class="bg-light">연관부서(계)3</th>
							<th class="bg-light">연관부서(계)4</th>
						</tr>
						<tr>
							<td>${processComplaint.dpName03 }</td>
							<td>${processComplaint.dpName04 }</td>
						</tr>
						<!-- 
						<tr>
							<th class="point" colspan="2">민원요지</th>
						</tr>
						<tr>
							<td colspan="2"><textarea disabled>${processComplaint.cKeyPoint }</textarea></td>
						</tr>
						 -->
						<tr>
							<th class="point" colspan="2">민원내용</th>
						</tr>
						<tr>
							<td colspan="2"><textarea rows="5" disabled>${processComplaint.cContent }</textarea></td>
						</tr>
						<tr>
							<th class="point" colspan="2">처리계획</th>
						</tr>
						<tr>
							<td colspan="2"><textarea rows="5">${processComplaint.cPlan }</textarea></td>
							</td>
						</tr>
					</tbody>
				</table>
			</div>


			<div id="div3">
				<h4>처리이력등록</h4>
				<table class="table table-input table-sm table-bordered">
					<colgroup>
						<col width="30%" />
						<col width="70%" />
					</colgroup>
					<thead>
						<tr>
							<th colspan="2" class="border-blue point">처리 진행 내용</th>
						</tr>
					</thead>
					<tbody>
						<tr>
							<th class="bg-light">일자별</th>
							<th class="bg-light">처리내용</th>
						</tr>

						<c:forEach var="settle" items="${complaintSettles }">
							<tr>
								<td>${settle.csDate }</td>
								<td style="white-space: inherit"><textarea disabled>${settle.csContent }</textarea>
								</td>
							</tr>
						</c:forEach>
					</tbody>
				</table>
				<c:if test="${fn:length(complaintSettles) == 0}">
					<div class="d-flex justify-content-center">해당 항목이 존재하지 않습니다.</div>
				</c:if>
			</div>

			<div id="div4">
				<h4>사진 (위치도, 현장사진 등)</h4>
				<div class='bigPictureWrapper'>
					<div class='bigPicture'></div>
				</div>
				<div class="row row-cols-1 row-cols-md-4 mb-3 text-center">
					<c:forEach var="image" items="${complaintImages }">
						<div class="col-md-3 py-2">
							<div class="card">
								<!-- 
								 <img src="/static/images/${image.ciImage }"
									class="card-img-top" alt="..." />
								  -->
								<img src="/static/images/${image.ciImage }"
									class="card-img-top imgSelect" alt="..." />
								<div class="card-body">
									<p class="card-text">${image.ciContent }</p>
								</div>
							</div>
						</div>
					</c:forEach>
				</div>
				<c:if test="${fn:length(complaintImages) == 0}">
					<div class="d-flex justify-content-center">해당 항목이 존재하지 않습니다.</div>
				</c:if>
			</div>
			<div id="div5">
				<h4>파일 (민원관련 서류 등)</h4>

				<table class="table table-input  table-sm table-bordered">
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
							</tr>
						</c:forEach>
					</tbody>
				</table>
				<c:if test="${fn:length(complaintFiles) == 0}">
					<div class="d-flex justify-content-center">해당 항목이 존재하지 않습니다.</div>
				</c:if>
			</div>
			<div id="div6">
				<h4>댓글목록</h4>
				<form id="insertReplyForm" method="post">
					<input type="hidden" id="cId" name="cId"
						value="${processComplaint.cId }"> <input type="hidden"
						id="uId" name="uId" value="${sessionScope.userId }"> <input
						type="hidden" id="dpName" name="dpName"
						value="${processComplaint.cDepartment }"> <input
						type="hidden" id="uName" name="uName"
						value="${sessionScope.userName }"> <input type="hidden"
						id="psName" name="psName" value="#">
					<div class="border p-3 my-3 bg-light d-flex">
						<div class="mr-2" style="width: calc(100% - 90px)">
							<div class="d-flex">
								<textarea name="crContent" id="crContent" wrap="on"
									class="w-100 border" placeholder="댓글 등록"></textarea>
							</div>
						</div>
						<button type="button" class="btn btn-bule" id="btnInsertReply"
							name="btnInsertReply">댓글 등록</button>
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
							<th class="bg_light">삭제</th>
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
					<div class="d-flex justify-content-center">해당 항목이 존재하지 않습니다.</div>
				</c:if>
			</div>
			<div id="div2">
				<h4>처리완료등록</h4>
				<form id="updateProcessForm" method="post">
					<input type="hidden" id="cId" name="cId"
						value="${processComplaint.cId }">
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
								<th class="border-blue point">조치내용(민원답변)</th>
								<td colspan="4"><textarea name="cAnswer" id="cAnswer"
										wrap="on" rows="5" disabled>${processComplaint.cAnswer }</textarea></td>
							</tr>

							<tr>
								<th class="point" rowspan="3">처리완료</th>
							</tr>
							<tr>
								<th class="bg-light">완료(예정)일</th>
								<th class="bg-light">민원답변완료</th>
								<th class="bg-light">민원 만족도</th>
								<th class="bg-light" colspan="2">비고</th>
							</tr>
							<tr>
								<td>${processComplaint.cDeadline }</td>
								<td>${processComplaint.cComplete }</td>
								<td>${processComplaint.cSatisfiction }</td>
								<td>${processComplaint.cClient }</td>
							</tr>
							<tr>
								<th class="point">참고사항</th>
								<td colspan="4">${processComplaint.cReference }</td>
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
									wrap="on" rows="5" placeholder="조치내용(민원답변)" disabled>${processComplaint.cAnswer }</textarea>
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
							<td>${processComplaint.cDeadline }</td>
							<td>${processComplaint.cComplete }</td>
						</tr>
						<tr>
							<th class="bg-light">민원 만족도</th>
							<th class="bg-light" colspan="2">비고</th>
						</tr>
						<tr>
							<td>${processComplaint.cSatisfiction }</td>
							<td>${processComplaint.cClient }</td>
						</tr>
						<tr>
							<th colspan="2" class="point">참고사항</th>
						</tr>
						<tr>
							<td colspan="2">${processComplaint.cReference }</td>
						</tr>
					</tbody>
				</table>

			</div>
		</div>
	</div>
</body>
<%@ include file="../include/main_footer.jsp"%>
<script>
	function changeProcess() {
		if (confirm("처리 구분 사항을 변경하시겠습니까?")) {
			location.href = "/main/change_process_class.do?id=" + ${processComplaint.cId} + "&process=" + $("#cProcessClass").val();
			alert("변경 완료되었습니다.");
		}
	}		
	
	$("#btnInsertReply").click(
			function() {
				$("#insertReplyForm").attr("action",
						"/main/insert_complaint_reply_completed.do");
				$("#insertReplyForm").submit();
			});
	function deleteReply(crId) {
		if (confirm("삭제하시겠습니까?")) {
			location.href="/main/delete_completed_reply.do?id=" + crId + "&cId=" + ${processComplaint.cId}; 
		}
	}
	$(document).ready(function (e) {

	      $(document).on("click", ".imgSelect", function () {
	        var path = $(this).attr('src')
	        showImage(path);
	      });//end click event

	      function showImage(fileCallPath) {

	        $(".bigPictureWrapper").css("display", "flex").show();

	        $(".bigPicture")
	          .html("<img src='" + fileCallPath + "' >")
	          .animate({ width: '100%', height: '100%' }, 1000);

	      }//end fileCallPath

	      $(".bigPictureWrapper").on("click", function (e) {
	        $(".bigPicture").animate({ width: '0%', height: '0%' }, 1000);
	        setTimeout(function () {
	          $('.bigPictureWrapper').hide();
	        }, 900);
	      });//end bigWrapperClick event
	    });
</script>

</html>
