<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<html lang="kr">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="description" content="">
    
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
              <h1 class="h2">삭제 민원</h1>
            </div>
            <div class="serch-form row border pt-2 bg-light mx-1">
              <div class="col-md-2 pb-2">
                <select
                    class="custom-select d-block w-100"
                    id="searchType"
                    name="searchType"
                  >
                    <option value="title">제목</option>
                    <option value="content">내용</option>
                    <option value="petitioner">민원인</option>
                    <option value="department">주관부서</option>
                    <option value="serial">일렬번호</option>
                  </select>
              </div>

              <div class="col-md-5 pb-2">
                <input type="text" class="form-control" id="keyword" name="keyword" />
              </div>
              <div class="col-md-2 pb-2">
                <select
                  class="custom-select d-block w-100"
                  id="state"
                  required=""
                >
                  <option value="">부서</option>
                  <option>부서1</option>
                </select>
              </div>
              <div class="col-md-2 pb-2 ml-auto">
                <button class="btn btn-block btn-bule" id="btnSearch">검색</button>
              </div>
            </div>
            <div class="table-responsive mt-4">
              <table class="table table-sm border-bottom">
                <thead>
                  <tr class="bg-light">
                    <th>일련번호</th>
                    <th>진행단계</th>
                    <th>민원신청일</th>
                    <th>주관부서</th>
                    <th>제목</th>
                    <th>복구</th>
                  </tr>
                </thead>
                <tbody>
                  <c:forEach var="deletedComplaint" items="${deletedComplaints }">
                  	<tr>
	                  <td>${deletedComplaint.cWriteDateCount }</td>
	                  <td>임시 삭제</td>
	                  <td>${deletedComplaint.cReceiptDate }</td>
	                  <td>${deletedComplaint.cDepartment }</td>
	                  <td>${deletedComplaint.cTitle }</td>
	                  <td><button id="restore" onclick="restoreMinwon(${deletedComplaint.cId})">복구하기</button></td>
	                </tr>
                  </c:forEach>
                </tbody>
              </table>
              <!-- pagination start -->
	        <div id="paginationBox" class="pagination1">
	            <ul class="pagination" style="justify-content: center;">
	 
	                <c:if test="${pagination.prev}">
	                    <li class="page-item"><a class="page-link" href="#"
	                        onClick="fn_prev('${pagination.page}', '${pagination.range}', '${pagination.rangeSize}', '${pagination.listSize}'
	                    ,'${search.searchType}', '${search.keyword}')">이전</a></li>
	                </c:if>
	 
	                <c:forEach begin="${pagination.startPage}" end="${pagination.endPage}" var="testId">
	                    <li class="page-item <c:out value="${pagination.page == testId ? 'active' : ''}"/> ">
	                    <a class="page-link" href="#"
	                        onClick="fn_pagination('${testId}', '${pagination.range}', '${pagination.rangeSize}', '${pagination.listSize}'
	                     ,'${search.searchType}', '${search.keyword}')">
	                            ${testId} </a></li>
	                </c:forEach>
	 
	                <c:if test="${pagination.next}">
	                    <li class="page-item"><a class="page-link" href="#"
	                        onClick="fn_next('${pagination.range}', '${pagination.range}', '${pagination.rangeSize}', '${pagination.listSize}'
	                    ,'${search.searchType}', '${search.keyword}')">다음</a></li>
	                </c:if>
	            </ul>
	        </div>
	        <!-- pagination end -->
            </div>
          </div>
          <%@ include file="../include/footer.jsp" %>
        </main>
	  </div>
	</div>
	<script>
		function fn_prev(page, range, rangeSize, listSize, searchType, keyword) {
	        
	        var page = ((range - 2) * rangeSize) + 1;
	        var range = range - 1;
	            
	        var url = "/admin/mw_delete.do";
	        url += "?page=" + page;
	        url += "&range=" + range;
	        url += "&listSize=" + listSize;
	        url += "&searchType=" + searchType;
	        url += "&keyword=" + keyword;
	        location.href = url;
	        }
	 
	 
	    //페이지 번호 클릭
	    function fn_pagination(page, range, rangeSize, listSize, searchType, keyword) {
	 
	        var url = "/admin/mw_delete.do";
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
	        var url = "/admin/mw_delete.do";
	            url += "?page=" + page;
	            url += "&range=" + range;
	            url += "&listSize=" + listSize;
	            url += "&searchType=" + searchType;
	            url += "&keyword=" + keyword;
	            location.href = url;
	        }
	        
	    // 검색
	    $(document).on('click', '#btnSearch', function(e){
	        e.preventDefault();
	        var url = "/admin/mw_delete.do";
	        url += "?searchType=" + $('#searchType').val();
	        url += "&keyword=" + $('#keyword').val();
	        location.href = url;
	        console.log(url);
	    });
	    
	    function restoreMinwon(id) {
	    	if (confirm("삭제된 민원을 복구하시겠습니까?")) {
	    		var url = "/admin/mw_restore.do";
	    		url += "?id=" + id;
	    		location.href = url;
	    	}
	    }
    </script>
  </body>
</html>
