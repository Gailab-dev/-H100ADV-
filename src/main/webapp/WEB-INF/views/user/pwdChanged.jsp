<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>비밀번호 재설정</title>
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/login.css">
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/resources/css/pwdChanged.css">
<script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
<script> 
	//비밀번호 보기/숨기기 토글
	function togglePassword(id, iconId) {
	  const input = document.getElementById(id);
	  const icon = document.getElementById(iconId);
	  
	  if (input.type === 'password') {
	    input.type = 'text';
	    icon.src = '${pageContext.request.contextPath}/resources/images/login/eye-open.svg';
	  } else {
	    input.type = 'password';
	    icon.src = '${pageContext.request.contextPath}/resources/images/login/eye-closed.svg';
	  }
	}
	
	//비번 규칙
	function isValidPassword(pwd) {
	  if (typeof pwd !== 'string') return false;
	
	  if (pwd.length < 9) {
	    return false;
	  }
	
	  let types = 0;
	
	  if (/[A-Z]/.test(pwd)) types++;
	  if (/[a-z]/.test(pwd)) types++;
	  if (/[0-9]/.test(pwd)) types++;
	  if (/[^A-Za-z0-9]/.test(pwd)) types++;
	
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
				// patches 2026-07-06: 비밀번호 변경 후 최초 화면을 통계 → 대시보드로 변경
				window.location.replace("${pageContext.request.contextPath}/dashboard");
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
	<header class="login-header"></header>
	<main class="login-wrap">
		<section class="bg-panel">
			<img
				src="${pageContext.request.contextPath}/resources/images/product.png"
				alt="제품 이미지" class="bg-img">
		</section>

		<section class="form-panel">
			<div class="login-card">
				<div class="title-row">
					<span class="title-text">비밀번호 재설정</span>
				</div>

				<div class="fields">
					<div class="input-group">
						<!-- 새 비밀번호 -->
						<div class="password-wrapper">
							<input id="newPwd" class="line-input" type="password"
								placeholder="새 비밀번호를 입력하세요." autocomplete="new-password">
							<button type="button" class="toggle-password"
								onclick="togglePassword('newPwd', 'eyeIcon1')">
								<img id="eyeIcon1"
									src="${pageContext.request.contextPath}/resources/images/login/eye-closed.svg"
									alt="비밀번호 표시">
							</button>
							<p class="hint-text">영문, 숫자, 특수문자 6-20자</p>
						</div>
						

						<!-- 새 비밀번호 확인 -->
						<div class="password-wrapper">
							<input id="reNewPwd" class="line-input" type="password"
								placeholder="새 비밀번호를 다시 한번 입력하세요." autocomplete="new-password">
							<button type="button" class="toggle-password"
								onclick="togglePassword('reNewPwd', 'eyeIcon2')">
								<img id="eyeIcon2"
									src="${pageContext.request.contextPath}/resources/images/login/eye-closed.svg"
									alt="비밀번호 표시">
							</button>
						</div>
					</div>

						<button class="primary-btn" onclick="updatePwd('${uId}')">비밀번호
							재설정하기</button>
					</div>
				</div>
		</section>
	</main>
	<footer class="login-footer"></footer>
</body>
<script>
(function () {
	  try {
	    history.replaceState({ pwdChanged: true, mark: 'current' }, "", location.href);
	    history.pushState({ pwdChanged: true, mark: 'stacked' }, "", location.href);
	  } catch (_) {}

	  window.addEventListener("popstate", function () {
	    location.replace("${pageContext.request.contextPath}/user/login.do");
	  });

	  window.addEventListener("pageshow", function (e) {
	    if (e.persisted) {
	      location.replace("${pageContext.request.contextPath}/user/login.do");
	      return;
	    }
	    try {
	      const nav = performance.getEntriesByType && performance.getEntriesByType("navigation")[0];
	      if (nav && nav.type === "back_forward") {
	        location.replace("${pageContext.request.contextPath}/user/login.do");
	      }
	    } catch (_) {}
	  });

	  try {
	    if (window.performance && performance.navigation && performance.navigation.type === 2) {
	      location.replace("${pageContext.request.contextPath}/user/login.do");
	    }
	  } catch (_) {}
	})();
</script>
</html>