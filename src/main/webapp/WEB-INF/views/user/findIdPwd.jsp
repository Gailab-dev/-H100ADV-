<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>아이디/비밀번호 찾기</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0"> <!-- 반응형 뷰포트 설정 (모바일 대응) -->
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/login.css"> <!-- CSS 불러오기 -->
</head>
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
		<section class="form-panel">
		<div class="login-card">
			<div id="mainTitle" class="mainTitle" role="heading" aria-level="1">
	          <span class="title-text">아이디/비밀번호 찾기</span>
	        </div>
			<div class="page-subtitle">
			  <div class="find-id active" onclick="showFindIdSubpage(this)">아이디 찾기</div>
			  <div class="find-pw" onclick="showFindPwdSubpage(this)">비밀번호 찾기</div>
			</div>
			<div id="subpage">

		
				</div>
			</div>
		
		 </section>
	</main>
</body>
<script>
	
	// 서브페이지 출력하는 div
	const subpageDiv = document.getElementById("subpage");
	
	// 오류 출력 함수
	function showAlert(msg){
		const p = document.getElementById("alert");
		if(!p) return;
		p.innerHTML = "";
		p.innerHTML = msg;
	}
	
	// 회원가입 api 모듈
	async function apiService(url,options = {},body){
		
		const fetchOptions = {
			method : options.method || 'GET',
				headers : options.headers || {
					'Content-Type':'application/x-www-form-urlencoded'
				},
				credentials : options.credentials || 'same-origin',
				cache: options.cache || 'no-store',	
			};
		
			// GET이 아니라면 body 추가
			if(fetchOptions.method !== 'GET' && body != null){
				fetchOptions.body = body;
			}
			
			const res = await fetch("${pageContext.request.contextPath}"+url,fetchOptions);
	
			if(!res.ok){
				
				return null;
			}
			
			return res;
	}
	
	// json 변환
	function makeJson(body){
		return JSON.stringify(body);
	}
	
	// 페이지 이동
	function goPage(url){
		window.location.href = "${pageContext.request.contextPath}" + url;
	} 
	
	// 페이지 이동(replace)
	function replacePage(url){
		window.location.replace("${pageContext.request.contextPath}" + url);
	}
	
	// 서브페이지 적용
	function loadSubpage(subpageDiv,res){
		subpageDiv.innerHTML = "";
		subpageDiv.innerHTML = res;
	}
	
	// 서브페이지 적용 시 title 숨기기 (특정 단계에서만)
	function loadSubpageHideTitle(subpageDiv, res){
	    // title 숨기기
	    const mainTitle = document.getElementById("mainTitle");
	    if(mainTitle) {
	        mainTitle.style.display = "none";
	    }
	    
	    subpageDiv.innerHTML = "";
	    subpageDiv.innerHTML = res;
	}
	
	// 탭 활성화 상태 변경 함수 추가
	function setActiveTab(clickedTab) {
	    document.querySelectorAll('.find-id, .find-pw').forEach(tab => {
	        tab.classList.remove('active');
	    });
	    clickedTab.classList.add('active');
	}
	// 아이디 찾기 서브페이지
	async function showFindIdSubpage(clickedTab){
		if(clickedTab) setActiveTab(clickedTab);
		
		//url
		url = "/user/viewfindIdSubpage.do";
		// subpage 받아오기
		res = await apiService(url);
		
		if(!res) return;
		
		const html = await res.text();
		
		// 결과 출력
		loadSubpage(subpageDiv,html);
		
	}
	
	// 비밀번호 찾기 서브페이지
	async function showFindPwdSubpage(clickedTab){
		if(clickedTab) setActiveTab(clickedTab);
		
		//url
		url = "/user/viewfindPwdSubpage.do";
		// subpage 받아오기
		res = await apiService(url);
		
		if(!res) return;
		
		const html = await res.text();
		
		// 결과 출력
		loadSubpage(subpageDiv,html);
		// 서브페이지 로드 후 이메일 인증 버튼 초기화
		setTimeout(() => {
	        initEmailAuthButton();
	    }, 100);
	}
	
	// 아이디 찾기 로직
	async function findId(){
		const name = document.getElementById("name")?.value;
		const phone = document.getElementById("phone")?.value;
		
		url = "/user/findId"
		
		body = makeJson({
			u_name : name
			, u_phone : phone
		});
		
		res = await apiService(
				url,
				{
					method : 'POST',
					headers : {
						'Content-Type':'application/json'
					},
					credentials : 'same-origin',
					cache: 'no-store',	
				},
				body
			);
		
		if(!res){
			return;
		}
		
		const result = await res.json();
		
		const alert = document.getElementById("");
		if(!result.ok){
			showAlert(result.msg);
			return;
		}else{
			viewShowMaskedIdSubpage(result.maskedId);
			return;
		}
		
	}
	
	// 마스크 된 아이디를 보여주는 서브페이지 출력
	async function viewShowMaskedIdSubpage(maskedId){
		
		url = "/user/viewShowMaskedIdSubpage.do?maskedId="+maskedId;
		
		res = await apiService(url);
		
		if(!res){
			return;
		}
		
		const html = await res.text();
		
		loadSubpage(subpageDiv, html);
	}
	
	// 로그인 화면으로 돌아가기.
	function goBackLogin(){
		alert("로그인 페이지로 돌아갑니다.");
		goPage("/user/login.do");
	}
	
	// ============ 이메일 인증 관련 함수들 ============

	// 이메일 인증 요청
	async function requestEmailAuth(){
	    const email = document.getElementById('email')?.value;
	    
	    if(!email || email.trim() === ""){
	        alert("이메일을 입력해주세요.");
	        return;
	    }
	    
	    const res = await fetch("${pageContext.request.contextPath}/user/request", {
	        method: "POST",
	        headers: {"Content-Type":"application/json"},
	        credentials: "same-origin",
	        cache: "no-store",
	        body: JSON.stringify({"u_email": email})
	    });
	    
	    if(!res.ok){
	        showAlert("인증메일 발송에 실패했습니다.");
	        return;
	    }
	    
	    const data = await res.json();
	    alert(data.msg);
	}

	// 이메일 인증 완료 확인
	async function isEmailVerified(email){
	    try {
	        const res = await fetch("${pageContext.request.contextPath}/user/isRegisterEmailVerified", {
	            method: "POST",
	            headers: {"Content-Type":"application/json", "Accept": "application/json"},
	            credentials: "same-origin",
	            body: JSON.stringify({ email })
	        });
	        
	        if(!res.ok) return false;
	        
	        const contentType = res.headers.get("content-type") || "";
	        if(!contentType.includes("application/json")) return false;
	        
	        const json = await res.json();
	        return json.verified === true;
	        
	    } catch(e) {
	        console.error("[isEmailVerified] error", e);
	        return false;
	    }
	}

	// 이메일 입력 감지하여 인증 버튼 활성화/비활성화
	function initEmailAuthButton(){
	    const emailInput = document.getElementById('email');
	    const confirmBtn = document.getElementById('emailAuthBtn');
	    
	    if(!emailInput || !confirmBtn) return;
	    
	    // 초기: 비활성화
	    confirmBtn.disabled = true;
	    confirmBtn.style.backgroundColor = '#ADADAD';
	    confirmBtn.style.cursor = 'not-allowed';
	    
	    emailInput.addEventListener('input', function(){
	        if(emailInput.value.trim().length > 0){
	            confirmBtn.disabled = false;
	            confirmBtn.style.backgroundColor = '#6955A2';
	            confirmBtn.style.cursor = 'pointer';
	        } else {
	            confirmBtn.disabled = true;
	            confirmBtn.style.backgroundColor = '#ADADAD';
	            confirmBtn.style.cursor = 'not-allowed';
	        }
	    });
	}
	
	//비밀번호 인증하기
	async function authPwd(){
		const name = document.getElementById("name")?.value;
		const phone = document.getElementById("email")?.value;
		const id = document.getElementById("id")?.value;
		
		url = "/user/authPwd";
		
		body = makeJson({
			u_name : name
			, u_email : email
			,u_login_id : id
		});
		
		res = await apiService(
				url,
				{
					method : 'POST',
					headers : {
						'Content-Type':'application/json'
					},
					credentials : 'same-origin',
					cache: 'no-store',	
				},
				body
			);
		
		if(!res){
			return;
		}
		
		const result = await res.json();
		
		if(!result.ok){
			showAlert(result.msg);
			return;
		}else{
			viewInputAuthNumberSubpage(result.uId);
			return;
		}
		
	}
	
	// 인증번호 전송 페이지 보여주기
	async function viewInputAuthNumberSubpage(uId){
		url = "/user/viewInputAuthNumberSubpage.do?uId="+uId;
		
		res = await apiService(url);
		
		if(!res){
			return;
		}
		
		const html = await res.text();
		
		loadSubpage(subpageDiv, html);
	}
	
	// 인증번호 인증하기
	async function authNumber(uId){
		const authNumber = document.getElementById("authNumber")?.value;
		
		url = "/user/authNumber";
		
		body = makeJson({
			authNumber : authNumber
		});
		
		res = await apiService(
				url,
				{
					method : 'POST',
					headers : {
						'Content-Type':'application/json'
					},
					credentials : 'same-origin',
					cache: 'no-store',	
				},
				body
			);
		
		if(!res){
			return;
		}
		
		const result = await res.json();
		
		if(!result.ok){
			showAlert(result.msg);
			return;
		}else{
			viewResetPwdSubpage(uId);
			return;
		}
	}
	
	// 비밀번호 리셋 서브페이지 보여주기
	async function viewResetPwdSubpage(uId){
		
		url = "/user/viewResetPwdSubpage.do?uId="+uId;
		
		res = await apiService(url);
		
		if(!res){
			return;
		}
		
		const html = await res.text();
		
		loadSubpage(subpageDiv, html);
	}
	
	// 비밀번호 리셋
	async function resetPwd(uId){
		const pwd = document.getElementById("pwd")?.value;
		const rePwd = document.getElementById("rePwd")?.value;
		
		url = "/user/resetPwd";
		
		body = makeJson({
			u_id : uId
			, u_login_pwd : pwd

		});
		
		res = await apiService(
				url,
				{
					method : 'POST',
					headers : {
						'Content-Type':'application/json'
					},
					credentials : 'same-origin',
					cache: 'no-store',	
				},
				body
			);
		
		if(!res){
			return;
		}
		
		const result = await res.json();
		
		if(!result.ok){
			showAlert(result.msg);
			return;
		}else{
			goBackLogin();
			return;
		}  
		
	}
	
	//id 찾기 서브페이지를 불러오기
	showFindIdSubpage();
	
</script>
</html>