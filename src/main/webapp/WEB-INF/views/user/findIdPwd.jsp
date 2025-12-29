<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>
	<div>
		<div>
			<ul>
				<li onclick="showFindIdSubpage()"> 아이디 찾기</li>
				<li onclick="showFindPwdSubpage()"> 비밀번호 찾기 </li>
			</ul>
			<div id ="subpage">
	
			</div>
		</div>
	
	</div>
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
	
	// 아이디 찾기 서브페이지
	async function showFindIdSubpage(){
		
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
	async function showFindPwdSubpage(){
		//url
		url = "/user/viewfindPwdSubpage.do";
		
		// subpage 받아오기
		res = await apiService(url);
		
		if(!res) return;
		
		const html = await res.text();
		
		// 결과 출력
		loadSubpage(subpageDiv,html);
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
	
	//비밀번호 인증하기
	async function authPwd(){
		const name = document.getElementById("name")?.value;
		const phone = document.getElementById("phone")?.value;
		const id = document.getElementById("id")?.value;
		
		url = "/user/authPwd";
		
		body = makeJson({
			u_name : name
			, u_phone : phone
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