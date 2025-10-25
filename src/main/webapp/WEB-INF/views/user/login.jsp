<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>관리자로그인</title> <!-- 페이지 제목 설정 -->
<meta name="viewport" content="width=device-width, initial-scale=1.0"> <!-- 반응형 뷰포트 설정 (모바일 대응) -->
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/login.css"> <!-- CSS 불러오기 -->
</head>
<script
  src="https://code.jquery.com/jquery-3.7.1.js"
  integrity="sha256-eKhayi8LEQwp4NKxN+CfCh+3qOVUtJn3QNZ0TciWLP4="
  crossorigin="anonymous"></script>
<script>
	
	/**
	* 엔터키 감지하여 로그인 버튼 클릭
	*/
	function enterKeyEvent(event){
		if(event.key == 'Enter'){
			const id = document.getElementById('id').value;
			const pwd = document.getElementById('pwd').value;
			login(id, pwd);
		}
	}
	
	/**
	* 키보드에 반응할 수 있도록 input태그에 eventListener 추가
	*/
	$(document).ready(function(){
		const id = document.getElementById('id');
		const pwd = document.getElementById('pwd');
		
		id.addEventListener('keyup',enterKeyEvent);
		pwd.addEventListener('keyup',enterKeyEvent);

	})
	
	/*
	 * 로그인 정보를 받아서 로그인 가능한 사용자라면 로그인
	 * @param id,pw
	 * @return successMessage or errorMessage
	 */
	async function login(id, pwd) {

		try{
			// validation
			if(id == null || id == "" || id == "undefined"){
				alert("아이디를 입력해주세요");
				return;
			}
			if(pwd == null || pwd == "" || pwd == "undefinded"){
				alert("비밀번호를 입력해주세요");
				return;
			}
		  	if( id.length >= 100 ){
		  		alert("ID는 100자를 넘을 수 없습니다.");
		  		return;
		  	}
		  	if( pwd.length >= 100 ){
		  		alert("비밀번호는 100자를 넘을 수 없습니다.");
		  		return;
		  	}
			
		    // 동기 통신으로 로그인
			const r = await fetch('/gov-disabled-web-gs/user/login',{
				method: 'POST',
		  		headers: {
		    		'Content-Type': 'application/json'
		    		, 'Accept': 'application/json'
		  		},
		        credentials: 'same-origin'
		        , cache: 'no-store'
		  		, body: JSON.stringify({id,pwd})
			});
		    
		    console.log(r);
			
		    // response 객체의 ok값(200~299)
	        if (!r.ok) {
	    		alert(r.ok +"error");
	            return;
	        }
			
	        // fetch는 반드시 json으로 parsing해야만 resultmap의 값을 사용할 수 있음
	        const result = await r.json();
	        
	        if(result.ok){
				if(result.pwdChanged){
					window.location.href = "/gov-disabled-web-gs/stats/viewStat.do";
				}else{
					window.location.href = "/gov-disabled-web-gs/user/viewPwdChanged.do?uId="+result.uId;
				}
	        }else{
	        	alert(result.msg);
	        	return;
	        }

		}catch (e){
			alert("로그인 오류: " + e);
	        
		}
	}
</script>
<body>
	<!-- 상단 헤더 공간 (투명, 고정 높이) -->
    <header class="login-header"></header>

	<main class="login-wrap">
	  <!-- 좌측: 제품 사진 -->
		<section class="bg-panel">
		    <img src="${pageContext.request.contextPath}/resources/images/product.png"
		         alt="제품 이미지"
		         class="bg-img">
		</section>
	
	    <!-- 우측: 로그인 카드 -->
	    <section class="form-panel">
	      <div class="login-card">
	        <p class="product-ver">G.Eye-Parking H100 V1.0</p>
	
	        <div class="title-row" role="heading" aria-level="1">
				<img src="${pageContext.request.contextPath}/resources/images/simbol.png"
				     alt="아이콘" class="title-icon">
	          <span class="title-text">관리자 로그인</span>
	        </div>
	
	        <div class="fields">
	          <input id="id"  class="line-input" type="text"     placeholder="아이디를 입력하세요" autocomplete="username">
	          <input id="pwd" class="line-input" type="password" placeholder="비밀번호를 입력하세요" autocomplete="current-password">
	
	          <button class="primary-btn"
	                  onclick="login(document.getElementById('id').value, document.getElementById('pwd').value)">
	            로그인
	          </button>
	        </div>
	      </div>
	    </section>
	</main>

    <footer class="login-footer"></footer>
</body>
</html>