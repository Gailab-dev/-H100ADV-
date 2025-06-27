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
          <div class="container px-md-4">
            <div
              class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3"
            >
              <h1 class="h2">해외 IP 접근 차단</h1>
            </div>
            <div class="row justify-content-center">
              <div class="col-md-8">
                <div class="alert alert-secondary" role="alert">
                  해외 IP 차단 중입니다. / 해외 정상 접근 가능합니다.
                </div>
                <div
                  class="btn-group btn-group-toggle w-100"
                  data-toggle="buttons"
                >
                  <label class="btn btn-lg btn-secondary btn-block active">
                    <input type="radio" name="options" id="option1" checked />
                    차단 안함
                  </label>
                  <label class="btn btn-lg btn-secondary btn-block">
                    <input type="radio" name="options" id="option2" /> 차단
                  </label>
                </div>
              </div>
            </div>
          </div>
          <%@ include file="../include/footer.jsp" %>
        </main>
	  </div>
	</div>
  </body>
</html>
