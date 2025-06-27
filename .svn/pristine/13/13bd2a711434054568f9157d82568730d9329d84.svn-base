<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<!DOCTYPE html>
<html lang="kr">
  <head>
    <meta charset="UTF-8">
  	<title>동구 종합민원이력관리시스템</title>
<link type="image/x-icon" rel="shortcut icon"
	href="${path}/resources/images/favicon.ico">
    <%@ include file="../include/lib.jsp" %>
  </head>
  <body>
    <%@ include file="../include/header.jsp" %>

    <div class="container-fluid">
      <div class="row">
        <%@ include file="../include/nav.jsp" %>

        <main
          role="main"
          class="col-md-9 ml-sm-auto col-lg-10 d-flex flex-column"
          style="height: calc(100vh - 91px)"
        >
          <div class="container">
            <div
              class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3"
            >
              <h1 class="h2">민원 수정</h1>
            </div>
            
            	<form id="completeForm">
            	<input type="hidden" id="id" name="id" value="${complaint.cId }">
            	<div class="search-form row border pt-2 bg-light mx-1">
            		<div class="col-md-2 pb-2">
		                <select
		                  class="custom-select d-block w-100"
		                  id="completion"
		                >
		                  <c:if test="${complaint.cNotificated == 1 }">
		                  	<option value="nonComplete">미완료</option>
		                  </c:if>
		                  <c:if test="${complaint.cNotificated == 2 }">
		                  	<option value="imsi">임시저장</option>
		                  	<option value="complete">완료</option>
		                  </c:if>
		                  <c:if test="${complaint.cNotificated == 9 }">
		                  	<option value="imsi">임시저장</option>
		                  	<option value="nonComplete">미완료</option>
		                  </c:if>
		                </select>
              	  
              	  </div>
            	</form>
            	<div class="col-md-2 pb-2">
	                <button id="completeButton" class="btn btn-success btn-block">
	                  진행단계 변경
	                </button>
	              </div>
              <div class="col-md-2 pb-2 ml-auto">
                <button id="tempDeleteButton" class="btn btn-outline-danger btn-block">
                  삭제
                </button>
              </div>
            </div>
            <!-- 
            <table class="table table-sm table-bordered mt-4">
              <colgroup>
                <col style="width: 15%" />
                <col style="width: auto" />
              </colgroup>
              <tbody>
                <tr>
                  <th class="bg-light" style="width: 20%">민원 내용</th>
                  <td style="width: 80%">
                  	<textarea style="width: 100%" disabled>
                  		${complaint.cContent }
                  	</textarea>
                  </td>
                </tr>
                <tr>
                  <th class="bg-light">처리 내용</th>
                  <td>${complaint.cComplete }</td>
                </tr>
                <tr>
                  <th class="bg-light">사진</th>
                  <td>사진</td>
                </tr>
              </tbody>
            </table>
             -->
             <br>
            <table class="table table-input table-pc table-sm table-bordered mt-4">
            <colgroup>
              <col width="15%" />
              <col width="15%" />
              <col width="10%" />
              <col width="40%" />
              <col width="20%" />
            </colgroup>
            <tbody>
              <tr>
                <th class="border-blue point" rowspan="2">제목</th>
                <td rowspan="2" colspan="3">${complaint.cTitle }</td>
                <th class="bg-light" colspan="2">일련번호</th>
              </tr>
              <tr>
                <td colspan="2">${complaint.cWriteDateCount }</td>
              </tr>
              <tr>
                <th class="point">위치</th>
                <td colspan="3">${complaint.cAddress }</td>
                <th class="bg-light">행정동</th>
                <td>${complaint.cDistrict }</td>
              </tr>
              <tr>
                <th class="point" rowspan="2">민원인</th>
                <th class="bg-light">성명</th>
                <th class="bg-light">연락처</th>
                <th class="bg-light" colspan="2">주소</th>
                <th class="bg-light">특이사항</th>
              </tr>
              <tr>
                <td>${complaint.cPetitioner }</td>
                <td>${complaint.cPetitionerPhone }</td>
                <td colspan="2">${complaint.cPetitionerAddress }</td>
                <td>${complaint.cPetitionerSpecific }</td>
              </tr>
              <tr>
                <th class="point" rowspan="2">민원 신청 및 접수</th>
                <th class="bg-light">신청접수일</th>
                <th class="bg-light">신청방법</th>
                <th class="bg-light">최초제기일</th>
                <th class="bg-light" colspan="2">제기횟수</th>
              </tr>
              <tr>
                <td>${complaint.cReceiptDate }</td>
                <td>${complaint.cReceiptWay }</td>
                <td>${complaint.cRaiseDate }</td>
                <td colspan="2">${complaint.cRaiseCount }</td>
              </tr>
              <tr>
                <th class="point" rowspan="2">처리자</th>
                <th class="bg-light">담당부서</th>
                <th class="bg-light">과장</th>
                <th class="bg-light">계장</th>
                <th class="bg-light" colspan="2">담당자</th>
              </tr>
              <tr>
                <td>${complaint.cDepartment }</td>
                <td>${complaint.cOfficer01 }</td>
                <td>${complaint.cOfficer02 }</td>
                <td colspan="2">${complaint.cOfficer03 }</td>
              </tr>
              <tr>
                <th class="point" rowspan="2">연관부서</th>
                <th class="bg-light">연관부서1</th>
                <th class="bg-light">연관부서2</th>
                <th class="bg-light">연관부서3</th>
                <th class="bg-light" colspan="2">연관부서4</th>
              </tr>
              <tr>
                <td>${complaint.dpName01 }</td>
                <td>${complaint.dpName02 }</td>
                <td>${complaint.dpName03 }</td>
                <td colspan="2">${complaint.dpName04 }</td>
              </tr>
              <!-- 
              <tr>
                <th class="point">민원요지</th>
                <td colspan="5">${complaint.cKeyPoint }</td>
              </tr>
               -->
              <tr>
                <th class="point">민원내용</th>
                <td colspan="5">
                	<textarea disabled>${complaint.cContent }</textarea>
                </td>
              </tr>
              <tr>
                <th class="point">처리계획</th>
                <td colspan="5">
                	<textarea>${complaint.cPlan }</textarea>
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
                <td colspan="2">${complaint.cTitle }</td>
              </tr>
              <tr>
                <th class="bg-light">일련번호</th>
                <td>${complaint.cWriteDateCount }</td>
              </tr>
              <tr>
                <th class="point" colspan="2">위치</th>
              </tr>
              <tr>
                <td colspan="2">${complaint.cAddress }</td>
              </tr>
              <tr>
                <th class="bg-light">행정동</th>
                <td>${complaint.cDistrict }</td>
              </tr>
              <tr>
                <th class="point" colspan="2">민원인</th>
              </tr>
              <tr>
                <th class="bg-light">성명</th>
                <th class="bg-light">연락처</th>
              </tr>
              <tr>
                <td>${complaint.cPetitioner }</td>
                <td>${complaint.cPetitionerPhone }</td>
              </tr>
              <tr>
                <th class="bg-light" colspan="2">주소</th>
              </tr>
              <tr>
                <td colspan="2">${complaint.cPetitionerAddress }</td>
              </tr>
              <tr>
                <th class="bg-light" colspan="2">특이사항</th>
              </tr>
              <tr>
                <td colspan="2">${complaint.cPetitionerSpecific }</td>
              </tr>
              <tr>
                <th class="point" colspan="2">민원 신청 및 접수</th>
              </tr>
              <tr>
                <th class="bg-light">신청접수일</th>
                <th class="bg-light">신청방법</th>
              </tr>
              <tr>
                <td>${complaint.cReceiptDate }</td>
                <td>${complaint.cReceiptWay }</td>
              </tr>
              <tr>
                <th class="bg-light">최초제기일</th>
                <th class="bg-light">제기횟수</th>
              </tr>
              <tr>
                <td>${complaint.cRaiseDate }</td>
                <td>${complaint.cRaiseCount }</td>
              </tr>
              <tr>
                <th class="point" colspan="2">처리자</th>
              </tr>
              <tr>
                <th class="bg-light">담당부서</th>
                <th class="bg-light">과장</th>
              </tr>
              <tr>
                <td>${complaint.cDepartment }</td>
                <td>${complaint.cOfficer01 }</td>
              </tr>
              <tr>
                <th class="bg-light">계장</th>
                <th class="bg-light">담당자</th>
              </tr>
              <tr>
                <td>${complaint.cOfficer02 }</td>
                <td>${complaint.cOfficer03 }</td>
              </tr>
              <tr>
                <th class="point" colspan="2">연관부서</th>
              </tr>
              <tr>
                <th class="bg-light">연관부서1</th>
                <th class="bg-light">연관부서2</th>
              </tr>
              <tr>
                <td>${complaint.dpName01 }</td>
                <td>${complaint.dpName02 }</td>
              </tr>
              <tr>
                <th class="bg-light">연관부서3</th>
                <th class="bg-light">연관부서4</th>
              </tr>
              <tr>
                <td>${complaint.dpName03 }</td>
                <td>${complaint.dpName04 }</td>
              </tr>
              <!-- 
              <tr>
                <th class="point" colspan="2">민원요지</th>
              </tr>
              <tr>
                <td colspan="2">${complaint.cKeyPoint }</td>
              </tr>
               -->
              <tr>
                <th class="point" colspan="2">민원내용</th>
              </tr>
              <tr>
                <td colspan="2">${complaint.cContent }</td>
              </tr>
              <tr>
                <th class="point" colspan="2">처리계획</th>
              </tr>
              <tr>
                <td colspan="2">${complaint.cPlan }</td>
              </tr>
            </tbody>
          </table>
          </div>
          <%@ include file="../include/footer.jsp" %>
        </main>
      </div>
    </div>
    <script>
	    $(document).ready(function(){			
			$("#completeButton").on('click', function() {
				var completion = $("#completion").val()
				if (confirm("진행 사항을 변경하시겠습니까?")) {
					if (completion === "imsi") {
						$("#completeForm").attr("action", "/admin/imsi_complaint.do?id=${complaintId}");
					} else if (completion === "nonComplete") {
						$("#completeForm").attr("action", "/admin/non_complete_complaint.do?id=${complaintId}");
					} else if (completion === "complete") {
						$("#completeForm").attr("action", "/admin/complete_complaint.do?id=${complaintId}");
					}
					$("#completeForm").submit();
				}
			});
			
			$("#tempDeleteButton").on('click', function() {
				if (confirm("해당 민원을 삭제하시겠습니까?")) {
					$("#completeForm").attr("action", "/admin/temp_delete_complaint.do?id=${complaintId}");
					$("#completeForm").submit();
				}
			})
		});
    </script>
	
	<!-- 
	<script
      src="https://cdn.jsdelivr.net/npm/jquery@3.5.1/dist/jquery.slim.min.js"
      integrity="sha384-DfXdz2htPH0lsSSs5nCTpuj/zy4C+OGpamoFVy38MVBnE+IbbVYUew+OrCXaRkfj"
      crossorigin="anonymous"
    ></script>
    <script>
      window.jQuery ||
        document.write(
          '<script src="../assets/js/vendor/jquery.slim.min.js"><\/script>'
        );
    </script>
    <script src="../assets/dist/js/bootstrap.bundle.min.js"></script>

    <script src="https://cdn.jsdelivr.net/npm/feather-icons@4.28.0/dist/feather.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@2.9.4/dist/Chart.min.js"></script>
    <script src="dashboard.js"></script>
	 -->
  </body>
</html>
