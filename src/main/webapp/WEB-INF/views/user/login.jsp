<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>로그인</title>
<!-- 페이지 제목 설정 -->
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<!-- 반응형 뷰포트 설정 (모바일 대응) -->
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/login.css">
<!-- CSS 불러오기 -->
<%-- (34번 ROI 설정) 로그아웃·세션 만료·다른 PC 로그인으로 이 화면에 오면 브라우저에 남은 ROI 편집 임시본(localStorage)을 지운다 --%>
<script src="${pageContext.request.contextPath}/resources/js/roi/roiDraftCleanup.js"></script>
</head>
<%-- (37 WP-L1) 로그아웃 사유 안내(다른 PC 로그인/장기 미사용/세션 만료)는 서버가 고정 문구로 바꿔 model 의 loginNotice 로 준다.
     예전에는 여기서 showError() 를 호출했으나 함수 정의(아래 스크립트)·#errorMessage 보다 앞서 실행되어 항상 실패했다 —
     이제 #errorMessage 안에 서버가 직접 출력한다(c:out 이스케이프, 스크립트 순서와 무관). --%>
<script src="https://code.jquery.com/jquery-3.7.1.js"
	integrity="sha256-eKhayi8LEQwp4NKxN+CfCh+3qOVUtJn3QNZ0TciWLP4="
	crossorigin="anonymous"></script>
<script>
	
	/**
	* 에러 메시지 표시 함수
	*/
	function showError(message) {
		const errorElement = document.getElementById('errorMessage');
		errorElement.textContent = message;
		errorElement.style.opacity = '1';
	}

	/**
	* 에러 메시지 숨기기 함수
	*/
	function clearError() {
		const errorElement = document.getElementById('errorMessage');
		errorElement.textContent = '';
		errorElement.style.opacity = '0';
	}
	
	/**
	* 엔터키 감지하여 로그인 버튼 클릭
	
	function enterKeyEvent(event){
		if(event.key == 'Enter'){
			const id = document.getElementById('id').value;
			const pwd = document.getElementById('pwd').value;
			login(id, pwd);
		}
	}
	*/
	
	/**
	* 비밀번호 보기/숨기기 토글
	*/
	function togglePassword() {
		const pwdInput = document.getElementById('pwd');
		const eyeIcon = document.getElementById('eyeIcon');
		
		if (pwdInput.type === 'password') {
			// 비밀번호 보이기
			pwdInput.type = 'text';
			eyeIcon.src = '${pageContext.request.contextPath}/resources/images/login/eye-open.svg';
			eyeIcon.alt = '비밀번호 숨기기';
		} else {
			// 비밀번호 숨기기
			pwdInput.type = 'password';
			eyeIcon.src = '${pageContext.request.contextPath}/resources/images/login/eye-closed.svg';
			eyeIcon.alt = '비밀번호 표시';
		}
	}
	
	/** form으로 수정하면서 자동처리가 가능해짐
	 form으로 했을때 모바일 키보드(완료 가능), 비밀번호 관리자 연동,자동완성도 가능
	* 키보드에 반응할 수 있도록 input태그에 eventListener 추가
	
	$(document).ready(function(){
		const id = document.getElementById('id');
		const pwd = document.getElementById('pwd');
		
		id.addEventListener('keyup',enterKeyEvent);
		pwd.addEventListener('keyup',enterKeyEvent);

	})
	*/
	
	/*
	 * 로그인 정보를 받아서 로그인 가능한 사용자라면 로그인
	 * @param id,pw
	 * @return successMessage or errorMessage
	 */
	async function login(id, pwd) {

		try{
			// validation
			if(id == null || id == "" || id == "undefined"){
				showError("아이디와 비밀번호를 정확히 입력해주세요.");
				return;
			}
			if(pwd == null || pwd == "" || pwd == "undefinded"){
				showError("아이디와 비밀번호를 정확히 입력해주세요.");
				return;
			}
		  	if( id.length >= 100 ){
		  		showError("ID는 100자를 넘을 수 없습니다.");
		  		return;
		  	}
		  	if( pwd.length >= 100 ){
		  		showError("비밀번호는 100자를 넘을 수 없습니다.");
		  		return;
		  	}
			
		    // 동기 통신으로 로그인
			const r = await fetch('${pageContext.request.contextPath}/user/login',{
				method: 'POST',
		  		headers: {
		    		'Content-Type': 'application/json'
		    		, 'Accept': 'application/json'
		  		},
		        credentials: 'same-origin'
		        , cache: 'no-store'
		  		, body: JSON.stringify({id,pwd})
			});
			
		    // response 객체의 ok값(200~299)
	        if (!r.ok) {
	        	// (fetch 의 Response 객체에는 msg 가 없다 — 이전에는 "false | undefined" 로 표시되었음)
	        	showError("로그인 요청에 실패했습니다. (HTTP " + r.status + ")");
	            return;
	        }
			
	        // fetch는 반드시 json으로 parsing해야만 resultmap의 값을 사용할 수 있음
	        const result = await r.json();
	        
	        if(result.ok){
				afterLoginSuccess(result);
	        }else if(result.needConfirm && result.confirmToken){
	        	// (37 WP-L2) 비밀번호 검증은 통과했으나 다른 곳에서 접속 중 — 확인 팝업.
	        	// 비밀번호는 더 이상 쓰지 않으므로 입력칸을 비운다(확인 단계에는 1회용 토큰만 사용).
	        	document.getElementById('pwd').value = '';
	        	clearError();
	        	openLoginConfirm(result.confirmToken);
	        	return;
	        }else{
	        	showError(result.msg);
	        	return;
	        }
		}catch (e){
			showError("로그인 오류: " + e);
		}
	}

	/** 로그인 성공 후 이동(일반 로그인·확인 후 강제 로그인 공통) */
	function afterLoginSuccess(result){
		if(result.pwdChanged){
			// patches 2026-07-06: 로그인 성공 최초 화면을 통계 → 대시보드로 변경
			window.location.replace("${pageContext.request.contextPath}/dashboard");
		}else{
			if(result.pwdPassedDays >= 180){
				alert("마지막 비밀번호 변경일이 180일이 지났습니다. 비밀번호를 재설정해주세요.")
			}else{
				alert("최초 로그인시 비밀번호를 변경해야 합니다.")
			}
			window.location.replace("${pageContext.request.contextPath}/user/viewPwdChanged.do?uId="+result.uId);
		}
	}

	/* ===== (37 WP-L2) 새 로그인 확인 팝업 =====
	   비밀번호 검증이 성공한 뒤에만 서버가 needConfirm 을 돌려준다(인증 전에는 접속 여부가 노출되지 않는다).
	   이 화면은 비밀번호를 보관하지 않고, 서버가 준 1회용 토큰(60초, 이 브라우저 세션에 묶임)만 들고 있는다. */
	const CONFIRM_POLL_MS = 3000;
	let confirmToken = null;       // 확인 대기 중인 1회용 토큰
	let confirmPollId = null;      // 기존 접속이 먼저 사라졌는지 보는 폴링
	let confirmBusy = false;       // 더블클릭·중복 요청 방지

	function openLoginConfirm(token){
		confirmToken = token;
		confirmBusy = false;
		document.getElementById('loginConfirmYes').disabled = false;
		document.getElementById('loginConfirmNo').disabled = false;
		document.getElementById('loginConfirmModal').style.display = 'flex';
		document.getElementById('loginConfirmNo').focus();   // 기본 포커스는 취소(실수 방지)
		stopConfirmPoll();
		confirmPollId = setInterval(pollConfirmStatus, CONFIRM_POLL_MS);
	}

	function closeLoginConfirm(){
		stopConfirmPoll();
		confirmToken = null;
		document.getElementById('loginConfirmModal').style.display = 'none';
	}

	function stopConfirmPoll(){
		if(confirmPollId !== null){
			clearInterval(confirmPollId);
			confirmPollId = null;
		}
	}

	function postJson(path, body){
		return fetch('${pageContext.request.contextPath}' + path, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
			credentials: 'same-origin',
			cache: 'no-store',
			body: JSON.stringify(body)
		});
	}

	/** 확인 대기 중 기존 접속이 먼저 사라지면(로그아웃·만료) 확인 없이 바로 로그인한다. 토큰이 만료되면 팝업을 닫는다. */
	async function pollConfirmStatus(){
		if(confirmBusy || !confirmToken) return;
		try{
			const r = await postJson('/user/loginConfirmStatus', {token: confirmToken});
			if(!r.ok) return;
			const d = await r.json();
			if(confirmBusy || !confirmToken) return;
			if(d.state === 'FREE'){
				await forceLogin();
			}else if(d.state === 'INVALID'){
				closeLoginConfirm();
				showError("확인 시간이 지났습니다. 다시 로그인해 주세요.");
			}
		}catch(e){ /* 일시적 오류는 무시 — 다음 폴링에서 재시도 */ }
	}

	/** "로그인" 클릭 — 1회용 토큰으로 강제 로그인 요청(서버가 기존 세션을 종료하고 새 세션을 발급) */
	async function forceLogin(){
		if(confirmBusy || !confirmToken) return;
		confirmBusy = true;
		document.getElementById('loginConfirmYes').disabled = true;
		document.getElementById('loginConfirmNo').disabled = true;
		stopConfirmPoll();
		const token = confirmToken;
		try{
			const r = await postJson('/user/loginForce', {token: token});
			if(!r.ok){
				closeLoginConfirm();
				showError("로그인 요청에 실패했습니다. (HTTP " + r.status + ")");
				return;
			}
			const result = await r.json();
			closeLoginConfirm();
			if(result.ok){
				afterLoginSuccess(result);
			}else{
				showError(result.msg || "로그인 처리 중 오류 발생.");
			}
		}catch(e){
			closeLoginConfirm();
			showError("로그인 오류: " + e);
		}
	}

	/** "취소" — 토큰만 폐기하고 아무 변화 없이 로그인 화면으로 돌아간다(기존 접속은 그대로) */
	function cancelLoginConfirm(){
		if(confirmBusy) return;
		const token = confirmToken;
		closeLoginConfirm();
		if(token){
			postJson('/user/loginCancel', {token: token}).catch(function(){ /* 실패해도 토큰은 60초 후 만료 */ });
		}
		document.getElementById('pwd').focus();
	}

	document.addEventListener('keydown', function(e){
		if(e.key === 'Escape' && confirmToken) cancelLoginConfirm();
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

		<!-- 우측: 로그인 카드 -->
		<section class="form-panel">
			<div class="login-card">
				<p class="product-ver">G.Eye-Parking H100 V1.0</p>

				<div class="title-row" role="heading" aria-level="1">
					<img
						src="${pageContext.request.contextPath}/resources/images/simbol.png"
						alt="아이콘" class="title-icon"> <span class="title-text">관리자
						로그인</span>
				</div>

				<div class="fields">
					<form
						onsubmit="event.preventDefault(); login(document.getElementById('id').value, document.getElementById('pwd').value);"
						class="login-content">
						<div class="input-group">
							<input id="id" class="line-input" type="text"
								placeholder="아이디를 입력하세요" autocomplete="username">
							<div class="password-wrapper">
								<input id="pwd" class="line-input" type="password"
									placeholder="비밀번호를 입력하세요" autocomplete="current-password">
								<button type="button" class="toggle-password"
									onclick="togglePassword()">
									<img id="eyeIcon"
										src="${pageContext.request.contextPath}/resources/images/login/eye-closed.svg"
										alt="비밀번호 표시">
								</button>
							</div>
						</div>
						<div class="login-state-wrapper">
							<input type="checkbox" id="keepLogin" class="keep-login-checkbox">
							<label for="keepLogin" class="loginState">아이디 저장</label>
							<P class="findIdPw">
								<a href="${pageContext.request.contextPath}/user/findIdPwd.do">아이디/비밀번호찾기</a>
							</P>
						</div>
						<div class="submitgroup">
							<p id="errorMessage" class="error-message"><c:out value="${loginNotice}" /></p>

							<button class="primary-btn"
								type="submit">
								로그인</button>
						</div>

					</form>
					<div class="login-foot">
						<P class="joinus">
							아직 회원이 아니신가요? <a
								href="${pageContext.request.contextPath}/user/register.do">회원가입</a>
						</P>
					</div>
				</div>
			</div>
		</section>
	</main>

	<%-- (37 WP-L2) 새 로그인 확인 팝업 — 비밀번호 검증 성공 후 다른 곳에서 접속 중일 때만 표시 --%>
	<div id="loginConfirmModal" class="login-confirm-modal" style="display:none;" role="dialog" aria-modal="true" aria-labelledby="loginConfirmTitle">
		<div class="login-confirm-backdrop" onclick="cancelLoginConfirm()"></div>
		<div class="login-confirm-dialog">
			<p id="loginConfirmTitle" class="login-confirm-title">다른 곳에서 접속 중인 계정입니다.</p>
			<p class="login-confirm-desc">로그인하시겠습니까?<br>계속하면 기존 접속은 로그아웃됩니다.</p>
			<div class="login-confirm-btns">
				<button type="button" id="loginConfirmNo" class="login-confirm-btn secondary" onclick="cancelLoginConfirm()">취소</button>
				<button type="button" id="loginConfirmYes" class="login-confirm-btn primary" onclick="forceLogin()">로그인</button>
			</div>
		</div>
	</div>


</body>
</html>