<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>login</title> <!-- 페이지 제목 설정 -->
<meta name="viewport" content="width=device-width, initial-scale=1.0"> <!-- 반응형 뷰포트 설정 (모바일 대응) -->
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/login.css"> <!-- CSS 불러오기 -->
</head>
<script>
	
	/*
	* 엔터키 감지하여 로그인 버튼 클릭
		
	$(document).ready(function(){
		
		const enterKeyEvent = document.getElementById('enterKeyEvent');
		enterKeyEvent.addEventListener('keydown',function(event){
			if (event.key === 'Enter'){
				event.preventDefault();
				enterKeyEvent.click();
			}
		})
	})
	*/
	/*
	 * 로그인 정보를 받아서 로그인 가능한 사용자라면 로그인
	 * @param id,pw
	 * @return successMessage or errorMessage
	 */
	async function login(id, pwd) {
		
		console.log(id + " "+ pwd)
		
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
	            const errorHtml = await response.text();
	            console.error("HTML 응답:", errorHtml);
	            throw new Error("서버 응답 오류 " + response.status);
	        }
		    
			const result = await response.json();
			
			if(result.success){
				window.location.href = "/gov-disabled-web-gs/stats/viewStat.do";
			}else {
				alert("로그인 실패");
			}
		}catch (err){
			console.error("로그인 오류:", err);
	        alert("서버 오류: 로그인 요청 처리 실패");
		}
	}
</script>
<body>
	<!-- 상단 헤더 공간 (투명, 고정 높이) -->
    <header class="login-header"></header>

    <main class="login-body">
        <div class="login-container">
            <h3 class="login-title">로그인</h3>

            <p id="showview"></p>

            <input id="id" class="login-input" type="text" placeholder="아이디를 입력해주세요">
            <input id="pwd" class="login-input" type="password" placeholder="비밀번호를 입력해주세요">

            <button id="enterKeyEvent" class="login-button" onclick="login(document.getElementById('id').value, document.getElementById('pwd').value)">
                로그인
            </button>
        </div>
    </main>

    <footer class="login-footer"></footer>
</body>
</html>