<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<script>
	
	//비번 규칙: 6~20글자 / 영문+숫자+특수문자 각 1개 이상 / 공백 불가
	const PASSWORD_RULE = /^(?=.*[A-Za-z])(?=.*\d)(?=.*[^\w\s])\S{6,20}$/;
	
	function updatePwd(uId){
		
		let newPwd = documnet.getElementById("newPwd").value;
		if(newPwd == null || newPwd == undefined || newPwd == ""){
			alert("새 비밀번호를 입력해 주세요.");
			return;
		}
		if(!PASSWORD_RULE.test(newPwd)){
			alert("새 비밀번호는 6자 - 20자 사이여야 하고, 영문, 숫자, 특수문자 1개 이상을 포함하는 문자열이여야 합니다.");
			return;
		}
			
		let reNewPwd = document.getElementById("reNewPwd").value;
		if(reNewPwd == null || reNewPwd == undefined || newPwd !== reNewPwd){
			alert("새 비밀번호 값과 다시 입력한 새 비밀변호 값이 다릅니다.");
			return;
		}
		
		axios.post('/gov-disabled-web-gs/user/updateNewPwd',{
			uId : uId
			, newPwd : newPwd
		})
		.then(function(r){
			if(r.data?.ok){
				window.location.href = "/gov-disabled-web-gs/stats/viewStat.do";
			}
			else{
				alert(r.data?.msg);
			}
		})
		.catch(function(e)){
			alert("비밀번호를 확인해주세요.");
		}
			
	}

</script>
<body>
	<div>
		<h3>비밀번호 재설정</h3>
		<input type="password" id = "newPwd" name="newPwd" placeholder="새 비밀번호를 입력하세요.">
		<h1>영문, 숫자, 특수문자 6-20자</h1>
		<input type="password" id = "reNewPwd" name="newPwd" placeholder="새 비밀번호를 다시 한번 입력하세요.">
		<button type="button" onclick="updatePwd('${uId}')"> 비밀번호 재설정하기 </button>
	</div>
</body>
</html>