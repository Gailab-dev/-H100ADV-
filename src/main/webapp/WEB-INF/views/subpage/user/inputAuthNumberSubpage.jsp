<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<div>
	<h5>인증번호 전송 완료</h5>
	<p>
		고객님의 전화번호로 인증번호를 발송했습니다.<br>
		인증번호가 오지 않으면 스팸함을 확인해주세요.<br>
		재발송을 원할시'재전송'을 눌러주세요.
	</p>
	<p>
		전화번호
	</p>	
	<div>
		<input id="authNumber" type="number" placeholder="인증번호를 입력하세요.">
		<button type="button">재전송</button>
	</div>
	<p id="alert" style="color:red;"></p>
	<button type="button" onclick="authNumber(${uId})">인증하기</button>
</div>