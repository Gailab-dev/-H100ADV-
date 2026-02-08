<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>

	<div class="fields">
		<div class="input-group">
			<input type="text" class="line-input" id="pwd"
				placeholder="비밀번호를 입력하세요.">
						<input type="text" class="line-input" id="rePwd"
				placeholder="비밀번호를 다시 입력하세요.">
				 
		</div>
		<div class="submitgroup">
			<p id="alert" style="color: red;"></p>
			<button class="primary-btn" type="button" onclick="resetPwd(${uId})">
				비밀번호 변경</button>
		</div>
	</div>
	







