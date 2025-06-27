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
	function login(id, pwd) {
		
		// 서버로 값을 넘겨주기 위한 formData 객체
	    const formData = new URLSearchParams();
	    formData.append('id', id);
	    formData.append('pwd', pwd);
		
		fetch('login',{
			method: 'POST',
	  		headers: {
	    		'Content-Type': 'application/x-www-form-urlencoded'
	  		},
	  		body: formData.toString()
		})
		.then(async (response) => {
			  // response로 서버가 응답한 값이 HTML 문서인지 아닌지 알기 위한 header의 Content_Type값
			  const contentType = response.headers.get("Content-Type");
				
			  if (response.redirected) {
			    // 서버가 redirect 시킨 경우, 즉 결과값이 url인 경우
			    window.location.href = response.url;

			  } else if (contentType && contentType.includes("text/html")) {
			    // 응답이 HTML 문서인 경우
			    const html = await response.text();
			    document.open();
			    document.write(html);
			    document.close();

			  } else if (contentType && contentType.includes("application/json")) {
			    // 응답이 JSON인 경우 (에러 메시지 포함)
			    const json = await response.json(); // 로그 확인시 사용
			    alert("로그인 실패");

			  } else {
			    // 일반 텍스트 (예: plain text 에러 메시지)
			    const text = await response.text(); // 로그 확인시 사용
			    alert(text || "알 수 없는 오류");
			  }
			})
			.catch(error => {
			  console.error('로그인 요청 실패:', error);
			  alert("서버 오류 또는 네트워크 오류가 발생했습니다.");
			});
	}
</script>
<body>
	<h3> 메인 화면</h3>


	<p id="showview"></p>
	
	<input id="id" type="text" placeholder="ID를 입력해주세요"></input>
	<input id="pwd" type="password" placeholder="PW를 입력해주세요"></input>
	
	<button onclick="login(document.getElementById('id').value, document.getElementById('pwd').value)"> 로그인 </button>
		
	

</body>
</html>