<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
   <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %> 
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/emailAuth.css"> <!-- CSS 불러오기 -->

<title>이메일 인증</title>
<%-- 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
<c:if test="${not empty errorMsg}">
<script>
	alert('<c:out value="${errorMsg}" />');
</script>
</c:if>
<%-- 에러 발생하여 해당 페이지로 돌아왔을 때 에러 메시지 출력 --%>
<script
  src="https://code.jquery.com/jquery-3.7.1.js"
  integrity="sha256-eKhayi8LEQwp4NKxN+CfCh+3qOVUtJn3QNZ0TciWLP4="
  crossorigin="anonymous"></script>
<script>
	// ------ 인증번호 재발송 [s] ------ //
	function resetAuthNumber(){
		const body = {
			email = '${email}'
		}
		const r = await fetch('${pageContext.request.contextPath}/user/resetAuthNumber',{
			method: 'POST',
	  		headers: {
	    		'Content-Type': 'application/json'
	    		, 'Accept': 'application/json'
	  		},
	        credentials: 'same-origin'
	        , cache: 'no-store'
	  		, body: JSON.stringify(body)
		});
	
   		// response 객체의 ok값(200~299)
      	if (!r.ok) {
  			alert(r.ok +"error");
          	return;
      	}
        const result = await r.json();
        if(result.ok){
        	alert("재발송 되었습니다.");
        }else{
        	alert(result.msg);
        	return;
        }
	}
	
	// ------ 인증번호 재발송 [e] ------ //
	// ------ 인증번호 승인 [S] ------ //
	async function submitAuthNumber(){
		const form = document.getElementById('emailAuthForm');
		const authNumber = form.querySelector('input[name="authNumber"')?.value;
		if(auhNumber === null || authNumber === undefined ||authNumber === '' ){
			alert("인증번호를 입력하세요.");
			return;
		}
		const regexAuthCode = /^[0-9]{6}$/;
		if(!regexAuthCode.test(authNumber)){
			alert("인증코드는 숫자 0부터 9까지 이루어진 6자리 문자입니다.");
			return;
		}
		const body = {
			authNumber = authNumber
		}
		const r = await fetch('${pageContext.request.contextPath}/user/submitAuthNumber',{
			method: 'POST',
	  		headers: {
	    		'Content-Type': 'application/json'
	    		, 'Accept': 'application/json'
	  		},
	        credentials: 'same-origin'
	        , cache: 'no-store'
	  		, body: JSON.stringify(body)
		});
	
   		// response 객체의 ok값(200~299)
      	if (!r.ok) {
  			alert(r.ok +"error");
          	return;
      	}
        const result = await r.json();
        if(result.ok){
    		// 회원가입
			register();        	
        }else{
        	// 오류 메시지 출력
        	alert(result.msg);
        	return;
        }
		
		
	}
	
	// ------ 인증번호 승인 [E] ------ //
	// ====== 회원 가입 [S] =======
	async function register() {

		const body = {
			u_login_id : '${body.id}''
			, u_login_pwd : '${body.pwd}' 
			, u_name : '${body.name}' 
			, u_phone : '${body.phone}' 
			, u_email : '${body.email}' 
			, u_region : '${body.region}' 
		}		
		
	    // 이메일 인증 페이지로 이동
		const res = await fetch('${pageContext.request.contextPath}/user/register',{
			method: 'POST',
	  		headers: {
	    		'Content-Type': 'application/json'
    			, 'Accept': 'application/json'
	  		},
	  		body: JSON.stringify(body)
		});
		
        if (!res.ok) {
            const text = await res.text(); // 에러 페이지로 나온 경우 내용 확인
            console.error('서버 오류 응답:', res.status, text);
            return; 
        }
	    
		const result = await res.json();
		
		if(result.ok){
			alert("회원가입 승인 완료.");
			window.location.href = "${pageContext.request.contextPath}/user/login.do";
		}else {
			alert(result.msg);
		}
		// ====== 회원 가입 [E] =======
	}
</script>
</head>
	<!-- 상단 헤더 공간 (투명, 고정 높이) -->
    <header class="login-header"></header>

	<main class="login-wrap">
	  <!-- 좌측: 제품 사진 -->
		<section class="bg-panel">
		    <img src="${pageContext.request.contextPath}/resources/images/product.png"
		         alt="제품 이미지"
		         class="bg-img">
		</section>
	
	    <!-- 우측: 이메일 인증 카드 -->
	    <section class="form-panel">
	      <div>
	        <p> 인증번호를 ${email} 로 발송하였습니다. }</p>
	        <form id = "emailAuthForm">
	        	<input type="text" name="authNumber">
	        	<button type="button" onclick="resetAuthNumber()"> 인증번호 재발송 </button>
	        	<button type="button" onclick="submitAuthNumber()"> 승인 </button>
	        </form>
	      </div>
	    </section>
	</main>
    <footer class="login-footer"></footer>
</body>
</html>