<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<div>
	<p class="find-info">
		비밀번호를 잊어버리셨나요? <br> 하단의 정보를 상세히 입력하세요.
	</p>
	<div class="fields">
		<div class="input-group">
			<input type="text" class="line-input" id="name"	placeholder="이름을 입력하세요."> 
			<input type="text" class="line-input" id="id" placeholder="아이디를 입력하세요.">

			<%-- 이메일 + 인증 버튼 --%>
			<div class="email-wrapper">
				<input type="email" class="line-input" id="email" placeholder="이메일을 입력하세요.">
				<button type="button" class="confirm" id="emailAuthBtn" onclick="requestEmailAuth()" disabled>인증</button>
			</div>
		</div>
		<div class="submitgroup">
			<p id="alert" class="error-message"></p>
			<button class="primary-btn" type="button" onclick="authPwd()">인증하기</button>
		</div>
	</div>
</div>