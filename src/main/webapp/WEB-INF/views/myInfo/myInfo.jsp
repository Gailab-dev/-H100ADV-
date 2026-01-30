<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/myinfo.css">
<title>내 정보</title>
</head>
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
<body>
	<div class=page-wrapper>
		<!-- 헤더 -->
		<header class="header">
			<div class="logo">
				<img
					src="${pageContext.request.contextPath}/resources/images/지아이랩-로고.png"
					alt="GAILAB" class="header-icon">
			</div>

			<div class="right-group">
				<c:if test="${useTblLog == false}">
					<div class="alert alert-warning">현재 로그 데이터 저장 공간이 매우 부족합니다.
						관리자에게 문의해주세요.</div>
				</c:if>
				<div class="user">
				 	<span class="user-name">
				 		<c:out value="${uName}" escapeXml="true" />
					</span> 
				</div>
				<div class="logout">
					<button
						onclick="location.href='${pageContext.request.contextPath}/user/logout'">로그아웃</button>
				</div>
			</div>
		</header>
		<div class="container">
			<aside class="sidebar">
				<ul class="menu">
					<li><a
						href="${pageContext.request.contextPath}/eventList/viewEventList.do">
							<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20"
								fill="none" xmlns="http://www.w3.org/2000/svg">
						<path fill-rule="evenodd" clip-rule="evenodd"
									d="M2.70837 5.83203C2.70837 5.66627 2.77422 5.5073 2.89143 5.39009C3.00864 5.27288 3.16761 5.20703 3.33337 5.20703H16.6667C16.8325 5.20703 16.9914 5.27288 17.1086 5.39009C17.2259 5.5073 17.2917 5.66627 17.2917 5.83203C17.2917 5.99779 17.2259 6.15676 17.1086 6.27397C16.9914 6.39118 16.8325 6.45703 16.6667 6.45703H3.33337C3.16761 6.45703 3.00864 6.39118 2.89143 6.27397C2.77422 6.15676 2.70837 5.99779 2.70837 5.83203ZM2.70837 9.9987C2.70837 9.83294 2.77422 9.67397 2.89143 9.55676C3.00864 9.43955 3.16761 9.3737 3.33337 9.3737H12.5C12.6658 9.3737 12.8248 9.43955 12.942 9.55676C13.0592 9.67397 13.125 9.83294 13.125 9.9987C13.125 10.1645 13.0592 10.3234 12.942 10.4406C12.8248 10.5578 12.6658 10.6237 12.5 10.6237H3.33337C3.16761 10.6237 3.00864 10.5578 2.89143 10.4406C2.77422 10.3234 2.70837 10.1645 2.70837 9.9987ZM2.70837 14.1654C2.70837 13.9996 2.77422 13.8406 2.89143 13.7234C3.00864 13.6062 3.16761 13.5404 3.33337 13.5404H7.50004C7.6658 13.5404 7.82477 13.6062 7.94198 13.7234C8.05919 13.8406 8.12504 13.9996 8.12504 14.1654C8.12504 14.3311 8.05919 14.4901 7.94198 14.6073C7.82477 14.7245 7.6658 14.7904 7.50004 14.7904H3.33337C3.16761 14.7904 3.00864 14.7245 2.89143 14.6073C2.77422 14.4901 2.70837 14.3311 2.70837 14.1654Z"
									fill="currentColor" />
						</svg>불법주차 리스트
					</a></li>
					<li><a
						href="${pageContext.request.contextPath}/stats/viewStat.do"> <svg
								class="menu-icon" width="20" height="20" viewBox="0 0 20 20"
								fill="none" xmlns="http://www.w3.org/2000/svg">
							<g clip-path="url(#clip0_300_3167)">
								<path d="M18.3333 18.3359H1.66663" stroke="currentColor"
									stroke-width="1.4" stroke-linecap="round" />
								<path
									d="M17.5 18.3346V12.0846C17.5 11.7531 17.3683 11.4352 17.1339 11.2008C16.8995 10.9663 16.5815 10.8346 16.25 10.8346H13.75C13.4185 10.8346 13.1005 10.9663 12.8661 11.2008C12.6317 11.4352 12.5 11.7531 12.5 12.0846V18.3346V4.16797C12.5 2.98964 12.5 2.40047 12.1333 2.03464C11.7683 1.66797 11.1792 1.66797 10 1.66797C8.82083 1.66797 8.2325 1.66797 7.86667 2.03464C7.5 2.39964 7.5 2.9888 7.5 4.16797V18.3346V7.91797C7.5 7.58645 7.3683 7.26851 7.13388 7.03408C6.89946 6.79966 6.58152 6.66797 6.25 6.66797H3.75C3.41848 6.66797 3.10054 6.79966 2.86612 7.03408C2.6317 7.26851 2.5 7.58645 2.5 7.91797V18.3346"
									stroke="currentColor" stroke-width="1.4" />
							</g>
							<defs>
							<clipPath id="clip0_300_3167">
							<rect width="20" height="20" fill="white" />	</clipPath></defs>
						</svg>통계
					</a></li>

					<li><a
						href="${pageContext.request.contextPath}/deviceList/viewDeviceList.do">
							<svg class="menu-icon" width="20" height="20" viewBox="0 0 20 20"
								fill="none" xmlns="http://www.w3.org/2000/svg">
							<path
									d="M7.50004 15H12.5M15 2.5C15.4421 2.5 15.866 2.67559 16.1786 2.98816C16.4911 3.30072 16.6667 3.72464 16.6667 4.16667V15.8333C16.6667 16.2754 16.4911 16.6993 16.1786 17.0118C15.866 17.3244 15.4421 17.5 15 17.5H5.00004C4.55801 17.5 4.13409 17.3244 3.82153 17.0118C3.50897 16.6993 3.33337 16.2754 3.33337 15.8333V4.16667C3.33337 3.72464 3.50897 3.30072 3.82153 2.98816C4.13409 2.67559 4.55801 2.5 5.00004 2.5H15Z"
									stroke="currentColor" stroke-width="1.4" stroke-linecap="round"
									stroke-linejoin="round" />
						</svg>디바이스 리스트
					</a></li>
					<li><a
						href="${pageContext.request.contextPath}/myInfo/viewMyInfo.do">
							<svg width="20" height="20" viewBox="0 0 12 12" fill="none"
								xmlns="http://www.w3.org/2000/svg">
								<circle cx="6" cy="6" r="5.5" stroke="currentColor" />
								<path
									d="M9.33335 9.75V8.91667C9.33335 8.47464 9.15776 8.05072 8.8452 7.73816C8.53264 7.4256 8.10871 7.25 7.66669 7.25H4.33335C3.89133 7.25 3.4674 7.4256 3.15484 7.73816C2.84228 8.05072 2.66669 8.47464 2.66669 8.91667V9.75M7.66669 3.91667C7.66669 4.83714 6.92049 5.58333 6.00002 5.58333C5.07955 5.58333 4.33335 4.83714 4.33335 3.91667C4.33335 2.99619 5.07955 2.25 6.00002 2.25C6.92049 2.25 7.66669 2.99619 7.66669 3.91667Z"
									stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" />
							</svg> 내 정보
					</a></li>


					<!-- 
                <li><a href="${pageContext.request.contextPath}/local/viewLocalManage.do"><img src="${pageContext.request.contextPath}/resources/images/icon_parking.png" alt="불법주차" class="menu-icon">지역 관리</a></li>
            	 -->
				</ul>
			</aside>
			<div class="content">
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
		</div>
</body>
</html>