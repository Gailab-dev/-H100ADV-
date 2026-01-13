<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>

<div>

	<p class="find-info">
		아이디를 잊어버리셨나요? <br> 하단의 정보를 상세히 입력하세요.
	</p>

	<div class="fields">
		<div class="input-group">
			<input type="text" class="line-input" id="name"
				placeholder="이름을 입력하세요."> <input type="text"
				class="line-input" id="email" placeholder="이메일을 입력하세요.">
		</div>
		<div class="submitgroup">
			<p id="alert" style="color: red;"></p>
			<button class="primary-btn" type="button" onclick="findId()">
				아이디 찾기</button>
		</div>
	</div>

</div>