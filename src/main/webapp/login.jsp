<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<script>
	/*
	 * 로그인 정보를 받아서 로그인 가능한 사용자라면 로그인
	 * @param id,pw
	 * @return successMessage or errorMessage
	 */
	function login() {
		
		let id = document.getElementById("id").value;
		let pw = document.getElementById("pw").value;
		
	    const formData = new URLSearchParams();
	    formData.append('id', id);
	    formData.append('pw', pw);
		
		fetch('login',{
			method: 'POST',
	  		headers: {
	    		'Content-Type': 'application/x-www-form-urlencoded'
	  		},
	  		body: formData.toString()
		})	
		.then(res => res.text())
		.then(html => {
			console.log(html);
		})
		.catch(errorMsg => {
			console.log("error : " + errorMsg);
			alert(errorMsg);
		});
	}
</script>
<body>
	<h1> 로그인 화면 </h1>
	
	<input type="text" id="id" placeholder="아이디"/>
	<input type="text" id="pwd" placeholder="비밀번호"/>
	
	<button onclick="login()"> 로그인</button>
</body>
</html>