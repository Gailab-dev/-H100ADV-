<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>회원가입</title>
<!-- 페이지 제목 설정 -->
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<!-- 반응형 뷰포트 설정 (모바일 대응) -->
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/login.css">
<!-- CSS 불러오기 -->
</head>
<script src="https://code.jquery.com/jquery-3.7.1.js"
	integrity="sha256-eKhayi8LEQwp4NKxN+CfCh+3qOVUtJn3QNZ0TciWLP4="
	crossorigin="anonymous"></script>
<script>
	
	
	/**
	* 엔터키 감지하여 = 회원가입 버튼 클릭
	
	function enterKeyEvent(event){
		if(event.key == 'Enter'){
			
			register();
		}
	}
	
	/**
	* 키보드에 반응할 수 있도록 input태그에 eventListener 추가
	 
	$(document).ready(function(){
		const id = document.getElementById('id');
		const pwd = document.getElementById('pwd');
		const email = document.getElementById('email');
		const tnc = document.getElementById('tnc');
		const usePi = document.getElementById('usePi');
		
		id.addEventListener('keyup',enterKeyEvent);
		pwd.addEventListener('keyup',enterKeyEvent);
		email.addEventListener('keyup',enterKeyEvent);
		tnc.addEventListener('keyup',enterKeyEvent);
		usePi.addEventListener('keyup',enterKeyEvent);

	})
	*/
	
	// id 중복 체크
	async function checkIdDuplicated(id){
		const res = await fetch('${pageContext.request.contextPath}/user/checkId?id='+id, {
		    method: 'GET',
		  });
			
		  // http 오류 상태가 200이 아닌 경우
		  if (!res.ok) {
			return false;
		  }

		  const data = await res.json();   //{ ok: true }
		  return data.ok === true; // true/false로 정리
	}
	
	// validation 발생시 오류 출력
	function showAlert(msg){
		
		// validation 오류시 알림
		const p = document.getElementById("errorMessage");
		p.textContent = msg;
	}
	
	/*
	 * 로그인 정보를 받아서 로그인 가능한 사용자라면 로그인
	 * @param id,pw
	 * @return successMessage or errorMessage
	 */
	async function register() {

		// 회원가입 파라미터 가져오기
		const id = document.getElementById("id")?.value;
		const pwd = document.getElementById("pwd")?.value;
		const name = document.getElementById("name")?.value;
		const email = document.getElementById("email")?.value;
		//const parkingLot = document.getElementById("parkingLot");
		//const selectOpt = parkingLot.options[parkingLot.selectedIndex];
		const tnc = document.getElementById("tnc")?.checked;
		const usePi = document.getElementById("usePi")?.checked;
		
		/*
		try{
		*/
			// validation
			// id
			if(!id){
				showAlert("아이디를 입력해주세요");
				return;
			}
		  	if( id.length >= 100 ){
		  		showAlert("ID는 100자를 넘을 수 없습니다.");
		  		return;
		  	}
		  	const isDuplicated = await checkIdDuplicated(id);
		  	if( isDuplicated ){
		  		showAlert("이미 사용중인 ID입니다.");
		  		return;
		  	}
			if(!pwd){
				showAlert("비밀번호를 입력해주세요");
				return;
			}
		  	if( pwd.length >= 100 ){
		  		showAlert("비밀번호는 100자를 넘을 수 없습니다.");
		  		return;
		  	}
		    //비번 규칙: 6~20글자 / 영문+숫자+특수문자 각 1개 이상 / 공백 불가 
		    const PASSWORD_RULE = /^(?=.*[A-Za-z])(?=.*\d)(?=.*[^\w\s])\S{6,20}$/; 
			if(!PASSWORD_RULE.test(pwd)){
		  		showAlert("비밀번호는 6자 - 20자 사이여야 하고, 영문, 숫자, 특수문자 1개 이상을 포함하는 문자열이여야 합니다.");
		  		return;
			}
			if(!name){
				showAlert("이름을 입력해주세요");
				return;
			}
		  	if( name.length >= 40 ){
		  		showAlert("이름은 최대 한글 20자, 영문 40자 이내로 입력해주세요.");
		  		return;
		  	}

		  	
			if(!email){
				showAlert("이메일을 입력해주세요");
				return;
			}
		  	if( email.length >= 100 ){
		  		showAlert("이메일은 100자를 넘을 수 없습니다.");
		  		return;
		  	}
		  	/*
		  	const EMAIL_RULE = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
		  	if( !EMAIL_RULE.test(phone) ){
		  		showAlert("이메일은 example@example.com 형식이어야 합니다.");
		  		return;
		  	}
		  	*/
			if (!tnc) {
			  showAlert("이용약관에 동의해 주세요.");
			  return;
			}

			if (!usePi) {
			  showAlert("개인정보 수집·이용에 동의해 주세요.");
			  return;
			}
		  	
			// body
			const body = {
				u_login_id : id
				, u_login_pwd : pwd
				, u_name : name
				, u_email : email
			}
			
		    // 이메일 인증을 위한 세션에 데이터 저장
			const res = await fetch('${pageContext.request.contextPath}/user/request',{
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
				window.location.href = "${pageContext.request.contextPath}/user/emailAuth.do";
			}else {
				alert(result.msg);
			}
		/*
		}catch (err){
			showAlert("회원가입 오류: " + err);
			return ;
	        
		}
		*/
	}
	
	// region 의 모든 option은 항상 block
	/*  function updateRegionOptions() {
	    const regionSel = document.getElementById('region');
	    Array.from(regionSel.options).forEach(function (opt) {
	      opt.style.display = 'block';
	    });
	  }*/
	  
	  /* 에러 메시지 표시 함수*/
		function showError(message) {
			const errorElement = document.getElementById('errorMessage');
			errorElement.textContent = message;
			errorElement.style.opacity = '1';
		}
		/*** 에러 메시지 숨기기 함수*/
		function clearError() {
			const errorElement = document.getElementById('errorMessage');
			errorElement.textContent = '';
			errorElement.style.opacity = '0';
		}
		
		/* 비밀번호 보기/숨기기 토글*/
		function togglePassword(inputId, iconId) {
		  const input = document.getElementById(inputId);
		  const icon = document.getElementById(iconId);
		  
		  if (input.type === 'password') {
		    input.type = 'text';
		    icon.src = '${pageContext.request.contextPath}/resources/images/login/eye-open.svg';
		  } else {
		    input.type = 'password';
		    icon.src = '${pageContext.request.contextPath}/resources/images/login/eye-closed.svg';
		  }
		}
	  
	  /*전체 동의 -> 하위 약관 동의 */
		function toggleAllAgree(){
			const allAgree = document.getElementById('allAgree');
			const tnc = document.getElementById('tnc');
			const usePi = document.getElementById('usePi');
			
			tnc.checked = allAgree.checked;
			usePi.checked = allAgree.checked;
		}
		
		function updateAllAgree(){
			const allAgree = document.getElementById('allAgree');
			const tnc = document.getElementById('tnc');
			const usePi = document.getElementById('usePi');
		 
			allAgree.checked = tnc.checked && usePi.checked;
		}

		
		// 공통: 특정 select를 default option으로 되돌리는 함수
		function resetSelectToDefault(selectId) {
		  const sel = document.getElementById(selectId);
		  if (!sel) return;
		
		  // id에 'default'가 들어간 option을 찾아서 선택
		  const defOpt = sel.querySelector("option[id*='default']");
		  if (defOpt) {
		    defOpt.selected = true;
		  } else {
		    // 혹시 default가 없으면 첫 번째 option으로
		    sel.selectedIndex = 0;
		  }
		}
		
		// 이메일 입력 감지하여 인증 버튼 활성화/비활성화
		$(document).ready(function(){
		    const emailInput = document.getElementById('email');
		    const confirmBtn = document.querySelector('.email-wrapper .confirm');
		    
		    // 초기 상태: 비활성화
		    confirmBtn.disabled = true;
		    
		    // 이메일 입력 감지
		    emailInput.addEventListener('input', function(){
		        if(emailInput.value.trim().length > 0){
		            // 이메일이 입력되면 활성화
		            confirmBtn.disabled = false;
		            confirmBtn.style.backgroundColor = '#6955A2';
		            confirmBtn.style.cursor = 'pointer';
		        } else {
		            // 이메일이 비어있으면 비활성화
		            confirmBtn.disabled = true;
		            confirmBtn.style.backgroundColor = '#ADADAD';
		            confirmBtn.style.cursor = 'not-allowed';
		        }
		    });
		});
	 
</script>
<body>
	<!-- 상단 헤더 공간 (투명, 고정 높이) -->
	<header class="login-header"></header>

	<main class="login-wrap">
		<!-- 좌측: 제품 사진 -->
		<section class="bg-panel">
			<img
				src="${pageContext.request.contextPath}/resources/images/product.png"
				alt="제품 이미지" class="bg-img">
		</section>

		<section class="form-panel">
			<div class="login-card">
				<div class="mainTitle" role="heading" aria-level="1">
					<span class="title-text">회원가입</span>
				</div>
				<form onsubmit="event.preventDefault(); register();"
					class="register-form">
					<div class="fields">
						<div class="input-group">
							<input id="id" class="line-input" type="text"
								placeholder="아이디를 입력하세요" autocomplete="username">
							<!-- 비밀번호 -->
							<div class="password-wrapper">
								<input id="pwd" class="line-input" type="password"
									placeholder="비밀번호 영문,숫자,특수문자 6-20자를 입력하세요"
									autocomplete="new-password">
								<button type="button" class="toggle-password"
									onclick="togglePassword('pwd', 'eyeIcon1')">
									<img id="eyeIcon1"
										src="${pageContext.request.contextPath}/resources/images/login/eye-closed.svg"
										alt="비밀번호 표시">
								</button>
							</div>

							<!-- 비밀번호 확인 -->
							<div class="password-wrapper">
								<input id="pwdConfirm" class="line-input" type="password"
									placeholder="비밀번호를 확인하세요" autocomplete="new-password">
								<button type="button" class="toggle-password"
									onclick="togglePassword('pwdConfirm', 'eyeIcon2')">
									<img id="eyeIcon2"
										src="${pageContext.request.contextPath}/resources/images/login/eye-closed.svg"
										alt="비밀번호 표시">
								</button>
							</div>
							<input id="name" class="line-input" type="text"
								placeholder="이름을 입력하세요" autocomplete="name">
							<div class="email-wrapper">
								<input id="email" class="line-input" type="email"
									placeholder="이메일을 입력하세요" autocomplete="email">
								<button type="button" class="confirm">인증</button>
							</div>
						</div>


						<div class="assent-group">
							<label class="assent"> <input id="allAgree"
								class="assent-line-input" type="checkbox" value=""
								onchange=toggleAllAgree()>전체동의
							</label> <label class="assent"> <input id="tnc"
								class="assent-line-input" type="checkbox" value=""
								onchange=updateAllAgree()>(필수) 이용약관 동의 <a href="#">전문보기</a>
							</label> <label class="assent"> <input id="usePi"
								class="assent-line-input" type="checkbox" value=""
								onchange=updateAllAgree()>(필수) 개인정보 수집 및 이용 동의 <a
								href="#">전문보기</a>
							</label>
						</div>
						<div class="submitgroup">
							<p id="errorMessage" class="error-message"></p>
							<button class="primary-btn" type="submit">회원가입</button>
						</div>
					</div>
				</form>
			</div>
		</section>
	</main>

	<footer class="login-footer"></footer>
</body>
</html>