<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>회원가입</title> <!-- 페이지 제목 설정 -->
<meta name="viewport" content="width=device-width, initial-scale=1.0"> <!-- 반응형 뷰포트 설정 (모바일 대응) -->
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/login.css"> <!-- CSS 불러오기 -->
</head>
<script
  src="https://code.jquery.com/jquery-3.7.1.js"
  integrity="sha256-eKhayi8LEQwp4NKxN+CfCh+3qOVUtJn3QNZ0TciWLP4="
  crossorigin="anonymous"></script>
<script>
	
	/**
	* 엔터키 감지하여 = 회원가입 버튼 클릭
	*/
	function enterKeyEvent(event){
		if(event.key == 'Enter'){
			const id = document.getElementById('id').value;
			const pwd = document.getElementById('pwd').value;
			const phone = document.getElementById('phone').value;
			const region = document.getElementById('region').value;
			
			register(id, pwd);
		}
	}
	
	/**
	* 키보드에 반응할 수 있도록 input태그에 eventListener 추가
	*/
	$(document).ready(function(){
		const id = document.getElementById('id');
		const pwd = document.getElementById('pwd');
		const phone = document.getElementById('phone');
		const region = document.getElementById('region');
		const tnc = document.getElementById('tnc');
		const usePi = document.getElementById('usePi');
		
		id.addEventListener('keyup',enterKeyEvent);
		pwd.addEventListener('keyup',enterKeyEvent);
		phone.addEventListener('keyup',enterKeyEvent);
		region.addEventListener('keyup',enterKeyEvent);
		tnc.addEventListener('keyup',enterKeyEvent);
		usePi.addEventListener('keyup',enterKeyEvent);

	})
	
	/*
	 * 로그인 정보를 받아서 로그인 가능한 사용자라면 로그인
	 * @param id,pw
	 * @return successMessage or errorMessage
	 */
	async function login(id, pwd) {

		try{
			// validation
			if(id == null || id == "" || id == "undefinded"){
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
			const response = await fetch('/gov-disabled-web-gs/stats/login',{
				method: 'POST',
		  		headers: {
		    		'Content-Type': 'application/json'
		  		},
		  		body: JSON.stringify({id,pwd
	  			})
			});
			
	        if (!response.ok) {
	            alert("서버 응답 오류 " + response.status);
	        }
		    
			const result = await response.json();
			
			if(result.success){
				window.location.href = "/gov-disabled-web-gs/stats/viewStat.do";
			}else {
				alert("ID 또는 비밀번호가 다릅니다.");
			}
		}catch (err){
			alert("로그인 오류: " + err);
	        
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
	          <input id="phone" class="line-input" type="text" placeholder="전화번호를 입력하세요" autocomplete="current-password">
	          <input id="region" class="line-input" type="text" placeholder="지역를 입력하세요" autocomplete="current-password">
	          <input id="tnc" class="line-input" type="text" placeholder="본인인증를 입력하세요" autocomplete="current-password">
	          <input id="usePi" class="line-input" type="text" placeholder="개인정보 동의를 입력하세요" autocomplete="current-password">
	
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