<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%> 
<!DOCTYPE html> 
<html> 
<head> 
<meta charset="UTF-8"> 
<title>비밀번호 재설정</title> 
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/pwdChanged.css"> <!-- CSS 불러오기 -->
<script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script> 
<script> 
	//비밀번호 보기/숨기기 토글
	function togglePwd(id, iconId) {
	  const input = document.getElementById(id);
	  const icon = document.getElementById(iconId);
	  if (input.type === "password") {
	    input.type = "text";
	    icon.innerHTML = `
	      <svg width="22" height="16" viewBox="0 0 22 16" fill="none" xmlns="http://www.w3.org/2000/svg">
	        <path d="M9.53005 0.873782C9.95162 0.824971 10.3757 0.800597 10.8 0.800782C15.464 0.800782 19.2 3.70378 20.8 7.80078C20.4127 8.79734 19.8894 9.73555 19.245 10.5888M5.32005 2.31978C3.28005 3.56478 1.70005 5.49378 0.800049 7.80078C2.40005 11.8978 6.13605 14.8008 10.8 14.8008C12.7322 14.811 14.6292 14.2848 16.28 13.2808M8.68005 5.68078C8.40145 5.95938 8.18045 6.29013 8.02968 6.65413C7.8789 7.01814 7.80129 7.40828 7.80129 7.80228C7.80129 8.19628 7.8789 8.58642 8.02968 8.95043C8.18045 9.31444 8.40145 9.64518 8.68005 9.92378C8.95865 10.2024 9.28939 10.4234 9.6534 10.5742C10.0174 10.7249 10.4075 10.8025 10.8015 10.8025C11.1955 10.8025 11.5857 10.7249 11.9497 10.5742C12.3137 10.4234 12.6444 10.2024 12.923 9.92378" stroke="#767676" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
	      </svg>`;
	  } else {
	    input.type = "password";
	    icon.innerHTML = `
	      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
	        <path d="M10.73 5.073C11.1516 5.02419 11.5756 4.99982 12 5C16.664 5 20.4 7.903 22 12C21.6126 12.9966 21.0893 13.9348 20.445 14.788M6.52 6.519C4.48 7.764 2.9 9.693 2 12C3.6 16.097 7.336 19 12 19C13.9321 19.0102 15.8292 18.484 17.48 17.48M9.88 9.88C9.6014 10.1586 9.3804 10.4893 9.22963 10.8534C9.07885 11.2174 9.00125 11.6075 9.00125 12.0015C9.00125 12.3955 9.07885 12.7856 9.22963 13.1496C9.3804 13.5137 9.6014 13.8444 9.88 14.123C10.1586 14.4016 10.4893 14.6226 10.8534 14.7734C11.2174 14.9242 11.6075 15.0018 12.0015 15.0018C12.3955 15.0018 12.7856 14.9242 13.1496 14.7734C13.5137 14.6226 13.8444 14.4016 14.123 14.123" stroke="#767676" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
	        <path d="M4 4L20 20" stroke="#767676" stroke-width="1.6" stroke-linecap="round"/>
	      </svg>`;
	  }
	}
	
	//비번 규칙: 6~20글자 / 영문대문자+영문소문자+숫자+특수문자 3종류 이상, 길이 9자 이상 각 1개 이상 / 공백 불가 
	function isValidPassword(pwd) {
	  if (typeof pwd !== 'string') return false;
	
	  // 1) 길이 체크
	  if (pwd.length < 9) {
	    return false;
	  }
	
	  let types = 0;
	
	  // 2) 각 문자 종류별 포함 여부 체크
	  if (/[A-Z]/.test(pwd)) types++;           // 영어 대문자
	  if (/[a-z]/.test(pwd)) types++;           // 영어 소문자
	  if (/[0-9]/.test(pwd)) types++;           // 숫자
	  if (/[^A-Za-z0-9]/.test(pwd)) types++;    // 특수문자 (영문/숫자 제외)
	
	  // 3가지 이상 포함이면 통과
	  return types >= 3;
	}
	
	window.updatePwd = async function(uId){ 
		
		let newPwd = document.getElementById("newPwd").value; 
		
		if(newPwd == null || newPwd == undefined || newPwd == ""){ 
			alert("새 비밀번호를 입력해 주세요."); 
			return; 
		} 
		
		if(!isValidPassword(newPwd)){ 
			alert("영문대문자, 영문소문자, 숫자, 특수문자 중 3개 이상을 포함하며, 9자 이상이어야 합니다."); 
			return; 
		} 
		
		let reNewPwd = document.getElementById("reNewPwd").value; 
		if(reNewPwd == null || reNewPwd == undefined || newPwd !== reNewPwd){ 
			alert("새 비밀번호 값과 다시 입력한 새 비밀번호 값이 다릅니다."); 
			return; 
		} 
		
		try{ 
			const r = await axios.post('${pageContext.request.contextPath}/user/updateNewPwd',{ 
				uId : uId , 
				newPwd : newPwd 
			}); 
			
			if(r.data?.ok){ 
				window.location.replace("${pageContext.request.contextPath}/stats/viewStat.do"); 
			} 
			else{ 
				alert(r.data?.msg); 
				} 
			} 
		
		catch(e){ 
			alert(e); 
		} 
	}
	

  
</script> 
</head> 
<body> 
	<!-- 상단 헤더 공간 (투명, 고정 높이) --> 
	<header class="login-header"></header> 
		<main class="login-wrap"> 
			<!-- 좌측: 제품 사진 --> 
			<section class="bg-panel"> 
				<img src="${pageContext.request.contextPath}/resources/images/product.png" alt="제품 이미지" class="bg-img"> 
			</section> 
			
			<!-- 우측: 비밀번호 재설정 카드 -->
			<section class="form-panel">
			  <div class="login-card">
			    <p class="product-ver">G.Eye-Parking H100 V1.0</p>
			
			    <div class="title-row">
			      <img src="${pageContext.request.contextPath}/resources/images/simbol.png" alt="로고" class="title-icon">
			      <span class="title-text">비밀번호 재설정</span>
			    </div>
			
			    <div class="fields">
			      <!-- 새 비밀번호 -->
			      <div class="input-wrap">
			        <input id="newPwd" class="line-input" type="password" placeholder="새 비밀번호를 입력하세요.">
			        <span class="eye-icon" id="eye1" onclick="togglePwd('newPwd','eye1')">
			          <!-- 눈감은 모양 -->
			          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
			            <path d="M10.73 5.073C11.1516 5.02419 11.5756 4.99982 12 5C16.664 5 20.4 7.903 22 12C21.6126 12.9966 21.0893 13.9348 20.445 14.788M6.52 6.519C4.48 7.764 2.9 9.693 2 12C3.6 16.097 7.336 19 12 19C13.9321 19.0102 15.8292 18.484 17.48 17.48M9.88 9.88C9.6014 10.1586 9.3804 10.4893 9.22963 10.8534C9.07885 11.2174 9.00125 11.6075 9.00125 12.0015C9.00125 12.3955 9.07885 12.7856 9.22963 13.1496C9.3804 13.5137 9.6014 13.8444 9.88 14.123C10.1586 14.4016 10.4893 14.6226 10.8534 14.7734C11.2174 14.9242 11.6075 15.0018 12.0015 15.0018C12.3955 15.0018 12.7856 14.9242 13.1496 14.7734C13.5137 14.6226 13.8444 14.4016 14.123 14.123" stroke="#767676" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
			            <path d="M4 4L20 20" stroke="#767676" stroke-width="1.6" stroke-linecap="round"/>
			          </svg>
			        </span>
			      </div>
			      <p class="hint-text">영문 대문자, 영문 소문자, 숫자, 특수문자 9자 이상</p>
			
			      <!-- 새 비밀번호 확인 -->
			      <div class="input-wrap">
			        <input id="reNewPwd" class="line-input" type="password" placeholder="새 비밀번호를 다시 한 번 입력하세요.">
			        <span class="eye-icon" id="eye2" onclick="togglePwd('reNewPwd','eye2')">
			          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
			            <path d="M10.73 5.073C11.1516 5.02419 11.5756 4.99982 12 5C16.664 5 20.4 7.903 22 12C21.6126 12.9966 21.0893 13.9348 20.445 14.788M6.52 6.519C4.48 7.764 2.9 9.693 2 12C3.6 16.097 7.336 19 12 19C13.9321 19.0102 15.8292 18.484 17.48 17.48M9.88 9.88C9.6014 10.1586 9.3804 10.4893 9.22963 10.8534C9.07885 11.2174 9.00125 11.6075 9.00125 12.0015C9.00125 12.3955 9.07885 12.7856 9.22963 13.1496C9.3804 13.5137 9.6014 13.8444 9.88 14.123C10.1586 14.4016 10.4893 14.6226 10.8534 14.7734C11.2174 14.9242 11.6075 15.0018 12.0015 15.0018C12.3955 15.0018 12.7856 14.9242 13.1496 14.7734C13.5137 14.6226 13.8444 14.4016 14.123 14.123" stroke="#767676" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
			            <path d="M4 4L20 20" stroke="#767676" stroke-width="1.6" stroke-linecap="round"/>
			          </svg>
			        </span>
			      </div>
			
			      <button class="primary-btn" onclick="updatePwd('${uId}')">비밀번호 재설정하기</button>
			    </div>
			  </div>
			</section>
		</main> 
	<footer class="login-footer"></footer> 
</body>
<script>
(function () {
	  // 1) 동일 URL에서 히스토리 트릭: replaceState로 현재 엔트리를 표식으로 바꾸고, 이어서 pushState
	  try {
	    history.replaceState({ pwdChanged: true, mark: 'current' }, "", location.href);
	    history.pushState({ pwdChanged: true, mark: 'stacked' }, "", location.href);
	  } catch (_) {}

	  // 2) 뒤로가기(popstate) 발생 시, 로그인으로 이동 (히스토리 흔적 남기지 않음)
	  window.addEventListener("popstate", function () {
	    location.replace("${pageContext.request.contextPath}/user/login.do");
	  });

	  // 3) bfcache로 복귀되는 경우(브라우저가 페이지를 메모리에서 복원) 강제 이동
	  window.addEventListener("pageshow", function (e) {
	    // e.persisted === true 이면 bfcache 복원
	    if (e.persisted) {
	      location.replace("${pageContext.request.contextPath}/user/login.do");
	      return;
	    }
	    // 일부 브라우저는 navigation API로 back/forward 구분이 가능
	    try {
	      const nav = performance.getEntriesByType && performance.getEntriesByType("navigation")[0];
	      if (nav && nav.type === "back_forward") {
	        location.replace("${pageContext.request.contextPath}/user/login.do");
	      }
	    } catch (_) {}
	  });

	  // 4) 캐시/히스토리 무효화(안전망)
	  try {
	    if (window.performance && performance.navigation && performance.navigation.type === 2) {
	      // type 2: back/forward (구형)
	      location.replace("${pageContext.request.contextPath}/user/login.do");
	    }
	  } catch (_) {}
	})();
</script> 
</html>