<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<%-- [Tiles fragment] 공용 chrome(헤더/사이드바/푸터)은 defaultLayout 제공. 이하 이 페이지 전용 CSS/JS/콘텐츠 --%>
<meta charset="UTF-8">
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/myinfo.css">
<title>내 정보</title>

<script>
	
	// 변경 전 이메일
	let originalEmail = '';

	/* 에러 메시지 표시 함수*/
	function showError(message) {
		const errorElement = document.getElementById('errorMessage');
		errorElement.textContent = message;
		errorElement.style.opacity = '1';
	}
	/* 에러 메시지 숨기기 함수*/
	function clearError() {
		const errorElement = document.getElementById('errorMessage');
		errorElement.textContent = '';
		errorElement.style.opacity = '0';
	}

	//비밀번호 표시/숨기기 토글 함수
	function togglePassword(inputId, iconId) {
		const input = document.getElementById(inputId);
		const icon = document.getElementById(iconId);

		if (input.type === 'password') {
			input.type = 'text';
			icon.src = '${pageContext.request.contextPath}/resources/images/login/eye-open.svg';
		} else {
			input.type = 'password';
			icon.src ='${pageContext.request.contextPath}/resources/images/login/eye-closed.svg';
		}
	}
	
	async function myInfoSave(){
		// 이메일이 변경되었는지 확인
	    const currentEmail = document.getElementById('email')?.value;
		
		console.log("currentEmail : " + currentEmail);
		console.log("originalEmail : " + originalEmail);
		
	    if (currentEmail !== originalEmail) {
	        // 이메일이 변경되었으면 인증 확인
	        if (!(await isVerifiedNow(currentEmail))) {
	            showError("변경된 이메일에 대한 인증이 필요합니다.");
	            return;
	        }
	    }
		// 유효성 체크
		const currentPw = document.getElementById("currentPw")?.value;
		const newPw = document.getElementById("newPw")?.value;
		const confirmPw = document.getElementById("confirmPw")?.value;
		const name = document.getElementById("name")?.value;
		const email = document.getElementById("email")?.value;
		
		const checkedPwd = await checkCurrentPwd(currentPw);
		if(!checkedPwd){
            showError("기존 비밀번호가 틀립니다.");
            return
		}
		
		if (myInfoValChk(currentPw,newPw,confirmPw,name,email)){

			// 동기 통신으로 개인정보 수정
			const r = await fetch('${pageContext.request.contextPath}/myInfo/saveMyInfo.do',{
				method: 'POST',
		  		headers: {
		    		'Content-Type': 'application/json'
		    		, 'Accept': 'application/json'
		  		},
		        credentials: 'same-origin'
		        , cache: 'no-store'
		        	, body: JSON.stringify({currentPw, newPw, confirmPw, name, email})
			}); 
			
		    // response 객체의 ok값(200~299)
	        if (!r.ok) {
	        	alert("r.ok : " + r.ok);
	         	showError("내 정보 수정 중 오류가 발생했습니다.");
	            return;
	        }else{
	        	clearError();
	        	
	        	const data = await r.json();
	        	if(data.ok === "false"){
	        		showError(data.msg);
	        		return;
	        	}
	        	
	        	window.location.href = "${pageContext.request.contextPath}/stats/viewStat.do";
	        }
		    
		}	
	}
	
	function myInfoValChk(currentPw,newPw,confirmPw,name,email){
		let result = false;
		
		if(!currentPw){
			showError("기존 비밀번호를 입력해주세요.");
	  		return result;
		}
		
	  	if( currentPw.length >= 100 ){
	  		showError("기존 비밀번호는 100자를 넘을 수 없습니다.");
	  		return;
	  	}
	  	
	    //비번 규칙: 6~20글자 / 영문+숫자+특수문자 각 1개 이상 / 공백 불가 
	    const PASSWORD_RULE = /^(?=.*[A-Za-z])(?=.*\d)(?=.*[^\w\s])\S{6,20}$/; 
		if(!PASSWORD_RULE.test(currentPw)){
			showError("비밀번호는 6자 - 20자 사이여야 하고, 영문, 숫자, 특수문자 1개 이상을 포함하는 문자열이여야 합니다.");
	  		return;
		}
		
		if(!newPw){
			showError("새 비밀번호를 입력해주세요.");
			return result;
		}
		
	  	if( newPw.length >= 100 ){
	  		showError("새 비밀번호는 100자를 넘을 수 없습니다.");
	  		return;
	  	}
	  	
		if(!PASSWORD_RULE.test(newPw)){
			showError("비밀번호는 6자 - 20자 사이여야 하고, 영문, 숫자, 특수문자 1개 이상을 포함하는 문자열이여야 합니다.");
	  		return;
		}
		
		if(!confirmPw){
			showError("비밀번호 확인을 입력해주세요.");
			return result;
		}
		
	  	if( confirmPw.length >= 100 ){
	  		showError("새 비밀번호 확인은 100자를 넘을 수 없습니다.");
	  		return;
	  	}
		
		if(newPw != confirmPw){
			showError("새 비밀번호와 비밀번호 확인 값이 서로 다릅니다.");
			return result;
		}
	  	
		if(newPw == currentPw){
			showError("새 비밀번호와 기존 비밀번호는 달라야 합니다.");
			return result;
		}
		
		if(!name){
			showError("이름을 입력해주세요.");
			return result;
		}
		
	  	if( name.length >= 40 ){
	  		showError("이름은 최대 한글 20자, 영문 40자 이내로 입력해주세요.");
	  		return;
	  	}
		
		result = true;
		return result;
	}
	
	// 이메일을 입력 받았을 때 인증번호 인증
	async function request(){
		
		const email = document.getElementById('email')?.value;
		if(email == null || email.trim() === ""){
			showError("이메일을 입력해주세요.");
			return;
		}
		
		const r = await fetch("${pageContext.request.contextPath}/user/request",{
			method: "POST",
			mode: "same-origin",
			cache:"no-cache",
			headers:{
				"Content-Type":"application/json",
			},
			body: JSON.stringify({"u_email":email}),
		})
		
		if(!r.ok){
	      const text = await r.text().catch(() => "");
	      console.error("인증메일 요청 실패:", r.status, text);
	      showError("인증메일 발송에 실패했습니다.");
	      return;
		}
		
		const data = await r.json();
		
		alert(data.msg);
		alert("인증메일을 발송했습니다.");
		
	}
	
	// 이메일 인증했는지 확인
	async function isVerifiedNow(email){
	  try {
	    const res = await fetch("${pageContext.request.contextPath}/user/isRegisterEmailVerified", {
	      method: "POST",
	      headers: { "Content-Type": "application/json", "Accept": "application/json" },
	      credentials: "same-origin",
	      body: JSON.stringify({ email })
	    });
	
	    const contentType = res.headers.get("content-type") || "";
	    const raw = await res.text();
	
	    console.log("[isVerifiedNow] status=", res.status);
	    console.log("[isVerifiedNow] redirected=", res.redirected, "url=", res.url);
	    console.log("[isVerifiedNow] contentType=", contentType);
	    console.log("[isVerifiedNow] raw=", raw);
	
	    if (!res.ok) return false;
	
	    // 서버가 JSON이 아닌 페이지를 반환하면 무조건 false
	    if (!contentType.includes("application/json")) return false;
	
	    const json = JSON.parse(raw);
	    
	    console.log(json.verified);
	    
	    return json.verified === true;
	
	  } catch (e) {
	    console.error("[isVerifiedNow] error", e);
	    return false;
	  }
	}
	
	// 원본 이메일 저장 (페이지 로드 시)
	document.addEventListener('DOMContentLoaded', function() {
	    originalEmail = document.getElementById('email')?.value || '';
	});

	// 이메일 변경 감지
	function checkEmailChange() {
	    const currentEmail = document.getElementById('email')?.value;
	    const authBtn = document.getElementById('emailAuthBtn');
	    
	    if (currentEmail && currentEmail !== originalEmail && currentEmail.trim() !== '') {
	        authBtn.disabled = false;
	        authBtn.classList.add('active');
	    } else {
	        authBtn.disabled = true;
	        authBtn.classList.remove('active');
	    }
	}
	
	// 입력한 비밀번호가 기존 비밀번호가 맞는지 확인
	async function checkCurrentPwd(currentPw){
		
		try {
		    const res = await fetch("${pageContext.request.contextPath}/myInfo/checkCurrentPwd", {
		      method: "POST",
		      headers: { "Content-Type": "application/json", "Accept": "application/json" },
		      credentials: "same-origin",
		      body: JSON.stringify({ currentPw })
		    });
		
		    const contentType = res.headers.get("content-type") || "";
		    const raw = await res.text();
		
		    console.log("[checkCurrentPwd] status=", res.status);
		    console.log("[checkCurrentPwd] redirected=", res.redirected, "url=", res.url);
		    console.log("[checkCurrentPwd] contentType=", contentType);
		    console.log("[checkCurrentPwd] raw=", raw);
		
		    if (!res.ok) return false;
		
		    // 서버가 JSON이 아닌 페이지를 반환하면 무조건 false
		    if (!contentType.includes("application/json")) return false;
		
		    const json = JSON.parse(raw);
		    
		    if(json.ok){
		    	showError(json.msg);
		    	
		    }
		    
		    return json.ok;
		
		  } catch (e) {
		    console.error("[isVerifiedNow] error", e);
		    return false;
		  }
		
	}

</script>

	<div class=page-wrapper>
		<!-- 헤더 -->
		
		
			
			
				<div class="topTitle">
					<p class="mypageTitle">내 정보</p>
				</div>

				<form class="editForm">
					<div class="form-group">
						<label for="userId">아이디</label> <input type="text" id="userId"
							name="userId" value="${myInfoMap.u_login_id }" readonly>
					</div>

					<div class="form-group">
						<label for="currentPw">기존 비밀번호</label>
						<div class="inputBox">
							<div class="password-wrapper">
								<input type="password" id="currentPw" name="currentPw">
								<button type="button" class="toggle-password"
									onclick="togglePassword('currentPw', 'eyeIcon1')">
									<img id="eyeIcon1"
										src="${pageContext.request.contextPath}/resources/images/login/eye-closed.svg"
										alt="비밀번호 표시">
								</button>
							</div>
							<p class="hint-text">영문, 숫자, 특수문자 6-20자</p>
						</div>
					</div>

					<div class="form-group">
						<label for="newPw">새 비밀번호</label>
						<div class="inputBox">
							<div class="password-wrapper">
								<input type="password" id="newPw" name="newPw">
								<button type="button" class="toggle-password"
									onclick="togglePassword('newPw', 'eyeIcon2')">
									<img id="eyeIcon2"
										src="${pageContext.request.contextPath}/resources/images/login/eye-closed.svg"
										alt="비밀번호 표시">
								</button>
							</div>
							<p class="hint-text">영문, 숫자, 특수문자 6-20자</p>
						</div>
					</div>

					<div class="form-group">
						<label for="confirmPw">비밀번호 확인</label>
						<div class="inputBox">
							<div class="password-wrapper">
								<input type="password" id="confirmPw" name="confirmPw">
								<button type="button" class="toggle-password"
									onclick="togglePassword('confirmPw', 'eyeIcon3')">
									<img id="eyeIcon3"
										src="${pageContext.request.contextPath}/resources/images/login/eye-closed.svg"
										alt="비밀번호 표시">
								</button>
							</div>
						</div>
					</div>

					<div class="form-group">
						<label for="confirmPw">이름</label> <input type="text" id="name"
							name="name" value="${myInfoMap.u_name }" class="user_name">
					</div>

					<div class="form-group">
						<label for="email">이메일</label>
						<div class="emailBox">
							<input type="email" id="email" name="email" 
								value="${myInfoMap.u_email }"
								oninput="checkEmailChange()">
								<button type="button" class="editEmail"  id="emailAuthBtn" onclick="request()" disabled>인증</button>
						</div>
					</div>
				</form>
				<div class="saveBox">
					<p id="errorMessage" class="error-message"></p>
					<button type="submit" class="saveButton" onclick="myInfoSave()">저장</button>
				</div>
			</div>
		

