<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<div>
	
	<p>
		아이디를 잊어버리셨나요? <br>
		하단의 정보를 상세히 입력하세요.
	</p>
	
	<div>
		<input type="text" id="name" placeholder="이름을 입력하세요.">
		<input type="text" id="phone" placeholder="전화번호를 입력하세요.">
	
	</div>
	<p id="alert" style="color:red;"></p>
	<button type="button" onclick="findId()"> 아이디 찾기 </button>
</div>